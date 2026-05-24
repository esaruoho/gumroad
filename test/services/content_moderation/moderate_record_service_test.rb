# frozen_string_literal: true

require "test_helper"

class ContentModeration::ModerateRecordServiceTest < ActiveSupport::TestCase
  StrategyResult = Struct.new(:status, :reasoning, keyword_init: true)
  FakeStrategy = Struct.new(:result) do
    def perform = result
  end

  class RaisingStrategy
    def initialize(error)
      @error = error
    end

    def perform
      raise @error
    end
  end

  class FakeExtractor
    attr_reader :post_extracted

    def initialize(product_result: default_result, post_result: default_result)
      @product_result = product_result
      @post_result = post_result
    end

    def extract_from_product(_product)
      @product_result
    end

    def extract_from_post(_post)
      @post_extracted = true
      @post_result
    end

    private
      def default_result
        ContentModeration::ContentExtractor::Result.new(text: "Clean content", image_urls: [])
      end
  end

  setup do
    @seller = users(:named_seller)
    @product = links(:named_seller_product)
  end

  test ".check returns passed when the feature flag is off" do
    with_content_extractor_not_called do
      result = with_feature(active: false) { ContentModeration::ModerateRecordService.check(@product, :product) }

      assert_equal true, result.passed
      assert_equal [], result.reasons
    end
  end

  test ".check skips moderation for verified sellers" do
    @seller.update_columns(verified: true)

    with_content_extractor_not_called do
      result = with_feature { ContentModeration::ModerateRecordService.check(@product, :product) }

      assert_equal true, result.passed
      assert_equal [], result.reasons
    end
  end

  test ".check skips moderation for products with moderation disabled" do
    @product.define_singleton_method(:content_moderation_disabled?) { true }

    with_content_extractor_not_called do
      result = with_feature { ContentModeration::ModerateRecordService.check(@product, :product) }

      assert_equal true, result.passed
      assert_equal [], result.reasons
    end
  end

  test ".check returns passed when content is empty" do
    empty_content = ContentModeration::ContentExtractor::Result.new(text: "", image_urls: [])
    extractor = FakeExtractor.new(product_result: empty_content)

    result = with_feature do
      with_extractor(extractor) { ContentModeration::ModerateRecordService.check(@product, :product) }
    end

    assert_equal true, result.passed
  end

  test ".check returns failed with blocklist reasons" do
    result = with_feature do
      with_strategy_results(blocklist: flagged_result("Matched blocked word: banned")) do
        ContentModeration::ModerateRecordService.check(@product, :product)
      end
    end

    assert_equal false, result.passed
    assert_equal ["Matched blocked word: banned"], result.reasons
  end

  test ".check short-circuits without running AI strategies when blocklist flags content" do
    result = with_feature do
      with_strategy_results(
        blocklist: flagged_result("Matched blocked word: banned"),
        classifier: ->(**) { raise "classifier should not run" },
        prompt: ->(**) { raise "prompt should not run" }
      ) do
        ContentModeration::ModerateRecordService.check(@product, :product)
      end
    end

    assert_equal false, result.passed
  end

  test ".check leaves a note on the user for Gumclaw review when blocklist flags content" do
    assert_difference -> { @seller.reload.comments.count }, 1 do
      with_feature do
        with_strategy_results(blocklist: flagged_result("Matched blocked word: banned")) do
          ContentModeration::ModerateRecordService.check(@product, :product)
        end
      end
    end

    comment = @seller.comments.last
    assert_equal Comment::COMMENT_TYPE_NOTE, comment.comment_type
    assert_equal ContentModeration::ModerateRecordService::AUTHOR_NAME, comment.author_name
    assert_includes comment.content, "Product ##{@product.id}"
    assert_includes comment.content, "Matched blocked word: banned"
  end

  test ".check does not create a duplicate note on rapid retries with identical content" do
    with_feature do
      with_strategy_results(blocklist: flagged_result("Matched blocked word: banned")) do
        ContentModeration::ModerateRecordService.check(@product, :product)

        assert_no_difference -> { @seller.reload.comments.count } do
          ContentModeration::ModerateRecordService.check(@product, :product)
          ContentModeration::ModerateRecordService.check(@product, :product)
        end
      end
    end
  end

  test ".check creates a fresh note once the dedup window has elapsed" do
    with_feature do
      with_strategy_results(blocklist: flagged_result("Matched blocked word: banned")) do
        ContentModeration::ModerateRecordService.check(@product, :product)

        travel_to(ContentModeration::ModerateRecordService::ADMIN_COMMENT_DEDUP_WINDOW.from_now + 1.second) do
          assert_difference -> { @seller.reload.comments.count }, 1 do
            ContentModeration::ModerateRecordService.check(@product, :product)
          end
        end
      end
    end
  end

  test ".check returns failed with AI reasons when an AI strategy flags content" do
    result = with_feature do
      with_strategy_results(classifier: flagged_result("OpenAI moderation flagged: sexual")) do
        ContentModeration::ModerateRecordService.check(@product, :product)
      end
    end

    assert_equal false, result.passed
    assert_includes result.reasons, "OpenAI moderation flagged: sexual"
  end

  test ".check leaves a note on the user when an AI strategy flags content" do
    assert_difference -> { @seller.reload.comments.count }, 1 do
      with_feature do
        with_strategy_results(classifier: flagged_result("OpenAI moderation flagged: sexual")) do
          ContentModeration::ModerateRecordService.check(@product, :product)
        end
      end
    end

    assert_includes @seller.comments.last.content, "OpenAI moderation flagged: sexual"
  end

  test ".check returns passed without creating a comment when all strategies are compliant" do
    result = nil

    assert_no_difference -> { @seller.reload.comments.count } do
      result = with_feature do
        with_strategy_results { ContentModeration::ModerateRecordService.check(@product, :product) }
      end
    end

    assert_equal true, result.passed
    assert_equal [], result.reasons
  end

  test ".check propagates errors raised by AI strategies" do
    error = assert_raises(StandardError) do
      with_feature do
        with_strategy_results(classifier: RaisingStrategy.new(StandardError.new("OpenAI down"))) do
          ContentModeration::ModerateRecordService.check(@product, :product)
        end
      end
    end

    assert_equal "OpenAI down", error.message
  end

  test ".check runs the post extractor for posts" do
    post = installments(:published_post)
    extractor = FakeExtractor.new

    with_feature do
      with_extractor(extractor) do
        with_strategy_results { ContentModeration::ModerateRecordService.check(post, :post) }
      end
    end

    assert_equal true, extractor.post_extracted
  end

  private
    def compliant_result = StrategyResult.new(status: "compliant", reasoning: [])

    def flagged_result(reason)
      StrategyResult.new(status: "flagged", reasoning: [reason])
    end

    def with_feature(active: true, &block)
      Feature.stub(:active?, ->(flag) {
        assert_equal :content_moderation, flag
        active
      }, &block)
    end

    def with_content_extractor_not_called(&block)
      ContentModeration::ContentExtractor.stub(:new, -> { raise "content extractor should not run" }, &block)
    end

    def with_extractor(extractor, &block)
      ContentModeration::ContentExtractor.stub(:new, extractor, &block)
    end

    def with_strategy_results(blocklist: compliant_result, classifier: compliant_result, prompt: compliant_result)
      blocklist_strategy = strategy_stub(blocklist)
      classifier_strategy = strategy_stub(classifier)
      prompt_strategy = strategy_stub(prompt)

      ContentModeration::Strategies::BlocklistStrategy.stub(:new, blocklist_strategy) do
        ContentModeration::Strategies::ClassifierStrategy.stub(:new, classifier_strategy) do
          ContentModeration::Strategies::PromptStrategy.stub(:new, prompt_strategy) do
            yield
          end
        end
      end
    end

    def strategy_stub(result_or_callable)
      return result_or_callable if result_or_callable.respond_to?(:call)
      return result_or_callable if result_or_callable.respond_to?(:perform)

      FakeStrategy.new(result_or_callable)
    end
end

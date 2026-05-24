# frozen_string_literal: true

require "test_helper"

class SendLastPostJobTest < ActiveSupport::TestCase
  setup do
    @product = links(:named_seller_product)
    # Create a minimal purchase row to drive the job.
    @purchase = Purchase.new(seller: @product.user, link: @product, email: "buyer-#{SecureRandom.hex(4)}@example.com",
                              price_cents: 100, total_transaction_cents: 100, fee_cents: 0,
                              purchase_state: "successful")
    @purchase.save!(validate: false)
  end

  test "no-op when there are no emailable posts for the purchase" do
    Installment.stub(:emailable_posts_for_purchase, ->(purchase:) { Installment.none }) do
      called = false
      PostEmailApi.stub(:process, ->(*_a, **_kw) { called = true }) do
        SendLastPostJob.new.perform(@purchase.id)
      end
      refute called
    end
  end

  test "no-op when posts exist but none pass filters" do
    fake_post = Object.new
    fake_post.define_singleton_method(:purchase_passes_filters) { |_p| false }
    rel = Object.new
    rel.define_singleton_method(:order) { |*_a| [fake_post] }

    Installment.stub(:emailable_posts_for_purchase, ->(purchase:) { rel }) do
      called = false
      PostEmailApi.stub(:process, ->(*_a, **_kw) { called = true }) do
        SendLastPostJob.new.perform(@purchase.id)
      end
      refute called
    end
  end

  test "dispatches PostEmailApi when a matching post is found" do
    fake_post = Object.new
    fake_post.define_singleton_method(:purchase_passes_filters) { |_p| true }
    fake_post.define_singleton_method(:has_files?) { false }
    rel = Object.new
    rel.define_singleton_method(:order) { |*_a| [fake_post] }

    Installment.stub(:emailable_posts_for_purchase, ->(purchase:) { rel }) do
      SentPostEmail.stub(:ensure_uniqueness, ->(post:, email:, &blk) { blk.call }) do
        recipients_seen = nil
        PostEmailApi.stub(:process, ->(post:, recipients:) { recipients_seen = recipients }) do
          SendLastPostJob.new.perform(@purchase.id)
        end
        assert_equal 1, recipients_seen.size
        assert_equal @purchase.email, recipients_seen.first[:email]
      end
    end
  end
end

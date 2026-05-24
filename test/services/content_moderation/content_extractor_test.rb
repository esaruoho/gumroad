# frozen_string_literal: true

require "test_helper"

class ContentModeration::ContentExtractorTest < ActiveSupport::TestCase
  # The product extraction path (extract_from_product) is heavily entangled
  # with AssetPreview + ProductRichContent + ProductFile S3-key/signed-URL
  # plumbing that the RSpec suite stubbed via instance_double. Building real
  # fixture rows for those collaborators is out of scope here. The post
  # extraction path (#extract_from_post) is pure Nokogiri parsing and ports
  # directly — that's what we cover below.

  setup do
    @extractor = ContentModeration::ContentExtractor.new
  end

  test "#extract_from_post parses HTML and extracts name + message text and image URLs" do
    post = Installment.new(
      name: "Moderated Post",
      message: '<div><p>Hello <strong>world</strong></p><img src="https://cdn.example.com/post.png"></div>',
    )
    result = @extractor.extract_from_post(post)

    assert_equal "Name: Moderated Post Message: Hello world", result.text
    assert_equal ["https://cdn.example.com/post.png"], result.image_urls
  end

  test "#extract_from_post ignores images without a src attribute" do
    post = Installment.new(
      name: "Moderated Post",
      message: '<div><p>Hello</p><img><img src="https://cdn.example.com/post.png"></div>',
    )
    result = @extractor.extract_from_post(post)
    assert_equal ["https://cdn.example.com/post.png"], result.image_urls
  end

  test "#extract_from_post ignores images with an empty src attribute" do
    post = Installment.new(
      name: "Moderated Post",
      message: '<div><p>Hello</p><img src=""><img src="https://cdn.example.com/post.png"></div>',
    )
    result = @extractor.extract_from_post(post)
    assert_equal ["https://cdn.example.com/post.png"], result.image_urls
  end

  test "#extract_from_post parses the post HTML only once" do
    post = Installment.new(
      name: "Moderated Post",
      message: '<div><p>Hello <strong>world</strong></p><img src="https://cdn.example.com/post.png"></div>',
    )

    parse_count = 0
    original = Nokogiri.singleton_class.instance_method(:HTML)
    Nokogiri.singleton_class.define_method(:HTML) do |*args, **kwargs|
      parse_count += 1
      original.bind(self).call(*args, **kwargs)
    end
    begin
      @extractor.extract_from_post(post)
    ensure
      Nokogiri.singleton_class.send(:remove_method, :HTML)
      Nokogiri.singleton_class.define_method(:HTML, original)
    end
    assert_equal 1, parse_count
  end
end

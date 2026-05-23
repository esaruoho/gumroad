# frozen_string_literal: true

require "test_helper"

class OEmbedFinderTest < ActiveSupport::TestCase
  def setup
    @response_mock = Object.new
    @register_calls = 0
    OEmbed::Providers.define_singleton_method(:register_all) { |*| }
  end

  def stub_provider_get(response)
    OEmbed::Providers.define_singleton_method(:get) { |_url, **_opts| response }
  end

  def stub_provider_get_raises(error)
    OEmbed::Providers.define_singleton_method(:get) { |_url, **_opts| raise error }
  end

  def teardown
    # Restore real methods by removing our singleton overrides if present.
    [:register_all, :get].each do |m|
      OEmbed::Providers.singleton_class.remove_method(m)
    rescue NameError
      # no-op if the override wasn't defined
    end
  end

  def make_video_response(html)
    response = Object.new
    response.define_singleton_method(:video?) { true }
    response.define_singleton_method(:fields) do
      {
        "width" => 600,
        "height" => 400,
        "thumbnail_url" => "http://example.com/url-to-thumbnail.jpg",
        "thumbnail_width" => 200,
        "thumbnail_height" => 133
      }
    end
    response.define_singleton_method(:html) { html }
    response
  end

  def make_photo_response(html)
    response = Object.new
    response.define_singleton_method(:video?) { false }
    response.define_singleton_method(:rich?) { false }
    response.define_singleton_method(:photo?) { true }
    response.define_singleton_method(:html) { html }
    response
  end

  test "returns nil if there is an exception when getting oembed" do
    stub_provider_get_raises(StandardError)
    assert_nil OEmbedFinder.embeddable_from_url("some url")
  end

  test "video: returns plain embeddable" do
    embeddable = "<oembed/>"
    stub_provider_get(make_video_response(embeddable))
    result = OEmbedFinder.embeddable_from_url("url")
    assert_equal embeddable, result[:html]
    assert_equal({
      "width" => 600,
      "height" => 400,
      "thumbnail_url" => "http://example.com/url-to-thumbnail.jpg"
    }, result[:info])
  end

  test "soundcloud: replaces http with https" do
    embeddable = "<oembed><author_url>http://w.soundcloud.com</author_url><provider_url>api.soundcloud.com</provider_url></oembed>"
    processed = "<oembed><author_url>https://w.soundcloud.com</author_url><provider_url>api.soundcloud.com</provider_url></oembed>"
    stub_provider_get(make_video_response(embeddable))
    assert_equal processed, OEmbedFinder.embeddable_from_url("url")[:html]
  end

  test "soundcloud: replaces show_artwork payload with all available payloads with false value" do
    embeddable = "<oembed><author_url>http://w.soundcloud.com?show_artwork=true</author_url><provider_url>api.soundcloud.com</provider_url></oembed>"
    all_payloads_with_false = OEmbedFinder::SOUNDCLOUD_PARAMS.map { |k| "#{k}=false" }.join("&")
    processed = "<oembed><author_url>https://w.soundcloud.com?#{all_payloads_with_false}</author_url>" \
                "<provider_url>api.soundcloud.com</provider_url></oembed>"
    stub_provider_get(make_video_response(embeddable))
    assert_equal processed, OEmbedFinder.embeddable_from_url("url")[:html]
  end

  test "youtube: replaces http with https" do
    embeddable = "<oembed><author_url>http://www.youtube.com/embed</author_url></oembed>"
    processed = "<oembed><author_url>https://www.youtube.com/embed</author_url></oembed>"
    stub_provider_get(make_video_response(embeddable))
    assert_equal processed, OEmbedFinder.embeddable_from_url("url")[:html]
  end

  test "youtube: adds showinfo and controls payloads" do
    embeddable = "<oembed><author_url>https://www.youtube.com/embed?feature=oembed</author_url></oembed>"
    processed = "<oembed><author_url>https://www.youtube.com/embed?feature=oembed&showinfo=0&controls=0&rel=0</author_url></oembed>"
    stub_provider_get(make_video_response(embeddable))
    assert_equal processed, OEmbedFinder.embeddable_from_url("url")[:html]
  end

  test "vimeo: replaces http with https" do
    embeddable = "<oembed><author_url>http://player.vimeo.com/video/71588076</author_url></oembed>"
    processed = "<oembed><author_url>https://player.vimeo.com/video/71588076</author_url></oembed>"
    stub_provider_get(make_video_response(embeddable))
    assert_equal processed, OEmbedFinder.embeddable_from_url("url")[:html]
  end

  test "photo: returns nil so that we fallback to default preview container" do
    stub_provider_get(make_photo_response("Some image"))
    assert_nil OEmbedFinder.embeddable_from_url("https://www.flickr.com/id=1")
  end
end

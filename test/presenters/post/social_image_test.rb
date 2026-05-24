# frozen_string_literal: true

require "test_helper"

class Post::SocialImageTest < ActiveSupport::TestCase
  test "parses the embedded image correctly" do
    content = <<~HTML
      <p>First paragraph</p>
      <figure>
        <img src="path/to/image.jpg">
        <p class="figcaption">Image description</p>
      </figure>
      <p>Second paragraph</p>
    HTML
    social_image = Post::SocialImage.for(content)
    assert_equal "path/to/image.jpg", social_image.url
    assert_equal "Image description", social_image.caption
    assert_not social_image.blank?
  end

  test "sets the full social image URL when image is an ActiveStorage upload" do
    content = <<~HTML
      <p>First paragraph</p>
      <figure>
        <img src="#{AWS_S3_ENDPOINT}/#{PUBLIC_STORAGE_S3_BUCKET}/blobKey">
        <p class="figcaption">Image description</p>
      </figure>
      <p>Second paragraph</p>
    HTML
    social_image = Post::SocialImage.for(content)
    assert_equal "#{AWS_S3_ENDPOINT}/#{PUBLIC_STORAGE_S3_BUCKET}/blobKey", social_image.url
  end

  test "is blank when no embedded image" do
    social_image = Post::SocialImage.for("<p>hi!</p>")
    assert social_image.url.blank?
    assert social_image.caption.blank?
    assert social_image.blank?
  end

  test "uses the first image when multiple embedded images" do
    content = <<~HTML
      <figure>
        <img src="path/to/first_image.jpg">
        <p class="figcaption">First image description</p>
      </figure>
      <figure>
        <img src="path/to/second_image.jpg">
        <p class="figcaption">Second image description</p>
      </figure>
    HTML
    social_image = Post::SocialImage.for(content)
    assert_equal "path/to/first_image.jpg", social_image.url
    assert_equal "First image description", social_image.caption
  end

  test "does not use second image's caption when first image has no caption" do
    content = <<~HTML
      <figure>
        <img src="path/to/first_image.jpg">
      </figure>
      <figure>
        <img src="path/to/second_image.jpg">
        <p class="figcaption">Second image description</p>
      </figure>
    HTML
    social_image = Post::SocialImage.for(content)
    assert_equal "path/to/first_image.jpg", social_image.url
    assert social_image.caption.blank?
  end

  test "ignores non-image embeds when different media types are embedded" do
    content = <<~HTML
      <figure>
        <iframe src="embedded_tweet"/>
      </figure>
      <figure>
        <img src="path/to/image.jpg">
        <p class="figcaption">Image description</p>
      </figure>
    HTML
    social_image = Post::SocialImage.for(content)
    assert_equal "path/to/image.jpg", social_image.url
    assert_equal "Image description", social_image.caption
  end
end

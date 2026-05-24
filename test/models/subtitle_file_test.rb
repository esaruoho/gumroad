require "test_helper"

class SubtitleFileTest < ActiveSupport::TestCase
  def build_subtitle(**attrs)
    SubtitleFile.new({
      product_file: product_files(:signed_url_helper_pdf),
      url: "#{AWS_S3_ENDPOINT}/#{S3_BUCKET}/#{SecureRandom.hex}.srt",
      language: "English",
    }.merge(attrs))
  end

  # Invalid types
  ["txt", "mov", "mp4", "mp3"].each do |ft|
    test "invalid file type #{ft} is invalid" do
      assert_not build_subtitle(url: "subtitle.#{ft}").valid?
    end

    test "invalid file type #{ft} does not save the record" do
      subtitle = build_subtitle(url: "subtitle.#{ft}")
      assert_no_difference -> { SubtitleFile.count } do
        subtitle.save
      end
    end

    test "invalid file type #{ft} displays an unsupported file type error message" do
      subtitle = build_subtitle(url: "subtitle.#{ft}")
      subtitle.save
      assert_includes subtitle.errors.full_messages[0], "Subtitle type not supported."
    end
  end

  test "invalid type with S3 URL is invalid" do
    subtitle = build_subtitle(url: "#{AWS_S3_ENDPOINT}/gumroad/attachments/1234/abcdef/original/My Awesome Youtube video.mov")
    assert_not subtitle.valid?
  end

  # Valid types
  ["srt", "sub", "sbv", "vtt"].each do |ft|
    test "valid file type #{ft} is valid" do
      assert build_subtitle(url: "subtitle.#{ft}").valid?
    end

    test "valid file type #{ft} saves the record" do
      subtitle = build_subtitle(url: "subtitle.#{ft}")
      assert_difference -> { SubtitleFile.count }, 1 do
        subtitle.save
      end
    end
  end

  test "valid type with S3 URL is valid" do
    subtitle = build_subtitle(url: "#{AWS_S3_ENDPOINT}/gumroad/attachments/1234/abcdef/original/My Subtitle.sub")
    assert subtitle.valid?
  end

  test "updating to an invalid type is invalid" do
    subtitle = build_subtitle(url: "subtitle.pdf")
    subtitle.save!(validate: false)
    subtitle.url = "subtitle.txt"
    assert_equal false, subtitle.save
    assert_includes subtitle.errors.full_messages[0], "Subtitle type not supported."
  end

  test "#has_alive_duplicate_files? returns true when an alive record with the same url exists" do
    url = "#{AWS_S3_ENDPOINT}/#{S3_BUCKET}/some-file.srt"
    file_1 = SubtitleFile.create!(product_file: product_files(:signed_url_helper_pdf), url: url, language: "English")
    file_2 = SubtitleFile.create!(product_file: product_files(:signed_url_helper_pdf), url: url, language: "English")
    file_1.mark_deleted
    file_1.save!
    assert_equal true, file_1.has_alive_duplicate_files?
    assert_equal true, file_2.has_alive_duplicate_files?
  end

  test "#has_alive_duplicate_files? returns false when no other alive record with the same url" do
    url = "#{AWS_S3_ENDPOINT}/#{S3_BUCKET}/some-file.srt"
    file_1 = SubtitleFile.create!(product_file: product_files(:signed_url_helper_pdf), url: url, language: "English")
    file_2 = SubtitleFile.create!(product_file: product_files(:signed_url_helper_pdf), url: url, language: "English")
    file_1.mark_deleted
    file_1.save!
    file_2.mark_deleted
    file_2.save!
    assert_equal false, file_1.has_alive_duplicate_files?
    assert_equal false, file_2.has_alive_duplicate_files?
  end
end

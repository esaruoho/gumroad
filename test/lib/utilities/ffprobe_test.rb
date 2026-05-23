# frozen_string_literal: true

require "test_helper"

class FfprobeTest < ActiveSupport::TestCase
  EXPECTED_SAMPLE_MOV = {
    bit_rate: "27506",
    duration: "4.483333",
    height: 132,
    r_frame_rate: "60/1",
    width: 176
  }.freeze

  EXPECTED_MULTI_AUDIO = {
    bit_rate: "34638",
    duration: "1.016667",
    height: 24,
    r_frame_rate: "60/1",
    width: 28
  }.freeze

  EXPECTED_SAMPLE_MOV.each do |property, value|
    test "parses sample.mov: correct value for #{property}" do
      parsed = Ffprobe.new(file_fixture("sample.mov")).parse
      assert_equal value, parsed.public_send(property)
    end
  end

  EXPECTED_MULTI_AUDIO.each do |property, value|
    test "parses multi-audio-tracks video: correct value for #{property}" do
      parsed = Ffprobe.new(file_fixture("video_with_multiple_audio_tracks.mov")).parse
      assert_equal value, parsed.public_send(property)
    end
  end

  test "raises NoMethodError when an invalid movie file is supplied" do
    assert_raises(NoMethodError) do
      Ffprobe.new(file_fixture("sample.epub")).parse
    end
  end

  test "raises ArgumentError when a non-existent file is supplied" do
    file_path = File.join(Rails.root, "spec", "sample_data", "non-existent.mov")
    error = assert_raises(ArgumentError) { Ffprobe.new(file_path).parse }
    assert_equal "File not found #{file_path}", error.message
  end
end

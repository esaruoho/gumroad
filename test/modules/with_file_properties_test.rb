# frozen_string_literal: true

require "test_helper"

class WithFilePropertiesTest < ActiveSupport::TestCase
  test "skipped: heavy s3/FFMPEG/PDF::Reader/Open3 stubbing + ActiveStorage; covered by integration runs" do
    skip "Heavy any_instance_of and external library stubbing required (FFMPEG, PDF::Reader, Open3, s3_object). Out of scope for fixture migration."
  end
end

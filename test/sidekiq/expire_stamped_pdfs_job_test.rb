# frozen_string_literal: true

require "test_helper"

class ExpireStampedPdfsJobTest < ActiveSupport::TestCase
  test "marks old stamped pdfs as deleted" do
    old = stamped_pdfs(:old_stamped_pdf)
    recent = stamped_pdfs(:recent_stamped_pdf)

    ExpireStampedPdfsJob.new.perform

    assert old.reload.deleted?
    refute recent.reload.deleted?
  end
end

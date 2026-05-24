# frozen_string_literal: true

require "test_helper"
require "digest"

class LicenseTest < ActiveSupport::TestCase
  setup do
    @product = links(:named_seller_product)
    @purchase = purchases(:licensed_admin_lookup_purchase)
    ElasticsearchIndexerWorker.jobs.clear
  end

  def create_license(**attrs)
    License.create!({ link: @product, purchase: @purchase }.merge(attrs))
  end

  test "validations: does not allow users to unset token" do
    license = create_license
    license.serial = nil
    refute license.valid?
  end

  test "populates serial correctly on new licenses" do
    license = create_license
    assert_match(/\A.{8}-.{8}-.{8}-.{8}\z/, license.serial)
  end

  test "#disabled? returns true when disabled" do
    license = create_license
    license.disabled_at = Date.current
    assert license.disabled?
  end

  test "#disabled? returns false when enabled" do
    license = create_license
    refute license.disabled?
  end

  test "#disable! disables the license" do
    license = create_license
    current_time = Time.current.change(usec: 0)
    travel_to(current_time) do
      assert_equal true, license.disable!
      assert_equal current_time, license.reload.disabled_at
    end
  end

  test "#disable! raises an exception on error" do
    license = create_license
    license.serial = nil
    assert_raises(ActiveRecord::RecordInvalid) { license.disable! }
  end

  test "#enable! enables the license" do
    license = create_license(disabled_at: Time.current)
    assert_equal true, license.enable!
    assert_nil license.reload.disabled_at
  end

  test "#enable! raises an exception on error" do
    license = create_license(disabled_at: Time.current)
    license.serial = nil
    assert_raises(ActiveRecord::RecordInvalid) { license.enable! }
  end

  test "#rotate! generates a new serial key" do
    license = create_license
    old_serial = license.serial
    assert_equal true, license.rotate!
    refute_equal old_serial, license.reload.serial
    assert_match(/\A.{8}-.{8}-.{8}-.{8}\z/, license.serial)
  end

  test "enqueues a purchase re-index when uses changes via increment!" do
    license = create_license
    ElasticsearchIndexerWorker.jobs.clear

    license.increment!(:uses)

    job = ElasticsearchIndexerWorker.jobs.find do |j|
      j["args"][0] == "update" && j["args"][1]["record_id"] == @purchase.id &&
        j["args"][1]["class_name"] == "Purchase" && j["args"][1]["fields"] == ["license_uses"]
    end
    assert job, "expected ElasticsearchIndexerWorker job for license_uses, got #{ElasticsearchIndexerWorker.jobs.inspect}"
  end

  test "enqueues a purchase re-index when serial changes" do
    license = create_license
    ElasticsearchIndexerWorker.jobs.clear

    license.rotate!

    job = ElasticsearchIndexerWorker.jobs.find do |j|
      j["args"][0] == "update" && j["args"][1]["record_id"] == @purchase.id &&
        j["args"][1]["fields"] == ["license_serial"]
    end
    assert job, "expected ElasticsearchIndexerWorker job for license_serial"
  end

  test "does not enqueue a purchase re-index when neither uses nor serial changes" do
    license = create_license
    ElasticsearchIndexerWorker.jobs.clear

    license.update!(disabled_at: Time.current)

    assert_empty ElasticsearchIndexerWorker.jobs
  end

  test "does not enqueue a purchase re-index when there is no associated purchase" do
    license_without_purchase = License.create!(link: @product, purchase: nil)
    ElasticsearchIndexerWorker.jobs.clear

    license_without_purchase.increment!(:uses)

    assert_empty ElasticsearchIndexerWorker.jobs
  end

  test "paper_trail tracks changes to disabled_at when disabling" do
    license = create_license
    with_paper_trail do
      assert_difference -> { license.versions.count }, 1 do
        license.disable!
      end
      assert license.versions.last.changeset.key?("disabled_at")
    end
  end

  test "paper_trail tracks changes to disabled_at when enabling" do
    license = create_license
    with_paper_trail do
      license.disable!
      assert_difference -> { license.versions.count }, 1 do
        license.enable!
      end
      assert license.versions.last.changeset.key?("disabled_at")
    end
  end

  test "paper_trail tracks changes to serial when rotating" do
    license = create_license
    with_paper_trail do
      assert_difference -> { license.versions.count }, 1 do
        license.rotate!
      end
      assert license.versions.last.changeset.key?("serial")
    end
  end

  test "paper_trail does not track changes to uses" do
    license = create_license
    with_paper_trail do
      assert_no_difference -> { license.versions.count } do
        license.increment!(:uses)
      end
    end
  end

  private
    def with_paper_trail
      was_enabled = PaperTrail.enabled?
      PaperTrail.enabled = true
      yield
    ensure
      PaperTrail.enabled = was_enabled
    end
end

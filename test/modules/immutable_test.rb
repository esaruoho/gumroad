# frozen_string_literal: true

require "test_helper"

class ImmutableTest < ActiveSupport::TestCase
  def today
    @today ||= Date.today
  end

  def build_compliance_info(**overrides)
    UserComplianceInfo.new({
      user: users(:basic_user),
      first_name: "Chuck",
      last_name: "Bartowski",
      street_address: "address_full_match",
      city: "San Francisco",
      state: "California",
      zip_code: "94107",
      country: "United States",
      verticals: [Vertical::PUBLISHING],
      is_business: false,
      has_sold_before: false,
      individual_tax_id: "000000000",
      birthday: Date.new(1901, 1, 1),
      dba: "Chuckster",
      phone: "0000000000",
    }.merge(overrides))
  end

  # --- creating ---
  test "is able to create a record" do
    assert build_compliance_info.save!
  end

  # --- updating: no changes ---
  test "is able to update a record with no changes" do
    model = build_compliance_info
    model.save!
    assert model.save!
  end

  # --- updating: changes allowed (deleted_at is attr_mutable) ---
  test "is able to update the record when only mutable attributes change" do
    model = build_compliance_info
    model.save!
    model.deleted_at = Time.current
    assert model.save!
  end

  # --- updating: changes not allowed ---
  test "isn't able to update the record when an immutable attribute changes" do
    model = build_compliance_info
    model.save!
    model.first_name = "Santa Clause"
    assert_raises(Immutable::RecordImmutable) { model.save! }
  end

  # --- #dup_and_save: changes are valid ---
  test "dup_and_save with valid changes returns true and duplicates with the change" do
    model = build_compliance_info(birthday: today - 30.years)
    model.save!
    result, new_model = model.dup_and_save do |nm|
      nm.birthday = today - 20.years
    end
    model.reload
    new_model.reload

    assert_equal true, result
    assert_equal model.class, new_model.class
    assert_equal model.first_name, new_model.first_name
    assert_equal model.last_name, new_model.last_name
    refute_equal model.birthday, new_model.birthday
    assert_equal today - 20.years, new_model.birthday
    assert new_model.id.present?
    assert model.deleted?
  end

  # --- #dup_and_save: changes valid, original values invalid ---
  test "dup_and_save when original record's values are invalid still saves duplicate" do
    model = build_compliance_info(birthday: today - 30.years)
    model.save!
    model.update_column("birthday", today)
    result, new_model = model.dup_and_save do |nm|
      nm.birthday = today - 20.years
    end
    model.reload
    new_model.reload

    assert_equal true, result
    assert_equal today - 20.years, new_model.birthday
    assert new_model.id.present?
    assert model.deleted?
  end

  # --- #dup_and_save: changes are invalid ---
  test "dup_and_save returns false and does not persist or delete when invalid" do
    model = build_compliance_info(birthday: today - 30.years)
    model.save!
    result, new_model = model.dup_and_save do |nm|
      nm.birthday = today
    end
    model.reload

    assert_equal false, result
    assert_equal model.class, new_model.class
    assert_equal today, new_model.birthday
    assert_nil new_model.id
    refute model.deleted?
  end

  # --- #dup_and_save!: changes are valid ---
  test "dup_and_save! with valid changes returns true and duplicates" do
    model = build_compliance_info(birthday: today - 30.years)
    model.save!
    result, new_model = model.dup_and_save! do |nm|
      nm.birthday = today - 20.years
    end
    model.reload
    new_model.reload

    assert_equal true, result
    assert_equal today - 20.years, new_model.birthday
    assert new_model.id.present?
    assert model.deleted?
  end

  # --- #dup_and_save!: changes are invalid ---
  test "dup_and_save! raises a validation error when changes are invalid" do
    model = build_compliance_info
    model.save!
    assert_raises(ActiveRecord::RecordInvalid) do
      model.dup_and_save! do |nm|
        nm.birthday = today
      end
    end
  end

  test "dup_and_save! does not create a new record nor delete original after error" do
    model = build_compliance_info
    model.save!
    model_id = model.id
    assert_raises(ActiveRecord::RecordInvalid) do
      model.dup_and_save! do |nm|
        nm.birthday = today
      end
    end
    found = UserComplianceInfo.find(model_id)
    assert_equal 1, found.user.user_compliance_infos.count
    refute found.deleted?
  end
end

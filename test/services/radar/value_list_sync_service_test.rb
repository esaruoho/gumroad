# frozen_string_literal: true

require "test_helper"

class Radar::ValueListSyncServiceTest < ActiveSupport::TestCase
  ValueList = Struct.new(:id)
  ValueListItem = Struct.new(:id)
  ValueListItems = Struct.new(:data)

  setup do
    @service = Radar::ValueListSyncService.new
  end

  test "#sync_blocked_emails pushes recently blocked emails to Stripe Radar" do
    PlatformBlock.add!(object_type: PlatformBlock::TYPES[:email], object_value: "bad@example.com")
    created_items = []

    with_value_list("gumroad_blocked_emails") do
      Stripe::Radar::ValueListItem.stub(:create, ->(**params) {
        created_items << params
      }) do
        @service.sync_blocked_emails
      end
    end

    assert_equal [{ value_list: "rsl_123", value: "bad@example.com" }], created_items
  end

  test "#sync_blocked_emails skips emails blocked more than 25 hours ago" do
    travel_to 2.days.ago do
      PlatformBlock.add!(object_type: PlatformBlock::TYPES[:email], object_value: "old@example.com")
    end

    with_value_list("gumroad_blocked_emails") do
      Stripe::Radar::ValueListItem.stub(:create, ->(**_params) { flunk "Unexpected Stripe create" }) do
        @service.sync_blocked_emails
      end
    end
  end

  test "#sync_blocked_emails removes recently unblocked emails from Stripe Radar" do
    blocked = PlatformBlock.add!(object_type: PlatformBlock::TYPES[:email], object_value: "unblocked@example.com")
    blocked.unblock!
    deleted_items = []

    with_value_list("gumroad_blocked_emails") do
      with_list_items("rsl_123", "unblocked@example.com", [ValueListItem.new("rsli_456")]) do
        Stripe::Radar::ValueListItem.stub(:delete, ->(id) { deleted_items << id }) do
          @service.sync_blocked_emails
        end
      end
    end

    assert_equal ["rsli_456"], deleted_items
  end

  test "#sync_blocked_emails removes expired blocked emails from Stripe Radar" do
    PlatformBlock.add!(
      object_type: PlatformBlock::TYPES[:email],
      object_value: "expired@example.com",
      expires_in: 1.hour
    )
    deleted_items = []

    travel 2.hours do
      with_value_list("gumroad_blocked_emails") do
        with_list_items("rsl_123", "expired@example.com", [ValueListItem.new("rsli_789")]) do
          Stripe::Radar::ValueListItem.stub(:delete, ->(id) { deleted_items << id }) do
            @service.sync_blocked_emails
          end
        end
      end
    end

    assert_equal ["rsli_789"], deleted_items
  end

  test "#sync_blocked_emails creates the value list if it does not exist" do
    created_lists = []

    Stripe::Radar::ValueList.stub(:retrieve, ->(list_alias) {
      assert_equal "gumroad_blocked_emails", list_alias
      raise Stripe::InvalidRequestError.new("No such value list", "alias", code: "resource_missing")
    }) do
      Stripe::Radar::ValueList.stub(:create, ->(**params) {
        created_lists << params
        ValueList.new("rsl_123")
      }) do
        @service.sync_blocked_emails
      end
    end

    assert_equal [
      {
        alias: "gumroad_blocked_emails",
        name: "Gumroad Blocked Emails",
        item_type: "email"
      }
    ], created_lists
  end

  test "#sync_blocked_emails ignores duplicate item errors" do
    PlatformBlock.add!(object_type: PlatformBlock::TYPES[:email], object_value: "dup@example.com")

    with_value_list("gumroad_blocked_emails") do
      Stripe::Radar::ValueListItem.stub(:create, ->(**_params) {
        raise Stripe::InvalidRequestError.new(
          "This value already exists",
          "value",
          code: "value_list_item_already_exists"
        )
      }) do
        assert_nothing_raised { @service.sync_blocked_emails }
      end
    end
  end

  test "#sync_blocked_emails picks up re-blocked emails by filtering on blocked_at" do
    travel_to 1.month.ago do
      blocked = PlatformBlock.add!(object_type: PlatformBlock::TYPES[:email], object_value: "reblocked@example.com")
      blocked.unblock!
    end
    PlatformBlock.add!(object_type: PlatformBlock::TYPES[:email], object_value: "reblocked@example.com")
    created_items = []

    with_value_list("gumroad_blocked_emails") do
      Stripe::Radar::ValueListItem.stub(:create, ->(**params) {
        created_items << params
      }) do
        @service.sync_blocked_emails
      end
    end

    assert_equal [{ value_list: "rsl_123", value: "reblocked@example.com" }], created_items
  end

  test "#sync_blocked_cards pushes recently blocked card fingerprints to Stripe Radar" do
    PlatformBlock.add!(
      object_type: PlatformBlock::TYPES[:charge_processor_fingerprint],
      object_value: "fpabc123"
    )
    created_items = []

    with_value_list("gumroad_blocked_cards") do
      Stripe::Radar::ValueListItem.stub(:create, ->(**params) {
        created_items << params
      }) do
        @service.sync_blocked_cards
      end
    end

    assert_equal [{ value_list: "rsl_123", value: "fpabc123" }], created_items
  end

  test "#sync_blocked_cards skips fingerprints blocked more than 25 hours ago" do
    travel_to 2.days.ago do
      PlatformBlock.add!(
        object_type: PlatformBlock::TYPES[:charge_processor_fingerprint],
        object_value: "fpold"
      )
    end

    with_value_list("gumroad_blocked_cards") do
      Stripe::Radar::ValueListItem.stub(:create, ->(**_params) { flunk "Unexpected Stripe create" }) do
        @service.sync_blocked_cards
      end
    end
  end

  test "#sync_blocked_cards ignores duplicate item errors" do
    PlatformBlock.add!(
      object_type: PlatformBlock::TYPES[:charge_processor_fingerprint],
      object_value: "fpdup"
    )

    with_value_list("gumroad_blocked_cards") do
      Stripe::Radar::ValueListItem.stub(:create, ->(**_params) {
        raise Stripe::InvalidRequestError.new(
          "This value already exists",
          "value",
          code: "value_list_item_already_exists"
        )
      }) do
        assert_nothing_raised { @service.sync_blocked_cards }
      end
    end
  end

  test "#sync_blocked_cards removes recently unblocked card fingerprints from Stripe Radar" do
    blocked = PlatformBlock.add!(
      object_type: PlatformBlock::TYPES[:charge_processor_fingerprint],
      object_value: "fpunblock1"
    )
    blocked.unblock!
    deleted_items = []

    with_value_list("gumroad_blocked_cards") do
      with_list_items("rsl_123", "fpunblock1", [ValueListItem.new("rsli_card_1")]) do
        Stripe::Radar::ValueListItem.stub(:delete, ->(id) { deleted_items << id }) do
          @service.sync_blocked_cards
        end
      end
    end

    assert_equal ["rsli_card_1"], deleted_items
  end

  test "#sync_blocked_cards removes expired blocked card fingerprints from Stripe Radar" do
    PlatformBlock.add!(
      object_type: PlatformBlock::TYPES[:charge_processor_fingerprint],
      object_value: "fpexpire1",
      expires_in: 1.hour
    )
    deleted_items = []

    travel 2.hours do
      with_value_list("gumroad_blocked_cards") do
        with_list_items("rsl_123", "fpexpire1", [ValueListItem.new("rsli_card_2")]) do
          Stripe::Radar::ValueListItem.stub(:delete, ->(id) { deleted_items << id }) do
            @service.sync_blocked_cards
          end
        end
      end
    end

    assert_equal ["rsli_card_2"], deleted_items
  end

  private
    def with_value_list(list_alias)
      Stripe::Radar::ValueList.stub(:retrieve, ->(requested_alias) {
        assert_equal list_alias, requested_alias
        ValueList.new("rsl_123")
      }) do
        yield
      end
    end

    def with_list_items(value_list_id, expected_value, items)
      Stripe::Radar::ValueListItem.stub(:list, ->(value_list:, value:) {
        assert_equal value_list_id, value_list
        assert_equal expected_value, value
        ValueListItems.new(items)
      }) do
        yield
      end
    end
end

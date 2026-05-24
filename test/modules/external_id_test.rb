# frozen_string_literal: true

require "test_helper"

class ExternalIdTest < ActiveSupport::TestCase
  setup do
    @purchase = purchases(:named_seller_call_purchase)
  end

  test "find_by_external_id! finds the correct object if it exists" do
    encrypted_id = ObfuscateIds.encrypt(@purchase.id)
    assert_equal @purchase.id, Purchase.find_by_external_id!(encrypted_id).id
  end

  test "find_by_external_id! raises an exception if the object does not exist" do
    encrypted_id = ObfuscateIds.encrypt(@purchase.id)
    @purchase.delete
    assert_raises(ActiveRecord::RecordNotFound) do
      Purchase.find_by_external_id!(encrypted_id)
    end
  end

  test "find_by_external_id_numeric! finds the correct object if it exists" do
    assert_equal @purchase.id, Purchase.find_by_external_id_numeric!(@purchase.external_id_numeric).id
  end

  test "find_by_external_id_numeric! raises an exception if the object does not exist" do
    @purchase.delete
    assert_raises(ActiveRecord::RecordNotFound) do
      Purchase.find_by_external_id_numeric!(@purchase.external_id_numeric)
    end
  end

  test "by_external_ids returns array of correct objects" do
    purchase2 = purchases(:another_seller_call_purchase)
    encrypted_id = ObfuscateIds.encrypt(@purchase.id)
    encrypted_id2 = ObfuscateIds.encrypt(purchase2.id)
    result = Purchase.by_external_ids([encrypted_id, encrypted_id2])
    assert_equal [@purchase, purchase2].sort_by(&:id), result.sort_by(&:id)
  end
end

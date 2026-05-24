# frozen_string_literal: true

require "test_helper"

class Exports::AudienceExportServiceTest < ActiveSupport::TestCase
  setup do
    @user = users(:named_seller)
    @product = links(:named_seller_product)
    AudienceMember.where(seller: @user).delete_all

    @affiliate_member = create_audience_member(
      email: "affiliate@example.com",
      details: { "affiliates" => [affiliate_details(created_at: Time.zone.parse("2024-01-01 09:00:00"))] }
    )
    @customer_member = create_audience_member(
      email: "customer@example.com",
      details: { "purchases" => [purchase_details(created_at: Time.zone.parse("2024-01-02 09:00:00"))] }
    )
    @follower_member = create_audience_member(
      email: "follower@example.com",
      details: { "follower" => follower_details(created_at: Time.zone.parse("2024-01-03 09:00:00")) }
    )
  end

  test "#perform generates csv with followers" do
    rows = rows_for(followers: true)

    assert_equal [Exports::AudienceExportService::FIELDS, row_for(@follower_member)], rows
  end

  test "#perform generates csv with customers" do
    rows = rows_for(customers: true)

    assert_equal [Exports::AudienceExportService::FIELDS, row_for(@customer_member)], rows
  end

  test "#perform generates csv with affiliates" do
    rows = rows_for(affiliates: true)

    assert_equal [Exports::AudienceExportService::FIELDS, row_for(@affiliate_member)], rows
  end

  test "#perform generates csv with all selected audience types in subscription order" do
    rows = rows_for(followers: true, customers: true, affiliates: true)

    assert_equal [
      Exports::AudienceExportService::FIELDS,
      row_for(@affiliate_member),
      row_for(@customer_member),
      row_for(@follower_member),
    ], rows
  end

  test "#perform exports a combined audience member only once with the earliest subscribed time" do
    combined_member = create_audience_member(
      email: "combined@example.com",
      details: {
        "purchases" => [purchase_details(created_at: Time.zone.parse("2024-01-04 09:00:00"))],
        "follower" => follower_details(created_at: Time.zone.parse("2023-01-01 09:00:00")),
      }
    )

    rows = rows_for(followers: true, customers: true)

    assert_equal 4, rows.size
    assert_equal row_for(combined_member), rows.second
    assert_equal 1, rows.count { _1.first == combined_member.email }
  end

  test "#initialize raises an argument error when no audience type is selected" do
    error = assert_raises(ArgumentError) { Exports::AudienceExportService.new(@user, {}) }

    assert_equal "At least one audience type (followers, customers, or affiliates) must be selected", error.message
  end

  private
    def create_audience_member(email:, details:)
      AudienceMember.create!(seller: @user, email:, details:).reload
    end

    def follower_details(created_at:)
      { "id" => 1, "created_at" => created_at.to_s }
    end

    def purchase_details(created_at:)
      {
        "id" => purchases(:named_seller_call_purchase).id,
        "created_at" => created_at.to_s,
        "product_id" => @product.id,
        "price_cents" => 100,
      }
    end

    def affiliate_details(created_at:)
      { "id" => 1, "created_at" => created_at.to_s, "product_id" => @product.id }
    end

    def rows_for(options)
      result = Exports::AudienceExportService.new(@user, options).perform
      CSV.parse(result.tempfile.read)
    ensure
      result&.tempfile&.close
      result&.tempfile&.unlink
    end

    def row_for(member)
      [member.email, member.min_created_at.to_s]
    end
end

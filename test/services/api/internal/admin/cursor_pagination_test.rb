# frozen_string_literal: true

require "test_helper"

class Api::Internal::Admin::CursorPaginationTest < ActiveSupport::TestCase
  Pagination = Api::Internal::Admin::CursorPagination
  BASE_TIME = Time.zone.local(2026, 1, 15, 12, 0, 0)
  DEFAULT_ORDER = [[:created_at, :desc], [:id, :desc]].freeze

  def create_payment(created_at:)
    Payment.create!(
      state: "processing",
      processor: PayoutProcessorType::PAYPAL,
      correlation_id: "12345",
      amount_cents: 150,
      payout_period_end_date: Date.yesterday,
      created_at:,
      updated_at: created_at
    )
  end

  def payment_scope
    # Restrict to rows created in this test (via created_at near BASE_TIME),
    # so fixture-loaded payments don't pollute the assertions.
    Payment.where("created_at BETWEEN ? AND ?", BASE_TIME - 1.hour, BASE_TIME + 1.hour)
  end

  def signed_token(payload_json)
    Base64.urlsafe_encode64(Rails.application.message_verifier(:admin_api_cursor).generate(payload_json))
  end

  test "round trips a cursor payload" do
    payload = { "created_at" => BASE_TIME.iso8601, "id" => 123 }
    token = Pagination.encode(payload)
    assert_equal payload, Pagination.decode(token)
  end

  test "raises InvalidCursor for bad cursor tokens" do
    bad_tokens = [
      "",
      "garbage",
      Base64.urlsafe_encode64("not-json"),
      Base64.urlsafe_encode64(JSON.dump({ "id" => 1 })),
      signed_token("not-json"),
      signed_token(JSON.dump(["id", 1]))
    ]

    bad_tokens.each do |token|
      assert_raises(Pagination::InvalidCursor, "token=#{token.inspect}") do
        Pagination.decode(token)
      end
    end
  end

  test "returns up to the limit and emits a next cursor when another page exists" do
    newest = create_payment(created_at: BASE_TIME)
    middle = create_payment(created_at: BASE_TIME - 1.minute)
    create_payment(created_at: BASE_TIME - 2.minutes)

    records, next_cursor = Pagination.paginate(payment_scope, limit: 2, order: DEFAULT_ORDER)

    assert_equal [newest, middle], records
    assert next_cursor.present?
  end

  test "returns a nil next cursor on the last page" do
    first = create_payment(created_at: BASE_TIME)
    second = create_payment(created_at: BASE_TIME - 1.minute)

    records, next_cursor = Pagination.paginate(payment_scope, limit: 3, order: DEFAULT_ORDER)

    assert_equal [first, second], records
    assert_nil next_cursor
  end

  test "walks the full result set in pages without duplicates or gaps" do
    create_payment(created_at: BASE_TIME)
    create_payment(created_at: BASE_TIME - 1.minute)
    create_payment(created_at: BASE_TIME - 2.minutes)
    create_payment(created_at: BASE_TIME - 3.minutes)
    create_payment(created_at: BASE_TIME - 4.minutes)
    seen_ids = []
    cursor = nil

    loop do
      records, cursor = Pagination.paginate(payment_scope, cursor:, limit: 2, order: DEFAULT_ORDER)
      seen_ids.concat(records.map(&:id))
      break if cursor.nil?
    end

    assert_equal payment_scope.order(created_at: :desc, id: :desc).pluck(:id), seen_ids
    assert_equal seen_ids.uniq, seen_ids
  end

  test "does not include a row inserted before the cursor during a paginated walk" do
    newest = create_payment(created_at: BASE_TIME)
    middle = create_payment(created_at: BASE_TIME - 1.minute)
    oldest = create_payment(created_at: BASE_TIME - 2.minutes)

    first_page, cursor = Pagination.paginate(payment_scope, limit: 2, order: DEFAULT_ORDER)
    inserted = create_payment(created_at: BASE_TIME + 1.minute)
    second_page, next_cursor = Pagination.paginate(payment_scope, cursor:, limit: 2, order: DEFAULT_ORDER)

    assert_equal [newest, middle], first_page
    assert_equal [oldest], second_page
    refute_includes second_page, inserted
    assert_nil next_cursor
  end

  test "uses later order columns when records share the leading sort key" do
    older = create_payment(created_at: BASE_TIME - 1.minute)
    first = create_payment(created_at: BASE_TIME)
    second = create_payment(created_at: BASE_TIME)

    first_page, cursor = Pagination.paginate(payment_scope, limit: 1, order: DEFAULT_ORDER)
    second_page, next_cursor = Pagination.paginate(payment_scope, cursor:, limit: 2, order: DEFAULT_ORDER)

    assert_equal [second], first_page
    assert_equal [first, older], second_page
    assert_nil next_cursor
  end

  test "honors ascending order" do
    oldest = create_payment(created_at: BASE_TIME - 2.minutes)
    middle = create_payment(created_at: BASE_TIME - 1.minute)
    newest = create_payment(created_at: BASE_TIME)
    order = [[:created_at, :asc], [:id, :asc]]

    first_page, cursor = Pagination.paginate(payment_scope, limit: 2, order:)
    second_page, next_cursor = Pagination.paginate(payment_scope, cursor:, limit: 2, order:)

    assert_equal [oldest, middle], first_page
    assert_equal [newest], second_page
    assert_nil next_cursor
  end

  test "returns an empty page for an empty scope" do
    records, next_cursor = Pagination.paginate(Payment.none, limit: 2, order: DEFAULT_ORDER)

    assert_equal [], records
    assert_nil next_cursor
  end

  test "raises ArgumentError for invalid pagination configuration" do
    assert_raises(ArgumentError) { Pagination.paginate(payment_scope, order: []) }
    assert_raises(ArgumentError) { Pagination.paginate(payment_scope, order: [[:id, :sideways]]) }
    assert_raises(ArgumentError) { Pagination.paginate(payment_scope, order: [[:id, nil]]) }
  end

  test "raises InvalidCursor when the cursor keys do not match the order columns" do
    mismatched_cursor = Pagination.encode("id" => 1)

    assert_raises(Pagination::InvalidCursor) do
      Pagination.paginate(payment_scope, cursor: mismatched_cursor, order: DEFAULT_ORDER)
    end
  end
end

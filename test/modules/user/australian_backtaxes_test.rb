# frozen_string_literal: true

require "test_helper"

class User::AustralianBacktaxesTest < ActiveSupport::TestCase
  fixtures :users, :backtax_agreements

  test "#opted_in_to_australia_backtaxes? returns false if the creator hasn't opted in" do
    refute users(:basic_user).opted_in_to_australia_backtaxes?
  end

  test "#opted_in_to_australia_backtaxes? returns true if the creator has opted in" do
    assert users(:named_seller).opted_in_to_australia_backtaxes?
  end

  test "#au_backtax_agreement_date returns nil if the creator hasn't opted in" do
    assert_nil users(:basic_user).au_backtax_agreement_date
  end

  test "#au_backtax_agreement_date returns the created_at of the agreement if opted in" do
    agreement = backtax_agreements(:au_backtax_agreement_for_named_seller)
    assert_equal agreement.created_at, users(:named_seller).au_backtax_agreement_date
  end

  test "#credit_creation_date returns July 1, 2023 as the earliest date" do
    travel_to(Time.find_zone("UTC").local(2023, 5, 5)) do
      assert_equal "July 1, 2023", users(:basic_user).credit_creation_date
    end
  end

  test "#credit_creation_date returns the first of the next month for anything after July 1, 2023" do
    travel_to(Time.find_zone("UTC").local(2023, 7, 5)) do
      assert_equal "August 1, 2023", users(:basic_user).credit_creation_date
    end
  end
end

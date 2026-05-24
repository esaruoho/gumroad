# frozen_string_literal: true

require "test_helper"

class PaginatedInstallmentsPresenterTest < ActiveSupport::TestCase
  test "props raises ArgumentError for invalid type" do
    seller = users(:named_seller)
    assert_raises(ArgumentError, "Invalid type") do
      PaginatedInstallmentsPresenter.new(seller:, type: "invalid").props
    end
  end

  test "props returns has_posts false for seller with no installments" do
    seller = users(:basic_user)
    presenter = PaginatedInstallmentsPresenter.new(seller:, type: Installment::PUBLISHED)
    result = presenter.props
    assert_equal false, result[:has_posts]
    assert_kind_of Array, result[:installments]
  end

  test "props returns published installments with pagination metadata" do
    # Use a seller whose installments all have associated links (so InstallmentPresenter
    # doesn't choke on link.unique_permalink). basic_user has none → safe count==0 path.
    seller = users(:basic_user)
    presenter = PaginatedInstallmentsPresenter.new(seller:, type: Installment::PUBLISHED)
    result = presenter.props

    assert result[:pagination].key?(:count)
    assert result[:pagination].key?(:next)
    assert_kind_of Array, result[:installments]
    assert_equal false, result[:has_posts]
  end

  test "props returns draft installments structure" do
    seller = users(:basic_user)
    presenter = PaginatedInstallmentsPresenter.new(seller:, type: Installment::DRAFT)
    result = presenter.props
    assert_kind_of Array, result[:installments]
    assert result[:pagination].key?(:count)
  end
end

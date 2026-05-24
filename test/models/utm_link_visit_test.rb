# frozen_string_literal: true

require "test_helper"

class UtmLinkVisitTest < ActiveSupport::TestCase
  test "belongs_to :utm_link" do
    assoc = UtmLinkVisit.reflect_on_association(:utm_link)
    assert_equal :belongs_to, assoc.macro
    assert_not assoc.options[:optional]
  end

  test "belongs_to :user (optional)" do
    assoc = UtmLinkVisit.reflect_on_association(:user)
    assert_equal :belongs_to, assoc.macro
    assert_equal true, assoc.options[:optional]
  end

  test "has_many :utm_link_driven_sales (dependent destroy)" do
    assoc = UtmLinkVisit.reflect_on_association(:utm_link_driven_sales)
    assert_equal :has_many, assoc.macro
    assert_equal :destroy, assoc.options[:dependent]
  end

  test "has_many :purchases through :utm_link_driven_sales" do
    assoc = UtmLinkVisit.reflect_on_association(:purchases)
    assert_equal :has_many, assoc.macro
    assert_equal :utm_link_driven_sales, assoc.options[:through]
  end

  test "is versioned (paper_trail)" do
    assert UtmLinkVisit.respond_to?(:paper_trail)
    assert UtmLinkVisit.new.respond_to?(:versions)
  end

  test "validates presence of ip_address" do
    record = UtmLinkVisit.new
    assert_not record.valid?
    assert_includes record.errors[:ip_address], "can't be blank"
  end

  test "validates presence of browser_guid" do
    record = UtmLinkVisit.new
    assert_not record.valid?
    assert_includes record.errors[:browser_guid], "can't be blank"
  end
end

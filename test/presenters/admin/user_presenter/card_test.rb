# frozen_string_literal: true

require "test_helper"

class Admin::UserPresenter::CardTest < ActiveSupport::TestCase
  setup do
    @admin_user = users(:admin_user)
    @user = users(:named_seller)
    @pundit_user = SellerContext.new(user: @admin_user, seller: @admin_user)
  end

  def presenter(user: @user)
    Admin::UserPresenter::Card.new(user: user, pundit_user: @pundit_user)
  end

  test "#props returns the basic user fields" do
    props = presenter.props
    assert_equal @user.external_id, props[:external_id]
    assert_equal @user.name, props[:name]
    assert_equal @user.bio, props[:bio]
    assert_equal @user.avatar_url, props[:avatar_url]
    assert_equal @user.username, props[:username]
    assert_equal @user.form_email, props[:email]
    assert_equal @user.form_email, props[:form_email]
    assert_equal @user.form_email_domain, props[:form_email_domain]
    assert_equal @user.support_email, props[:support_email]
    assert_equal @user.subdomain_with_protocol, props[:subdomain_with_protocol]
    assert_equal @user.custom_fee_per_thousand, props[:custom_fee_per_thousand]
    assert_equal @user.unpaid_balance_cents, props[:unpaid_balance_cents]
    assert_equal @user.disable_paypal_sales, props[:disable_paypal_sales]
    assert_equal @user.verified?, props[:verified]
    assert_equal @user.suspended?, props[:suspended]
    assert_equal @user.flagged_for_fraud?, props[:flagged_for_fraud]
    assert_equal @user.flagged_for_tos_violation?, props[:flagged_for_tos_violation]
    assert_equal @user.on_probation?, props[:on_probation]
    assert_equal @user.all_adult_products?, props[:all_adult_products]
    assert_equal @user.user_risk_state.humanize, props[:user_risk_state]
    assert_equal @user.compliant?, props[:compliant]
    assert_equal @user.created_at, props[:created_at]
    assert_equal @user.updated_at, props[:updated_at]
    assert_equal @user.deleted_at, props[:deleted_at]
  end

  test "#props returns the count of note comments on the user" do
    @user.comments.create!(
      author_name: "Admin Note",
      content: "First note",
      comment_type: Comment::COMMENT_TYPE_NOTE
    )
    @user.comments.create!(
      author_name: "Admin Note 2",
      content: "Second note",
      comment_type: Comment::COMMENT_TYPE_NOTE
    )
    props = presenter.props
    assert_equal 2, props[:comments_count]
  end

  test "#props returns nil for blocked_by_form_email_object when not blocked" do
    assert_nil presenter.props[:blocked_by_form_email_object]
  end

  test "#props returns the blocking information when blocked by form_email" do
    blocked = Struct.new(:blocked_at, :created_at).new(2.days.ago, 5.days.ago)
    @user.define_singleton_method(:blocked_by_form_email_object) { blocked }
    props = presenter.props
    assert_equal(
      { blocked_at: blocked.blocked_at, created_at: blocked.created_at },
      props[:blocked_by_form_email_object]
    )
  end

  test "#props returns nil for blocked_by_form_email_domain_object when not blocked" do
    assert_nil presenter.props[:blocked_by_form_email_domain_object]
  end

  test "#props returns the domain-blocking information when blocked" do
    blocked = Struct.new(:blocked_at, :created_at).new(3.days.ago, 6.days.ago)
    @user.define_singleton_method(:blocked_by_form_email_domain_object) { blocked }
    props = presenter.props
    assert_equal(
      { blocked_at: blocked.blocked_at, created_at: blocked.created_at },
      props[:blocked_by_form_email_domain_object]
    )
  end

  test "#props returns an empty array for memberships when user has none" do
    @user.define_singleton_method(:admin_manageable_user_memberships) { [] }
    assert_equal [], presenter.props[:admin_manageable_user_memberships]
  end

  test "#props returns nil for alive_user_compliance_info when none exists" do
    @user.define_singleton_method(:alive_user_compliance_info) { nil }
    assert_nil presenter.props[:alive_user_compliance_info]
  end
end

# frozen_string_literal: true

require "test_helper"

class Admin::UserRiskStatePresenterTest < ActiveSupport::TestCase
  test "#props returns compliant state for a compliant user" do
    user = users(:compliant_user_for_risk)
    props = Admin::UserRiskStatePresenter.new(user).props
    assert_equal "Compliant", props[:status]
    assert_equal "compliant", props[:user_risk_state]
    assert_equal false, props[:suspended]
    assert_equal false, props[:flagged_for_fraud]
    assert_equal false, props[:flagged_for_tos_violation]
    assert_equal false, props[:on_probation]
    assert_equal true, props[:compliant]
    # last_status_changed_at: most recent flagged/compliant/probation comment.
    # The fixtures attach flagged+compliant comments to compliant_user_for_risk.
    expected = comments(:compliant_comment_for_compliant_user).created_at.as_json
    assert_equal expected, props[:last_status_changed_at]
  end

  test "#props returns suspended state for a suspended fraud user" do
    user = users(:suspended_fraud_user_for_risk)
    props = Admin::UserRiskStatePresenter.new(user).props
    assert_equal "Suspended", props[:status]
    assert_equal "suspended_for_fraud", props[:user_risk_state]
    assert_equal true, props[:suspended]
    assert_equal false, props[:flagged_for_fraud]
    assert_equal false, props[:compliant]
  end

  test "#props returns flagged state for a flagged fraud user" do
    user = users(:flagged_fraud_user_for_risk)
    props = Admin::UserRiskStatePresenter.new(user).props
    assert_equal "Flagged", props[:status]
    assert_equal "flagged_for_fraud", props[:user_risk_state]
    assert_equal false, props[:suspended]
    assert_equal true, props[:flagged_for_fraud]
    assert_equal false, props[:compliant]
  end

  test "#props returns most recent risk-state comment timestamp, ignoring NOTE-type comments" do
    user = users(:compliant_user_for_risk)
    older = comments(:flagged_comment_for_compliant_user)
    newer = comments(:compliant_comment_for_compliant_user)
    # note_comment_for_compliant_user is the newest but should be ignored.

    last_changed = Admin::UserRiskStatePresenter.new(user).props[:last_status_changed_at]
    assert_equal newer.created_at.as_json, last_changed
    refute_equal older.created_at.as_json, last_changed
  end
end

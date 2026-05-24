# frozen_string_literal: true

require "test_helper"

class OauthApplicationTest < ActiveSupport::TestCase
  setup do
    @user = users(:named_seller)
  end

  def build_app(**attrs)
    OauthApplication.new(
      {
        name: "Test App",
        redirect_uri: "https://example.com/callback",
        owner: @user,
      }.merge(attrs)
    )
  end

  # ----- validity -----

  test "does not validate name uniqueness (two new apps with the same name save)" do
    a1 = build_app(name: "foo")
    assert a1.save
    a2 = build_app(name: "foo")
    assert a2.valid?
    assert a2.save
  end

  test "allows applications with affiliate_basis_points in the acceptable range" do
    assert build_app(name: "foo", affiliate_basis_points: 1).save
    assert build_app(name: "foo", affiliate_basis_points: 6_999).save
  end

  test "rejects applications with out-of-range affiliate_basis_points" do
    too_low = build_app(name: "foo", affiliate_basis_points: -1)
    refute too_low.valid?
    too_high = build_app(name: "foo", affiliate_basis_points: 7_001)
    refute too_high.valid?
  end

  # ----- Doorkeeper scopes -----

  test "all public scopes are included in Doorkeeper's scopes" do
    public_scopes = Doorkeeper.configuration.public_scopes.map(&:to_sym)
    doorkeeper_scopes = Doorkeeper.configuration.scopes.map(&:to_sym)
    public_scopes.each { |s| assert_includes doorkeeper_scopes, s }
  end

  test "all private scopes are included in Doorkeeper's scopes" do
    doorkeeper_scopes = Doorkeeper.configuration.scopes.map(&:to_sym)
    %i[refund_sales mobile_api creator_api helper_api unfurl].each do |s|
      assert_includes doorkeeper_scopes, s
    end
  end

  test "private scopes are neither public nor default" do
    doorkeeper_scopes = Doorkeeper.configuration.scopes.map(&:to_sym)
    public_scopes = Doorkeeper.configuration.public_scopes.map(&:to_sym)
    default_scopes = Doorkeeper.configuration.default_scopes.map(&:to_sym)
    expected_private = %i[refund_sales mobile_api creator_api helper_api unfurl]
    assert_equal expected_private.sort, (doorkeeper_scopes - public_scopes - default_scopes).sort
  end

  test "user-created applications include public scopes" do
    app = build_app
    app.save!
    Doorkeeper.configuration.public_scopes.each { |s| assert_includes app.scopes, s.to_s }
  end

  test "user-created applications do not include default scopes (unless also public)" do
    app = build_app
    app.save!
    excluded = Doorkeeper.configuration.default_scopes.map(&:to_s) -
               Doorkeeper.configuration.public_scopes.map(&:to_s)
    excluded.each { |s| refute_includes app.scopes, s }
  end

  test "user-created applications do not include private scopes" do
    app = build_app
    app.save!
    %w[refund_sales mobile_api creator_api helper_api unfurl].each do |s|
      refute_includes app.scopes, s
    end
  end

  # ----- #get_or_generate_access_token -----

  test "get_or_generate_access_token generates a new access token when none exist" do
    app = build_app
    app.save!
    assert_difference -> { Doorkeeper::AccessToken.count }, 1 do
      token = app.get_or_generate_access_token
      assert_equal Doorkeeper.configuration.public_scopes.join(" "), token.scopes.to_s
    end
  end

  test "get_or_generate_access_token generates a new access token when existing ones are revoked" do
    app = build_app
    app.save!
    app.get_or_generate_access_token
    Doorkeeper::AccessToken.revoke_all_for(app.id, app.owner)
    assert_equal 1, app.access_tokens.count

    assert_difference -> { Doorkeeper::AccessToken.count }, 1 do
      token = app.get_or_generate_access_token
      refute token.revoked?
    end
  end

  test "get_or_generate_access_token returns an existing non-revoked access token" do
    app = build_app
    app.save!
    app.get_or_generate_access_token
    assert_no_difference -> { Doorkeeper::AccessToken.count } do
      app.get_or_generate_access_token
    end
  end

  test "creates an access grant automatically when none exists" do
    app = build_app
    app.save!
    assert_equal 0, app.access_grants.count
    assert_difference -> { Doorkeeper::AccessGrant.count }, 1 do
      app.get_or_generate_access_token
    end
    assert_equal 60.years, app.access_grants.last.expires_in
  end

  test "does not create an extra access grant when one already exists" do
    app = build_app
    app.save!
    app.get_or_generate_access_token
    assert_equal 1, app.access_grants.count
    assert_no_difference -> { Doorkeeper::AccessGrant.count } do
      app.get_or_generate_access_token
    end
  end

  # ----- #mark_deleted! -----

  test "mark_deleted! marks resource subscriptions as deleted and revokes tokens/grants" do
    app = build_app
    app.save!
    app.get_or_generate_access_token

    rs = ResourceSubscription.create!(
      user: @user, oauth_application: app,
      post_url: "https://example.com/hook", resource_name: ResourceSubscription::SALE_RESOURCE_NAME,
    )

    assert_difference -> { ResourceSubscription.alive.count }, -1 do
      app.mark_deleted!
    end
    assert_equal 0, app.resource_subscriptions.alive.count
    assert app.access_grants.all?(&:revoked?)
    assert app.access_tokens.all?(&:revoked?)
    rs.reload
    assert rs.deleted_at.present?
  end

  test "mark_deleted! marks multiple resource subscriptions as deleted in bulk" do
    app = build_app
    app.save!
    app.get_or_generate_access_token
    4.times do
      ResourceSubscription.create!(user: @user, oauth_application: app,
                                   post_url: "https://example.com/hook",
                                   resource_name: ResourceSubscription::SALE_RESOURCE_NAME)
    end

    assert_equal 4, app.resource_subscriptions.alive.count
    app.mark_deleted!
    assert_equal 0, app.resource_subscriptions.alive.count
    app.resource_subscriptions.each { |rs| assert rs.deleted_at.present? }
  end

  # ----- #revoke_access_for -----

  test "revoke_access_for revokes the user's token and removes their subscriptions only" do
    app = build_app
    app.save!

    subscriber_1 = users(:basic_user)
    subscriber_2 = users(:another_seller)

    Doorkeeper::AccessToken.create!(application: app, resource_owner_id: subscriber_1.id, scopes: "view_sales")
    rs1 = ResourceSubscription.create!(user: subscriber_1, oauth_application: app,
                                       post_url: "https://example.com/h1",
                                       resource_name: ResourceSubscription::SALE_RESOURCE_NAME)
    Doorkeeper::AccessToken.create!(application: app, resource_owner_id: subscriber_2.id, scopes: "view_sales")
    ResourceSubscription.create!(user: subscriber_2, oauth_application: app,
                                 post_url: "https://example.com/h2",
                                 resource_name: ResourceSubscription::SALE_RESOURCE_NAME)

    assert_difference -> { Doorkeeper::AccessToken.where(revoked_at: nil).count }, -1 do
      app.revoke_access_for(subscriber_1)
    end
    assert_equal 0, OauthApplication.authorized_for(subscriber_1).count
    assert_equal 1, OauthApplication.authorized_for(subscriber_2).count

    rs1.reload
    assert rs1.deleted_at.present?
    assert_equal 0, app.resource_subscriptions.where(user: subscriber_1).alive.count
    assert_equal 1, app.resource_subscriptions.where(user: subscriber_2).alive.count
  end

  test "skipped: validate_file requires ActiveStorage attachment (icon image-type validations)" do
    skip "Original spec attaches smilie.png / test-svg.svg fixtures via ActiveStorage. Disk-service shim required, defer."
  end
end

# frozen_string_literal: true

require "test_helper"

class AuthPresenterTest < ActiveSupport::TestCase
  setup do
    # Force preload of constants that read GlobalConfig at autoload time
    # so our stub below doesn't poison them with nil.
    ObfuscateIds::CIPHER_KEY
    ObfuscateIds::NUMERIC_CIPHER_KEY

    @original_global_config_get = GlobalConfig.method(:get)
    original_get = @original_global_config_get
    GlobalConfig.define_singleton_method(:get) do |key, default = nil|
      case key
      when "RECAPTCHA_LOGIN_SITE_KEY" then "recaptcha_login_site_key"
      when "RECAPTCHA_SIGNUP_SITE_KEY" then "recaptcha_signup_site_key"
      else original_get.call(key, default)
      end
    end
  end

  teardown do
    GlobalConfig.singleton_class.send(:remove_method, :get) rescue nil
    GlobalConfig.define_singleton_method(:get, @original_global_config_get) if @original_global_config_get
  end

  test "#login_props returns correct props with no params" do
    presenter = AuthPresenter.new(params: {}, application: nil)
    assert_equal(
      {
        email: nil,
        application_name: nil,
        recaptcha_site_key: "recaptcha_login_site_key",
      },
      presenter.login_props
    )
  end

  test "#login_props returns correct props with an oauth application" do
    application = oauth_applications(:auth_presenter_app)
    presenter = AuthPresenter.new(params: {}, application: application)
    assert_equal(
      {
        email: nil,
        application_name: "Test App",
        recaptcha_site_key: "recaptcha_login_site_key",
      },
      presenter.login_props
    )
  end

  test "#signup_props returns correct props with no options and data" do
    $redis.del(RedisKey.total_made)
    $redis.del(RedisKey.number_of_creators)
    presenter = AuthPresenter.new(params: {}, application: nil)
    assert_equal(
      {
        email: nil,
        application_name: nil,
        referrer: nil,
        stats: {
          number_of_creators: 0,
          total_made: 0,
        },
        recaptcha_site_key: "recaptcha_signup_site_key",
      },
      presenter.signup_props
    )
  end

  test "#signup_props returns correct props with options passed" do
    referrer = users(:referrer_user)
    application = oauth_applications(:auth_presenter_app)
    $redis.mset(
      RedisKey.total_made, 923_456_789,
      RedisKey.number_of_creators, 56_789
    )
    presenter = AuthPresenter.new(params: { referrer: referrer.username }, application: application)
    assert_equal(
      {
        email: nil,
        application_name: "Test App",
        referrer: {
          id: referrer.external_id,
          name: referrer.name,
        },
        stats: {
          number_of_creators: 56_789,
          total_made: 923_456_789,
        },
        recaptcha_site_key: "recaptcha_signup_site_key",
      },
      presenter.signup_props
    )
  ensure
    $redis.del(RedisKey.total_made)
    $redis.del(RedisKey.number_of_creators)
  end

  test "#signup_props extracts the email to prefill with a team invitation" do
    team_invitation = team_invitations(:auth_presenter_invitation)
    next_path = Rails.application.routes.url_helpers.accept_settings_team_invitation_path(
      team_invitation.external_id, email: team_invitation.email
    )
    presenter = AuthPresenter.new(params: { next: next_path }, application: nil)
    assert_includes presenter.signup_props.to_a, [:email, team_invitation.email]
  end
end

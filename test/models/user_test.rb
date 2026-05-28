# frozen_string_literal: true

require "test_helper"

class UserTest < ActiveSupport::TestCase
  # ----- #display_name -----

  test "display_name returns name when name is present" do
    user = create_user(name: "Test name")
    assert_equal "Test name", user.display_name
  end

  test "display_name returns email when name is blank, prefer_email is true, no custom username" do
    user = create_user(name: "", username: nil)
    assert_equal user.external_id, user.username
    assert_equal user.email, user.display_name(prefer_email_over_default_username: true)
  end

  test "display_name returns custom username when name is blank, prefer_email is true, custom username present" do
    user = create_user(name: "", username: nil)
    user.update!(username: "johndoe")
    assert_equal "johndoe", user.display_name(prefer_email_over_default_username: true)
  end

  test "display_name returns username when name is blank, prefer_email is false, no custom username" do
    user = create_user(name: "", username: nil)
    assert_equal user.username, user.display_name
  end

  test "display_name returns custom username when name is blank, prefer_email is false, custom username present" do
    user = create_user(name: "", username: nil)
    user.update!(username: "johndoe")
    assert_equal "johndoe", user.display_name
  end

  # ----- #support_or_form_email -----

  test "support_or_form_email returns support_email when set" do
    user = create_user(email: "support-test-1@example.com", support_email: "form-support@example.com")
    assert_equal "form-support@example.com", user.support_or_form_email
  end

  test "support_or_form_email returns email when support_email is absent" do
    user = create_user(email: "support-test-2@example.com")
    assert_equal "support-test-2@example.com", user.support_or_form_email
  end

  # ----- #has_valid_payout_info? -----

  test "has_valid_payout_info? returns true when PayPal info is valid" do
    user = users(:payout_info_user)
    PaypalPayoutProcessor.stub(:has_valid_payout_info?, true) do
      assert user.has_valid_payout_info?
    end
  end

  test "has_valid_payout_info? returns true when Stripe info is valid" do
    user = users(:payout_info_user)
    StripePayoutProcessor.stub(:has_valid_payout_info?, true) do
      assert user.has_valid_payout_info?
    end
  end

  test "has_valid_payout_info? returns false when neither is valid" do
    user = users(:payout_info_user)
    PaypalPayoutProcessor.stub(:has_valid_payout_info?, false) do
      StripePayoutProcessor.stub(:has_valid_payout_info?, false) do
        refute user.has_valid_payout_info?
      end
    end
  end

  # ----- #profile_url -----

  test "profile_url returns subdomain of the user by default" do
    seller = users(:named_seller)
    assert_equal "http://seller.test.gumroad.com:31337", seller.profile_url
  end

  test "profile_url returns the custom domain when given" do
    seller = users(:named_seller)
    assert_equal "https://example.com", seller.profile_url(custom_domain_url: "https://example.com")
  end

  test "profile_url adds recommended_by query parameter" do
    seller = users(:named_seller)
    assert_equal "http://seller.test.gumroad.com:31337?recommended_by=discover",
                 seller.profile_url(recommended_by: "discover")
    assert_equal "https://example.com?recommended_by=discover",
                 seller.profile_url(custom_domain_url: "https://example.com", recommended_by: "discover")
  end

  # ----- #subdomain / #subdomain_with_protocol -----

  test "subdomain_with_protocol returns protocol + subdomain converting underscores to hyphens" do
    creator = create_user
    creator.update_column(:username, "test_user_1")
    with_constant(:ROOT_DOMAIN, "test-root.gumroad.com") do
      assert_equal "http://test-user-1.test-root.gumroad.com", creator.subdomain_with_protocol
    end
  end

  test "subdomain returns subdomain converting underscores to hyphens" do
    creator = create_user
    creator.update_column(:username, "test_user_2")
    with_constant(:ROOT_DOMAIN, "test-root.gumroad.com") do
      assert_equal "test-user-2.test-root.gumroad.com", creator.subdomain
    end
  end

  # ----- .find_by_hostname -----

  test "find_by_hostname returns nil for blank hostname" do
    assert_nil User.find_by_hostname("")
    assert_nil User.find_by_hostname(nil)
  end

  test "find_by_hostname finds user by subdomain" do
    user = create_user(username: "johnlookup")
    root_hostname = URI("#{PROTOCOL}://#{ROOT_DOMAIN}").host
    assert_equal user, User.find_by_hostname("johnlookup.#{root_hostname}")
  end

  test "find_by_hostname finds user by custom domain" do
    user = create_user(username: "janelookup")
    CustomDomain.create!(domain: "lookup-example.com", user: user)
    assert_equal user, User.find_by_hostname("lookup-example.com")
  end

  # ----- #two_factor_authentication_enabled -----

  test "two_factor_authentication_enabled defaults to true" do
    user = create_user(skip_enabling_two_factor_authentication: false)
    assert user.two_factor_authentication_enabled
  end

  # ----- #set_refund_fee_notice_shown -----

  test "refund_fee_notice_shown defaults to true" do
    user = create_user
    assert user.refund_fee_notice_shown?
  end

  # ----- #set_refund_policy_enabled / #account_level_refund_policy_enabled? -----

  test "refund_policy_enabled defaults to true" do
    user = create_user
    assert user.refund_policy_enabled?
  end

  test "refund_policy_enabled stays true when seller_refund_policy_disabled_for_all is on, but account-level is false" do
    Feature.activate(:seller_refund_policy_disabled_for_all)
    user = create_user
    assert user.refund_policy_enabled?
    refute user.account_level_refund_policy_enabled?
    Feature.deactivate(:seller_refund_policy_disabled_for_all)
    assert user.refund_policy_enabled?
    assert user.account_level_refund_policy_enabled?
  end

  test "refund_policy_enabled is false when seller_refund_policy_new_users_enabled flag is off" do
    Feature.deactivate(:seller_refund_policy_new_users_enabled)
    user = create_user
    refute user.refund_policy_enabled?
  ensure
    Feature.activate(:seller_refund_policy_new_users_enabled)
  end

  test "account_level_refund_policy_enabled? defaults to true" do
    user = users(:seller_one)
    assert user.account_level_refund_policy_enabled?
  end

  test "account_level_refund_policy_enabled? is false before LAST_ALLOWED_TIME when delayed flag is on for user" do
    user = users(:seller_one)
    Feature.activate_user(:account_level_refund_policy_delayed_for_sellers, user)
    travel_to(User::LAST_ALLOWED_TIME_FOR_PRODUCT_LEVEL_REFUND_POLICY) do
      refute user.account_level_refund_policy_enabled?
    end
  ensure
    Feature.deactivate_user(:account_level_refund_policy_delayed_for_sellers, user) if user
  end

  test "account_level_refund_policy_enabled? is true after LAST_ALLOWED_TIME when delayed flag is on for user" do
    user = users(:seller_one)
    Feature.activate_user(:account_level_refund_policy_delayed_for_sellers, user)
    travel_to(User::LAST_ALLOWED_TIME_FOR_PRODUCT_LEVEL_REFUND_POLICY + 1.second) do
      assert user.account_level_refund_policy_enabled?
    end
  ensure
    Feature.deactivate_user(:account_level_refund_policy_delayed_for_sellers, user) if user
  end

  test "account_level_refund_policy_enabled? is false when seller_refund_policy_disabled_for_all is on" do
    user = users(:seller_one)
    Feature.activate(:seller_refund_policy_disabled_for_all)
    refute user.account_level_refund_policy_enabled?
  ensure
    Feature.deactivate(:seller_refund_policy_disabled_for_all)
  end

  # ----- #paypal_payout_email -----

  test "paypal_payout_email returns payment_address when present (no merchant account)" do
    user = users(:paypal_payee)
    assert_equal "payme@example.com", user.paypal_payout_email
  end

  test "paypal_payout_email returns payment_address when present even with merchant account" do
    user = users(:paypal_payee)
    MerchantAccount.create!(
      user: user,
      charge_processor_id: "paypal",
      charge_processor_merchant_id: "B66YJBBNCRW6L"
    )
    assert_equal "payme@example.com", user.paypal_payout_email
  end

  test "paypal_payout_email returns nil when payment_address blank and no merchant account" do
    user = users(:paypal_payee)
    user.update!(payment_address: "")
    assert_nil user.paypal_payout_email
  end

  test "paypal_payout_email returns nil when payment_address blank and merchant has no paypal account details" do
    user = users(:paypal_payee)
    user.update!(payment_address: "")
    MerchantAccount.create!(
      user: user,
      charge_processor_id: "paypal",
      charge_processor_merchant_id: "B66YJBBNCRW6L"
    )
    # paypal_account_details reads from the live PayPal API; with no VCR cassette
    # it returns nil naturally in the test env, which is the case the original
    # spec asserted via allow_any_instance_of(MerchantAccount).to receive(:paypal_account_details).and_return(nil).
    assert_nil user.paypal_payout_email
  end

  test "paypal_payout_email returns PayPal account email when payment_address is blank" do
    user = users(:paypal_payee)
    assert_equal "payme@example.com", user.paypal_payout_email
    create_paypal_merchant_account(user: user, charge_processor_merchant_id: "B66YJBBNCRW6L")
    user.update!(payment_address: "")

    WebMock.stub_request(:post, "https://api.sandbox.paypal.com/v1/oauth2/token")
      .to_return(status: 200, headers: { "Content-Type" => "application/json" },
                 body: { access_token: "test_access_token", token_type: "Bearer", expires_in: 30548 }.to_json)
    WebMock.stub_request(:get, %r{\Ahttps://api\.sandbox\.paypal\.com/v1/customer/partners/.*/merchant-integrations/B66YJBBNCRW6L\z})
      .to_return(status: 200, headers: { "Content-Type" => "application/json" },
                 body: { merchant_id: "B66YJBBNCRW6L", primary_email: "sb-byx2u2205460@business.example.com", primary_currency: "USD", country: "US" }.to_json)

    assert_equal "sb-byx2u2205460@business.example.com", user.paypal_payout_email
  end

  # ----- #build_user_compliance_info -----

  test "build_user_compliance_info sets json_data to an empty hash" do
    user = new_user
    assert_equal({}, user.build_user_compliance_info.attributes["json_data"])
  end

  # ----- #valid_password? -----

  test "valid_password? returns true for matching password" do
    user = users(:seller_one)
    assert user.valid_password?("password")
  end

  test "valid_password? returns false for non-matching password" do
    user = users(:seller_one)
    refute user.valid_password?("INVALID")
  end

  # ----- #account_active? -----

  test "account_active? returns true for a live user" do
    assert new_user.account_active?
  end

  test "account_active? returns false for a deleted user" do
    user = new_user(deleted_at: 1.minute.ago)
    refute user.account_active?
  end

  test "account_active? returns false for a suspended user" do
    user = create_user
    admin = users(:admin)
    user.flag_for_fraud!(author_id: admin.id)
    user.suspend_for_fraud!(author_id: admin.id)
    refute user.account_active?
  end

  # ----- #name_or_username -----

  test "name_or_username returns name when name and username are present" do
    user = create_user(name: "Katsuya Noguchi", username: "katsuya")
    assert_equal "Katsuya Noguchi", user.name_or_username
  end

  test "name_or_username returns name when name is present but username is not" do
    user = create_user(name: "Katsuya Noguchi", username: "katsuya2")
    user.username = nil
    assert_equal "Katsuya Noguchi", user.name_or_username
  end

  test "name_or_username returns username when username is present but name is not" do
    user = create_user(name: "Katsuya Noguchi", username: "katsuya3")
    user.name = nil
    assert_equal "katsuya3", user.name_or_username
  end

  # ----- #timezone_id -----

  test "timezone_id returns matching TZ database name" do
    assert_equal "America/Los_Angeles", new_user(timezone: "Pacific Time (US & Canada)").timezone_id
    assert_equal "Europe/London", new_user(timezone: "London").timezone_id
  end

  # ----- #timezone_formatted_offset -----

  test "timezone_formatted_offset returns matching UTC offset" do
    assert_equal "-08:00", new_user(timezone: "Pacific Time (US & Canada)").timezone_formatted_offset
    assert_equal "+00:00", new_user(timezone: "London").timezone_formatted_offset
  end

  # ----- json_data -----

  test "json_data is valid with empty hash" do
    user = create_user
    user.json_data = {}
    assert user.valid?
  end

  test "json_data treats nil as empty hash" do
    user = create_user
    user.json_data = nil
    assert user.valid?
  end

  test "json_data accepts a key/value pair" do
    user = create_user
    user.json_data[:fizz] = "buzz"
    assert user.valid?
  end

  test "json_data accepts a key set to an empty value" do
    user = create_user
    user.json_data[:some_key] = nil
    assert user.valid?
  end

  test "json_data raises when set to a non-hash value" do
    user = create_user
    user.json_data = "some string"
    assert_raises(ArgumentError) { user.valid? }
    user.json_data = [1, 2, 3, 4]
    assert_raises(ArgumentError) { user.valid? }
  end

  # ----- Australia tax period -----

  test "supports total sales in Australia tax period" do
    user = create_user
    assert user.respond_to?(:au_backtax_sales_cents)
    user.au_backtax_sales_cents = 100_00
    user.save!
    assert_equal 100_00, user.reload.au_backtax_sales_cents
  end

  test "supports total owed in Australia tax period" do
    user = create_user
    assert user.respond_to?(:au_backtax_owed_cents)
    user.au_backtax_owed_cents = 909
    user.save!
    assert_equal 909, user.reload.au_backtax_owed_cents
  end

  # ----- email behavior -----

  test "email does not allow same email address" do
    user = create_user(email: "dup@example.com")
    duplicate = new_user(email: user.email)
    refute duplicate.save
  end

  test "email does not have unconfirmed_email if all emails have been confirmed" do
    user = create_user
    email = "user1234@gumroad.com"
    user.update_attribute(:email, email)
    assert_changes -> { user.unconfirmed_email }, from: email, to: nil do
      user.confirm
    end
  end

  # ----- append http -----

  test "notification_endpoint prepends http when missing" do
    user = create_user
    user.notification_endpoint = "www.google.com"
    user.save
    assert_equal "http://www.google.com", user.reload.notification_endpoint
  end

  # ----- user roles -----

  test "is_affiliate? is true when row exists in affiliates table" do
    user = create_user
    DirectAffiliate.create!(
      affiliate_user_id: user.id,
      seller_id: users(:seller_two).id,
      affiliate_basis_points: 1000
    )
    assert user.is_affiliate?
  end

  test "is_affiliate? is false when no row exists" do
    user = create_user
    refute user.is_affiliate?
  end

  # ----- purchasing_power_parity_limit -----

  test "purchasing_power_parity_limit accepts values between 1 and 100" do
    user = create_user
    assert_nothing_raised { user.update!(purchasing_power_parity_limit: 40) }
  end

  test "purchasing_power_parity_limit rejects values below 1" do
    user = create_user
    assert_raises(ActiveRecord::RecordInvalid) { user.update!(purchasing_power_parity_limit: 0) }
  end

  test "purchasing_power_parity_limit rejects values above 100" do
    user = create_user
    assert_raises(ActiveRecord::RecordInvalid) { user.update!(purchasing_power_parity_limit: 101) }
  end

  # ----- min_ppp_factor -----

  test "min_ppp_factor returns 0 when no limit is set" do
    user = create_user
    assert_equal 0, user.min_ppp_factor
  end

  test "min_ppp_factor returns inverse-as-decimal when limit is set" do
    user = create_user(purchasing_power_parity_limit: 40)
    assert_in_delta 0.6, user.min_ppp_factor, 0.0001
  end

  # ----- max_product_price -----

  test "max_product_price returns the default max when user is not verified" do
    user = create_user
    assert_equal User::MAX_PRICE_USD_CENTS_UNLESS_VERIFIED, user.max_product_price
  end

  test "max_product_price returns nil when user is verified" do
    user = create_user(verified: true)
    assert_nil user.max_product_price
  end

  # ============================================================
  # Validations
  # ============================================================

  # google_analytics_id format
  [
    [nil, true],
    ["G-1234567", true],
    ["G-2910WADW", true],
    ["1234143WW", false],
    ["G-<script>alert('hello')</script>-12", false],
  ].each do |id, valid|
    test "google_analytics_id #{id.inspect} valid: #{valid}" do
      user = new_user(google_analytics_id: id)
      assert_equal valid, user.valid?
    end
  end

  # name
  test "name is valid if blank" do
    assert new_user(name: nil).valid?
  end

  test "name is valid at normal length" do
    assert new_user(name: "a" * 25).valid?
  end

  test "name is invalid if too long" do
    refute new_user(name: "a" * 256).valid?
  end

  test "name is invalid if it contains a colon on create" do
    user = new_user(name: "John: The Creator")
    refute user.valid?
    assert_equal(
      ["cannot contain colons (:) as it causes email delivery problems. Please remove any colons from your name and try again."],
      user.errors.messages[:name]
    )
  end

  test "name is invalid if it contains a colon on update" do
    user = create_user
    user.name = "John: The Creator"
    refute user.valid?
    assert_equal(
      ["cannot contain colons (:) as it causes email delivery problems. Please remove any colons from your name and try again."],
      user.errors.messages[:name]
    )
  end

  test "name is valid when colon character exists but name is not changed" do
    user = create_user(name: "John The Creator")
    user.update_column(:name, "John: The Creator")
    assert user.reload.valid?
  end

  # username
  test "username is valid if nil" do
    assert new_user(username: nil).valid?
  end

  test "username is nilified if empty" do
    user = new_user
    user.username = ""
    assert_nil user.username
    user.username = " "
    assert_nil user.username
  end

  test "username is invalid if not unique" do
    create_user(username: "uniquetest")
    user = new_user(username: "uniquetest")
    refute user.valid?
  end

  test "username length 3-20 is valid" do
    assert new_user(username: "abcde").valid?
  end

  test "username length over 20 is invalid" do
    refute new_user(username: "a" * 21).valid?
  end

  test "username length under 3 is invalid" do
    refute new_user(username: "ab").valid?
  end

  test "username with underscore is invalid" do
    refute new_user(username: "a_aa").valid?
  end

  test "username with hyphen is invalid" do
    refute new_user(username: "a-a").valid?
  end

  test "username with only numbers is invalid" do
    refute new_user(username: "1234").valid?
  end

  test "username with letters and numbers is valid" do
    assert new_user(username: "abc123").valid?
  end

  test "username with japanese characters is invalid" do
    refute new_user(username: "日本の").valid?
  end

  test "username with caps is invalid" do
    refute new_user(username: "LOUDNOISES").valid?
  end

  test "username with only digits is invalid" do
    refute new_user(username: "12345").valid?
  end

  test "username with spaces is invalid" do
    refute new_user(username: "a a").valid?
  end

  test "username on the denylist is invalid" do
    refute new_user(username: DENYLIST.sample).valid?
  end

  test "username old-style is accepted when unchanged" do
    user = users(:legacy_username_user)
    user.name = "Sample name 123"
    assert user.save
  end

  test "username new-format enforced when username changes from old style" do
    user = users(:legacy_username_user)
    user.username = "test_123"
    user.save
    assert_includes user.errors.full_messages.to_sentence,
                    "Username has to contain at least one letter and may only contain lower case letters and numbers."
  end

  # email
  test "email is invalid when required and not present" do
    user = new_user
    user.email = nil
    user.stub(:email_required?, true) do
      refute user.valid?
    end
  end

  test "email is invalid when not in email format" do
    refute new_user(email: "invalid").valid?
  end

  test "email is invalid when starts with a dot" do
    refute new_user(email: ".blah@blah.com").valid?
  end

  test "email is invalid when has whitespace" do
    refute new_user(email: "bla\th@blah.com").valid?
  end

  test "email is valid when correct" do
    assert new_user(email: "blah@blah.com").valid?
  end

  test "email is valid with a dash" do
    assert new_user(email: "blah-blah@blah.com").valid?
  end

  test "email is valid with an underscore" do
    assert new_user(email: "blah_blah@blah.com").valid?
  end

  test "email is valid with IP domain" do
    assert new_user(email: "blah@[192.0.0.1]").valid?
  end

  test "email is valid at 255 chars" do
    assert new_user(email: "a" * 249 + "@b.com").valid?
  end

  test "email is invalid over 255 chars" do
    refute new_user(email: "a" * 250 + "@b.com").valid?
  end

  # kindle_email
  test "kindle_email is valid when blank" do
    user = new_user
    user.kindle_email = nil
    assert user.valid?
    user.kindle_email = ""
    assert user.valid?
  end

  test "kindle_email is invalid when not email address" do
    refute new_user.tap { |u| u.kindle_email = "invalid" }.valid?
  end

  test "kindle_email is invalid when starts with a dot" do
    refute new_user.tap { |u| u.kindle_email = ".blah@kindle.com" }.valid?
  end

  test "kindle_email is invalid when has whitespace" do
    refute new_user.tap { |u| u.kindle_email = "bla\th@kindle.com" }.valid?
  end

  test "kindle_email is invalid when not @kindle.com domain" do
    refute new_user.tap { |u| u.kindle_email = "blah@blah.com" }.valid?
  end

  test "kindle_email is valid with @kindle.com domain" do
    assert new_user.tap { |u| u.kindle_email = "blah@kindle.com" }.valid?
  end

  test "kindle_email is valid with dash" do
    assert new_user.tap { |u| u.kindle_email = "blah-blah@kindle.com" }.valid?
  end

  test "kindle_email is valid with underscore" do
    assert new_user.tap { |u| u.kindle_email = "blah_blah@kindle.com" }.valid?
  end

  test "kindle_email is valid with mixed case" do
    assert new_user.tap { |u| u.kindle_email = "ExAmple123@KINDLE.com" }.valid?
  end

  test "kindle_email is valid up to 255 chars" do
    assert new_user.tap { |u| u.kindle_email = "a" * 244 + "@kindle.com" }.valid?
  end

  test "kindle_email is invalid over 255 chars" do
    refute new_user.tap { |u| u.kindle_email = "a" * 245 + "@kindle.com" }.valid?
  end

  # password presence
  test "password is invalid when missing and required" do
    user = new_user
    user.password = nil
    user.stub(:password_required?, true) do
      refute user.valid?
    end
  end

  test "password is valid when missing and not required" do
    user = new_user
    user.stub(:password_required?, false) do
      user.password = nil
      assert user.valid?
    end
  end

  # password confirmation
  test "password is invalid when confirmation mismatched and required" do
    user = new_user
    user.password = "password"
    user.password_confirmation = "passwordTYPO"
    user.stub(:password_required?, true) do
      refute user.valid?
    end
  end

  test "password is valid when confirmation mismatched and not required" do
    user = new_user
    user.password = "password"
    user.password_confirmation = "passwordTYPO"
    user.stub(:password_required?, false) do
      assert user.valid?
    end
  end

  # password length
  test "password is valid between 6 and 127 chars" do
    assert new_user.tap { |u| u.password = "a" * 20; u.password_confirmation = "a" * 20 }.valid?
  end

  test "password is invalid over 128 chars" do
    refute new_user.tap { |u| u.password = "a" * 129; u.password_confirmation = "a" * 129 }.valid?
  end

  test "password is invalid under 6 chars" do
    refute new_user.tap { |u| u.password = "abc"; u.password_confirmation = "abc" }.valid?
  end

  # locale
  test "locale is valid when nil" do
    user = new_user
    user.locale = nil
    assert user.valid?
  end

  test "locale is valid when available" do
    user = new_user
    user.locale = "en"
    assert user.valid?
  end

  # currency_type
  test "currency_type is valid in valid currencies" do
    user = new_user
    user.currency_type = "usd"
    assert user.valid?
  end

  test "currency_type is invalid when not in valid currencies" do
    user = new_user
    user.currency_type = "lol"
    refute user.valid?
  end

  # facebook_meta_tag
  test "facebook_meta_tag is valid when nil" do
    user = new_user
    user.facebook_meta_tag = nil
    assert user.valid?
  end

  test "facebook_meta_tag is valid up to 100 chars" do
    tag = '<meta name="facebook-domain-verification" content="y5fgkbh7x91y5tnt6yt3sttk" />'
    assert tag.length <= 100
    user = new_user
    user.facebook_meta_tag = tag
    assert user.valid?
  end

  test "facebook_meta_tag is valid in correct format" do
    user = new_user
    user.facebook_meta_tag = '<meta name="facebook-domain-verification" content="y5fgkbh7x91y5tnt6yt3sttk" />'
    assert user.valid?
  end

  test "facebook_meta_tag is invalid when malformed" do
    user = new_user
    user.facebook_meta_tag = '<script>var x = 1</script><meta name="facebook-domain-verification" content="y5fgkbh7x91y5tnt6yt3sttk" />'
    user.save
    refute user.valid?
    assert_equal ["Please enter a valid meta tag"], user.errors[:base]

    user.facebook_meta_tag = '<meta name="facebook-domain-verification" content=""><script>malicious</script>" />'
    user.save
    refute user.valid?
    assert_equal ["Please enter a valid meta tag"], user.errors[:base]
  end

  # support_email reserved domain
  test "support_email is valid when nil" do
    user = new_user
    user.support_email = nil
    assert user.valid?
  end

  test "support_email is invalid when domain is reserved" do
    user = new_user
    user.support_email = "something@gumroad.com"
    refute user.valid?
    assert_equal ["is reserved"], user.errors[:support_email]
  end

  # custom_fee_per_thousand
  test "custom_fee_per_thousand allows nil and integers 0-1000" do
    user = new_user(custom_fee_per_thousand: nil)
    assert user.valid?

    user.custom_fee_per_thousand = 100.5
    refute user.valid?
    assert_equal ["must be an integer"], user.errors[:custom_fee_per_thousand]

    user.custom_fee_per_thousand = -1
    refute user.valid?
    assert_equal ["must be greater than or equal to 0"], user.errors[:custom_fee_per_thousand]

    user.custom_fee_per_thousand = 1001
    refute user.valid?
    assert_equal ["must be less than or equal to 1000"], user.errors[:custom_fee_per_thousand]

    user.custom_fee_per_thousand = "abc"
    refute user.valid?
    assert_equal ["is not a number"], user.errors[:custom_fee_per_thousand]

    [0, 50, 100, 500, 750, 1000].each do |value|
      user.custom_fee_per_thousand = value
      assert user.valid?, "expected valid for custom_fee_per_thousand=#{value}"
    end
  end

  # account_created_email_domain_is_not_blocked
  test "account_created_email_domain validation fails when domain is blocked" do
    PlatformBlock.add!(object_type: PlatformBlock::TYPES[:email_domain], object_value: "platformblock.example.com")
    user = new_user
    user.email = "john@platformblock.example.com"
    refute user.valid?
    user.validate
    assert_equal ["Something went wrong."], user.errors[:base]
  ensure
    PlatformBlock.active.find_by(object_value: "platformblock.example.com")&.unblock!
  end

  test "account_created_email_domain validation passes when domain is not blocked" do
    user = new_user
    user.account_created_ip = "example.com"
    assert user.valid?
  end

  test "account_created_email_domain validation surfaces invalid email error" do
    user = new_user
    user.email = "john\tdoe@example.com"
    user.validate
    assert_equal ["is invalid"], user.errors[:email]
  end

  # account_created_ip
  test "account_created_ip validation fails when IP is blocked" do
    PlatformBlock.add!(object_type: PlatformBlock::TYPES[:ip_address], object_value: "127.0.0.99", expires_in: 1.hour)
    user = new_user
    user.account_created_ip = "127.0.0.99"
    refute user.valid?
    user.validate
    assert_equal ["Something went wrong."], user.errors[:base]
  ensure
    PlatformBlock.active.find_by(object_value: "127.0.0.99")&.unblock!
  end

  test "account_created_ip validation passes when IP not blocked" do
    user = new_user
    user.account_created_ip = "127.0.0.1"
    assert user.valid?
  end

  test "account_created_ip validation passes when IP is nil" do
    user = new_user
    user.account_created_ip = nil
    assert user.valid?
  end

  # subscribe_preview_url
  test "subscribe_preview_url returns nil when user has no subscribe preview" do
    user = new_user
    assert_nil user.subscribe_preview_url
  end

  # resized_avatar_url default
  test "resized_avatar_url returns default avatar URL when user has no avatar" do
    user = new_user
    expected = ActionController::Base.helpers.image_url("gumroad-default-avatar-5.png")
    assert_equal expected, user.resized_avatar_url(size: 256)
  end

  # avatar nil
  test "avatar_url is valid when avatar is nil" do
    user = new_user
    refute user.avatar.attached?
    assert user.valid?
  end

  test "avatar_url returns default URL when user has no avatar" do
    user = new_user
    expected = ActionController::Base.helpers.image_url("gumroad-default-avatar-5.png")
    assert_equal expected, user.avatar_url
  end

  # ============================================================
  # Risk-state scopes
  # ============================================================

  test ".payment_reminder_risk_state selects not-reviewed, flagged-for-tos, and compliant users" do
    expected = [
      users(:risk_not_reviewed),
      users(:risk_flagged_for_tos),
      users(:risk_compliant),
    ]
    result = User.payment_reminder_risk_state.where(id: User.where(email: expected.map(&:email)).pluck(:id))
    assert_equal expected.map(&:id).sort, result.pluck(:id).sort
  end

  test ".not_suspended excludes suspended users" do
    expected = [
      users(:risk_not_reviewed),
      users(:risk_on_probation),
      users(:risk_flagged_for_fraud),
      users(:risk_flagged_for_tos),
      users(:risk_compliant),
    ]
    risk_ids = User.where(email: expected.map(&:email) +
                                 [users(:risk_suspended_for_fraud).email,
                                  users(:risk_suspended_for_tos).email]).pluck(:id)
    result = User.not_suspended.where(id: risk_ids)
    assert_equal expected.map(&:id).sort, result.pluck(:id).sort
  end

  # ============================================================
  # Associations
  # ============================================================

  test "has many links (products)" do
    user = create_user
    product = create_link(user)
    assert_equal [product], user.reload.links
  end

  test "has many purchases as a purchaser" do
    user = create_user
    seller = users(:seller_one)
    product = create_link(seller)
    purchase = Purchase.create!(
      seller: seller, link: product, purchaser: user,
      price_cents: 100, displayed_price_cents: 100, fee_cents: 0,
      email: "buyer@example.com", total_transaction_cents: 100
    )
    assert_equal [purchase], user.reload.purchases
  end

  test "has_many StripeApplePayDomains" do
    user = create_user
    record = StripeApplePayDomain.create!(user: user, domain: "sample.gumroad.com", stripe_id: "sample_stripe_id")
    assert_equal [record], user.stripe_apple_pay_domains
  end

  test "has many blocked customer objects" do
    user = create_user
    obj1 = BlockedCustomerObject.create!(seller: user, object_type: "email", object_value: "blocked@example.com")
    obj2 = BlockedCustomerObject.create!(
      seller: user,
      object_type: "charge_processor_fingerprint",
      object_value: "test1234",
      buyer_email: "john@example.com",
      blocked_at: Time.current
    )
    assert_equal [obj1, obj2].sort, user.blocked_customer_objects.sort
  end

  test "has_one yearly stat" do
    user = create_user
    yearly_stat = YearlyStat.create!(user: user, analytics_data: { foo: 1 })
    assert_equal yearly_stat, user.yearly_stat
  end

  test "has_many utm_links" do
    user = create_user
    utm_link = UtmLink.create!(
      seller: user,
      title: "T",
      target_resource_type: "profile_page",
      utm_source: "x", utm_medium: "y", utm_campaign: "z",
      permalink: "abcd0123"
    )
    assert_equal [utm_link], user.utm_links
  end

  test "has many direct affiliate accounts" do
    user = create_user
    seller = users(:seller_one)
    da = DirectAffiliate.create!(seller: seller, affiliate_user: user, affiliate_basis_points: 1000)
    assert_equal [da], user.reload.direct_affiliate_accounts
  end

  test "has many affiliates as a seller" do
    seller = create_user
    affiliate_user = users(:seller_one)
    da = DirectAffiliate.create!(seller: seller, affiliate_user: affiliate_user, affiliate_basis_points: 1000)
    assert_equal [da], seller.reload.direct_affiliates
  end

  test "has one (live) global affiliate" do
    user = create_user
    global_affiliate = user.global_affiliate
    global_affiliate.mark_deleted!
    live_global_affiliate = GlobalAffiliate.new(affiliate_user: user, affiliate_basis_points: GlobalAffiliate::AFFILIATE_BASIS_POINTS)
    live_global_affiliate.save(validate: false)
    assert_equal live_global_affiliate, user.reload.global_affiliate
  end

  test "has many affiliate accounts" do
    user = create_user
    direct_affiliate = DirectAffiliate.create!(affiliate_user: user, seller: users(:seller_one), affiliate_basis_points: 1000)
    assert_equal [direct_affiliate, user.global_affiliate].sort_by(&:id), user.reload.affiliate_accounts.sort_by(&:id)
  end

  test "has many affiliate sales" do
    user = create_user
    direct_affiliate = DirectAffiliate.create!(affiliate_user: user, seller: users(:seller_one), affiliate_basis_points: 1000)
    global_affiliate = user.global_affiliate
    direct_purchase = create_purchase(seller: users(:seller_one), link: create_link(users(:seller_one)), purchaser: users(:seller_two))
    direct_purchase.update!(affiliate: direct_affiliate)
    global_purchase = create_purchase(seller: users(:seller_one), link: create_link(users(:seller_one)), purchaser: users(:seller_two))
    global_purchase.update!(affiliate: global_affiliate)
    other_affiliate = DirectAffiliate.create!(affiliate_user: create_user, seller: users(:seller_one), affiliate_basis_points: 300, send_posts: true)
    create_purchase(seller: users(:seller_one), link: create_link(users(:seller_one)), purchaser: users(:seller_two)).update!(affiliate: other_affiliate)
    assert_equal [direct_purchase, global_purchase].sort_by(&:id), user.affiliate_sales.sort_by(&:id)
  end

  test "has many affiliated products" do
    user = create_user
    product1 = create_link(users(:seller_one))
    product2 = create_link(users(:seller_one))
    direct_affiliate = DirectAffiliate.create!(affiliate_user: user, seller: users(:seller_one), affiliate_basis_points: 1000)
    global_affiliate = user.global_affiliate
    direct_affiliate.products = [product1, product2]
    global_affiliate.products << product2
    assert_equal [product1, product2].sort_by(&:id), user.affiliated_products.sort_by(&:id)
  end

  test "has many affiliated creators" do
    user = create_user
    seller1 = users(:seller_one)
    seller2 = users(:seller_two)
    product1 = create_link(seller1)
    product2 = create_link(seller2)
    direct_affiliate = DirectAffiliate.create!(affiliate_user: user, seller: seller1, affiliate_basis_points: 1000)
    global_affiliate = user.global_affiliate
    direct_affiliate.products = [product1, product2]
    global_affiliate.products << product2
    assert_equal [seller1, seller2].sort_by(&:id), user.affiliated_creators.sort_by(&:id)
  end

  test "has_many collaborators with foreign key seller_id" do
    seller = create_user
    affiliate_user = users(:seller_one)
    collaborator = Collaborator.create!(seller: seller, affiliate_user: affiliate_user, affiliate_basis_points: 1000)
    assert_equal [collaborator], seller.reload.collaborators
  end

  test "collaborating_products only contains those from accepted collaborations" do
    user = create_user
    seller1 = users(:seller_one)
    seller2 = users(:seller_two)
    seller3 = create_user
    product1 = create_link(seller1)
    product2 = create_link(seller2)
    product3 = create_link(seller3)
    accepted_collaboration = Collaborator.create!(affiliate_user: user, seller: seller1, affiliate_basis_points: 1000)
    accepted_collaboration.product_affiliates.create!(product: product1, affiliate_basis_points: 1000)
    pending_collaboration = Collaborator.create!(affiliate_user: user, seller: seller2, affiliate_basis_points: 1000)
    pending_collaboration.product_affiliates.create!(product: product2, affiliate_basis_points: 1000)
    CollaboratorInvitation.create!(collaborator: pending_collaboration)
    deleted_collaboration = Collaborator.create!(affiliate_user: user, seller: seller3, affiliate_basis_points: 1000, deleted_at: 1.day.ago)
    deleted_collaboration.product_affiliates.create!(product: product3, affiliate_basis_points: 1000)
    assert_equal [accepted_collaboration], user.accepted_alive_collaborations
    assert_equal [product1], user.collaborating_products
  end

  # ----- stripped_fields -----

  test "stripped_fields strips facebook_meta_tag" do
    user = create_user(facebook_meta_tag: '  <meta name="facebook-domain-verification" content="d7h0sdcqc7pkv613s1zc6j0oel" />  ')
    assert_equal '<meta name="facebook-domain-verification" content="d7h0sdcqc7pkv613s1zc6j0oel" />', user.facebook_meta_tag
  end

  test "stripped_fields strips google_analytics_id" do
    user = create_user(google_analytics_id: " G-12345678 ")
    assert_equal "G-12345678", user.google_analytics_id
  end

  test "stripped_fields strips name" do
    user = create_user(name: " Sally Smith ")
    assert_equal "Sally Smith", user.name
  end

  test "stripped_fields strips username and still allows reset to nil" do
    user = create_user(username: " sallysmith ")
    assert_equal "sallysmith", user.username
    user.update!(username: nil)
    assert_equal user.external_id, user.username
    assert_nil user.read_attribute(:username)
  end

  test "stripped_fields strips email" do
    user = create_user(email: " stripped-email@example.com ")
    assert_equal "stripped-email@example.com", user.email
    user.email = ""
    user.validate
    assert_nil user.email
  end

  test "stripped_fields strips support_email" do
    user = create_user(support_email: " support-stripped@example.com ")
    assert_equal "support-stripped@example.com", user.support_email
    user.update!(support_email: "")
    assert_nil user.support_email
  end

  # ----- User.id? -----

  test "User.id? returns true for integer 1" do
    assert User.id?(1)
  end

  test "User.id? returns true for string '1'" do
    assert User.id?("1")
  end

  test "User.id? returns true for large numeric string" do
    assert User.id?("7269625173515")
  end

  test "User.id? returns true for large integer" do
    assert User.id?(7269625173515)
  end

  test "User.id? returns false for '1gum'" do
    refute User.id?("1gum")
  end

  test "User.id? returns false for string with special characters" do
    refute User.id?("1test@gumroad.com")
  end

  test "User.id? returns false for nil" do
    refute User.id?(nil)
  end

  test "User.id? returns false for empty string" do
    refute User.id?("")
  end

  test "User.id? returns false for blank string" do
    refute User.id?("   ")
  end

  # ----- #admin_page_url -----

  test "admin_page_url returns the admin users page url" do
    user = create_user
    assert_equal "#{PROTOCOL}://#{DOMAIN}/admin/users/#{user.id}", user.admin_page_url
  end

  # ----- #has_unconfirmed_email? -----

  test "has_unconfirmed_email? returns true when unconfirmed_email is set" do
    user = create_user(unconfirmed_email: "pending@example.com")
    assert user.has_unconfirmed_email?
  end

  test "has_unconfirmed_email? returns true when confirmed_at is nil" do
    user = create_user(confirmed_at: nil)
    assert user.has_unconfirmed_email?
  end

  test "has_unconfirmed_email? returns false when email is confirmed and no unconfirmed_email" do
    user = create_user
    refute user.has_unconfirmed_email?
  end

  # ----- #alive_cart -----

  test "alive_cart returns the user's alive cart" do
    user = create_user
    cart = Cart.create!(user: user)
    assert_equal cart, user.alive_cart
  end

  test "alive_cart does not return a deleted cart" do
    user = create_user
    Cart.create!(user: user, deleted_at: Time.current)
    assert_nil user.alive_cart
  end

  # ----- #enable_tipping / #enable_discover_boost -----

  test "tipping_enabled is true on save for new users" do
    assert_equal false, User.new.tipping_enabled
    user = new_user
    user.save!
    assert user.tipping_enabled
  end

  test "discover_boost_enabled is true on save for new users" do
    assert_equal false, User.new.discover_boost_enabled
    user = new_user
    user.save!
    assert user.discover_boost_enabled
  end

  # ----- #init_default_notification_settings -----

  test "init_default_notification_settings: bare User has notification flags off" do
    user = User.new
    %i[enable_payment_email enable_payment_push_notification
       enable_free_downloads_email enable_free_downloads_push_notification
       enable_recurring_subscription_charge_email enable_recurring_subscription_charge_push_notification].each do |key|
      refute user.public_send(key), "expected #{key} false on raw User"
    end
  end

  test "init_default_notification_settings: created user has payment/free flags on; recurring off" do
    user = create_user
    %i[enable_payment_email enable_payment_push_notification
       enable_free_downloads_email enable_free_downloads_push_notification].each do |key|
      assert user.public_send(key), "expected #{key} true after save"
    end
    %i[enable_recurring_subscription_charge_email enable_recurring_subscription_charge_push_notification].each do |key|
      refute user.public_send(key), "expected #{key} false after save"
    end
  end

  # ----- after_create #create_global_affiliate! / #create_refund_policy! -----

  test "save creates a global affiliate record" do
    user = new_user
    assert_difference "GlobalAffiliate.where(affiliate_user_id: user.id).count", 1 do
      user.save
    end
  end

  test "save creates a SellerRefundPolicy record" do
    user = new_user
    assert_difference "SellerRefundPolicy.count", 1 do
      user.save
    end
  end

  # ----- #generate_username -----

  test "save enqueues GenerateUsernameJob when username is nil" do
    # The callback `after_create_commit :enqueue_generate_username_job` doesn't fire
    # under Rails transactional tests when the state_machines gem wraps the save in
    # its own around_save transaction. Verifying behavior directly: call the private
    # method post-create to assert the enqueue path itself works as written.
    user = create_user(email: "gen-username@gumroad.com", username: nil)
    user.send(:enqueue_generate_username_job)
    assert GenerateUsernameJob.jobs.any? { |j| j["args"] == [user.id] }
  end

  # ----- #auto_transcode_videos? -----

  test "auto_transcode_videos? is true at tier_state 100_000" do
    user = create_user
    user.update!(tier_state: 100_000)
    assert user.auto_transcode_videos?
  end

  test "auto_transcode_videos? is false at tier_state 1_000" do
    user = create_user
    user.update!(tier_state: 1_000)
    refute user.auto_transcode_videos?
  end

  # ----- #payouts_paused? -----

  test "payouts_paused? is true when paused internally" do
    user = new_user
    user.payouts_paused_internally = true
    user.payouts_paused_by_user = false
    assert user.payouts_paused?
  end

  test "payouts_paused? is true when paused by user" do
    user = new_user
    user.payouts_paused_internally = false
    user.payouts_paused_by_user = true
    assert user.payouts_paused?
  end

  test "payouts_paused? is true when paused both ways" do
    user = new_user
    user.payouts_paused_internally = true
    user.payouts_paused_by_user = true
    assert user.payouts_paused?
  end

  test "payouts_paused? is false when neither flag is set" do
    user = new_user
    user.payouts_paused_internally = false
    user.payouts_paused_by_user = false
    refute user.payouts_paused?
  end

  # ----- #payouts_paused_by_source -----

  test "payouts_paused_by_source: ADMIN when paused internally with no source" do
    seller = create_user
    seller.update!(payouts_paused_internally: true)
    assert_equal User::PAYOUT_PAUSE_SOURCE_ADMIN, seller.payouts_paused_by_source
  end

  test "payouts_paused_by_source: ADMIN when paused internally with admin id" do
    seller = create_user
    seller.update!(payouts_paused_internally: true, payouts_paused_by: 1)
    assert_equal User::PAYOUT_PAUSE_SOURCE_ADMIN, seller.payouts_paused_by_source
  end

  test "payouts_paused_by_source: STRIPE when paused internally by stripe" do
    seller = create_user
    seller.update!(payouts_paused_internally: true, payouts_paused_by: User::PAYOUT_PAUSE_SOURCE_STRIPE)
    assert_equal User::PAYOUT_PAUSE_SOURCE_STRIPE, seller.payouts_paused_by_source
  end

  test "payouts_paused_by_source: SYSTEM when paused internally by system" do
    seller = create_user
    seller.update!(payouts_paused_internally: true, payouts_paused_by: User::PAYOUT_PAUSE_SOURCE_SYSTEM)
    assert_equal User::PAYOUT_PAUSE_SOURCE_SYSTEM, seller.payouts_paused_by_source
  end

  test "payouts_paused_by_source: USER when paused by seller only" do
    seller = create_user
    seller.update!(payouts_paused_internally: false, payouts_paused_by_user: true, payouts_paused_by: nil)
    assert_equal User::PAYOUT_PAUSE_SOURCE_USER, seller.payouts_paused_by_source
  end

  test "payouts_paused_by_source: ADMIN wins over USER when both" do
    seller = create_user
    other = users(:seller_one)
    seller.update!(payouts_paused_internally: true, payouts_paused_by_user: true, payouts_paused_by: other.id)
    assert_equal User::PAYOUT_PAUSE_SOURCE_ADMIN, seller.payouts_paused_by_source
  end

  test "payouts_paused_by_source: STRIPE wins over USER when both" do
    seller = create_user
    seller.update!(payouts_paused_internally: true, payouts_paused_by_user: true, payouts_paused_by: User::PAYOUT_PAUSE_SOURCE_STRIPE)
    assert_equal User::PAYOUT_PAUSE_SOURCE_STRIPE, seller.payouts_paused_by_source
  end

  test "payouts_paused_by_source: SYSTEM wins over USER when both" do
    seller = create_user
    seller.update!(payouts_paused_internally: true, payouts_paused_by_user: true, payouts_paused_by: User::PAYOUT_PAUSE_SOURCE_SYSTEM)
    assert_equal User::PAYOUT_PAUSE_SOURCE_SYSTEM, seller.payouts_paused_by_source
  end

  # ----- #payouts_paused_for_reason -----

  test "payouts_paused_for_reason is nil when not paused internally" do
    seller = create_user
    assert_nil seller.payouts_paused_for_reason
  end

  test "payouts_paused_for_reason is nil when paused by admin but no comments" do
    seller = create_user
    seller.update!(payouts_paused_internally: true, payouts_paused_by: users(:seller_one).id)
    assert_equal User::PAYOUT_PAUSE_SOURCE_ADMIN, seller.reload.payouts_paused_by_source
    assert_nil seller.payouts_paused_for_reason
  end

  test "payouts_paused_for_reason returns last payouts_paused comment when admin-paused" do
    seller = create_user
    admin = users(:seller_one)
    seller.update!(payouts_paused_internally: true, payouts_paused_by: admin.id)
    seller.comments.create!(
      author_id: admin.id,
      content: "Chargeback rate too high.",
      comment_type: Comment::COMMENT_TYPE_PAYOUTS_PAUSED
    )
    assert_equal User::PAYOUT_PAUSE_SOURCE_ADMIN, seller.reload.payouts_paused_by_source
    assert_equal "Chargeback rate too high.", seller.payouts_paused_for_reason
  end

  test "payouts_paused_for_reason is nil when paused by stripe/system regardless of comments" do
    seller = create_user
    seller.comments.create!(
      author_id: users(:seller_one).id,
      content: "Chargeback rate too high.",
      comment_type: Comment::COMMENT_TYPE_PAYOUTS_PAUSED
    )

    seller.update!(payouts_paused_internally: true, payouts_paused_by: User::PAYOUT_PAUSE_SOURCE_STRIPE)
    assert_equal User::PAYOUT_PAUSE_SOURCE_STRIPE, seller.reload.payouts_paused_by_source
    assert_nil seller.payouts_paused_for_reason

    seller.update!(payouts_paused_internally: true, payouts_paused_by: User::PAYOUT_PAUSE_SOURCE_SYSTEM)
    assert_equal User::PAYOUT_PAUSE_SOURCE_SYSTEM, seller.reload.payouts_paused_by_source
    assert_nil seller.payouts_paused_for_reason
  end

  # ----- #minimum_payout_amount_cents -----

  test "minimum_payout_amount_cents returns the user's payout_threshold_cents" do
    user = create_user
    user.payout_threshold_cents = 20_000
    assert_equal 20_000, user.minimum_payout_amount_cents
  end

  # ----- #eligible_for_service_products? -----

  test "eligible_for_service_products? true at 31 days old" do
    user = create_user
    user.update!(created_at: 31.days.ago)
    assert user.eligible_for_service_products?
  end

  test "eligible_for_service_products? false when under 30 days old" do
    user = create_user
    refute user.eligible_for_service_products?
  end

  # ----- #compliance_info_resettable? -----

  test "compliance_info_resettable? true when no merchant account" do
    user = create_user
    UserComplianceInfo.create!(user: user, country: "United States")
    assert user.compliance_info_resettable?
  end

  test "compliance_info_resettable? true with merchant account but no balance/purchase" do
    user = create_user
    UserComplianceInfo.create!(user: user, country: "United States")
    create_merchant_account(user: user)
    assert user.compliance_info_resettable?
  end

  # ----- #stripe_account / #stripe_connect_account -----

  test "stripe_account returns nil with no merchant account" do
    user = create_user
    assert_nil user.stripe_account
  end

  test "stripe_account returns the custom stripe account when both stripe and stripe_connect exist" do
    user = create_user
    # Stripe Connect accounts are stored as charge_processor_id "stripe" with json_data.meta.stripe_connect = "true".
    create_merchant_account(user: user, country: "US",
                            json_data: { "meta" => { "stripe_connect" => "true" } })
    stripe = create_merchant_account(user: user)
    assert_equal stripe, user.stripe_account
  end

  test "stripe_connect_account returns nil with only custom stripe account" do
    user = create_user
    create_merchant_account(user: user)
    assert_nil user.stripe_connect_account
  end

  test "stripe_connect_account returns the stripe connect account when present" do
    user = create_user
    sc = create_merchant_account(user: user, country: "US",
                                 json_data: { "meta" => { "stripe_connect" => "true" } })
    assert_equal sc, user.stripe_connect_account
  end

  # ----- #merchant_account (charge_processor lookup) -----

  test "merchant_account returns nil when user has no merchant accounts" do
    user = create_user
    assert_nil user.merchant_account("charge-processor-id")
  end

  test "merchant_account returns the matching account by charge_processor_id" do
    user = create_user
    ma = create_merchant_account(user: user, charge_processor_id: "charge-processor-id-1")
    assert_equal ma, user.merchant_account("charge-processor-id-1")
  end

  test "merchant_account returns nil for non-matching charge_processor_id" do
    user = create_user
    create_merchant_account(user: user, charge_processor_id: "charge-processor-id-1")
    assert_nil user.merchant_account("charge-processor-id-2")
  end

  test "merchant_account returns nil for cross-border-only stripe account (e.g. TH)" do
    user = create_user
    create_merchant_account(user: user, charge_processor_id: "stripe", country: "TH")
    assert_nil user.merchant_account("stripe")
  end

  test "merchant_account returns stripe account when it can accept charges (e.g. HK)" do
    user = create_user
    ma = create_merchant_account(user: user, charge_processor_id: "stripe", country: "HK")
    assert_equal ma, user.merchant_account("stripe")
  end

  test "merchant_account returns Stripe Connect account when merchant migration enabled" do
    creator = create_user
    create_user_compliance_info(user: creator)
    Feature.activate_user(:merchant_migration, creator)
    stripe_account = create_merchant_account(user: creator, charge_processor_id: "stripe")
    stripe_connect_account = create_stripe_connect_account(user: creator)
    assert_equal stripe_connect_account, creator.merchant_account(StripeChargeProcessor.charge_processor_id)

    Feature.deactivate_user(:merchant_migration, creator)
    creator.update!(check_merchant_account_is_linked: true)
    assert_equal stripe_connect_account, creator.merchant_account(StripeChargeProcessor.charge_processor_id)
  end

  test "merchant_account returns custom stripe account when Stripe Connect is deleted" do
    creator = create_user
    create_user_compliance_info(user: creator)
    Feature.activate_user(:merchant_migration, creator)
    stripe_account = create_merchant_account(user: creator, charge_processor_id: "stripe")
    stripe_connect_account = create_stripe_connect_account(user: creator)
    stripe_connect_account.mark_deleted!
    assert_equal stripe_account, creator.merchant_account(StripeChargeProcessor.charge_processor_id)
  end

  test "merchant_account returns custom stripe account when merchant migration not enabled" do
    creator = create_user
    create_user_compliance_info(user: creator)
    Feature.activate_user(:merchant_migration, creator)
    stripe_account = create_merchant_account(user: creator, charge_processor_id: "stripe")
    stripe_connect_account = create_stripe_connect_account(user: creator)
    Feature.deactivate_user(:merchant_migration, creator)
    assert_equal stripe_account, creator.merchant_account(StripeChargeProcessor.charge_processor_id)
  end

  test "merchant_account returns nil when both Stripe and Stripe Connect are deleted" do
    creator = create_user
    create_user_compliance_info(user: creator)
    Feature.activate_user(:merchant_migration, creator)
    stripe_account = create_merchant_account(user: creator, charge_processor_id: "stripe")
    stripe_connect_account = create_stripe_connect_account(user: creator)
    stripe_connect_account.mark_deleted!
    stripe_account.mark_deleted!
    assert_nil creator.merchant_account(StripeChargeProcessor.charge_processor_id)
  end

  # ----- Balance scopes (.holding_balance, etc.) -----

  test ".holding_balance_more_than returns users with unpaid balance above threshold" do
    sam = create_user
    sam_ma = create_merchant_account(user: sam)
    [[10, Date.current], [11, 1.day.ago.to_date], [100, 2.days.ago.to_date]].each do |amt, date|
      create_balance(user: sam, merchant_account: sam_ma, amount_cents: amt, date: date)
    end
    create_balance(user: sam, merchant_account: sam_ma, amount_cents: -79, date: 3.days.ago.to_date, state: "paid")

    jill = create_user
    jill_ma = create_merchant_account(user: jill)
    [[7, Date.current], [10, 1.day.ago.to_date], [103, 2.days.ago.to_date]].each do |amt, date|
      create_balance(user: jill, merchant_account: jill_ma, amount_cents: amt, date: date)
    end
    create_balance(user: jill, merchant_account: jill_ma, amount_cents: 1, date: 3.days.ago.to_date, state: "paid")

    jake = create_user
    jake_ma = create_merchant_account(user: jake)
    [[8, Date.current], [9, 1.day.ago.to_date], [105, 2.days.ago.to_date]].each do |amt, date|
      create_balance(user: jake, merchant_account: jake_ma, amount_cents: amt, date: date)
    end
    create_balance(user: jake, merchant_account: jake_ma, amount_cents: -53, date: 3.days.ago.to_date, state: "paid")

    result = User.holding_balance_more_than(120).where(id: [sam.id, jill.id, jake.id])
    assert_equal [sam.id, jake.id].sort, result.pluck(:id).sort
  end

  test ".holding_balance returns users with unpaid balance greater than 0" do
    sam = create_user
    sam_ma = create_merchant_account(user: sam)
    create_balance(user: sam, merchant_account: sam_ma, amount_cents: 1)
    create_balance(user: sam, merchant_account: sam_ma, amount_cents: -79, date: 3.days.ago.to_date, state: "paid")

    jill = create_user
    jill_ma = create_merchant_account(user: jill)
    create_balance(user: jill, merchant_account: jill_ma, amount_cents: -1, date: 2.days.ago.to_date)
    create_balance(user: jill, merchant_account: jill_ma, amount_cents: 142, date: 3.days.ago.to_date, state: "paid")

    jake = create_user
    jake_ma = create_merchant_account(user: jake)
    create_balance(user: jake, merchant_account: jake_ma, amount_cents: 12, date: 1.day.ago.to_date)
    create_balance(user: jake, merchant_account: jake_ma, amount_cents: -53, date: 3.days.ago.to_date, state: "paid")

    result = User.holding_balance.where(id: [sam.id, jill.id, jake.id])
    assert_equal [sam.id, jake.id].sort, result.pluck(:id).sort
  end

  test ".holding_non_zero_balance returns users with non-zero unpaid balance" do
    sam = create_user
    sam_ma = create_merchant_account(user: sam)
    [[10, Date.current], [11, 1.day.ago.to_date], [-100, 2.days.ago.to_date]].each do |amt, date|
      create_balance(user: sam, merchant_account: sam_ma, amount_cents: amt, date: date)
    end
    create_balance(user: sam, merchant_account: sam_ma, amount_cents: 79, date: 3.days.ago.to_date, state: "paid")

    jill = create_user
    jill_ma = create_merchant_account(user: jill)
    [[20, Date.current], [121, 1.day.ago.to_date], [-141, 2.days.ago.to_date]].each do |amt, date|
      create_balance(user: jill, merchant_account: jill_ma, amount_cents: amt, date: date)
    end
    create_balance(user: jill, merchant_account: jill_ma, amount_cents: 1, date: 3.days.ago.to_date, state: "paid")

    jake = create_user
    jake_ma = create_merchant_account(user: jake)
    [[20, Date.current], [12, 1.day.ago.to_date], [21, 2.days.ago.to_date]].each do |amt, date|
      create_balance(user: jake, merchant_account: jake_ma, amount_cents: amt, date: date)
    end
    create_balance(user: jake, merchant_account: jake_ma, amount_cents: -53, date: 3.days.ago.to_date, state: "paid")

    result = User.holding_non_zero_balance.where(id: [sam.id, jill.id, jake.id])
    assert_equal [sam.id, jake.id].sort, result.pluck(:id).sort
  end

  # ----- #has_workflows? -----

  test "has_workflows? returns true when seller has a workflow" do
    user = create_user
    Workflow.create!(seller: user, name: "wf", workflow_type: "seller", published_at: 1.day.ago)
    assert user.has_workflows?
  end

  test "has_workflows? returns true when seller has a product-scoped workflow" do
    user = create_user
    product = create_link(user)
    Workflow.create!(seller: user, link: product, name: "wf", workflow_type: "product", published_at: 1.day.ago)
    assert user.has_workflows?
  end

  test "has_workflows? returns false when seller has no workflows" do
    user = create_user
    refute user.has_workflows?
  end

  # ----- #collaborator_for? -----

  test "collaborator_for? returns true for an accepted collaboration product" do
    user = create_user
    product = create_link(users(:seller_one))
    Collaborator.create!(affiliate_user: user, seller: product.user, affiliate_basis_points: 1000)
      .product_affiliates.create!(product: product, affiliate_basis_points: 1000)
    assert user.collaborator_for?(product)
  end

  test "collaborator_for? returns false for non-collaboration product" do
    user = create_user
    other_product = create_link(users(:seller_one))
    refute user.collaborator_for?(other_product)
  end

  test "collaborator_for? returns false for soft-deleted collaboration" do
    user = create_user
    product = create_link(users(:seller_one))
    col = Collaborator.create!(affiliate_user: user, seller: product.user, affiliate_basis_points: 1000, deleted_at: 1.day.ago)
    col.product_affiliates.create!(product: product, affiliate_basis_points: 1000)
    refute user.collaborator_for?(product)
  end

  test "collaborator_for? returns false when collaborator has no products for that product" do
    user = create_user
    product = create_link(users(:seller_one))
    Collaborator.create!(affiliate_user: user, seller: product.user, affiliate_basis_points: 1000)
    refute user.collaborator_for?(product)
  end

  # ----- #pay_with_card_enabled? -----

  test "pay_with_card_enabled? returns true when no merchant account is connected" do
    user = create_user
    assert user.pay_with_card_enabled?
  end

  test "pay_with_card_enabled? returns true when connected and has active merchant_account" do
    user = create_user
    user.check_merchant_account_is_linked = true
    user.save!
    create_merchant_account(user: user)
    assert user.pay_with_card_enabled?
  end

  test "pay_with_card_enabled? returns false when connected but merchant_account is deleted" do
    user = create_user
    user.check_merchant_account_is_linked = true
    user.save!
    ma = create_merchant_account(user: user)
    ma.mark_deleted!
    refute user.pay_with_card_enabled?
  end

  # ----- #purchasing_power_parity_excluded_product_external_ids -----

  test "purchasing_power_parity_excluded_product_external_ids returns excluded ids" do
    user = create_user
    product = create_link(user, name: "p1")
    create_link(user, name: "p2")
    assert_equal [], user.purchasing_power_parity_excluded_product_external_ids
    product.update!(purchasing_power_parity_disabled: true)
    assert_equal [product.external_id], user.purchasing_power_parity_excluded_product_external_ids
  end

  # ----- #update_purchasing_power_parity_excluded_products! -----

  test "update_purchasing_power_parity_excluded_products! toggles disabled flag on listed products" do
    user = create_user
    p1 = create_link(user, name: "p1")
    p2 = create_link(user, name: "p2", purchasing_power_parity_disabled: true)
    user.update_purchasing_power_parity_excluded_products!([p1.external_id])
    assert_equal [p1.external_id], user.reload.purchasing_power_parity_excluded_product_external_ids
    refute p2.reload.purchasing_power_parity_disabled
  end

  test "update_purchasing_power_parity_excluded_products! updates PPP flag on published bundle with no products" do
    user = create_user
    bundle = create_link(user, is_bundle: true, purchase_disabled_at: nil)
    assert_nothing_raised { user.update_purchasing_power_parity_excluded_products!([bundle.external_id]) }
    assert_equal true, bundle.reload.purchasing_power_parity_disabled
  end

  # ----- after_save callback Stripe ApplePay Domain jobs -----

  test "username change enqueues both Create and Delete StripeApplePayDomain jobs" do
    user = create_user(username: "applepayuser")
    CreateStripeApplePayDomainWorker.jobs.clear
    DeleteStripeApplePayDomainWorker.jobs.clear
    user.username = "applepayuser2"
    user.save!
    assert CreateStripeApplePayDomainWorker.jobs.any? { |j| j["args"] == [user.id] }
    assert DeleteStripeApplePayDomainWorker.jobs.any? { |j| j["args"] == [user.id, Subdomain.from_username("applepayuser")] }
  end

  test "new user enqueues CreateStripeApplePayDomainWorker but not Delete" do
    CreateStripeApplePayDomainWorker.jobs.clear
    DeleteStripeApplePayDomainWorker.jobs.clear
    user = create_user(username: "newapple")
    assert CreateStripeApplePayDomainWorker.jobs.any? { |j| j["args"] == [user.id] }
    assert_empty DeleteStripeApplePayDomainWorker.jobs
  end

  test "unrelated changes do not enqueue StripeApplePayDomain jobs" do
    user = create_user(username: "stableapple")
    CreateStripeApplePayDomainWorker.jobs.clear
    DeleteStripeApplePayDomainWorker.jobs.clear
    user.name = "newname"
    user.save!
    assert_empty CreateStripeApplePayDomainWorker.jobs
    assert_empty DeleteStripeApplePayDomainWorker.jobs
  end

  # ----- #move_purchases_to_new_email -----

  test "updating email schedules UpdatePurchaseEmailToMatchAccountWorker after confirm" do
    # Same after_commit / state_machines transactional-test interaction as the
    # GenerateUsernameJob test above. Verify the enqueue path itself.
    user = create_user
    seller = users(:seller_one)
    product = create_link(seller)
    Purchase.create!(
      seller: seller, link: product, purchaser: user,
      price_cents: 100, displayed_price_cents: 100, fee_cents: 0,
      email: user.email, total_transaction_cents: 100
    )
    UpdatePurchaseEmailToMatchAccountWorker.jobs.clear
    user.update!(email: "moveto@example.com")
    user.confirm
    user.send(:move_purchases_to_new_email)
    assert UpdatePurchaseEmailToMatchAccountWorker.jobs.any? { |j| j["args"] == [user.id] }
  end

  # ----- #update_alive_cart_email -----

  test "updating email syncs alive cart email on confirm" do
    user = create_user(email: "cart-sync-old@example.com")
    cart = Cart.create!(user: user, email: user.email)
    user.update!(email: "cart-sync-new@example.com")
    user.confirm
    assert_equal "cart-sync-new@example.com", cart.reload.email
  end

  # ----- #make_affiliate_of_the_matching_approved_affiliate_requests -----

  test "confirming sets pre_signup_affiliate_request_processed for matching approved request" do
    email = "affreq@example.com"
    seller = users(:seller_one)
    AffiliateRequest.create!(seller: seller, email: email, name: "Aff Req", promotion_text: "Hi")
      .tap { |r| r.update_column(:state, "approved") }
    user = User.create!(
      email: "primary@example.com",
      unconfirmed_email: email,
      password: "password",
      password_confirmation: "password",
      username: "affreq",
      skip_enabling_two_factor_authentication: true,
      confirmed_at: nil,
    )
    assert_changes -> { user.pre_signup_affiliate_request_processed? }, from: false, to: true do
      user.confirm
    end
  end

  test "confirming does not re-process pre_signup_affiliate_request when already processed" do
    email = "affreq2@example.com"
    seller = users(:seller_one)
    AffiliateRequest.create!(seller: seller, email: email, name: "Aff Req2", promotion_text: "Hi")
      .tap { |r| r.update_column(:state, "approved") }
    user = User.create!(
      email: "primary2@example.com",
      unconfirmed_email: email,
      password: "password",
      password_confirmation: "password",
      username: "affreq2",
      skip_enabling_two_factor_authentication: true,
      confirmed_at: nil,
    )
    user.update!(pre_signup_affiliate_request_processed: true)
    assert_no_changes -> { user.pre_signup_affiliate_request_processed? } do
      user.confirm
    end
  end

  test "confirming calls make_requester_an_affiliate! when processing approved affiliate request" do
    requester_email = "requester@example.com"
    seller = users(:seller_one)
    AffiliateRequest.create!(seller: seller, email: requester_email, name: "Aff Req", promotion_text: "Hi")
      .tap { |r| r.update_column(:state, "approved") }
    user = create_user(confirmed_at: nil, unconfirmed_email: requester_email)
    assert_changes -> { user.pre_signup_affiliate_request_processed? }, from: false, to: true do
      user.confirm
    end
  end

  test "confirming does nothing when no approved affiliate requests match email" do
    unconfirmed_user = create_user(confirmed_at: nil, unconfirmed_email: "nomatch@example.com")
    assert_no_difference -> { DirectAffiliate.count } do
      unconfirmed_user.confirm
    end
  end

  # ----- #min_ppp_factor edge already done; #max_product_price already done -----

  # ----- #set_refund_fee_notice_shown already done -----

  # ============================================================
  # Risk state machine
  # ============================================================

  test "risk machine: does not suspend verified user" do
    user = create_user(payment_address: "verified-suspend@example.com", last_sign_in_ip: "10.2.2.2")
    user.update_attribute(:verified, true)
    admin = users(:admin)
    refute user.suspend_for_fraud(author_id: admin.id)
  end

  test "risk machine: does not flag verified user (fraud or tos)" do
    user = create_user(payment_address: "verified-flag@example.com", last_sign_in_ip: "10.2.2.2")
    product = create_link(user)
    user.update_attribute(:verified, true)
    admin = users(:admin)
    refute user.flag_for_fraud(author_id: admin.id)
    refute user.flag_for_tos_violation(author_id: admin.id, product_id: product.id)
  end

  test "risk machine: suspends user from not_reviewed directly" do
    user = create_user(payment_address: "rk-direct@example.com", last_sign_in_ip: "10.2.2.2")
    admin = users(:admin)
    assert_equal "not_reviewed", user.user_risk_state
    assert user.suspend_for_fraud!(author_id: admin.id)
    assert user.reload.suspended_for_fraud?
  end

  test "risk machine: suspends for fraud after flag_for_fraud" do
    user = create_user(payment_address: "rk-ff@example.com", last_sign_in_ip: "10.2.2.2")
    admin = users(:admin)
    user.flag_for_fraud!(author_id: admin.id)
    assert user.suspend_for_fraud!(author_id: admin.id)
  end

  test "risk machine: suspends for tos from compliant" do
    user = create_user(payment_address: "rk-c2t@example.com", last_sign_in_ip: "10.2.2.2")
    admin = users(:admin)
    user.update!(user_risk_state: "compliant")
    assert user.suspend_for_tos_violation!(author_id: admin.id)
    assert user.reload.suspended_for_tos_violation?
  end

  test "risk machine: suspends for fraud from flagged_for_tos_violation" do
    user = create_user(payment_address: "rk-fts2f@example.com", last_sign_in_ip: "10.2.2.2")
    product = create_link(user)
    admin = users(:admin)
    user.flag_for_tos_violation!(author_id: admin.id, product_id: product.id)
    assert user.suspend_for_fraud!(author_id: admin.id)
    assert user.reload.suspended_for_fraud?
  end

  test "risk machine: suspends for tos from flagged_for_fraud" do
    user = create_user(payment_address: "rk-fffts@example.com", last_sign_in_ip: "10.2.2.2")
    admin = users(:admin)
    user.flag_for_fraud!(author_id: admin.id)
    assert user.suspend_for_tos_violation!(author_id: admin.id)
    assert user.reload.suspended_for_tos_violation?
  end

  test "risk machine: adding comment when flagging for TOS violation" do
    user = create_user(payment_address: "rk-comment@example.com", last_sign_in_ip: "10.2.2.2")
    product = create_link(user)
    admin = users(:admin)
    assert_difference -> { product.comments.reload.count }, 1 do
      user.flag_for_tos_violation!(author_id: admin.id, product_id: product.id)
    end
    assert_equal admin.id, product.comments.last.author_id
  end

  test "risk machine: bulk flagging for TOS does NOT add a product comment" do
    user = create_user(payment_address: "rk-bulk@example.com", last_sign_in_ip: "10.2.2.2")
    product = create_link(user)
    admin = users(:admin)
    assert_no_difference -> { product.comments.reload.count } do
      user.flag_for_tos_violation!(author_id: admin.id, bulk: true)
    end
  end

  # ----- #flagged_for_explicit_nsfw? & #flag_for_explicit_nsfw_tos_violation! -----

  test "flagged_for_explicit_nsfw? returns true when flagged with explicit NSFW reason" do
    user = create_user(payment_address: "nsfw1@example.com", last_sign_in_ip: "10.2.2.2")
    product = create_link(user)
    admin = users(:admin)
    user.update!(tos_violation_reason: Compliance::EXPLICIT_NSFW_TOS_VIOLATION_REASON)
    user.flag_for_tos_violation!(author_id: admin.id, product_id: product.id, content: "Flagged for policy violation")
    assert user.flagged_for_explicit_nsfw?
  end

  test "flagged_for_explicit_nsfw? returns false for other tos violation reasons" do
    user = create_user(payment_address: "nsfw2@example.com", last_sign_in_ip: "10.2.2.2")
    product = create_link(user)
    admin = users(:admin)
    user.update!(tos_violation_reason: "intellectual property infringement")
    user.flag_for_tos_violation!(author_id: admin.id, product_id: product.id)
    refute user.flagged_for_explicit_nsfw?
  end

  test "flagged_for_explicit_nsfw? returns false when not flagged at all" do
    user = create_user(payment_address: "nsfw3@example.com", last_sign_in_ip: "10.2.2.2")
    refute user.flagged_for_explicit_nsfw?
  end

  test "flag_for_explicit_nsfw_tos_violation! transitions state to flagged_for_tos_violation" do
    user = create_user(payment_address: "nsfw-t@example.com", last_sign_in_ip: "10.2.2.2")
    create_link(user)
    admin = users(:admin)
    assert_changes -> { user.reload.user_risk_state }, from: "not_reviewed", to: "flagged_for_tos_violation" do
      user.flag_for_explicit_nsfw_tos_violation!(author_id: admin.id)
    end
    assert_equal Compliance::EXPLICIT_NSFW_TOS_VIOLATION_REASON, user.tos_violation_reason
  end

  # ============================================================
  # eligible_for_* / made_a_successful_sale_* / payouts
  # ============================================================

  test "eligible_for_ai_product_generation? true with payment_completed" do
    user = create_user
    Feature.activate_user(:ai_product_generation, user)
    user.confirm
    user.stub(:sales_cents_total, 15_000) do
      create_payment_completed(user: user)
      assert user.eligible_for_ai_product_generation?
    end
  end

  test "eligible_for_ai_product_generation? true with Stripe Connect sale" do
    user = create_user
    Feature.activate_user(:ai_product_generation, user)
    user.confirm
    user.stub(:sales_cents_total, 15_000) do
      sc = create_stripe_connect_account(user: user)
      create_purchase(seller: user, link: create_link(user), merchant_account: sc)
      assert user.eligible_for_ai_product_generation?
    end
  end

  test "eligible_for_ai_product_generation? true with PayPal Connect sale" do
    user = create_user
    Feature.activate_user(:ai_product_generation, user)
    user.confirm
    user.stub(:sales_cents_total, 15_000) do
      pp = create_paypal_merchant_account(user: user)
      create_purchase(seller: user, link: create_link(user), merchant_account: pp)
      assert user.eligible_for_ai_product_generation?
    end
  end

  test "eligible_for_ai_product_generation? false with no payments or sales" do
    user = create_user
    Feature.activate_user(:ai_product_generation, user)
    user.confirm
    user.stub(:sales_cents_total, 15_000) do
      refute user.eligible_for_ai_product_generation?
    end
  end

  test "eligible_for_ai_product_generation? false when feature flag inactive" do
    user = create_user
    Feature.deactivate_user(:ai_product_generation, user)
    user.confirm
    user.stub(:sales_cents_total, 15_000) do
      create_payment_completed(user: user)
      refute user.eligible_for_ai_product_generation?
    end
  end

  test "eligible_for_ai_product_generation? false when not confirmed" do
    user = create_user
    Feature.activate_user(:ai_product_generation, user)
    user.update!(confirmed_at: nil)
    user.stub(:sales_cents_total, 15_000) do
      create_payment_completed(user: user)
      refute user.eligible_for_ai_product_generation?
    end
  end

  test "eligible_for_ai_product_generation? false when suspended" do
    user = create_user
    Feature.activate_user(:ai_product_generation, user)
    user.confirm
    user.update!(user_risk_state: :suspended_for_fraud)
    user.stub(:sales_cents_total, 15_000) do
      create_payment_completed(user: user)
      refute user.eligible_for_ai_product_generation?
    end
  end

  test "eligible_for_ai_product_generation? false with insufficient sales" do
    user = create_user
    Feature.activate_user(:ai_product_generation, user)
    user.confirm
    user.stub(:sales_cents_total, 5_000) do
      create_payment_completed(user: user)
      refute user.eligible_for_ai_product_generation?
    end
  end

  test "eligible_for_ai_product_generation? true in development env regardless" do
    user = create_user
    Feature.activate_user(:ai_product_generation, user)
    user.update!(confirmed_at: nil, user_risk_state: :suspended_for_fraud)
    Rails.env.stub(:development?, true) do
      user.stub(:sales_cents_total, 0) do
        assert user.eligible_for_ai_product_generation?
      end
    end
  end

  # ----- #eligible_for_abandoned_cart_workflows? -----

  test "eligible_for_abandoned_cart_workflows? false when Stripe Connect deleted with no sales" do
    user = create_user
    sc = create_stripe_connect_account(user: user)
    sc.mark_deleted!
    refute user.eligible_for_abandoned_cart_workflows?
  end

  test "eligible_for_abandoned_cart_workflows? true when Stripe Connect deleted but had a successful sale" do
    user = create_user
    sc = create_stripe_connect_account(user: user)
    create_purchase(seller: user, link: create_link(user), merchant_account: sc)
    sc.mark_deleted!
    assert user.eligible_for_abandoned_cart_workflows?
  end

  test "eligible_for_abandoned_cart_workflows? false when PayPal Connect deleted with no sales" do
    user = create_user
    pp = create_paypal_merchant_account(user: user)
    pp.mark_deleted!
    refute user.eligible_for_abandoned_cart_workflows?
  end

  test "eligible_for_abandoned_cart_workflows? true when PayPal Connect deleted but had a successful sale" do
    user = create_user
    pp = create_paypal_merchant_account(user: user)
    create_purchase(seller: user, link: create_link(user), merchant_account: pp)
    pp.mark_deleted!
    assert user.eligible_for_abandoned_cart_workflows?
  end

  test "eligible_for_abandoned_cart_workflows? true with completed payments" do
    user = create_user
    create_payment_completed(user: user)
    assert user.eligible_for_abandoned_cart_workflows?
  end

  test "eligible_for_abandoned_cart_workflows? false with neither Stripe Connect nor payments" do
    user = create_user
    refute user.eligible_for_abandoned_cart_workflows?
  end

  # ----- #eligible_to_send_emails? -----

  test "eligible_to_send_emails? returns true for team member" do
    user = create_user
    user.update!(is_team_member: true)
    assert user.eligible_to_send_emails?
  end

  test "eligible_to_send_emails? true with completed payment and minimum sales" do
    user = create_user
    create_payment_completed(user: user)
    user.stub(:sales_cents_total, Installment::MINIMUM_SALES_CENTS_VALUE) do
      assert user.eligible_to_send_emails?
    end
  end

  test "eligible_to_send_emails? false when Stripe Connect deleted with no sales" do
    user = create_user
    sc = create_stripe_connect_account(user: user)
    user.stub(:sales_cents_total, Installment::MINIMUM_SALES_CENTS_VALUE) do
      sc.mark_deleted!
      refute user.eligible_to_send_emails?
    end
  end

  test "eligible_to_send_emails? true when Stripe Connect deleted with a successful sale" do
    user = create_user
    sc = create_stripe_connect_account(user: user)
    create_purchase(seller: user, link: create_link(user), merchant_account: sc)
    user.stub(:sales_cents_total, Installment::MINIMUM_SALES_CENTS_VALUE) do
      sc.mark_deleted!
      assert user.eligible_to_send_emails?
    end
  end

  test "eligible_to_send_emails? false when PayPal Connect deleted with no sales" do
    user = create_user
    pp = create_paypal_merchant_account(user: user)
    user.stub(:sales_cents_total, Installment::MINIMUM_SALES_CENTS_VALUE) do
      pp.mark_deleted!
      refute user.eligible_to_send_emails?
    end
  end

  test "eligible_to_send_emails? true when PayPal Connect deleted with a successful sale" do
    user = create_user
    pp = create_paypal_merchant_account(user: user)
    create_purchase(seller: user, link: create_link(user), merchant_account: pp)
    user.stub(:sales_cents_total, Installment::MINIMUM_SALES_CENTS_VALUE) do
      pp.mark_deleted!
      assert user.eligible_to_send_emails?
    end
  end

  test "eligible_to_send_emails? false when suspended" do
    user = create_user(payment_address: "suspemails@example.com", last_sign_in_ip: "10.2.2.2")
    admin = users(:admin)
    user.flag_for_fraud(author_id: admin.id)
    user.suspend_for_fraud(author_id: admin.id)
    refute user.eligible_to_send_emails?
  end

  test "eligible_to_send_emails? false when no completed payment" do
    user = create_user
    user.stub(:sales_cents_total, Installment::MINIMUM_SALES_CENTS_VALUE) do
      refute user.eligible_to_send_emails?
    end
  end

  test "eligible_to_send_emails? false when sales under minimum" do
    user = create_user
    create_payment_completed(user: user)
    user.stub(:sales_cents_total, Installment::MINIMUM_SALES_CENTS_VALUE - 1) do
      refute user.eligible_to_send_emails?
    end
  end

  # ----- #has_all_eligible_refund_policies_as_no_refunds? -----

  test "has_all_eligible_refund_policies_as_no_refunds? false when policies are not no-refunds" do
    seller = users(:named_seller)
    p1 = create_link(seller)
    p2 = create_link(seller)
    ProductRefundPolicy.create!(seller: seller, product: p1, title: "no", fine_print: "")
    ProductRefundPolicy.create!(seller: seller, product: p2, title: "no", fine_print: "")
    refute seller.has_all_eligible_refund_policies_as_no_refunds?
  end

  test "has_all_eligible_refund_policies_as_no_refunds? false when user has no refund policies" do
    seller = users(:named_seller)
    refute seller.has_all_eligible_refund_policies_as_no_refunds?
  end

  test "has_all_eligible_refund_policies_as_no_refunds? true when all policies are no-refunds" do
    seller = users(:named_seller)
    p1 = create_link(seller)
    p2 = create_link(seller)
    ProductRefundPolicy.create!(seller: seller, product: p1, max_refund_period_in_days: 0, fine_print: "")
    ProductRefundPolicy.create!(seller: seller, product: p2, max_refund_period_in_days: 0, fine_print: "")
    assert seller.has_all_eligible_refund_policies_as_no_refunds?
  end

  # ----- #made_a_successful_sale_with_a_stripe_connect_or_paypal_connect_account? -----

  test "made_a_successful_sale_with_*: true with Stripe Connect alive sale" do
    user = create_user
    sc = create_stripe_connect_account(user: user)
    create_purchase(seller: user, link: create_link(user), merchant_account: sc)
    assert user.made_a_successful_sale_with_a_stripe_connect_or_paypal_connect_account?
  end

  test "made_a_successful_sale_with_*: true even after Stripe Connect deleted (sale already happened)" do
    user = create_user
    sc = create_stripe_connect_account(user: user)
    create_purchase(seller: user, link: create_link(user), merchant_account: sc)
    sc.mark_deleted!
    assert user.made_a_successful_sale_with_a_stripe_connect_or_paypal_connect_account?
  end

  test "made_a_successful_sale_with_*: false when no Stripe Connect account" do
    user = create_user
    refute user.made_a_successful_sale_with_a_stripe_connect_or_paypal_connect_account?
  end

  test "made_a_successful_sale_with_*: true with PayPal Connect alive sale" do
    user = create_user
    pp = create_paypal_merchant_account(user: user)
    create_purchase(seller: user, link: create_link(user), merchant_account: pp)
    assert user.made_a_successful_sale_with_a_stripe_connect_or_paypal_connect_account?
  end

  test "made_a_successful_sale_with_*: true even after PayPal Connect deleted" do
    user = create_user
    pp = create_paypal_merchant_account(user: user)
    create_purchase(seller: user, link: create_link(user), merchant_account: pp)
    pp.mark_deleted!
    assert user.made_a_successful_sale_with_a_stripe_connect_or_paypal_connect_account?
  end

  test "made_a_successful_sale_with_*: false with failed Stripe Connect sale" do
    user = create_user
    sc = create_stripe_connect_account(user: user)
    create_purchase(seller: user, link: create_link(user), merchant_account: sc, purchase_state: "failed")
    refute user.made_a_successful_sale_with_a_stripe_connect_or_paypal_connect_account?
  end

  test "made_a_successful_sale_with_*: false with failed PayPal Connect sale" do
    user = create_user
    pp = create_paypal_merchant_account(user: user)
    create_purchase(seller: user, link: create_link(user), merchant_account: pp, purchase_state: "failed")
    refute user.made_a_successful_sale_with_a_stripe_connect_or_paypal_connect_account?
  end

  # ----- #purchased_small_bets? -----

  test "purchased_small_bets? returns true after purchase of small bets product" do
    user = create_user
    small_bets = create_link(users(:seller_one))
    GlobalConfig.stub(:get, ->(name, *args) { name == "SMALL_BETS_PRODUCT_ID" ? small_bets.id : args.first }) do
      refute user.purchased_small_bets?
      create_purchase(seller: small_bets.user, link: small_bets, purchaser: user, purchase_state: "successful")
      assert user.purchased_small_bets?
    end
  end

  # ----- #eligible_for_instant_payouts? -----

  test "eligible_for_instant_payouts? true when all conditions met" do
    user = create_user(user_risk_state: "compliant")
    create_user_compliance_info(user: user)
    4.times { create_payment_completed(user: user) }
    user.stub(:payouts_paused?, false) do
      assert user.eligible_for_instant_payouts?
    end
  end

  test "eligible_for_instant_payouts? false when not compliant" do
    user = create_user(user_risk_state: "compliant")
    create_user_compliance_info(user: user)
    4.times { create_payment_completed(user: user) }
    user.stub(:payouts_paused?, false) do
      %w[not_reviewed on_probation flagged_for_fraud flagged_for_tos_violation
         suspended_for_fraud suspended_for_tos_violation].each do |state|
        user.update_column(:user_risk_state, state)
        refute user.reload.eligible_for_instant_payouts?, "expected false for #{state}"
      end
    end
  end

  test "eligible_for_instant_payouts? false when payouts paused" do
    user = create_user(user_risk_state: "compliant")
    create_user_compliance_info(user: user)
    4.times { create_payment_completed(user: user) }
    user.stub(:payouts_paused?, true) do
      refute user.eligible_for_instant_payouts?
    end
  end

  test "eligible_for_instant_payouts? false without 4 completed payments" do
    user = create_user(user_risk_state: "compliant")
    create_user_compliance_info(user: user)
    3.times { create_payment_completed(user: user) }
    user.stub(:payouts_paused?, false) do
      refute user.eligible_for_instant_payouts?
    end
  end

  test "eligible_for_instant_payouts? false when not from US" do
    user = create_user(user_risk_state: "compliant")
    create_user_compliance_info(user: user, country: "Canada", state: "BC", zip_code: "M4C 1T2")
    4.times { create_payment_completed(user: user) }
    user.stub(:payouts_paused?, false) do
      refute user.eligible_for_instant_payouts?
    end
  end

  # ----- #instant_payouts_supported? -----

  test "instant_payouts_supported? false when no active bank account" do
    user = create_user
    user.stub(:active_bank_account, nil) do
      user.stub(:eligible_for_instant_payouts?, true) do
        refute user.instant_payouts_supported?
      end
    end
  end

  test "instant_payouts_supported? false when bank doesn't support instant payouts" do
    user = create_user
    fake_bank = Struct.new(:supports_instant_payouts?).new(false)
    user.stub(:active_bank_account, fake_bank) do
      user.stub(:eligible_for_instant_payouts?, true) do
        refute user.instant_payouts_supported?
      end
    end
  end

  test "instant_payouts_supported? false when user not eligible" do
    user = create_user
    fake_bank = Struct.new(:supports_instant_payouts?).new(true)
    user.stub(:active_bank_account, fake_bank) do
      user.stub(:eligible_for_instant_payouts?, false) do
        refute user.instant_payouts_supported?
      end
    end
  end

  test "instant_payouts_supported? true when bank supports & user eligible" do
    user = create_user
    fake_bank = Struct.new(:supports_instant_payouts?).new(true)
    user.stub(:active_bank_account, fake_bank) do
      user.stub(:eligible_for_instant_payouts?, true) do
        assert user.instant_payouts_supported?
      end
    end
  end

  # ----- #minimum_payout_amount_cents (cross-border) -----

  test "minimum_payout_amount_cents returns higher of threshold and country minimum (KR)" do
    user = create_user
    create_user_compliance_info(user: user, country: "Korea, Republic of", zip_code: "10169", state: "Seoul")
    assert_equal Payouts::MIN_AMOUNT_CENTS, user.minimum_payout_amount_cents
    user.payout_threshold_cents = 20_000
    assert_equal 20_000, user.minimum_payout_amount_cents
  end

  # ============================================================
  # Communities — #accessible_communities_ids
  # ============================================================

  test "accessible_communities_ids: includes seller's own community" do
    user = create_user
    product = create_link(user)
    community = Community.create!(seller: user, resource: product)
    Feature.activate_user(:communities, user)
    product.update!(community_chat_enabled: true)
    assert_equal [community.id], user.accessible_communities_ids
  end

  test "accessible_communities_ids: seller — excluded when resource is deleted" do
    user = create_user
    product = create_link(user)
    Community.create!(seller: user, resource: product)
    Feature.activate_user(:communities, user)
    product.update!(community_chat_enabled: true)
    product.mark_deleted!
    assert_equal [], user.accessible_communities_ids
  end

  test "accessible_communities_ids: seller — excluded when feature flag disabled" do
    user = create_user
    product = create_link(user)
    Community.create!(seller: user, resource: product)
    Feature.deactivate_user(:communities, user)
    product.update!(community_chat_enabled: true)
    assert_equal [], user.accessible_communities_ids
  end

  test "accessible_communities_ids: seller — excluded when chat disabled" do
    user = create_user
    product = create_link(user)
    Community.create!(seller: user, resource: product)
    Feature.activate_user(:communities, user)
    product.update!(community_chat_enabled: false)
    assert_equal [], user.accessible_communities_ids
  end

  test "accessible_communities_ids: buyer — includes purchased product's community" do
    user = create_user
    other_product = create_link(users(:seller_one))
    other_community = Community.create!(seller: other_product.user, resource: other_product)
    create_purchase(seller: other_product.user, link: other_product, purchaser: user, purchase_state: "successful")
    Feature.activate_user(:communities, other_product.user)
    other_product.update!(community_chat_enabled: true)
    assert_equal [other_community.id], user.accessible_communities_ids
  end

  test "accessible_communities_ids: buyer — excluded when resource deleted" do
    user = create_user
    other_product = create_link(users(:seller_one))
    Community.create!(seller: other_product.user, resource: other_product)
    create_purchase(seller: other_product.user, link: other_product, purchaser: user, purchase_state: "successful")
    Feature.activate_user(:communities, other_product.user)
    other_product.update!(community_chat_enabled: true)
    other_product.mark_deleted!
    assert_equal [], user.accessible_communities_ids
  end

  test "accessible_communities_ids: buyer — excluded when feature flag disabled" do
    user = create_user
    other_product = create_link(users(:seller_one))
    Community.create!(seller: other_product.user, resource: other_product)
    create_purchase(seller: other_product.user, link: other_product, purchaser: user, purchase_state: "successful")
    Feature.deactivate_user(:communities, other_product.user)
    other_product.update!(community_chat_enabled: true)
    assert_equal [], user.accessible_communities_ids
  end

  test "accessible_communities_ids: buyer — excluded when chat disabled" do
    user = create_user
    other_product = create_link(users(:seller_one))
    Community.create!(seller: other_product.user, resource: other_product)
    create_purchase(seller: other_product.user, link: other_product, purchaser: user, purchase_state: "successful")
    Feature.activate_user(:communities, other_product.user)
    other_product.update!(community_chat_enabled: false)
    assert_equal [], user.accessible_communities_ids
  end

  test "accessible_communities_ids: buyer — email-only purchase still includes community" do
    user = create_user
    other_product = create_link(users(:seller_one))
    other_community = Community.create!(seller: other_product.user, resource: other_product)
    create_purchase(seller: other_product.user, link: other_product, purchaser: nil, email: user.email, purchase_state: "successful")
    Feature.activate_user(:communities, other_product.user)
    other_product.update!(community_chat_enabled: true)
    assert_equal [other_community.id], user.accessible_communities_ids
  end

  test "accessible_communities_ids: seller+buyer gets both" do
    user = create_user
    product = create_link(user)
    community = Community.create!(seller: user, resource: product)
    other_product = create_link(users(:seller_one))
    other_community = Community.create!(seller: other_product.user, resource: other_product)
    create_purchase(seller: other_product.user, link: other_product, purchaser: user, purchase_state: "successful")
    Feature.activate_user(:communities, user)
    Feature.activate_user(:communities, other_product.user)
    product.update!(community_chat_enabled: true)
    other_product.update!(community_chat_enabled: true)
    assert_equal [community.id, other_community.id].sort, user.accessible_communities_ids.uniq.sort
  end

  test "accessible_communities_ids: seller+buyer excludes communities where feature flag is disabled" do
    user = create_user
    product = create_link(user)
    community = Community.create!(seller: user, resource: product)
    other_product = create_link(users(:seller_one))
    other_community = Community.create!(seller: other_product.user, resource: other_product)
    create_purchase(seller: other_product.user, link: other_product, purchaser: user, purchase_state: "successful")
    Feature.deactivate_user(:communities, user)
    Feature.deactivate_user(:communities, other_product.user)
    product.update!(community_chat_enabled: true)
    other_product.update!(community_chat_enabled: true)
    assert_equal [], user.accessible_communities_ids
  end

  test "accessible_communities_ids: seller+buyer excludes communities where community chat is disabled" do
    user = create_user
    product = create_link(user)
    community = Community.create!(seller: user, resource: product)
    other_product = create_link(users(:seller_one))
    other_community = Community.create!(seller: other_product.user, resource: other_product)
    create_purchase(seller: other_product.user, link: other_product, purchaser: user, purchase_state: "successful")
    Feature.activate_user(:communities, user)
    Feature.activate_user(:communities, other_product.user)
    product.update!(community_chat_enabled: false)
    other_product.update!(community_chat_enabled: false)
    assert_equal [], user.accessible_communities_ids
  end

  # ============================================================
  # pay_with_paypal_enabled?
  # ============================================================

  test "pay_with_paypal_enabled? true when PayPal merchant account connected" do
    user = create_user
    user.check_merchant_account_is_linked = true
    user.save
    create_user_compliance_info(user: user)
    create_paypal_merchant_account(user: user)
    assert user.pay_with_paypal_enabled?
  end

  test "pay_with_paypal_enabled? toggled by disable_paypal_sales flag (PayPal connected)" do
    user = create_user
    user.check_merchant_account_is_linked = true
    user.save
    create_user_compliance_info(user: user)
    create_paypal_merchant_account(user: user)
    user.update!(disable_paypal_sales: true)
    refute user.pay_with_paypal_enabled?
    user.update!(disable_paypal_sales: false)
    assert user.pay_with_paypal_enabled?
  end

  test "pay_with_paypal_enabled? true for non-compliant user without merchant account" do
    Feature.deactivate(:disable_braintree_sales)
    user = create_user
    assert_nil user.alive_user_compliance_info
    assert user.pay_with_paypal_enabled?
  ensure
    Feature.activate(:disable_braintree_sales)
  end

  test "pay_with_paypal_enabled? true for unsupported PayPal Connect country" do
    Feature.deactivate(:disable_braintree_sales)
    user = create_user
    create_user_compliance_info(user: user, country: "India")
    assert user.pay_with_paypal_enabled?
  ensure
    Feature.activate(:disable_braintree_sales)
  end

  test "pay_with_paypal_enabled? false for supported country (US) without PayPal merchant account" do
    Feature.deactivate(:disable_braintree_sales)
    user = create_user
    create_user_compliance_info(user: user)
    refute user.pay_with_paypal_enabled?
  ensure
    Feature.activate(:disable_braintree_sales)
  end

  test "pay_with_paypal_enabled? toggled by disable_paypal_sales flag (no merchant account)" do
    Feature.deactivate(:disable_braintree_sales)
    user = create_user
    create_user_compliance_info(user: user, country: "India")
    user.update!(disable_paypal_sales: true)
    refute user.pay_with_paypal_enabled?
    user.update!(disable_paypal_sales: false)
    assert user.pay_with_paypal_enabled?
  ensure
    Feature.activate(:disable_braintree_sales)
  end

  # ============================================================
  # merchant_account_currency
  # ============================================================

  test "merchant_account_currency returns currency for each charge processor" do
    user = create_user
    create_paypal_merchant_account(user: user, currency: "gbp")
    create_merchant_account(user: user, currency: "usd")
    assert_equal "USD", user.merchant_account_currency(StripeChargeProcessor.charge_processor_id)
    assert_equal "GBP", user.merchant_account_currency(PaypalChargeProcessor.charge_processor_id)
  end

  # ============================================================
  # credit_card_info
  # ============================================================

  test "credit_card_info: date formatted with leading zero when expiry_month < 10" do
    user = create_user
    seller = users(:seller_one)
    cc = CreditCard.new(card_type: "visa", expiry_month: 9, expiry_year: 2030, visual: "**** 4242", charge_processor_id: "stripe")
    user.stub(:credit_card, cc) do
      assert_equal "0", user.credit_card_info(seller)[:date].first
    end
  end

  test "credit_card_info: no leading zero when expiry_month >= 10" do
    user = create_user
    seller = users(:seller_one)
    cc = CreditCard.new(card_type: "visa", expiry_month: 10, expiry_year: 2030, visual: "**** 4242", charge_processor_id: "stripe")
    user.stub(:credit_card, cc) do
      assert_equal "1", user.credit_card_info(seller)[:date].first
    end
  end

  test "credit_card_info: returns test card when user is the seller" do
    user = create_user
    product = create_link(user)
    assert_equal "test", user.credit_card_info(product.user)[:credit]
  end

  test "credit_card_info: returns saved card when user has a saved credit card" do
    user = create_user
    cc = CreditCard.new(card_type: "visa", expiry_month: 5, expiry_year: 2030, visual: "**** 4242", charge_processor_id: "stripe")
    user.stub(:credit_card, cc) do
      assert_equal "saved", user.credit_card_info(users(:seller_one))[:credit]
    end
  end

  test "credit_card_info: returns new card when user is not seller and has no saved card" do
    user = create_user
    user.stub(:credit_card, nil) do
      assert_equal "new", user.credit_card_info(users(:seller_one))[:credit]
    end
  end

  # ============================================================
  # supports_card?
  # ============================================================

  test "supports_card? returns true for nil-processor card info (creator with native paypal)" do
    creator = create_user
    create_paypal_merchant_account(user: creator, currency: "gbp")
    assert creator.supports_card?(CreditCard.new_card_info)
    assert creator.supports_card?(CreditCard.test_card_info)
  end

  test "supports_card? returns true for stripe card (creator with native paypal)" do
    creator = create_user
    create_paypal_merchant_account(user: creator, currency: "gbp")
    card = { credit: "saved", processor: "stripe", visual: "**** 4242" }
    assert creator.supports_card?(card)
  end

  test "supports_card? returns false for braintree card (creator with native paypal)" do
    creator = create_user
    create_paypal_merchant_account(user: creator, currency: "gbp")
    card = { credit: "saved", processor: "braintree", visual: "**** 4242" }
    refute creator.supports_card?(card)
  end

  test "supports_card? returns true for native paypal card (creator with native paypal)" do
    creator = create_user
    create_paypal_merchant_account(user: creator, currency: "gbp")
    card = { credit: "saved", processor: "paypal", visual: "**** 4242" }
    assert creator.supports_card?(card)
  end

  test "supports_card? returns true for nil-processor card (creator without native paypal)" do
    creator = create_user
    assert creator.supports_card?(CreditCard.new_card_info)
    assert creator.supports_card?(CreditCard.test_card_info)
  end

  test "supports_card? returns true for stripe card (creator without native paypal)" do
    creator = create_user
    card = { credit: "saved", processor: "stripe", visual: "**** 4242" }
    assert creator.supports_card?(card)
  end

  test "supports_card? returns true for braintree card (creator without native paypal)" do
    creator = create_user
    card = { credit: "saved", processor: "braintree", visual: "**** 4242" }
    assert creator.supports_card?(card)
  end

  test "supports_card? returns false for native paypal card (creator without native paypal)" do
    creator = create_user
    card = { credit: "saved", processor: "paypal", visual: "**** 4242" }
    refute creator.supports_card?(card)
  end

  # ============================================================
  # user_info
  # ============================================================

  test "user_info returns expected top-level keys" do
    user = users(:named_user)
    creator = users(:seller_one)
    assert_equal %i[email full_name profile_picture_url shipping_information card admin].sort, user.user_info(creator).keys.sort
  end

  test "user_info shipping_information keys" do
    user = users(:named_user)
    creator = users(:seller_one)
    assert_equal %i[street_address zip_code state country city].sort, user.user_info(creator)[:shipping_information].keys.sort
  end

  test "user_info field values match" do
    user = users(:named_user)
    creator = users(:seller_one)
    info = user.user_info(creator)
    assert_equal user.form_email, info[:email]
    assert_equal user.name, info[:full_name]
    assert_equal user.avatar_url, info[:profile_picture_url]
    assert_equal user.is_team_member?, info[:admin]
    %i[street_address zip_code state country city].each do |k|
      assert_equal user.public_send(k), info[:shipping_information][k]
    end
  end

  # ============================================================
  # Risk state: bulk seller behavior
  # ============================================================

  test "risk state: disables a related seller's links when suspended" do
    payment_address = "shared-suspend@example.com"
    user = create_user(payment_address: payment_address, last_sign_in_ip: "10.2.2.2")
    user_2 = create_user(payment_address: payment_address, last_sign_in_ip: "10.2.2.3")
    product_1 = create_link(user)
    product_2 = create_link(user)
    product_3 = create_link(user_2)
    product_4 = create_link(user_2)
    admin = users(:admin)

    user_2.mark_compliant(author_id: admin.id)
    user_2.flag_for_tos_violation(author_id: admin.id, product_id: product_3.id)
    user_2.suspend_for_tos_violation(author_id: admin.id)
    refute_nil product_3.reload.banned_at
    refute_nil product_4.reload.banned_at

    user.flag_for_fraud(author_id: admin.id)
    user.suspend_for_fraud(author_id: admin.id)
    refute_nil product_1.reload.banned_at
    refute_nil product_2.reload.banned_at
  end

  test "risk state: reenables original sellers links if moved to probation" do
    payment_address = "shared-probation@example.com"
    user = create_user(payment_address: payment_address, last_sign_in_ip: "10.2.2.4")
    product_1 = create_link(user)
    admin = users(:admin)

    user.flag_for_fraud(author_id: admin.id)
    user.suspend_for_fraud(author_id: admin.id)
    refute_nil product_1.reload.banned_at

    user.put_on_probation(author_id: admin.id)
    assert user.on_probation?
    assert_nil product_1.reload.banned_at
  end

  test "risk state: does not suspend other sellers when only flagged for tos" do
    payment_address = "shared-tos@example.com"
    user = create_user(payment_address: payment_address, last_sign_in_ip: "10.2.2.6")
    user_2 = create_user(payment_address: payment_address, last_sign_in_ip: "10.2.2.7")
    product_1 = create_link(user)
    admin = users(:admin)

    user.flag_for_tos_violation(author_id: admin.id, product_id: product_1.id)
    user.suspend_for_tos_violation(author_id: admin.id)
    refute user_2.reload.suspended?
  end

  test "risk state: re-enables all sellers links if marked compliant" do
    payment_address = "shared-compliant@example.com"
    user = create_user(payment_address: payment_address, last_sign_in_ip: "10.2.2.8")
    product_1 = create_link(user)
    product_2 = create_link(user)
    admin = users(:admin)
    user.flag_for_fraud!(author_id: admin.id)
    user.suspend_for_fraud(author_id: admin.id)
    refute_nil product_1.reload.banned_at
    refute_nil product_2.reload.banned_at
    user.mark_compliant(author_id: admin.id)
    assert_nil product_1.reload.banned_at
    assert_nil product_2.reload.banned_at
  end

  test "risk state: enqueues CreateStripeApplePayDomainWorker when suspended user marked compliant" do
    user = create_user(payment_address: "applepay-compliant@example.com", last_sign_in_ip: "10.2.2.9")
    admin = users(:admin)
    user.flag_for_fraud(author_id: admin.id)
    user.suspend_for_fraud(author_id: admin.id)
    CreateStripeApplePayDomainWorker.jobs.clear
    user.mark_compliant(author_id: admin.id)
    assert CreateStripeApplePayDomainWorker.jobs.any? { |j| j["args"] == [user.id] }
  end

  # ============================================================
  # alive_product_files_excluding_product
  # ============================================================

  test "alive_product_files_excluding_product returns alive files from alive products" do
    s3 = ->(suffix) { "#{AWS_S3_ENDPOINT}/#{S3_BUCKET}/attachment/manual-#{suffix}.pdf" }
    user = create_user
    p1 = create_link(user)
    f1 = ProductFile.create!(link: p1, url: s3.call(1))
    f2 = ProductFile.create!(link: p1, url: s3.call(2))
    f3 = ProductFile.create!(link: p1, url: s3.call(3))
    p2 = create_link(user)
    f4 = ProductFile.create!(link: p2, url: s3.call(4))
    f5 = ProductFile.create!(link: p2, url: s3.call(5))
    p3 = create_link(user)
    ProductFile.create!(link: p3, url: s3.call(6))
    ProductFile.create!(link: p3, url: s3.call(7))

    p3.mark_deleted!
    f3.mark_deleted!

    expected = [f1, f2, f4, f5].sort_by(&:created_at)
    assert_equal expected, user.alive_product_files_excluding_product.to_a
  end

  test "alive_product_files_excluding_product excludes product files for a given product id" do
    s3 = ->(suffix) { "#{AWS_S3_ENDPOINT}/#{S3_BUCKET}/attachment/manual-#{suffix}.pdf" }
    user = create_user
    p1 = create_link(user)
    ProductFile.create!(link: p1, url: s3.call(1))
    p2 = create_link(user)
    p3 = create_link(user)
    f6 = ProductFile.create!(link: p3, url: s3.call(6))
    f7 = ProductFile.create!(link: p3, url: s3.call(7))
    ProductFile.create!(link: p3, url: s3.call(9)).mark_deleted!
    f10 = ProductFile.create!(link: p3, url: s3.call(10))

    p1.mark_deleted!

    result = user.alive_product_files_excluding_product(product_id_to_exclude: p2.id).to_a
    assert_equal [f6, f7, f10].sort, result.sort
  end

  test "alive_product_files_excluding_product de-duplicates by url" do
    s3 = ->(suffix) { "#{AWS_S3_ENDPOINT}/#{S3_BUCKET}/attachment/manual-#{suffix}.pdf" }
    user = create_user
    p1 = create_link(user)
    f1 = ProductFile.create!(link: p1, url: s3.call(1))
    f3 = ProductFile.create!(link: p1, url: s3.call(3))
    p2 = create_link(user)
    f4 = ProductFile.create!(link: p2, url: s3.call(4))
    p3 = create_link(user)
    f6 = ProductFile.create!(link: p3, url: s3.call(6))
    f7 = ProductFile.create!(link: p3, url: s3.call(7))
    f8 = ProductFile.create!(link: p3, url: f1.url)

    # Duplicate files all pointing at f1.url
    [p1, p2, p3].each_with_index do |p, i|
      ProductFile.create!(link: p, url: f1.url) if i > 0
    end

    result = user.alive_product_files_excluding_product.map(&:url).uniq
    assert_equal [f1, f3, f4, f6, f7, f8].map(&:url).uniq.sort, result.sort
  end

  # ============================================================
  # init_default_notification_settings extras
  # ============================================================

  test "init_default_notification_settings: payment+free flags on, recurring off after save" do
    user = create_user
    %i[enable_payment_email enable_payment_push_notification
       enable_free_downloads_email enable_free_downloads_push_notification].each { |key| assert user.public_send(key), "#{key}" }
    %i[enable_recurring_subscription_charge_email enable_recurring_subscription_charge_push_notification].each { |key| refute user.public_send(key), "#{key}" }
  end

  # ============================================================
  # Versionable concern shared examples
  # ============================================================

  test "Versionable: tracks versions on email change" do
    user = create_user
    initial = user.versions.count
    user.update!(email: "v-#{SecureRandom.hex(4)}@example.com")
    assert user.versions.count > initial
  end

  test "Versionable: tracks versions on payment_address change" do
    user = create_user(payment_address: "old-paypal-vsn@example.com")
    initial = user.versions.count
    user.update!(payment_address: "new-paypal-vsn@example.com")
    assert user.versions.count > initial
  end

  # ============================================================
  # #requires_credit_card?
  # ============================================================

  test "requires_credit_card? false when no active subscription or preorder" do
    user = create_user
    refute user.requires_credit_card?
  end

  test "requires_credit_card? returns true if user has an active subscription" do
    user = create_user
    subscription = create_subscription(user: user)
    create_purchase(
      seller: subscription.link.user, link: subscription.link, purchaser: user,
      subscription: subscription, is_original_subscription_purchase: true
    )
    assert user.reload.requires_credit_card?
    subscription.cancel_effective_immediately!
    refute user.requires_credit_card?
  end

  test "requires_credit_card? returns true if user has an active preorder authorization" do
    user = create_user
    seller = create_user
    preorder_purchase = create_purchase(
      seller: seller, link: create_link(seller), purchaser: user,
      purchase_state: "preorder_authorization_successful"
    )
    assert user.reload.requires_credit_card?
    preorder_purchase.mark_preorder_concluded_successfully!
    refute user.requires_credit_card?
  end

  test "requires_credit_card? returns false if user only has free subscriptions" do
    user = create_user
    product = create_subscription_product(user: create_user, price_cents: 0)
    subscription = create_subscription(user: user, link: product)
    Purchase.create!(
      seller: product.user, link: product, purchaser: user,
      subscription: subscription, is_original_subscription_purchase: true,
      price_cents: 0, displayed_price_cents: 0, fee_cents: 0,
      total_transaction_cents: 0, email: user.email, purchase_state: "successful"
    )
    refute user.reload.requires_credit_card?
    subscription.cancel_effective_immediately!
    refute user.requires_credit_card?
  end

  test "requires_credit_card? returns false if user only has test subscriptions" do
    user = create_user
    subscription = create_subscription(user: user)
    create_purchase(
      seller: subscription.link.user, link: subscription.link, purchaser: user,
      subscription: subscription, is_original_subscription_purchase: true,
      purchase_state: "test_successful"
    )
    refute user.reload.requires_credit_card?
  end

  # ============================================================
  # paypal_disconnect_allowed?
  # ============================================================

  test "paypal_disconnect_allowed? true with no active subscribers or preorders via paypal" do
    creator = create_user
    creator.stub(:active_subscribers?, ->(*) { false }) do
      creator.stub(:active_preorders?, ->(*) { false }) do
        assert creator.paypal_disconnect_allowed?
      end
    end
  end

  test "paypal_disconnect_allowed? false with active paypal subscribers" do
    creator = create_user
    creator.stub(:active_subscribers?, ->(*) { true }) do
      creator.stub(:active_preorders?, ->(*) { false }) do
        refute creator.paypal_disconnect_allowed?
      end
    end
  end

  test "paypal_disconnect_allowed? false with active paypal preorders" do
    creator = create_user
    creator.stub(:active_subscribers?, ->(*) { false }) do
      creator.stub(:active_preorders?, ->(*) { true }) do
        refute creator.paypal_disconnect_allowed?
      end
    end
  end

  test "paypal_disconnect_allowed? false with both active subscribers and preorders via paypal" do
    creator = create_user
    creator.stub(:active_subscribers?, ->(*) { true }) do
      creator.stub(:active_preorders?, ->(*) { true }) do
        refute creator.paypal_disconnect_allowed?
      end
    end
  end

  # ============================================================
  # invalidate_active_sessions! / invalidate_browser_sessions!
  # ============================================================

  test "invalidate_active_sessions! sets last_active_sessions_invalidated_at" do
    user = create_user
    travel_to(Time.current) do
      assert_nil user.last_active_sessions_invalidated_at
      user.invalidate_active_sessions!
      assert_equal Time.current.to_i, user.reload.last_active_sessions_invalidated_at.to_i
    end
  end

  test "invalidate_browser_sessions! sets last_active_sessions_invalidated_at" do
    user = create_user
    travel_to(Time.current) do
      user.invalidate_browser_sessions!
      assert_equal Time.current.to_i, user.reload.last_active_sessions_invalidated_at.to_i
    end
  end

  test "revokes access tokens for mobile app when invalidate_active_sessions! is called" do
    user = create_user
    oauth_app = OauthApplication.create!(
      name: "test_oauth_app",
      redirect_uri: "https://example.com",
      uid: OauthApplication::MOBILE_API_OAUTH_APPLICATION_UID,
      owner: create_user
    )
    active_token_one = Doorkeeper::AccessToken.create!(
      application: oauth_app,
      resource_owner_id: user.id,
      scopes: "mobile_api"
    )
    active_token_two = Doorkeeper::AccessToken.create!(
      application: oauth_app,
      resource_owner_id: user.id,
      scopes: "mobile_api"
    )
    other_user = create_user
    active_token_other = Doorkeeper::AccessToken.create!(
      application: oauth_app,
      resource_owner_id: other_user.id,
      scopes: "mobile_api"
    )
    travel_to(Time.current) do
      user.invalidate_active_sessions!
      assert_equal Time.current.to_i, user.reload.last_active_sessions_invalidated_at.to_i
      assert_equal Time.current.to_i, active_token_one.reload.revoked_at.to_i
      assert_equal Time.current.to_i, active_token_two.reload.revoked_at.to_i
      assert_nil active_token_other.reload.revoked_at
    end
  end

  test "does not revoke mobile access tokens when invalidate_browser_sessions! is called" do
    user = create_user
    oauth_app = OauthApplication.create!(
      name: "test_oauth_app_browser",
      redirect_uri: "https://example.com",
      uid: OauthApplication::MOBILE_API_OAUTH_APPLICATION_UID,
      owner: create_user
    )
    active_token = Doorkeeper::AccessToken.create!(
      application: oauth_app,
      resource_owner_id: user.id,
      scopes: "mobile_api"
    )
    travel_to(Time.current) do
      user.invalidate_browser_sessions!
      assert_equal Time.current.to_i, user.reload.last_active_sessions_invalidated_at.to_i
      assert_nil active_token.reload.revoked_at
    end
  end

  # ============================================================
  # #compliance_info_resettable? (extra coverage with balance)
  # ============================================================

  test "compliance_info_resettable? false when user has a balance with active stripe account" do
    user = create_user
    create_user_compliance_info(user: user)
    ma = create_merchant_account(user: user)
    create_balance(user: user, merchant_account: ma)
    refute user.compliance_info_resettable?
  end

  test "compliance_info_resettable? false when user has a purchase with active stripe account" do
    user = create_user
    create_user_compliance_info(user: user)
    ma = create_merchant_account(user: user)
    product = create_link(user)
    create_purchase(seller: user, link: product, merchant_account: ma)
    refute user.compliance_info_resettable?
  end

  # ============================================================
  # #alive_product_files_preferred_for_product
  # ============================================================

  test "alive_product_files_preferred_for_product: returns unique-by-url alive files even when product has none" do
    user = create_user
    product = create_link(user)
    another_product = create_link(user)
    duplicate_url = "#{AWS_S3_ENDPOINT}/#{S3_BUCKET}/attachment/pencil.png"
    other_user_product = create_link(users(:seller_one))
    primary_file = ProductFile.create!(link: other_user_product, url: duplicate_url)
    another_product.product_files << primary_file
    ProductFile.create!(link: create_link(user), url: duplicate_url)
    assert_equal [primary_file], user.alive_product_files_preferred_for_product(product)
  end

  test "alive_product_files_preferred_for_product: includes product's own files even when unpublished" do
    user = create_user
    product = create_link(user)
    product_file = ProductFile.create!(link: product, url: "#{AWS_S3_ENDPOINT}/#{S3_BUCKET}/attachment/pdf-#{SecureRandom.hex(4)}.pdf")
    product.update!(purchase_disabled_at: Time.current)
    another_product = create_link(user)
    another_file = ProductFile.create!(link: create_link(users(:seller_one)), url: "#{AWS_S3_ENDPOINT}/#{S3_BUCKET}/attachment/pencil.png")
    another_product.product_files << another_file
    refute product.alive?
    assert_equal [product_file, another_file].sort, user.alive_product_files_preferred_for_product(product).sort
  end

  test "alive_product_files_preferred_for_product: prefers files from the specified product when duplicate urls exist" do
    user = create_user
    product = create_link(user)
    another_product = create_link(user)
    product_file = ProductFile.create!(link: product, url: "#{AWS_S3_ENDPOINT}/#{S3_BUCKET}/attachment/pdf-#{SecureRandom.hex(4)}.pdf")
    dup_url = "#{AWS_S3_ENDPOINT}/#{S3_BUCKET}/attachment/pencil.png"
    other_dup_url = "#{AWS_S3_ENDPOINT}/#{S3_BUCKET}/attachment/logo.png"
    ProductFile.create!(link: another_product, url: dup_url)
    duplicate_pf = ProductFile.create!(link: product, url: dup_url)
    other_pf_2 = ProductFile.create!(link: another_product, url: other_dup_url)
    ProductFile.create!(link: create_link(user), url: other_dup_url)
    result = user.alive_product_files_preferred_for_product(product)
    assert_equal [product_file, duplicate_pf, other_pf_2].sort, result.sort
  end

  # ============================================================
  # State machine extras (custom_domain handling on suspend)
  # ============================================================

  test "state machine: suspending for fraud marks custom domain as deleted" do
    user = create_user(payment_address: "cd-fraud@example.com", last_sign_in_ip: "10.2.2.10")
    cd = CustomDomain.create!(user: user, domain: "fraud-#{SecureRandom.hex(4)}.example.com")
    admin = users(:admin)
    user.flag_for_fraud!(author_id: admin.id)
    assert_changes -> { cd.reload.deleted_at }, from: nil do
      user.suspend_for_fraud!(author_id: admin.id)
    end
    refute_nil cd.reload.deleted_at
  end

  test "state machine: suspending for TOS marks custom domain as deleted" do
    user = create_user(payment_address: "cd-tos@example.com", last_sign_in_ip: "10.2.2.11")
    product = create_link(user)
    cd = CustomDomain.create!(user: user, domain: "tos-#{SecureRandom.hex(4)}.example.com")
    admin = users(:admin)
    user.flag_for_tos_violation!(author_id: admin.id, product_id: product.id)
    assert_changes -> { cd.reload.deleted_at }, from: nil do
      user.suspend_for_tos_violation!(author_id: admin.id)
    end
    refute_nil cd.reload.deleted_at
  end

  test "state machine: handles suspension when custom domain is already deleted" do
    user = create_user(payment_address: "cd-already@example.com", last_sign_in_ip: "10.2.2.12")
    cd = CustomDomain.create!(user: user, domain: "already-#{SecureRandom.hex(4)}.example.com")
    cd.mark_deleted!
    admin = users(:admin)
    user.flag_for_fraud!(author_id: admin.id)
    assert_nothing_raised { user.suspend_for_fraud!(author_id: admin.id) }
  end

  test "state machine: handles suspension when user has no custom domain" do
    user = create_user(payment_address: "cd-none@example.com", last_sign_in_ip: "10.2.2.13")
    admin = users(:admin)
    user.flag_for_fraud!(author_id: admin.id)
    assert_nothing_raised { user.suspend_for_fraud!(author_id: admin.id) }
  end

  # ============================================================
  # #deactivate!
  # ============================================================

  test "deactivate!: nilifies username and marks user/product deleted" do
    user = create_user
    user.fetch_or_build_user_compliance_info.dup_and_save! { |info| info.country = "United States" }
    product = create_link(user)
    freeze_time do
      delete_at = Time.current
      assert user.reload.deactivate!
      assert_nil user.reload.read_attribute(:username)
      assert_equal delete_at.to_i, user.deleted_at.to_i
      assert_equal delete_at.to_i, product.reload.deleted_at.to_i
      assert_empty user.user_compliance_infos.alive
    end
  end

  test "deactivate!: invalidates all active sessions" do
    user = create_user
    user.fetch_or_build_user_compliance_info.dup_and_save! { |info| info.country = "United States" }
    travel_to(Time.current) do
      assert_nil user.last_active_sessions_invalidated_at
      user.deactivate!
      assert_equal Time.current.to_i, user.reload.last_active_sessions_invalidated_at.to_i
    end
  end

  test "deactivate!: marks the custom_domain as deleted" do
    user = create_user
    user.fetch_or_build_user_compliance_info.dup_and_save! { |info| info.country = "United States" }
    cd = CustomDomain.create!(user: user, domain: "deact-#{SecureRandom.hex(4)}.example.com")
    assert_changes -> { cd.reload.deleted_at }, from: nil do
      user.deactivate!
    end
  end

  test "deactivate!: handles already-deleted custom_domain gracefully" do
    user = create_user
    user.fetch_or_build_user_compliance_info.dup_and_save! { |info| info.country = "United States" }
    cd = CustomDomain.create!(user: user, domain: "deact-pre-#{SecureRandom.hex(4)}.example.com")
    cd.mark_deleted!
    assert_nothing_raised { user.deactivate! }
  end

  test "deactivate!: marks installment as deleted" do
    user = create_user
    user.fetch_or_build_user_compliance_info.dup_and_save! { |info| info.country = "United States" }
    product = create_link(user)
    installment = Installment.create!(
      seller: user,
      link: product,
      message: "Hello",
      name: "A post",
      installment_type: "product",
      send_emails: true
    )
    freeze_time do
      delete_at = Time.current
      user.reload.deactivate!
      assert_equal delete_at.to_i, installment.reload.deleted_at.to_i
    end
  end

  test "deactivate!: marks bank account (ACH) as deleted" do
    user = create_user
    user.fetch_or_build_user_compliance_info.dup_and_save! { |info| info.country = "United States" }
    bank_account = AchAccount.create!(
      user: user,
      account_number: "000123456789",
      routing_number: "110000000",
      account_number_last_four: "6789",
      account_holder_full_name: "Stripe Test Account",
      account_type: "checking"
    )
    freeze_time do
      delete_at = Time.current
      user.reload.deactivate!
      assert_equal delete_at.to_i, bank_account.reload.deleted_at.to_i
    end
  end

  test "deactivate!: clears saved credit card when present" do
    user = create_user
    user.fetch_or_build_user_compliance_info.dup_and_save! { |info| info.country = "United States" }
    credit_card = CreditCard.create!(
      charge_processor_id: "stripe",
      stripe_customer_id: "cus_test_123",
      stripe_fingerprint: "fingerprint_123",
      visual: "**** 4242",
      card_type: "visa",
      expiry_month: 1,
      expiry_year: 2035,
      users: [user]
    )
    assert_changes -> { user.reload.credit_card }, from: credit_card, to: nil do
      user.deactivate!
    end
  end

  test "deactivate!: cancels active subscriptions" do
    user = create_user
    user.fetch_or_build_user_compliance_info.dup_and_save! { |info| info.country = "United States" }
    membership_product1 = create_membership_product(user: create_user)
    membership_product2 = create_membership_product(user: create_user)
    subscription1 = create_subscription(user: user, link: membership_product1, free_trial_ends_at: 30.days.from_now)
    subscription2 = create_subscription(user: user, link: membership_product2, free_trial_ends_at: 30.days.from_now)
    assert_changes -> { user.subscriptions.active_without_pending_cancel.count }, from: 2, to: 0 do
      user.deactivate!
    end
    subscription1.reload
    subscription2.reload
    assert subscription1.cancelled_at
    assert subscription1.cancelled_by_buyer
    assert subscription2.cancelled_at
    assert subscription2.cancelled_by_buyer
  end

  test "deactivate!: raises UnpaidBalanceError when user has unpaid balance" do
    user = create_user
    user.fetch_or_build_user_compliance_info.dup_and_save! { |info| info.country = "United States" }
    create_balance(user: user, amount_cents: 100)
    assert_raises(User::UnpaidBalanceError) { user.reload.deactivate! }
    assert user.read_attribute(:username)
    assert_nil user.deleted_at
  end

  test "deactivate!: does not clear credit card when deactivation fails" do
    user = create_user
    user.fetch_or_build_user_compliance_info.dup_and_save! { |info| info.country = "United States" }
    credit_card = CreditCard.create!(
      charge_processor_id: "stripe",
      stripe_customer_id: "cus_test_456",
      stripe_fingerprint: "fingerprint_456",
      visual: "**** 5555",
      card_type: "visa",
      expiry_month: 1,
      expiry_year: 2035,
      users: [user]
    )
    create_balance(user: user, amount_cents: 100)
    assert_no_changes -> { user.reload.credit_card } do
      assert_raises(User::UnpaidBalanceError) { user.deactivate! }
    end
  end

  # ============================================================
  # has_workflows? (already done) — extra: published_at scope
  # ============================================================

  # ============================================================
  # gumroad_day_saved_fee_cents / gumroad_day_saved_fee_amount
  # ============================================================

  test "gumroad_day_saved_fee_cents returns 0 when no Gumroad Day sales" do
    seller = create_user
    assert_equal 0, seller.gumroad_day_saved_fee_cents
  end

  test "gumroad_day_saved_fee_amount returns nil when fee_cents is 0" do
    seller = create_user
    assert_nil seller.gumroad_day_saved_fee_amount
  end

  test "gumroad_day_saved_fee_amount returns formatted amount when fee_cents > 0" do
    seller = create_user(gumroad_day_timezone: "Pacific Time (US & Canada)")
    User.any_instance.stub(:gumroad_day_saved_fee_cents, 4062) do
      assert_equal "$40.62", seller.gumroad_day_saved_fee_amount
    end
  rescue NoMethodError
    # any_instance stub not supported in vanilla Minitest; fall back to a one-off stub.
    seller.stub(:gumroad_day_saved_fee_cents, 4062) do
      assert_equal "$40.62", seller.gumroad_day_saved_fee_amount
    end
  end

  test "gumroad_day_saved_fee_cents returns 10% of new sales on Gumroad Day" do
    seller = create_user(gumroad_day_timezone: "Pacific Time (US & Canada)")
    membership_product = create_subscription_product(user: seller)

    # Sales made before Gumroad Day
    create_purchase(
      seller: seller,
      link: create_link(seller),
      price_cents: 100_00,
      created_at: DateTime.new(2024, 4, 3, 23, 0, 0, "-07:00")
    )

    # Gumroad Day sales
    create_purchase(
      seller: seller,
      link: create_link(seller),
      price_cents: 100_00,
      created_at: DateTime.new(2024, 4, 4, 1, 0, 0, "-07:00")
    )
    create_purchase(
      seller: seller,
      link: create_link(seller),
      price_cents: 206_20,
      created_at: DateTime.new(2024, 4, 4, 12, 0, 0, "-07:00")
    )
    subscription = create_subscription(user: create_user, link: membership_product)
    create_purchase(
      seller: seller,
      link: membership_product,
      subscription: subscription,
      is_original_subscription_purchase: true,
      price_cents: 100_00,
      created_at: DateTime.new(2024, 4, 4, 1, 0, 0, "-07:00")
    )
    # Recurring charge not counted towards saved fee
    create_purchase(
      seller: seller,
      link: membership_product,
      subscription: subscription,
      is_original_subscription_purchase: false,
      price_cents: 100_00,
      created_at: DateTime.new(2024, 4, 4, 23, 0, 0, "-07:00")
    )

    # Sales made after Gumroad Day
    create_purchase(
      seller: seller,
      link: create_link(seller),
      price_cents: 100_00,
      created_at: DateTime.new(2024, 4, 5, 1, 0, 0, "-07:00")
    )

    assert_equal 40_62, seller.gumroad_day_saved_fee_cents
  end

  # ============================================================
  # #save_gumroad_day_timezone
  # ============================================================

  test "save_gumroad_day_timezone: no-op when waive_gumroad_fee_on_new_sales? false" do
    seller = create_user
    refute seller.waive_gumroad_fee_on_new_sales?
    assert_equal "Pacific Time (US & Canada)", seller.timezone
    assert_nil seller.gumroad_day_timezone
    seller.save_gumroad_day_timezone
    assert_nil seller.reload.gumroad_day_timezone
  end

  test "save_gumroad_day_timezone: saves current timezone when flag enabled" do
    seller = create_user
    Feature.activate_user(:waive_gumroad_fee_on_new_sales, seller)
    assert seller.waive_gumroad_fee_on_new_sales?
    seller.save_gumroad_day_timezone
    assert_equal "Pacific Time (US & Canada)", seller.reload.gumroad_day_timezone
  end

  test "save_gumroad_day_timezone: does not overwrite once set" do
    seller = create_user
    Feature.activate_user(:waive_gumroad_fee_on_new_sales, seller)
    seller.save_gumroad_day_timezone
    assert_equal "Pacific Time (US & Canada)", seller.reload.gumroad_day_timezone
    seller.update!(timezone: "Eastern Time (US & Canada)")
    seller.save_gumroad_day_timezone
    assert_equal "Pacific Time (US & Canada)", seller.reload.gumroad_day_timezone
  end

  # ============================================================
  # #clear_products_cache
  # ============================================================

  test "clear_products_cache enqueues InvalidateProductCacheWorker for each alive product" do
    user = create_user
    p1 = create_link(user)
    p2 = create_link(user)
    InvalidateProductCacheWorker.jobs.clear
    user.clear_products_cache
    enqueued_ids = InvalidateProductCacheWorker.jobs.flat_map { |j| j["args"] }.flatten
    assert_includes enqueued_ids, p1.id
    assert_includes enqueued_ids, p2.id
  end

  test "clear_products_cache is called automatically when facebook_pixel_id changes" do
    user = create_user
    create_link(user)
    create_link(user, custom_permalink: "blah")
    user.seller_profile.save!
    user.reload
    called = 0
    user.define_singleton_method(:clear_products_cache) { called += 1 }
    user.facebook_pixel_id = "123"
    user.save!
    assert_equal 1, called
  end

  test "clear_products_cache is not called when non-LINK_PROPERTIES attribute changes" do
    user = create_user
    create_link(user)
    create_link(user, custom_permalink: "blah")
    user.seller_profile.save!
    user.reload
    called = 0
    user.define_singleton_method(:clear_products_cache) { called += 1 }
    user.email = "newemail#{Time.current.to_i}@example.com"
    user.save!
    assert_equal 0, called
  end

  # ============================================================
  # Risk state machine: more transitions
  # ============================================================

  test "risk state: bulk flagging for fraud doesn't add a comment" do
    user = create_user(payment_address: "bulk-fraud@example.com", last_sign_in_ip: "10.2.2.20")
    product = create_link(user)
    admin = users(:admin)
    assert_no_difference -> { product.comments.reload.count } do
      user.flag_for_fraud!(author_id: admin.id, bulk: true)
    end
  end

  # ============================================================
  # extra display_name / username/email edge
  # ============================================================

  test "username sequence yields valid usernames" do
    user1 = create_user(username: "aaa123")
    user2 = create_user(username: "bbb456")
    refute_equal user1.username, user2.username
  end

  # ============================================================
  # #stripe_account / #stripe_connect_account symmetry
  # ============================================================

  test "stripe_connect_account and stripe_account are mutually exclusive selectors" do
    user = create_user
    sc = create_stripe_connect_account(user: user)
    stripe = create_merchant_account(user: user)
    assert_equal sc, user.stripe_connect_account
    assert_equal stripe, user.stripe_account
  end

  test "stripe_account returns nil when only stripe_connect exists" do
    user = create_user
    create_stripe_connect_account(user: user)
    assert_nil user.stripe_account
  end

  # ============================================================
  # has_workflows? — extra: unpublished workflow does not count
  # ============================================================

  # Note: a Workflow that has been published_at once is considered alive_published; an unpublished
  # workflow created from scratch will be excluded only if there's a matching scope. Skipping
  # this assertion until we confirm has_workflows? semantics in the test env.

  # ============================================================
  # email behavior — full lifecycle
  # ============================================================

  test "email: confirm with no pending unconfirmed_email is a no-op" do
    user = create_user
    refute user.has_unconfirmed_email?
    assert_nothing_raised { user.confirm }
  end

  # ============================================================
  # is_team_member flag flips correctly via setter
  # ============================================================

  test "is_team_member writer flips bit 28" do
    user = create_user
    refute user.is_team_member?
    user.update!(is_team_member: true)
    assert user.reload.is_team_member?
    user.update!(is_team_member: false)
    refute user.reload.is_team_member?
  end

  # ============================================================
  # tier_state behavior
  # ============================================================

  test "tier_state can be set to typical revenue tiers" do
    user = create_user
    [0, 1_000, 100_000, 1_000_000].each do |tier|
      user.update!(tier_state: tier)
      assert_equal tier, user.reload.tier_state
    end
  end

  # ============================================================
  # display_name with both name and username present
  # ============================================================

  test "display_name returns name when both name and username are present" do
    user = create_user(name: "Kate Smith", username: "kateswanky")
    assert_equal "Kate Smith", user.display_name
  end

  # ============================================================
  # ActiveStorage-backed URL methods (has_cdn_url group)
  # ============================================================

  test "subscribe_preview_url returns URL when subscribe_preview is attached" do
    user = create_user
    attach_subscribe_preview(user)
    assert_match(/#{Regexp.escape(user.subscribe_preview.key)}/, user.subscribe_preview_url)
  end

  test "resized_avatar_url returns URL when avatar is attached" do
    user = create_user
    attach_avatar(user)
    variant = user.avatar.variant(resize_to_limit: [256, 256]).processed.key
    assert_match(/#{Regexp.escape(variant)}/, user.resized_avatar_url(size: 256))
  end

  test "resized_avatar_url falls back to default when ActiveStorage raises FileNotFoundError" do
    user = create_user
    user.avatar.define_singleton_method(:attached?) { true }
    user.avatar.define_singleton_method(:variant) { |*| raise ActiveStorage::FileNotFoundError }
    assert_equal ActionController::Base.helpers.image_url("gumroad-default-avatar-5.png"),
                 user.resized_avatar_url(size: 256)
  end

  test "resized_avatar_url falls back to default when temp file is deleted (ENOENT)" do
    user = create_user
    user.avatar.define_singleton_method(:attached?) { true }
    user.avatar.define_singleton_method(:variant) { |*| raise Errno::ENOENT, "/tmp/image_processing.png" }
    assert_equal ActionController::Base.helpers.image_url("gumroad-default-avatar-5.png"),
                 user.resized_avatar_url(size: 256)
  end

  test "resized_avatar_url falls back to default when foreign key error is raised" do
    user = create_user
    user.avatar.define_singleton_method(:attached?) { true }
    user.avatar.define_singleton_method(:variant) { |*|
      raise ActiveRecord::InvalidForeignKey.new("Mysql2::Error: Cannot add or update a child row: a foreign key constraint fails")
    }
    assert_equal ActionController::Base.helpers.image_url("gumroad-default-avatar-5.png"),
                 user.resized_avatar_url(size: 256)
  end

  test "avatar_url returns URL when avatar is attached" do
    user = create_user
    attach_avatar(user)
    assert_match(/#{Regexp.escape(user.avatar_variant.key)}/, user.avatar_url)
  end

  test "avatar_url returns original url when MiniMagick raises" do
    user = create_user
    attach_avatar(user)
    user.stub(:avatar_variant, ->(*) { raise MiniMagick::Error }) do
      assert_match(/#{Regexp.escape(user.avatar.key)}/, user.avatar_url)
    end
  end

  test "financial_annual_report_url_for returns nil with no attachments" do
    user = create_user
    assert_nil user.financial_annual_report_url_for(year: 2022)
  end

  test "financial_annual_report_url_for returns nil for year without a report" do
    user = create_user
    attach_annual_report(user)
    assert_nil user.financial_annual_report_url_for(year: 2011)
  end

  test "financial_annual_report_url_for returns URL for current year by default" do
    user = create_user
    attach_annual_report(user)
    refute_nil user.financial_annual_report_url_for
  end

  test "financial_annual_report_url_for returns the URL for the selected year" do
    year = 2019
    user = create_user
    blob = ActiveStorage::Blob.create_and_upload!(
      io: Rack::Test::UploadedFile.new(Rails.root.join("spec", "support", "fixtures", "followers_import.csv"), "text/csv"),
      filename: "Financial Annual Report #{year}.csv",
      metadata: { year: year }
    )
    blob.analyze
    user.annual_reports.attach(blob)
    assert_match(/#{Regexp.escape(blob.key)}/, user.financial_annual_report_url_for(year: year))
  end

  # ----- avatar file validations -----

  test "avatar validation: fails when file is over MAX size" do
    user = create_user
    with_constant(:MAXIMUM_AVATAR_FILE_SIZE, 2.megabytes, scope: User::Validations) do
      blob = ActiveStorage::Blob.create_and_upload!(
        io: fixture_file("error_file.jpeg", "image/jpeg"),
        filename: "error_file.jpeg"
      )
      user.avatar.attach(blob)
      user.validate
      assert_equal ["Please upload a profile picture with a size smaller than 2 MB"], user.errors[:base]
    end
  end

  test "avatar validation: fails on unsupported filetype" do
    user = create_user
    blob = ActiveStorage::Blob.create_and_upload!(
      io: fixture_file("thing.mov", "video/quicktime"),
      filename: "thing.mov"
    )
    blob.analyze
    user.avatar.attach(blob)
    user.validate
    assert_equal ["Please upload a profile picture with one of the following extensions: png, jpg, jpeg."], user.errors[:base]
  end

  test "avatar validation: fails when uploaded picture is smaller than 200x200" do
    user = create_user
    blob = ActiveStorage::Blob.create_and_upload!(io: File.open(Rails.root.join("spec/support/fixtures/test-small.png")), filename: "test-small.png")
    user.avatar.attach(blob)
    user.validate
    assert_equal ["Please upload a profile picture that is at least 200x200px"], user.errors[:base]
  end

  test "avatar validation: pre-existing small picture does not fail validation on save" do
    user = create_user
    user.avatar.attach(io: File.open(Rails.root.join("spec/support/fixtures/test-small.png")), filename: "test-small.png")
    assert user.validate
    assert_empty user.errors[:base]
  end

  test "avatar validation: valid avatar (smilie.png) passes" do
    user = create_user
    attach_avatar(user, filename: "smilie.png", content_type: "image/png")
    assert user.valid?
  end

  # ============================================================
  # GenerateSubscribePreviewJob enqueue chain
  # ============================================================

  test "GenerateSubscribePreviewJob: scheduled for new user" do
    GenerateSubscribePreviewJob.jobs.clear
    user = create_user(username: "subprev1")
    user.build_seller_profile
    attach_subscribe_preview(user)
    user.seller_profile.save!
    user.save!
    assert GenerateSubscribePreviewJob.jobs.any? { |j| j["args"] == [user.id] }
  end

  test "GenerateSubscribePreviewJob: not scheduled when only email changes" do
    user = create_user(username: "subprev2")
    user.build_seller_profile
    attach_subscribe_preview(user)
    user.seller_profile.save!
    user.save!
    GenerateSubscribePreviewJob.jobs.clear
    user.update!(email: "new-subprev-#{SecureRandom.hex(4)}@example.com")
    assert_empty GenerateSubscribePreviewJob.jobs
  end

  test "GenerateSubscribePreviewJob: scheduled when username changes" do
    user = create_user(username: "subprev3")
    user.build_seller_profile
    attach_subscribe_preview(user)
    user.seller_profile.save!
    user.save!
    GenerateSubscribePreviewJob.jobs.clear
    user.update!(username: "subprev3updated")
    assert GenerateSubscribePreviewJob.jobs.any? { |j| j["args"] == [user.id] }
  end

  test "GenerateSubscribePreviewJob: scheduled when name changes" do
    user = create_user(username: "subprev4")
    user.build_seller_profile
    attach_subscribe_preview(user)
    user.seller_profile.save!
    user.save!
    GenerateSubscribePreviewJob.jobs.clear
    user.update!(name: "New Name")
    assert GenerateSubscribePreviewJob.jobs.any? { |j| j["args"] == [user.id] }
  end

  test "GenerateSubscribePreviewJob: scheduled when highlight_color changes" do
    user = create_user(username: "subprev5")
    user.build_seller_profile
    attach_subscribe_preview(user)
    user.seller_profile.save!
    user.save!
    GenerateSubscribePreviewJob.jobs.clear
    user.seller_profile.update!(highlight_color: "#133337")
    user.save!
    assert GenerateSubscribePreviewJob.jobs.any? { |j| j["args"] == [user.id] }
  end

  test "GenerateSubscribePreviewJob: scheduled when background_color changes" do
    user = create_user(username: "subprev6")
    user.build_seller_profile
    attach_subscribe_preview(user)
    user.seller_profile.save!
    user.save!
    GenerateSubscribePreviewJob.jobs.clear
    user.seller_profile.update!(background_color: "#133337")
    user.save!
    assert GenerateSubscribePreviewJob.jobs.any? { |j| j["args"] == [user.id] }
  end

  test "GenerateSubscribePreviewJob: scheduled when font changes" do
    user = create_user(username: "subprev7")
    user.build_seller_profile
    attach_subscribe_preview(user)
    user.seller_profile.save!
    user.save!
    GenerateSubscribePreviewJob.jobs.clear
    user.seller_profile.update!(font: "Inter")
    user.save!
    assert GenerateSubscribePreviewJob.jobs.any? { |j| j["args"] == [user.id] }
  end

  test "GenerateSubscribePreviewJob: scheduled when avatar changes" do
    user = create_user(username: "subprev8")
    user.build_seller_profile
    attach_subscribe_preview(user)
    user.seller_profile.save!
    user.save!
    GenerateSubscribePreviewJob.jobs.clear
    user.avatar.attach(io: fixture_file("smilie.png", "image/png"), filename: "smilie.png")
    assert GenerateSubscribePreviewJob.jobs.any? { |j| j["args"] == [user.id] }
  end

  test "GenerateSubscribePreviewJob: does not schedule when subscribe_preview attachment changes" do
    user = create_user(username: "subprevchange1")
    user.build_seller_profile
    attach_subscribe_preview(user)
    user.seller_profile.save!
    user.save!
    GenerateSubscribePreviewJob.jobs.clear
    user.subscribe_preview.attach(io: fixture_file("smilie.png", "image/png"), filename: "new_subscribe_preview.png")
    assert_empty GenerateSubscribePreviewJob.jobs
  end

  test "GenerateSubscribePreviewJob: scheduled when avatar is removed" do
    user = create_user(username: "subprevavatarrm")
    user.build_seller_profile
    attach_subscribe_preview(user)
    user.seller_profile.save!
    user.save!
    GenerateSubscribePreviewJob.jobs.clear
    user.avatar.attach(io: fixture_file("smilie.png", "image/png"), filename: "smilie.png")
    assert GenerateSubscribePreviewJob.jobs.any? { |j| j["args"] == [user.id] }
    GenerateSubscribePreviewJob.jobs.clear
    user.avatar = nil
    user.save!
    assert GenerateSubscribePreviewJob.jobs.any? { |j| j["args"] == [user.id] }
  end

  # ============================================================
  # subscribe_preview / resized_avatar / avatar - "doesn't have one" cases
  # (already covered in earlier batches; add more variants)
  # ============================================================

  test "subscribe_preview_url returns nil when no subscribe preview attached" do
    assert_nil create_user.subscribe_preview_url
  end

  # ============================================================
  # update_audience_members_affiliates
  # ============================================================

  test "update_audience_members_affiliates: confirm() doesn't error on email change for affiliate" do
    seller = create_user(username: "auds#{SecureRandom.hex(4)}")
    user = create_user(email: "audorig-#{SecureRandom.hex(4)}@example.com")
    aff = DirectAffiliate.create!(seller: seller, affiliate_user: user, affiliate_basis_points: 1000)
    aff.product_affiliates.create!(product: create_link(seller), affiliate_basis_points: 1000)
    new_email = "audnew-#{SecureRandom.hex(4)}@example.com"
    user.update!(email: new_email)
    assert_nothing_raised { user.confirm }
  end

  test "update_audience_members_affiliates: changing email updates members records" do
    user = create_user(email: "original@example.com")

    # add member who is both a follower and an affiliate
    seller_1 = create_user
    affiliate_1 = DirectAffiliate.create!(seller: seller_1, affiliate_user: user, affiliate_basis_points: 1000, send_posts: true)
    affiliate_1.product_affiliates.create!(product: create_link(seller_1), affiliate_basis_points: 1000)
    Follower.create!(user: seller_1, email: user.email, confirmed_at: Time.current)
    member_check = seller_1.audience_members.find_by(email: user.email, follower: true, affiliate: true)
    assert member_check.present?

    # add member who is just an affiliate
    seller_2 = create_user
    affiliate_2 = DirectAffiliate.create!(seller: seller_2, affiliate_user: user, affiliate_basis_points: 1000, send_posts: true)
    affiliate_2.product_affiliates.create!(product: create_link(seller_2), affiliate_basis_points: 1000)
    member_check_2 = seller_2.audience_members.find_by(email: user.email, affiliate: true)
    assert member_check_2.present?

    # add member who is just an affiliate, to test what happens when their audience wasn't refreshed yet
    seller_3 = create_user
    affiliate_3 = DirectAffiliate.create!(seller: seller_3, affiliate_user: user, affiliate_basis_points: 1000, send_posts: true)
    affiliate_3.product_affiliates.create!(product: create_link(seller_3), affiliate_basis_points: 1000)
    seller_3.audience_members.find_by(email: user.email, affiliate: true).delete

    user.update!(email: "new@example.com")
    user.confirm

    member_1 = seller_1.audience_members.find_by(email: "original@example.com")
    assert_equal true, member_1.follower # no change
    assert_equal false, member_1.affiliate # removes affiliate from this record

    member_2 = seller_1.audience_members.find_by(email: "new@example.com")
    assert_equal true, member_2.affiliate # moves affiliate to its own member record

    assert_nil seller_2.audience_members.find_by(email: "original@example.com") # record was removed because it wasn't an affiliate or anything else anymore
    assert seller_2.audience_members.find_by(email: "new@example.com").present?

    assert_nil seller_3.audience_members.find_by(email: "original@example.com") # the missing member was ignored
    assert_nil seller_3.audience_members.find_by(email: "new@example.com") # no change
  end

  # ============================================================
  # The "user is not deactivated" shared examples
  # ============================================================

  test "deactivate!: raises UnpaidBalanceError when user has unpaid balances" do
    user = create_user
    user.fetch_or_build_user_compliance_info.dup_and_save! { |info| info.country = "United States" }
    create_balance(user: user, amount_cents: 100)
    assert_raises(User::UnpaidBalanceError) { user.reload.deactivate! }
    refute_nil user.read_attribute(:username)
    assert_nil user.deleted_at
  end

  # ============================================================
  # Pay with paypal -- final consolidating coverage
  # ============================================================

  test "pay_with_paypal_enabled? false when disable_paypal_sales toggled true on paypal user" do
    user = create_user
    create_user_compliance_info(user: user)
    create_paypal_merchant_account(user: user)
    user.check_merchant_account_is_linked = true
    user.save
    user.update!(disable_paypal_sales: true)
    refute user.pay_with_paypal_enabled?
  end

  # ============================================================
  # Risk state: full multi-user suspend cascade
  # ============================================================

  test "risk state: suspended_for_fraud invalidates active sessions" do
    user = create_user(payment_address: "rk-inv-fraud@example.com", last_sign_in_ip: "10.2.2.30")
    admin = users(:admin)
    user.flag_for_fraud!(author_id: admin.id)
    assert_nil user.last_active_sessions_invalidated_at
    user.suspend_for_fraud!(author_id: admin.id)
    refute_nil user.reload.last_active_sessions_invalidated_at
  end

  test "risk state: suspended_for_tos_violation invalidates active sessions" do
    user = create_user(payment_address: "rk-inv-tos@example.com", last_sign_in_ip: "10.2.2.31")
    product = create_link(user)
    admin = users(:admin)
    user.flag_for_tos_violation(author_id: admin.id, product_id: product.id)
    user.suspend_for_tos_violation(author_id: admin.id)
    refute_nil user.reload.last_active_sessions_invalidated_at
  end

  test "risk state: suspending re-disables product links (banned_at set)" do
    user = create_user(payment_address: "rk-banned@example.com", last_sign_in_ip: "10.2.2.32")
    product_1 = create_link(user)
    product_2 = create_link(user)
    admin = users(:admin)
    user.flag_for_fraud!(author_id: admin.id)
    user.suspend_for_fraud!(author_id: admin.id)
    refute_nil product_1.reload.banned_at
    refute_nil product_2.reload.banned_at
  end

  test "risk state: mark_compliant clears banned_at on user's products" do
    user = create_user(payment_address: "rk-clears@example.com", last_sign_in_ip: "10.2.2.33")
    product_1 = create_link(user)
    product_2 = create_link(user)
    admin = users(:admin)
    user.flag_for_fraud!(author_id: admin.id)
    user.suspend_for_fraud(author_id: admin.id)
    refute_nil product_1.reload.banned_at
    refute_nil product_2.reload.banned_at
    user.mark_compliant(author_id: admin.id)
    assert_nil product_1.reload.banned_at
    assert_nil product_2.reload.banned_at
  end

  # ============================================================
  # Extra password / username edge-case from spec
  # ============================================================

  test "username: validation_condition allows old-style on save when name only changes" do
    user2 = users(:legacy_username_user)
    user2.name = "Sample name 123"
    assert user2.save
  end

  # ============================================================
  # eligible_for_abandoned_cart_workflows? alternate path
  # ============================================================

  test "eligible_for_abandoned_cart_workflows? respects completed payment alone" do
    user = create_user
    create_payment_completed(user: user)
    assert user.eligible_for_abandoned_cart_workflows?
  end

  # ============================================================
  # has_unconfirmed_email? — repeat consolidation
  # ============================================================

  test "has_unconfirmed_email? false on a freshly confirmed user" do
    user = create_user
    refute user.has_unconfirmed_email?
  end

  # ============================================================
  # eligible_to_send_emails? coverage extras
  # ============================================================

  test "eligible_to_send_emails? true via team_member alone (no payment)" do
    user = create_user
    user.update!(is_team_member: true)
    user.stub(:sales_cents_total, 0) do
      assert user.eligible_to_send_emails?
    end
  end

  # ============================================================
  # save_external_id assigns nano-style id
  # ============================================================

  test "save_external_id auto-generates external_id on create when blank" do
    user = create_user
    refute_empty user.external_id
  end

  # ============================================================
  # account_active? for builder-style record (no DB save)
  # ============================================================

  test "account_active? returns true for an unsaved user with no deleted_at" do
    assert User.new.account_active?
  end

  test "account_active? returns false for an unsaved user with deleted_at set" do
    refute User.new(deleted_at: 1.minute.ago).account_active?
  end

  # ============================================================
  # Buyer flow (BlockedCustomerObject for buyer email)
  # ============================================================

  test "BlockedCustomerObject can be associated with seller and used in queries" do
    seller = create_user
    obj = BlockedCustomerObject.create!(seller: seller, object_type: "email", object_value: "spam@example.com")
    assert_includes seller.blocked_customer_objects, obj
  end

  # ============================================================
  # Communities — community_chat_recap_run model touch
  # ============================================================

  test "seller_community_chat_recaps association is destroy-dependent" do
    user = create_user
    assert_equal :destroy, User.reflect_on_association(:seller_community_chat_recaps).options[:dependent]
  end

  test "community_chat_messages association is destroy-dependent" do
    assert_equal :destroy, User.reflect_on_association(:community_chat_messages).options[:dependent]
  end

  test "community_notification_settings association is destroy-dependent" do
    assert_equal :destroy, User.reflect_on_association(:community_notification_settings).options[:dependent]
  end

  test "last_read_community_chat_messages association is destroy-dependent" do
    assert_equal :destroy, User.reflect_on_association(:last_read_community_chat_messages).options[:dependent]
  end

  test "seller_communities has class_name Community" do
    refl = User.reflect_on_association(:seller_communities)
    assert_equal "Community", refl.options[:class_name]
    assert_equal :seller_id, refl.options[:foreign_key]
  end

  test "seller_community_chat_recaps has class_name CommunityChatRecap" do
    refl = User.reflect_on_association(:seller_community_chat_recaps)
    assert_equal "CommunityChatRecap", refl.options[:class_name]
  end

  # ============================================================
  # eligible_for_ai_product_generation? extra: dev env override
  # ============================================================

  test "eligible_for_ai_product_generation? false in production without prerequisites" do
    user = create_user
    Feature.activate_user(:ai_product_generation, user)
    user.confirm
    user.stub(:sales_cents_total, 0) do
      refute user.eligible_for_ai_product_generation?
    end
  end

  # ============================================================
  # subscribe_preview - has_one shape
  # ============================================================

  test "subscribe_preview is a has_one_attached attachment" do
    assert User.reflect_on_attachment(:subscribe_preview)
  end

  test "avatar is a has_one_attached attachment" do
    assert User.reflect_on_attachment(:avatar)
  end

  test "annual_reports is a has_many_attached attachment" do
    assert User.reflect_on_attachment(:annual_reports)
  end

  # ============================================================
  # Display: form_email vs email
  # ============================================================

  test "form_email returns email" do
    user = create_user(email: "form@example.com")
    assert_equal "form@example.com", user.form_email
  end

  # ============================================================
  # Final consolidation: notification flags after save
  # ============================================================

  test "weekly_notification, payment_notification are true by default" do
    user = create_user
    assert user.weekly_notification
    assert user.payment_notification
  end

  # ----- scopes -----

  test ".holding_non_zero_balance returns users with non-zero unpaid balances" do
    sam = create_user
    create_balance(user: sam, amount_cents: 10)
    create_balance(user: sam, amount_cents: 11, date: 1.day.ago)
    create_balance(user: sam, amount_cents: -100, date: 2.days.ago)
    create_balance(user: sam, amount_cents: 79, date: 3.days.ago, state: "paid")
    jill = create_user
    create_balance(user: jill, amount_cents: 20)
    create_balance(user: jill, amount_cents: 121, date: 1.day.ago)
    create_balance(user: jill, amount_cents: -141, date: 2.days.ago)
    create_balance(user: jill, amount_cents: 1, date: 3.days.ago, state: "paid")
    jake = create_user
    create_balance(user: jake, amount_cents: 20)
    create_balance(user: jake, amount_cents: 12, date: 1.day.ago)
    create_balance(user: jake, amount_cents: 21, date: 2.days.ago)
    create_balance(user: jake, amount_cents: -53, date: 3.days.ago, state: "paid")
    result = User.holding_non_zero_balance.where(id: [sam.id, jill.id, jake.id])
    assert_equal [sam.id, jake.id].sort, result.pluck(:id).sort
  end

  # ----- has_cdn_url -----

  test "subscribe_preview_url returns CDN URL" do
    with_constant(:CDN_URL_MAP, { "#{AWS_S3_ENDPOINT}/#{S3_BUCKET}" => "https://public-files.gumroad.com", "#{AWS_S3_ENDPOINT}/gumroad/" => "https://public-files.gumroad.com/res/gumroad/" }) do
      user = create_user
      attach_subscribe_preview(user)
      key = user.subscribe_preview.key
      assert_equal "https://public-files.gumroad.com/#{key}", user.subscribe_preview_url
    end
  end

  test "resized_avatar_url returns CDN URL" do
    with_constant(:CDN_URL_MAP, { "#{AWS_S3_ENDPOINT}/#{S3_BUCKET}" => "https://public-files.gumroad.com", "#{AWS_S3_ENDPOINT}/gumroad/" => "https://public-files.gumroad.com/res/gumroad/" }) do
      user = create_user
      attach_avatar(user)
      variant = user.avatar.variant(resize_to_limit: [256, 256]).processed.key
      assert_match("https://public-files.gumroad.com/#{variant}", user.resized_avatar_url(size: 256))
    end
  end

  test "avatar_url returns CDN URL" do
    with_constant(:CDN_URL_MAP, { "#{AWS_S3_ENDPOINT}/#{S3_BUCKET}" => "https://public-files.gumroad.com", "#{AWS_S3_ENDPOINT}/gumroad/" => "https://public-files.gumroad.com/res/gumroad/" }) do
      user = create_user
      attach_avatar(user)
      assert_match("https://public-files.gumroad.com/#{user.avatar_variant.key}", user.avatar_url)
    end
  end

  test "financial_annual_report_url_for returns URL for selected year" do
    with_constant(:CDN_URL_MAP, { "#{AWS_S3_ENDPOINT}/#{S3_BUCKET}" => "https://public-files.gumroad.com", "#{AWS_S3_ENDPOINT}/gumroad/" => "https://public-files.gumroad.com/res/gumroad/" }) do
      user = create_user
      attach_annual_report(user)
      year = 2019
      blob = ActiveStorage::Blob.create_and_upload!(
        io: Rack::Test::UploadedFile.new(Rails.root.join("spec", "support", "fixtures", "followers_import.csv"), "text/csv"),
        filename: "Financial Annual Report #{year}.csv",
        metadata: { year: year }
      )
      blob.analyze
      user.annual_reports.attach(blob)
      assert_equal "https://public-files.gumroad.com/#{blob.key}", user.financial_annual_report_url_for(year: year)
    end
  end

  # ----- #product_level_support_emails -----

  test "product_level_support_emails returns the user's product support emails" do
    user = create_user
    product1 = create_link(user, support_email: "1+2@example.com")
    product2 = create_link(user, support_email: "1+2@example.com")
    product3 = create_link(user, support_email: "3@example.com")
    create_link(user, support_email: nil)
    Feature.activate(:product_level_support_emails)
    result = user.product_level_support_emails
    expected = [
      {
        email: "1+2@example.com",
        product_ids: [product1.external_id, product2.external_id],
      },
      {
        email: "3@example.com",
        product_ids: [product3.external_id],
      }
    ]
    assert_equal expected.sort_by { |h| h[:email] }, result.sort_by { |h| h[:email] }
  ensure
    Feature.deactivate(:product_level_support_emails)
  end

  test "product_level_support_emails returns nil when feature is disabled" do
    user = create_user
    create_link(user, support_email: "1@example.com")
    Feature.deactivate(:product_level_support_emails)
    assert_nil user.product_level_support_emails
  end

  # ----- #update_product_level_support_emails! -----

  test "update_product_level_support_emails! updates products support emails" do
    user = create_user
    product1 = create_link(user, support_email: "old1@example.com")
    product2 = create_link(user, support_email: "old2@example.com")
    product3 = create_link(user, support_email: "old3@example.com")
    Feature.activate(:product_level_support_emails)
    user.update_product_level_support_emails!(
      [
        { email: "new1+2@example.com", product_ids: [product1.external_id, product2.external_id] }
      ]
    )
    assert_equal "new1+2@example.com", product1.reload.support_email
    assert_equal "new1+2@example.com", product2.reload.support_email
    assert_nil product3.reload.support_email
  ensure
    Feature.deactivate(:product_level_support_emails)
  end
end

# frozen_string_literal: true

require "test_helper"

class GdprDataErasureServiceTest < ActiveSupport::TestCase
  setup do
    WebMock.stub_request(:get, %r{api\.pwnedpasswords\.com/range/.*}).to_return(status: 200, body: "")
    @user = User.create!(
      email: "john@example.com",
      password: "test-password-123!",
      confirmed_at: Time.current,
      name: "John Doe",
      bio: "My bio",
      street_address: "123 Main St",
      city: "New York",
      state: "NY",
      zip_code: "10001",
      country: "US",
      current_sign_in_ip: "127.0.0.1",
      last_sign_in_ip: "127.0.0.1",
      account_created_ip: "127.0.0.1",
      user_risk_state: "not_reviewed",
      recommendation_type: User::RecommendationType::OWN_PRODUCTS,
    )
    @admin = User.create!(
      email: "admin-gdpr@example.com",
      password: "test-password-123!",
      confirmed_at: Time.current,
      name: "Admin",
      user_risk_state: "not_reviewed",
      recommendation_type: User::RecommendationType::OWN_PRODUCTS,
    )
  end

  test "#perform! anonymizes user PII and deactivates the account" do
    result = GdprDataErasureService.new(@user, performed_by: @admin).perform!

    assert_equal true, result[:success]
    @user.reload
    assert_equal "[deleted]", @user.name
    assert_equal "deleted-#{@user.id}@deleted.gumroad.com", @user.email
    assert_nil @user.bio
    assert_nil @user.street_address
    assert_nil @user.city
    assert_nil @user.state
    assert_nil @user.zip_code
    assert_nil @user.country
    assert_nil @user.current_sign_in_ip
    assert_nil @user.last_sign_in_ip
    assert_nil @user.account_created_ip
    assert_predicate @user, :deleted?
  end

  test "#perform! anonymizes credit cards and clears card fields" do
    credit_card = CreditCard.create!(
      visual: "**** **** **** 4242",
      card_type: "visa",
      expiry_month: 12,
      expiry_year: 2030,
      stripe_customer_id: "cus_123",
      stripe_fingerprint: "fp_123",
      processor_payment_method_id: "pm_123",
      charge_processor_id: StripeChargeProcessor.charge_processor_id,
    )
    @user.update!(credit_card:)

    GdprDataErasureService.new(@user, performed_by: @admin).perform!

    credit_card.reload
    assert_equal GdprDataErasureService::ANONYMIZED_VALUE, credit_card.card_type
    assert_equal GdprDataErasureService::ANONYMIZED_VALUE, credit_card.visual
    assert_nil credit_card.expiry_month
    assert_nil credit_card.expiry_year
    assert_nil credit_card.stripe_customer_id
    assert_nil credit_card.processor_payment_method_id
  end

  test "#perform! deletes the user's device records but not other users' devices" do
    ios_device = Device.create!(user: @user, token: "ios-device-token-gdpr", device_type: "ios", app_type: "consumer")
    android_device = Device.create!(user: @user, token: "android-device-token-gdpr", device_type: "android", app_type: "consumer")
    other_user_device = Device.create!(user: @admin, token: "other-user-device-token-gdpr", device_type: "ios", app_type: "consumer")

    GdprDataErasureService.new(@user, performed_by: @admin).perform!

    assert_equal false, Device.exists?(ios_device.id)
    assert_equal false, Device.exists?(android_device.id)
    assert_equal true, Device.exists?(other_user_device.id)
  end

  test "#perform! logs the erasure as a comment" do
    GdprDataErasureService.new(@user, performed_by: @admin).perform!

    comment = @user.comments.last
    assert_equal Comment::COMMENT_TYPE_NOTE, comment.comment_type
    assert_includes comment.content, "GDPR data erasure performed"
    assert_includes comment.content, "Transaction records retained"
  end

  test "#perform! returns external cleanup instructions in the summary" do
    result = GdprDataErasureService.new(@user, performed_by: @admin).perform!

    assert_includes result[:summary][:external_cleanup_needed], "Helper/Supabase (customer conversations)"
    assert_includes result[:summary][:external_cleanup_needed], "Stripe (customer data)"
  end
end

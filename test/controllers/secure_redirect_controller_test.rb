# frozen_string_literal: true

require "test_helper"

class SecureRedirectControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  setup do
    @destination_url = user_unsubscribe_url(id: "sample-id", email_type: "notify")
    @confirmation_text = "user@example.com"
    @secure_payload = {
      destination: @destination_url,
      confirmation_texts: [@confirmation_text],
      created_at: Time.current.to_i
    }
    @encrypted_payload = SecureEncryptService.encrypt(@secure_payload.to_json)
    @message = "Please confirm your email address"
    @field_name = "Email address"
    @error_message = "Email address does not match"
    @request.headers["X-Inertia"] = "true"
  end

  def inertia_props
    JSON.parse(@response.body)["props"]
  end

  def inertia_component
    JSON.parse(@response.body)["component"]
  end

  def valid_params
    {
      encrypted_payload: @encrypted_payload,
      confirmation_text: @confirmation_text,
      message: @message,
      field_name: @field_name,
      error_message: @error_message
    }
  end

  # GET #new
  test "GET new renders the Inertia page with valid params" do
    get :new, params: { encrypted_payload: @encrypted_payload, message: @message,
                        field_name: @field_name, error_message: @error_message }
    assert_response :success
    assert_equal "SecureRedirect/New", inertia_component
  end

  test "GET new sets inertia props" do
    get :new, params: { encrypted_payload: @encrypted_payload, message: @message,
                        field_name: @field_name, error_message: @error_message }
    props = inertia_props
    assert_equal @message, props["message"]
    assert_equal @field_name, props["field_name"]
    assert_equal @error_message, props["error_message"]
    assert_equal @encrypted_payload, props["encrypted_payload"]
  end

  test "GET new uses default values when optional params are missing" do
    get :new, params: { encrypted_payload: @encrypted_payload }
    props = inertia_props
    assert_equal "Please enter the confirmation text to continue to your destination.", props["message"]
    assert_equal "Confirmation text", props["field_name"]
    assert_equal "Confirmation text does not match", props["error_message"]
  end

  test "GET new includes flash alert in props when present" do
    get :new, params: { encrypted_payload: @encrypted_payload }, flash: { alert: "Test alert message" }
    assert_equal({ "message" => "Test alert message", "status" => "danger" }, inertia_props["flash"])
  end

  test "GET new does not include flash in props when not present" do
    get :new, params: { encrypted_payload: @encrypted_payload }
    assert_nil inertia_props["flash"]
  end

  test "GET new redirects to root when encrypted_payload is missing" do
    get :new
    assert_redirected_to root_path
  end

  # POST #create
  test "POST create redirects to the decrypted destination" do
    post :create, params: valid_params
    assert_redirected_to @destination_url
  end

  test "POST create appends confirmation_text when send_confirmation_text is true" do
    payload = @secure_payload.merge(send_confirmation_text: true)
    encrypted = SecureEncryptService.encrypt(payload.to_json)
    post :create, params: valid_params.merge(encrypted_payload: encrypted)
    expected = "#{@destination_url.split('?').first}?confirmation_text=#{CGI.escape(@confirmation_text)}&#{@destination_url.split('?').last}"
    assert_redirected_to expected
  end

  test "POST create does not append confirmation_text when send_confirmation_text is false" do
    post :create, params: valid_params
    assert_redirected_to @destination_url
  end

  test "POST create handles URLs that already have query parameters" do
    destination_with_params = "#{@destination_url}&existing=param"
    payload = {
      destination: destination_with_params,
      confirmation_texts: [@confirmation_text],
      created_at: Time.current.to_i,
      send_confirmation_text: true
    }
    encrypted = SecureEncryptService.encrypt(payload.to_json)
    post :create, params: valid_params.merge(encrypted_payload: encrypted)
    assert_response :redirect
    redirect_url = response.location
    assert_includes redirect_url, "?confirmation_text=#{CGI.escape(@confirmation_text)}"
    assert_includes redirect_url, "&existing=param"
    assert_includes redirect_url, "&email_type=notify"
  end

  test "POST create accepts confirmation text matching any allowed text" do
    payload = {
      destination: @destination_url,
      confirmation_texts: ["user1@example.com", "user2@example.com", "user3@example.com"],
      created_at: Time.current.to_i
    }
    encrypted = SecureEncryptService.encrypt(payload.to_json)
    post :create, params: valid_params.merge(encrypted_payload: encrypted, confirmation_text: "user3@example.com")
    assert_redirected_to @destination_url
  end

  test "POST create rejects confirmation text not matching any allowed text" do
    payload = {
      destination: @destination_url,
      confirmation_texts: ["user1@example.com", "user2@example.com"],
      created_at: Time.current.to_i
    }
    encrypted = SecureEncryptService.encrypt(payload.to_json)
    post :create, params: valid_params.merge(encrypted_payload: encrypted, confirmation_text: "nomatch@example.com")
    assert_redirected_to secure_url_redirect_path(encrypted_payload: encrypted, message: @message,
                                                  field_name: @field_name, error_message: @error_message)
    assert_equal @error_message, flash[:alert]
  end

  test "POST create works with single confirmation text" do
    post :create, params: valid_params
    assert_redirected_to @destination_url
  end

  test "POST create appends confirmation_text with multiple texts when send_confirmation_text" do
    payload = {
      destination: @destination_url,
      confirmation_texts: ["user1@example.com", "user2@example.com", "user3@example.com"],
      created_at: Time.current.to_i,
      send_confirmation_text: true
    }
    encrypted = SecureEncryptService.encrypt(payload.to_json)
    post :create, params: valid_params.merge(encrypted_payload: encrypted, confirmation_text: "user2@example.com")
    expected = "#{@destination_url.split('?').first}?confirmation_text=#{CGI.escape('user2@example.com')}&#{@destination_url.split('?').last}"
    assert_redirected_to expected
  end

  test "POST create redirects back with errors when confirmation text is blank" do
    post :create, params: valid_params.merge(confirmation_text: "")
    assert_redirected_to secure_url_redirect_path(encrypted_payload: @encrypted_payload, message: @message,
                                                  field_name: @field_name, error_message: @error_message)
    assert_equal "Please enter the confirmation text", flash[:alert]
  end

  test "POST create redirects back when confirmation text is nil" do
    post :create, params: valid_params.except(:confirmation_text)
    assert_redirected_to secure_url_redirect_path(encrypted_payload: @encrypted_payload, message: @message,
                                                  field_name: @field_name, error_message: @error_message)
    assert_equal "Please enter the confirmation text", flash[:alert]
  end

  test "POST create redirects back when confirmation text is whitespace only" do
    post :create, params: valid_params.merge(confirmation_text: "   ")
    assert_redirected_to secure_url_redirect_path(encrypted_payload: @encrypted_payload, message: @message,
                                                  field_name: @field_name, error_message: @error_message)
    assert_equal "Please enter the confirmation text", flash[:alert]
  end

  test "POST create redirects back with custom error message when wrong" do
    post :create, params: valid_params.merge(confirmation_text: "wrong@example.com")
    assert_redirected_to secure_url_redirect_path(encrypted_payload: @encrypted_payload, message: @message,
                                                  field_name: @field_name, error_message: @error_message)
    assert_equal @error_message, flash[:alert]
  end

  test "POST create uses default error message when not provided" do
    params_without_error = valid_params.except(:error_message).merge(confirmation_text: "wrong@example.com")
    post :create, params: params_without_error
    assert_redirected_to secure_url_redirect_path(encrypted_payload: @encrypted_payload, message: @message,
                                                  field_name: @field_name,
                                                  error_message: "Confirmation text does not match")
    assert_equal "Confirmation text does not match", flash[:alert]
  end

  test "POST create redirects back when encrypted_payload is tampered" do
    tampered = @encrypted_payload + "tamper"
    post :create, params: valid_params.merge(encrypted_payload: tampered)
    assert_redirected_to secure_url_redirect_path(encrypted_payload: tampered, message: @message,
                                                  field_name: @field_name, error_message: @error_message)
    assert_equal "Invalid request", flash[:alert]
  end

  test "POST create redirects back when encrypted_payload is invalid JSON" do
    invalid_payload = SecureEncryptService.encrypt("invalid json")
    post :create, params: valid_params.merge(encrypted_payload: invalid_payload)
    assert_redirected_to secure_url_redirect_path(encrypted_payload: invalid_payload, message: @message,
                                                  field_name: @field_name, error_message: @error_message)
    assert_equal "Invalid request", flash[:alert]
  end

  test "POST create redirects back when payload is expired" do
    expired_payload = {
      destination: @destination_url,
      confirmation_texts: [@confirmation_text],
      created_at: (Time.current - 25.hours).to_i
    }
    expired_encrypted = SecureEncryptService.encrypt(expired_payload.to_json)
    post :create, params: valid_params.merge(encrypted_payload: expired_encrypted)
    assert_redirected_to secure_url_redirect_path(encrypted_payload: expired_encrypted, message: @message,
                                                  field_name: @field_name, error_message: @error_message)
    assert_equal "This link has expired", flash[:alert]
  end

  test "POST create redirects to root when encrypted_payload is missing" do
    post :create, params: valid_params.except(:encrypted_payload)
    assert_redirected_to root_path
  end

  test "POST create redirects back with invalid destination error when destination empty" do
    empty_payload = {
      destination: "",
      confirmation_texts: [@confirmation_text],
      created_at: Time.current.to_i
    }
    empty_encrypted = SecureEncryptService.encrypt(empty_payload.to_json)
    post :create, params: valid_params.merge(encrypted_payload: empty_encrypted)
    assert_redirected_to secure_url_redirect_path(encrypted_payload: empty_encrypted, message: @message,
                                                  field_name: @field_name, error_message: @error_message)
    assert_equal "Invalid destination", flash[:alert]
  end
end

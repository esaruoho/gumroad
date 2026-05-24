# frozen_string_literal: true

require "test_helper"

class GoogleCalendarApiTest < ActiveSupport::TestCase
  test "POST oauth_token makes an oauth authorization request with the given code and redirect uri" do
    WebMock.stub_request(:post, "#{GoogleCalendarApi::GOOGLE_CALENDAR_OAUTH_URL}/token")
      .with(
        body: {
          grant_type: "authorization_code",
          code: "test_code",
          redirect_uri: "test_uri",
          client_id: GlobalConfig.get("GOOGLE_CLIENT_ID"),
          client_secret: GlobalConfig.get("GOOGLE_CLIENT_SECRET"),
        }
      )

    response = GoogleCalendarApi.new.oauth_token("test_code", "test_uri")
    assert_equal true, response.success?
  end

  test "GET user_info requests user info with the given token" do
    WebMock.stub_request(:get, "#{GoogleCalendarApi.base_uri}/oauth2/v2/userinfo").with(query: { access_token: "test_access_token" })
    response = GoogleCalendarApi.new.user_info("test_access_token")
    assert_equal true, response.success?
  end

  test "GET calendar_list requests calendar_list with the given token" do
    WebMock.stub_request(:get, "#{GoogleCalendarApi.base_uri}/calendar/v3/users/me/calendarList").with(headers: { "Authorization" => "Bearer test_access_token" })
    response = GoogleCalendarApi.new.calendar_list("test_access_token")
    assert_equal true, response.success?
  end

  test "POST disconnect requests disconnect with the given token" do
    WebMock.stub_request(:post, "#{GoogleCalendarApi::GOOGLE_CALENDAR_OAUTH_URL}/revoke").with(query: { token: "test_access_token" })
    response = GoogleCalendarApi.new.disconnect("test_access_token")
    assert_equal true, response.success?
  end

  test "POST refresh_token requests refresh_token with the given token" do
    WebMock.stub_request(:post, "#{GoogleCalendarApi::GOOGLE_CALENDAR_OAUTH_URL}/token")
      .with(
        body: {
          grant_type: "refresh_token",
          refresh_token: "test_refresh_token",
          client_id: GlobalConfig.get("GOOGLE_CLIENT_ID"),
          client_secret: GlobalConfig.get("GOOGLE_CLIENT_SECRET"),
        }
      )
    response = GoogleCalendarApi.new.refresh_token("test_refresh_token")
    assert_equal true, response.success?
  end

  test "POST insert_event inserts an event with the given parameters" do
    calendar_id = "primary"
    event = {
      summary: "Test Event",
      start: { dateTime: "2023-05-01T09:00:00-07:00" },
      end: { dateTime: "2023-05-01T10:00:00-07:00" }
    }
    access_token = "test_access_token"

    WebMock.stub_request(:post, "#{GoogleCalendarApi.base_uri}/calendar/v3/calendars/#{calendar_id}/events")
      .with(
        headers: { "Authorization" => "Bearer #{access_token}" },
        body: event.to_json
      )
      .to_return(status: 200, body: "", headers: {})

    response = GoogleCalendarApi.new.insert_event(calendar_id, event, access_token: access_token)
    assert_equal true, response.success?
  end
end

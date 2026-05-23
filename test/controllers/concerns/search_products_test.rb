# frozen_string_literal: true

require "test_helper"

# Test controller that includes the SearchProducts concern.
class SearchProductsTestController < ApplicationController
  include SearchProducts

  def index
    format_search_params!
    render json: params
  end
end

class SearchProductsTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  tests SearchProductsTestController

  setup do
    @routes = ActionDispatch::Routing::RouteSet.new
    @routes.draw { get "index" => "search_products_test#index" }
  end

  # --- with offer_code, feature active ---
  test "preserves allowed offer code when feature flag active" do
    Feature.activate(:offer_codes_search)
    begin
      get :index, params: { offer_code: "BLACKFRIDAY2025" }
      assert_equal "BLACKFRIDAY2025", JSON.parse(@response.body)["offer_code"]
    ensure
      Feature.deactivate(:offer_codes_search)
    end
  end

  test "returns __no_match__ when offer code is not allowed and feature flag active" do
    Feature.activate(:offer_codes_search)
    begin
      get :index, params: { offer_code: "SUMMER2025" }
      assert_equal "__no_match__", JSON.parse(@response.body)["offer_code"]
    ensure
      Feature.deactivate(:offer_codes_search)
    end
  end

  # --- with offer_code, feature inactive ---
  test "blocks offer_code when feature is disabled and no secret key" do
    Feature.deactivate(:offer_codes_search)
    get :index, params: { offer_code: "BLACKFRIDAY2025" }
    assert_equal "__no_match__", JSON.parse(@response.body)["offer_code"]
  end

  test "allows offer_code when valid secret key is provided" do
    Feature.deactivate(:offer_codes_search)
    ENV["SECRET_FEATURE_KEY"] = "test_secret_key_123"
    begin
      get :index, params: { offer_code: "BLACKFRIDAY2025", feature_key: "test_secret_key_123" }
      assert_equal "BLACKFRIDAY2025", JSON.parse(@response.body)["offer_code"]
    ensure
      ENV.delete("SECRET_FEATURE_KEY")
    end
  end

  test "blocks offer_code when invalid secret key is provided" do
    Feature.deactivate(:offer_codes_search)
    ENV["SECRET_FEATURE_KEY"] = "test_secret_key_123"
    begin
      get :index, params: { offer_code: "BLACKFRIDAY2025", feature_key: "wrong_key" }
      assert_equal "__no_match__", JSON.parse(@response.body)["offer_code"]
    ensure
      ENV.delete("SECRET_FEATURE_KEY")
    end
  end

  test "blocks offer_code when secret key is empty" do
    Feature.deactivate(:offer_codes_search)
    ENV["SECRET_FEATURE_KEY"] = "test_secret_key_123"
    begin
      get :index, params: { offer_code: "BLACKFRIDAY2025", feature_key: "" }
      assert_equal "__no_match__", JSON.parse(@response.body)["offer_code"]
    ensure
      ENV.delete("SECRET_FEATURE_KEY")
    end
  end

  test "blocks non-allowed offer_code even with valid secret key" do
    Feature.deactivate(:offer_codes_search)
    ENV["SECRET_FEATURE_KEY"] = "test_secret_key_123"
    begin
      get :index, params: { offer_code: "SUMMER2025", feature_key: "test_secret_key_123" }
      assert_equal "__no_match__", JSON.parse(@response.body)["offer_code"]
    ensure
      ENV.delete("SECRET_FEATURE_KEY")
    end
  end

  test "does not modify params when offer_code is not present" do
    get :index, params: { tags: "design" }
    assert_nil JSON.parse(@response.body)["offer_code"]
  end

  test "parses tags from string" do
    get :index, params: { tags: "design,art" }
    assert_equal ["design", "art"], JSON.parse(@response.body)["tags"]
  end

  test "parses filetypes from string" do
    get :index, params: { filetypes: "pdf,video" }
    assert_equal ["pdf", "video"], JSON.parse(@response.body)["filetypes"]
  end

  test "parses ids from string" do
    get :index, params: { ids: "abc,def, ghi" }
    assert_equal ["abc", "def", "ghi"], JSON.parse(@response.body)["ids"]
  end

  test "converts size to integer" do
    get :index, params: { size: "20" }
    assert_equal 20, JSON.parse(@response.body)["size"]
  end

  test "converts size from array to integer" do
    get :index, params: { size: ["20", "30"] }
    assert_equal 20, JSON.parse(@response.body)["size"]
  end

  test "converts from to integer when present" do
    get :index, params: { from: "5" }
    assert_equal 5, JSON.parse(@response.body)["from"]
  end

  test "converts from from array to integer" do
    get :index, params: { from: ["10", "20"] }
    assert_equal 10, JSON.parse(@response.body)["from"]
  end
end

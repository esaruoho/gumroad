# frozen_string_literal: true

require "test_helper"

class EmbeddedJavascriptsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  test "overlay returns the correct js" do
    get :overlay, format: :js

    manifest = ViteRuby.instance.manifest
    overlay_stylesheet_path = manifest.resolve_entries("overlay", type: :typescript).fetch(:stylesheets).first
    design_stylesheet_path = manifest.resolve_entries("design", type: :typescript).fetch(:stylesheets).first

    assert_includes @response.body, "/js/gumroad.js"
    assert_includes @response.body, "document.head.insertAdjacentHTML"
    assert_includes @response.body, overlay_stylesheet_path if overlay_stylesheet_path
    assert_includes @response.body, design_stylesheet_path if design_stylesheet_path
  end

  test "embed returns the correct js" do
    get :embed, format: :js
    assert_includes @response.body, "/js/gumroad-embed-bundle.js"
  end
end

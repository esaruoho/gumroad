require "test_helper"

class SellerProfileTest < ActiveSupport::TestCase
  def custom_styles_profile
    @custom_styles_profile ||= SellerProfile.create!(
      seller: users(:named_seller),
      highlight_color: "#009a49",
      font: "Roboto Mono",
      background_color: "#000000",
    )
  end

  test "#custom_styles has CSS for background color, accent color, and font" do
    styles = custom_styles_profile.custom_styles
    assert_includes styles, "--accent: 0 154 73;--contrast-accent: 255 255 255"
    assert_includes styles, "--filled: 0 0 0"
    assert_includes styles, "--body-bg: #000000"
    assert_includes styles, "--color: 255 255 255"
    assert_includes styles, %(--font-family: "Roboto Mono", "ABC Favorit", monospace)
  end

  test "#custom_styles rebuilds CSS when custom style attribute is saved" do
    profile = custom_styles_profile
    profile.update_attribute(:highlight_color, "#ff90e8")
    assert_equal false, Rails.cache.exist?(profile.custom_style_cache_name)
    assert_includes profile.custom_styles, "--accent: 255 144 232;--contrast-accent: 0 0 0"

    profile.update_attribute(:background_color, "#fff")
    assert_equal false, Rails.cache.exist?(profile.custom_style_cache_name)
    assert_includes profile.custom_styles, "--filled: 255 255 255"
    assert_includes profile.custom_styles, "--color: 0 0 0"

    profile.update_attribute(:font, "ABC Favorit")
    assert_equal false, Rails.cache.exist?(profile.custom_style_cache_name)
    assert_includes profile.custom_styles, %(--font-family: "ABC Favorit", "ABC Favorit", sans-serif)
    assert_equal true, Rails.cache.exist?(profile.custom_style_cache_name)
  end

  def default_profile
    @default_profile ||= SellerProfile.create!(seller: users(:named_seller))
  end

  test "#font_family returns the active font, then ABC Favorit and a generic fallback" do
    assert_equal %("ABC Favorit", "ABC Favorit", sans-serif), default_profile.font_family
  end

  test "#font_family returns a serif fallback for a serif font" do
    default_profile.update!(font: "Domine")
    assert_equal %("Domine", "ABC Favorit", serif), default_profile.font_family
  end

  test "#font_family returns a monospace fallback for a monospace font" do
    default_profile.update!(font: "Roboto Mono")
    assert_equal %("Roboto Mono", "ABC Favorit", monospace), default_profile.font_family
  end
end

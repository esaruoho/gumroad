# frozen_string_literal: true

require "test_helper"

class UserPresenterTest < ActiveSupport::TestCase
  setup do
    @seller = users(:named_seller)
    @seller.create_seller_profile! unless @seller.seller_profile
    @presenter = UserPresenter.new(user: @seller)
  end

  test "#as_current_seller returns the seller props" do
    time_zone = ActiveSupport::TimeZone[@seller.timezone]
    assert_equal(
      {
        id: @seller.external_id,
        email: @seller.email,
        name: @seller.display_name(prefer_email_over_default_username: true),
        subdomain: @seller.subdomain,
        avatar_url: @seller.avatar_url,
        is_buyer: @seller.is_buyer?,
        time_zone: { name: time_zone.tzinfo.name, offset: time_zone.tzinfo.utc_offset },
        has_published_products: @seller.products.alive.exists?,
        is_name_invalid_for_email_delivery: @seller.is_name_invalid_for_email_delivery?,
        profile_background_color: @seller.seller_profile.background_color,
        profile_highlight_color: @seller.seller_profile.highlight_color,
        profile_font: @seller.seller_profile.font,
      },
      @presenter.as_current_seller
    )
  end

  test "#author_byline_props returns the basic props" do
    assert_equal(
      {
        id: @seller.external_id,
        name: @seller.name,
        avatar_url: @seller.avatar_url,
        profile_url: @seller.profile_url(recommended_by: nil),
        is_verified: false,
      },
      @presenter.author_byline_props
    )
  end

  test "#author_byline_props sets is_verified=true when seller is verified" do
    @seller.update!(verified: true)
    assert_equal true, @presenter.author_byline_props[:is_verified]
  end

  test "#author_byline_props uses the custom domain for the profile url" do
    assert_equal "https://example.com",
                 @presenter.author_byline_props(custom_domain_url: "https://example.com")[:profile_url]
  end

  test "#author_byline_props returns the username when seller has no name" do
    @seller.update!(name: nil)
    assert_equal @seller.username,
                 @presenter.author_byline_props(custom_domain_url: "https://example.com")[:name]
  end

  test "#author_byline_props adds the recommended_by parameter to profile_url" do
    assert_equal @seller.profile_url(recommended_by: "discover"),
                 @presenter.author_byline_props(recommended_by: "discover")[:profile_url]
  end

  test "#audience_count returns audience_members count" do
    assert_equal @seller.audience_members.count, @presenter.audience_count
  end

  test "#audience_types returns empty array when no audience members" do
    @seller.audience_members.delete_all
    assert_empty @presenter.audience_types
  end
end

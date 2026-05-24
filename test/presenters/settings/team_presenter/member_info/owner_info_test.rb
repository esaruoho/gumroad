# frozen_string_literal: true

require "test_helper"

class Settings::TeamPresenter::MemberInfo::OwnerInfoTest < ActiveSupport::TestCase
  test "build_owner_info returns the expected hash" do
    seller = users(:named_seller)
    info = Settings::TeamPresenter::MemberInfo.build_owner_info(seller)

    assert_equal(
      {
        type: "owner",
        id: seller.external_id,
        role: "owner",
        name: seller.display_name,
        email: seller.form_email,
        avatar_url: seller.avatar_url,
        is_expired: false,
        options: [{ id: "owner", label: "Owner" }],
        leave_team_option: nil
      },
      info.to_hash
    )
  end
end

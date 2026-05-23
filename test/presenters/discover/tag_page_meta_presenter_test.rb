# frozen_string_literal: true

require "test_helper"

class Discover::TagPageMetaPresenterTest < ActiveSupport::TestCase
  test "#title returns the specific title when one tag with specific title available is provided" do
    assert_equal "Professional 3D Modeling Assets", Discover::TagPageMetaPresenter.new(["3d-models"], 1000).title
  end

  test "#title returns the default title when one tag without specific title is provided" do
    assert_equal "tutorial", Discover::TagPageMetaPresenter.new(["tutorial"], 1000).title
  end

  test "#title returns the default title when multiple tags are provided" do
    assert_equal "tag 1, tag 2", Discover::TagPageMetaPresenter.new(["tag 1", "tag 2"], 1000).title
  end

  test "#title does not raise and returns the default title when a single empty tag is provided" do
    assert_equal "", Discover::TagPageMetaPresenter.new([""], 1000).title
  end

  test "#title does not raise and returns the default title when a single whitespace-only tag is provided" do
    assert_equal " ", Discover::TagPageMetaPresenter.new([" "], 1000).title
  end

  test "#meta_description returns the specific meta description when one tag with specific meta description is provided" do
    expected = "Browse over 1,000 3D assets including 3D models, CG textures, HDRI environments & more for VFX, game development, AR/VR, architecture, and animation."
    assert_equal expected, Discover::TagPageMetaPresenter.new(["3d models"], 1000).meta_description
  end

  test "#meta_description returns the default meta description when one tag without specific meta description is provided" do
    expected = "Browse over 1,000 unique tutorial products published by independent creators on Gumroad. Discover the best things to read, watch, create & more!"
    assert_equal expected, Discover::TagPageMetaPresenter.new(["tutorial"], 1000).meta_description
  end

  test "#meta_description returns the default meta description when multiple tags are provided" do
    expected = "Browse over 1,000 unique tag 1 and tag 2 products published by independent creators on Gumroad. Discover the best things to read, watch, create & more!"
    assert_equal expected, Discover::TagPageMetaPresenter.new(["tag 1", "tag 2"], 1000).meta_description
  end

  test "#meta_description does not raise when a single empty tag is provided" do
    assert_nothing_raised { Discover::TagPageMetaPresenter.new([""], 1000).meta_description }
  end

  test "#meta_description does not raise when a single whitespace-only tag is provided" do
    assert_nothing_raised { Discover::TagPageMetaPresenter.new([" "], 1000).meta_description }
  end
end

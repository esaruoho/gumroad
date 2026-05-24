# frozen_string_literal: true

require "test_helper"

# Migrated from spec/presenters/collaborators_presenter_spec.rb (deleted in c9c93ee5).
# Exercises the small CollaboratorsPresenter#index_props seam using existing
# affiliates.yml + affiliates_links.yml fixtures (no new fixture tables).
class CollaboratorsPresenterTest < ActiveSupport::TestCase
  setup do
    @seller = users(:named_seller)
    @confirmed_collaborator = affiliates(:collaborator_for_named_seller_product)
    @collaborating_user = users(:collaborating_user)
  end

  test "index_props returns alive collaborators wrapped via CollaboratorPresenter" do
    props = CollaboratorsPresenter.new(seller: @seller).index_props

    expected_collaborators = [@confirmed_collaborator].map do |c|
      CollaboratorPresenter.new(seller: @seller, collaborator: c).collaborator_props
    end
    assert_equal expected_collaborators, props[:collaborators]
    # named_seller is also the affiliate_user on collaborator_adding_named_seller
    assert_equal true, props[:has_incoming_collaborators]
  end

  test "has_incoming_collaborators is false for a user with no incoming collaborations" do
    other = users(:purchaser)
    refute Collaborator.where(affiliate_user_id: other.id).exists?
    props = CollaboratorsPresenter.new(seller: other).index_props
    assert_equal false, props[:has_incoming_collaborators]
  end

  test "index_props excludes soft-deleted collaborators" do
    @confirmed_collaborator.mark_deleted!
    props = CollaboratorsPresenter.new(seller: @seller).index_props
    assert_equal [], props[:collaborators]
  end

  test "has_incoming_collaborators is true for a user who is an affiliate on someone else's product" do
    props = CollaboratorsPresenter.new(seller: @collaborating_user).index_props
    assert_equal true, props[:has_incoming_collaborators]
  end

  test "has_incoming_collaborators becomes false when incoming collaborations are deleted" do
    @confirmed_collaborator.mark_deleted!
    props = CollaboratorsPresenter.new(seller: @collaborating_user).index_props
    assert_equal false, props[:has_incoming_collaborators]
  end
end

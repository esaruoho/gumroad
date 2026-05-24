# frozen_string_literal: true

require "test_helper"

class ReindexUserElasticsearchDataWorkerTest < ActiveSupport::TestCase
  test "reindexes ES data for user" do
    user = users(:named_seller)
    admin = users(:admin_user)

    called_with = nil
    DevTools.stub(:reindex_all_for_user, ->(id) { called_with = id; nil }) do
      ReindexUserElasticsearchDataWorker.new.perform(user.id, admin.id)
    end

    assert_equal user.id, called_with
    admin_comment = user.comments.last
    assert_equal "Refreshed ES Data", admin_comment.content
    assert_equal admin.id, admin_comment.author_id
  end
end

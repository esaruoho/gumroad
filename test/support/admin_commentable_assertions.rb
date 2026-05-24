# frozen_string_literal: true

# Shared assertions for Admin::Commentable controllers
# (Admin::Products::CommentsController, Admin::Purchases::CommentsController,
# Admin::Users::CommentsController).
#
# Including test class must define:
#   - `commentable_object` returning the model instance under comment
#   - `route_params` returning the params hash used for routing
#
# And in setup:
#   - sign_in users(:admin_user)
module AdminCommentableAssertions
  def admin_commentable_admin_user
    users(:admin_user)
  end

  def assert_admin_commentable_index_returns_comments_in_descending_order
    admin = admin_commentable_admin_user
    comment1 = Comment.create!(
      commentable: commentable_object,
      author: admin,
      author_name: admin.username,
      content: "First comment",
      comment_type: "note",
      created_at: 2.days.ago
    )
    comment2 = Comment.create!(
      commentable: commentable_object,
      author: admin,
      author_name: admin.username,
      content: "Second comment",
      comment_type: "note",
      created_at: 1.day.ago
    )
    # unrelated noise — use a different existing fixture user
    Comment.create!(
      commentable: users(:basic_user),
      author: admin,
      content: "Unrelated comment",
      comment_type: "note",
      created_at: 3.days.ago
    )

    get :index, params: route_params, format: :json
    assert_response :success
    json = response.parsed_body
    assert_kind_of Array, json["comments"]
    assert_equal 2, json["comments"].length
    assert_predicate json["pagination"], :present?
    assert_equal(
      [
        {
          "id" => comment2.id,
          "content" => "Second comment",
          "author" => {
            "external_id" => admin.external_id,
            "name" => admin.name,
            "email" => admin.email,
          },
          "author_name" => admin.username,
          "comment_type" => "note",
          "updated_at" => comment2.updated_at.iso8601,
        },
        {
          "id" => comment1.id,
          "content" => "First comment",
          "author" => {
            "external_id" => admin.external_id,
            "name" => admin.name,
            "email" => admin.email,
          },
          "author_name" => admin.username,
          "comment_type" => "note",
          "updated_at" => comment1.updated_at.iso8601,
        },
      ],
      json["comments"]
    )
  end

  def assert_admin_commentable_index_paginates
    admin = admin_commentable_admin_user
    comment1 = Comment.create!(commentable: commentable_object, author: admin, content: "First comment", comment_type: "note", created_at: 2.days.ago)
    comment2 = Comment.create!(commentable: commentable_object, author: admin, content: "Second comment", comment_type: "note", created_at: 1.day.ago)

    get :index, params: route_params.merge(page: 1, per_page: 1), format: :json
    assert_response :success
    json = response.parsed_body
    assert_equal 1, json["comments"].length
    assert_equal comment2.id, json["comments"].first["id"]
    assert_equal "Second comment", json["comments"].first["content"]
    assert_equal 1, json["pagination"]["page"]
    assert_equal 2, json["pagination"]["count"]

    get :index, params: route_params.merge(page: 2, per_page: 1), format: :json
    assert_response :success
    json = response.parsed_body
    assert_equal 1, json["comments"].length
    assert_equal comment1.id, json["comments"].first["id"]
    assert_equal "First comment", json["comments"].first["content"]
    assert_equal 2, json["pagination"]["page"]
    assert_equal 2, json["pagination"]["count"]
  end

  def assert_admin_commentable_index_returns_empty_when_no_comments
    get :index, params: route_params, format: :json
    assert_response :success
    assert_equal [], response.parsed_body["comments"]
  end

  def assert_admin_commentable_create_creates_a_comment
    admin = admin_commentable_admin_user
    assert_difference -> { commentable_object.comments.count }, 1 do
      post :create, params: route_params.merge(comment: { content: "This is a test comment", comment_type: Comment::COMMENT_TYPE_FLAGGED }), format: :json
    end
    assert_response :success
    comment = commentable_object.comments.last
    assert_equal true, response.parsed_body["success"]
    assert_equal(
      {
        "id" => comment.id,
        "content" => "This is a test comment",
        "author" => {
          "external_id" => admin.external_id,
          "name" => admin.name,
          "email" => admin.email,
        },
        "author_name" => admin.name,
        "comment_type" => "flagged",
        "updated_at" => comment.updated_at.iso8601,
      },
      response.parsed_body["comment"]
    )
  end

  def assert_admin_commentable_create_associates_with_admin
    post :create, params: route_params.merge(comment: { content: "This is a test comment", comment_type: Comment::COMMENT_TYPE_FLAGGED }), format: :json
    assert_equal admin_commentable_admin_user, commentable_object.comments.last.author
  end

  def assert_admin_commentable_create_error_when_blank
    assert_no_difference -> { commentable_object.comments.count } do
      post :create, params: route_params.merge(comment: { content: "", comment_type: Comment::COMMENT_TYPE_FLAGGED }), format: :json
    end
    assert_response :unprocessable_entity
    assert_equal false, response.parsed_body["success"]
    assert_includes response.parsed_body["error"], "can't be blank"
  end

  def assert_admin_commentable_create_defaults_to_note
    assert_difference -> { commentable_object.comments.count }, 1 do
      post :create, params: route_params.merge(comment: { content: "This is a test comment" }), format: :json
    end
    assert_response :success
    assert_equal true, response.parsed_body["success"]
    assert_equal Comment::COMMENT_TYPE_NOTE, commentable_object.comments.last.comment_type
  end

  def assert_admin_commentable_create_error_when_too_long
    assert_no_difference -> { commentable_object.comments.count } do
      post :create, params: route_params.merge(comment: { content: "a" * 10_001, comment_type: Comment::COMMENT_TYPE_FLAGGED }), format: :json
    end
    assert_response :unprocessable_entity
    assert_equal false, response.parsed_body["success"]
    assert_includes response.parsed_body["error"], "too long"
  end
end

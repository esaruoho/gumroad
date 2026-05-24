# frozen_string_literal: true

require "test_helper"

class SentPostEmailTest < ActiveSupport::TestCase
  setup do
    @post = installments(:pcp_post)
    @other_post = installments(:published_post)
  end

  test "creation downcases email" do
    record = SentPostEmail.create!(post: @post, email: "FOO")
    assert_equal "foo", record.reload.email
  end

  test "ensures emails are unique for each post" do
    SentPostEmail.create!(post: @post, email: "foo")
    SentPostEmail.create!(post: @other_post, email: "foo") # different post — still unique
    assert_raises(ActiveRecord::RecordNotUnique) do
      SentPostEmail.create!(post: @post, email: "FOO")
    end
  end

  test ".missing_emails returns array of emails currently not stored" do
    SentPostEmail.create!(post: @post, email: "foo")
    SentPostEmail.create!(post: @post, email: "bar")
    SentPostEmail.create!(post: @other_post, email: "missing1")
    result = SentPostEmail.missing_emails(post: @post, emails: ["foo", "missing1", "bar", "missing2"])
    assert_equal ["missing1", "missing2"], result.sort
  end

  test ".ensure_uniqueness runs block once per unique post+email" do
    SentPostEmail.create!(post: @other_post, email: "foo")
    counter = 0
    SentPostEmail.ensure_uniqueness(post: @post, email: "foo") { counter += 1 }
    assert_equal 1, counter

    SentPostEmail.ensure_uniqueness(post: @post, email: "FOO") { counter += 1 }
    assert_equal 1, counter

    SentPostEmail.ensure_uniqueness(post: @post, email: "bar") { counter += 1 }
    assert_equal 2, counter
  end

  test ".ensure_uniqueness does not raise error if email is blank" do
    counter = 0
    SentPostEmail.ensure_uniqueness(post: @post, email: "") { counter += 1 }
    assert_equal 0, counter

    SentPostEmail.ensure_uniqueness(post: @post, email: nil) { counter += 1 }
    assert_equal 0, counter
  end

  test ".insert_all_emails inserts new emails and returns newly inserted" do
    SentPostEmail.create!(post: @post, email: "foo")
    SentPostEmail.create!(post: @other_post, email: "bar")

    assert_equal ["bar", "baz"], SentPostEmail.insert_all_emails(post: @post, emails: ["foo", "bar", "baz"]).sort
    assert_equal 3, SentPostEmail.where(post: @post, email: ["foo", "bar", "baz"]).count

    assert_equal [], SentPostEmail.insert_all_emails(post: @post, emails: ["foo", "bar", "baz"])
    assert_equal 3, SentPostEmail.where(post: @post, email: ["foo", "bar", "baz"]).count
  end
end

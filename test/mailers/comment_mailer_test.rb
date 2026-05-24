# frozen_string_literal: true

require "test_helper"

class CommentMailerTest < ActionMailer::TestCase
  include Rails.application.routes.url_helpers

  def default_url_options
    { host: DOMAIN, protocol: PROTOCOL }
  end

  test "notify_seller_of_new_comment emails to seller" do
    comment = comments(:named_seller_comment_on_published_post)
    mail = CommentMailer.notify_seller_of_new_comment(comment.id)

    assert_equal [comment.commentable.seller.form_email], mail.to
    assert_equal "New comment on #{comment.commentable.name}", mail.subject
    assert_includes mail.body.encoded, "#{comment.author.display_name} commented on #{CGI.escape_html(comment.commentable.name)}"
    assert_includes mail.body.encoded, "Their -&gt; they're"
    view_url = custom_domain_view_post_url(slug: comment.commentable.slug, host: comment.commentable.seller.subdomain_with_protocol)
    assert_includes mail.body.encoded, %Q{<a class="button primary" target="_blank" href="#{view_url}">View comment</a>}
    assert_includes mail.body.encoded, %Q{To stop receiving comment notifications, please <a target="_blank" href="#{settings_main_url(anchor: "notifications")}">change your notification settings</a>.}
  end
end

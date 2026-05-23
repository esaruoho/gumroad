# frozen_string_literal: true

require "test_helper"

class InstallmentsHelperTest < ActionView::TestCase
  setup do
    @post = installments(:published_post)
  end

  test "post_title_displayable returns plain title span when url missing" do
    expected = %(<span class="title">#{ERB::Util.html_escape(@post.subject)}</span>)
    assert_equal expected, post_title_displayable(post: @post, url: nil)
  end

  test "post_title_displayable returns anchor when url present" do
    url = "https://example.com/p/#{@post.slug}"
    expected = %(<a target="_blank" class="title" href="#{url}">#{ERB::Util.html_escape(@post.subject)}</a>)
    assert_equal expected, post_title_displayable(post: @post, url: url)
  end
end

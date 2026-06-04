# frozen_string_literal: true

require "spec_helper"

# Full-stack check: a custom_html product page must still carry the social meta
# tags (og:description, fb:app_id, twitter:*) that PageMeta::Product gives the
# standard product page. Before this fix the custom_html wrapper hand-built its
# own <head> with only og:title/type/url/image, so a product with a custom
# landing emitted no og:description even when its description was set — shared
# links showed no preview text. This goes through routing + the real show action
# (which redirects to the custom_html wrapper), not just the wrapper method.
describe "GET /l/:id social meta tags for a custom_html product", type: :request do
  let(:seller) { create(:user, username: "metaseller") }
  let(:product) do
    create(
      :product,
      user: seller,
      description: "<p>Finishes the sound and makes it move.</p>",
      custom_html: "<section><h1>Live landing page</h1></section>"
    )
  end

  before { Feature.activate_user(:custom_html_pages, seller) }

  it "emits og:description / fb:app_id / twitter meta from the product description, like the standard page" do
    host = URI.parse(seller.subdomain_with_protocol).host
    get "/l/#{product.unique_permalink}", headers: { "HOST" => host }

    expect(response).to be_successful
    # the custom landing wrapper is what's served (iframe to the embed endpoint)…
    expect(response.body).to include(%(src="/l/#{product.unique_permalink}/landing/embed"))
    # …and it now carries the description-derived social meta the standard page has.
    expect(response.body).to match(%r{<meta property="og:description" content="[^"]*Finishes the sound and makes it move})
    expect(response.body).to include(%(property="fb:app_id"))
    expect(response.body).to match(%r{<meta property="twitter:card" content="summary(_large_image)?">})
    expect(response.body).to match(%r{<meta property="twitter:description" content="[^"]*Finishes the sound and makes it move})
    expect(response.body).to match(%r{<meta name="description" content="[^"]*Finishes the sound and makes it move})
  end

  it "falls back to a default og:description when the product has no description" do
    product.update!(description: nil)
    host = URI.parse(seller.subdomain_with_protocol).host
    get "/l/#{product.unique_permalink}", headers: { "HOST" => host }

    expect(response).to be_successful
    expect(response.body).to include(%(<meta property="og:description" content="Available on Gumroad">))
  end
end

# frozen_string_literal: true

module EmbedHelpers
  def cleanup_embed_artifacts
    Dir.glob(Rails.root.join("public", "embed_spec_page_*.html")).each { |f| File.delete(f) }
  end

  # Wait for the Gumroad embed iframe to be injected by gumroad-embed.js before entering it,
  # then wait for the embedded React app to finish hydrating before yielding.
  #
  # Bare `within_frame` does not retry and fails instantly when the iframe hasn't loaded yet.
  # The previous gate (`#app > *`) only proved that *some* child node existed under `#app`,
  # which happens before React hydrates and renders the product UI — so any assertion the
  # caller made inside the block was racing the hydration. Waiting for the "Add to cart"
  # action (rendered by Product/Layout.tsx once hydrated; an `<a>` styled as a button when
  # `cart: true`, hence the link_or_button selector) is a real hydration signal and removes
  # the need for long `wait:` overrides on subsequent assertions.
  def within_embed_frame(wait: Capybara.default_max_wait_time, &block)
    iframe = find("iframe", wait:)
    within_frame(iframe) do
      expect(page).to have_selector(:link_or_button, "Add to cart", wait:)
      block.call
    end
  end

  def create_embed_page(product, template_name: "embed_page.html.erb", url: nil, gumroad_params: nil, outbound: true, insert_anchor_tag: true, custom_domain_base_uri: nil, query_params: {})
    template = Rails.root.join("spec", "support", "fixtures", template_name)
    filename = Rails.root.join("public", "embed_spec_page_#{product.unique_permalink}.html")
    File.delete(filename) if File.exist?(filename)
    embed_html = ERB.new(File.read(template)).result_with_hash(
      unique_permalink: product.unique_permalink,
      outbound:,
      product:,
      url:,
      gumroad_params:,
      insert_anchor_tag:,
      js_nonce:,
      custom_domain_base_uri:
    )

    File.open(filename, "w") do |f|
      f.write(embed_html)
    end
    "/#{filename.basename}?#{query_params.to_param}"
  end
end

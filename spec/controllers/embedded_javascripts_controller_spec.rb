# frozen_string_literal: true

require "spec_helper"

describe EmbeddedJavascriptsController do
  render_views

  def vite_asset_url(path)
    ActionController::Base.helpers.asset_url(path)
  end

  describe "overlay" do
    it "returns the overlay loader with Vite script and stylesheet URLs" do
      get :overlay, format: :js

      manifest = ViteRuby.instance.manifest
      overlay_script_url = vite_asset_url(manifest.path_for("entrypoints/overlay.ts", type: :javascript))
      overlay_stylesheet_url = vite_asset_url(manifest.resolve_entries("overlay", type: :typescript).fetch(:stylesheets).first)
      design_stylesheet_url = vite_asset_url(manifest.resolve_entries("design", type: :typescript).fetch(:stylesheets).first)

      expect(response.body).to include(%(script.src = "#{overlay_script_url}";))
      expect(response.body).to include(%(document.head.insertAdjacentHTML('beforeend')))
      expect(response.body).to include(overlay_stylesheet_url)
      expect(response.body).to include(%(document.querySelector("script[src*='/js/gumroad.js']")))
      expect(response.body).to include(%(loaderScript.dataset.stylesUrl = "#{design_stylesheet_url}";))
    end
  end

  describe "embed" do
    it "returns the embed loader with only the Vite script URL" do
      get :embed, format: :js

      embed_script_url = vite_asset_url(ViteRuby.instance.manifest.path_for("entrypoints/embed.ts", type: :javascript))

      expect(response.body).to include(%(script.src = "#{embed_script_url}";))
      expect(response.body).not_to include("document.head.insertAdjacentHTML")
      expect(response.body).not_to include("loaderScript.dataset.stylesUrl")
    end
  end
end

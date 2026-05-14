# frozen_string_literal: true

class EmbeddedJavascriptsController < ApplicationController
  skip_before_action :verify_authenticity_token, only: %i[overlay embed]

  def overlay
    manifest = ViteRuby.instance.manifest
    @script_path = manifest.path_for("entrypoints/overlay.ts", type: :javascript)
    @global_stylesheet_path = manifest.resolve_entries("design", type: :typescript).fetch(:stylesheets, []).first
    @stylesheet = "overlay"
    render :index
  end

  def embed
    manifest = ViteRuby.instance.manifest
    @script_path = manifest.path_for("entrypoints/embed.ts", type: :javascript)
    render :index
  end
end

class ApplicationController < ActionController::Base
  include Authentication
  layout :choose_layout
  skip_before_action :require_authentication, only: :not_found_method
  skip_forgery_protection if: -> { request.headers["Authorization"]&.start_with?("Bearer ") }
  before_action :set_cache_headers
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  def not_found_method
    render file: Rails.public_path.join("404.html"), status: :not_found, layout: false
  end

  private

  def choose_layout
    discord_authenticated? ? "discord_activity" : "application"
  end

  def set_cache_headers
    response.headers["Cache-Control"] = "no-cache, no-store"
    response.headers["Pragma"] = "no-cache"
  end
end

class ApplicationController < ActionController::Base
  include Authentication
  layout :choose_layout
  skip_before_action :require_authentication, only: :not_found_method
  # Discord activities run in a cross-origin iframe (discordsays.com -> our app), so CSRF
  # origin checks fail. Safe because discord_authenticated? validates the Bearer token on
  # every request — the token itself serves as the anti-forgery mechanism.
  skip_forgery_protection if: -> { request.headers["Authorization"]&.start_with?("Bearer ") || discord_authenticated? }
  before_action :set_cache_headers
  before_action :set_discord_iframe_headers
  before_action :set_round_info
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

  # Discord activities run inside an iframe on discord.com/discordsays.com. Rails sets
  # X-Frame-Options: SAMEORIGIN by default, which blocks the iframe. We remove it and
  # replace with a restrictive frame-ancestors CSP that only allows Discord origins.
  # Only applied for Discord-authenticated requests so non-Discord pages keep SAMEORIGIN.
  # Discord's proxy follows redirects transparently, returning the final page as
  # a 200. Turbo expects 303 from form POSTs so it breaks. Use a turbo_stream
  # navigate action for Discord; normal redirect_to for everyone else.
  # Discord's proxy follows redirects server-side, stripping the Authorization header.
  # Use a Turbo Stream navigate action instead so navigation happens client-side
  # where the Bearer token interceptor can inject the auth header.
  # Works for both GET and POST because setupDiscordTurbo() adds the Turbo Stream
  # Accept header to all Discord Turbo requests.
  def turbo_nav_or_redirect_to(path)
    if discord_authenticated?
      render turbo_stream: turbo_stream.action(:navigate, path)
    else
      redirect_to path
    end
  end

  def set_round_info
    game = @current_room&.current_game
    return unless game&.current_game_prompt

    @current_round = game.current_game_prompt.order + 1
    @total_rounds = GamePrompt.where(game_id: game.id).count
  end

  def set_discord_iframe_headers
    return unless discord_authenticated?

    response.headers.delete("X-Frame-Options")
    response.headers["Content-Security-Policy"] = "frame-ancestors https://discord.com https://*.discordsays.com"
  end
end

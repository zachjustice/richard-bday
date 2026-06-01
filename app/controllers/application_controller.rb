class ApplicationController < ActionController::Base
  # Origins permitted to frame the app. discordsays.com is wildcarded because Discord
  # assigns each Activity its own proxy subdomain there.
  DISCORD_FRAME_ANCESTORS = %w[
    https://discord.com
    https://canary.discord.com
    https://ptb.discord.com
    https://*.discordsays.com
  ].freeze

  include Authentication
  layout :choose_layout
  skip_before_action :require_authentication, only: :not_found_method
  # Discord activities run in a cross-origin iframe (discordsays.com -> our app), so CSRF
  # origin checks fail. Safe because discord_authenticated? validates the Bearer token on
  # every request — the token itself serves as the anti-forgery mechanism.
  skip_forgery_protection if: -> { request.headers["Authorization"]&.start_with?("Bearer ") || discord_authenticated? }
  before_action :set_cache_headers
  before_action :set_discord_iframe_headers
  before_action :apply_dev_phase_shortcut
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
    response.headers["Content-Security-Policy"] = "frame-ancestors #{DISCORD_FRAME_ANCESTORS.join(' ')}"
  end

  # Dev-only shortcut: `?roomStatus=Wait` (case-insensitive starts-with) drives the
  # current room to the matched RoomStatus via DevPhaseSimulatorService, then redirects
  # to the canonical URL for the user's role. See issue #39.
  def apply_dev_phase_shortcut
    return if Rails.env.production?
    return if params[:roomStatus].blank?
    return unless @current_room

    target_status = resolve_room_status_prefix(params[:roomStatus])
    result = DevPhaseSimulatorService.new(
      room: @current_room,
      target_status: target_status,
      player_count: params[:players]&.to_i,
      audience_count: params[:audience]&.to_i
    ).call

    if result.is_a?(DevPhaseSimulatorService::Failure)
      raise "DevPhaseSimulator failed: #{result.error}"
    end

    @current_room.reload
    canonical = canonical_dev_path_for(target_status)
    return if request.path == canonical

    separator = canonical.include?("?") ? "&" : "?"
    target_url = "#{canonical}#{separator}roomStatus=#{CGI.escape(params[:roomStatus].to_s)}"
    turbo_nav_or_redirect_to(target_url)
  end

  def resolve_room_status_prefix(prefix)
    needle = prefix.to_s.downcase
    matches = RoomStatus.constants.map(&:to_s).select { |c| c.downcase.start_with?(needle) }
    if matches.empty?
      raise ArgumentError, "Unknown roomStatus prefix #{prefix.inspect}: no RoomStatus constant matches"
    end
    if matches.size > 1
      raise ArgumentError, "Ambiguous roomStatus prefix #{prefix.inspect} matches: #{matches.inspect}"
    end
    matches.first
  end

  def canonical_dev_path_for(target_status)
    if @current_user&.creator? || (discord_authenticated? && @current_user&.navigator?)
      return room_status_path(@current_room)
    end

    case target_status
    when RoomStatus::WaitingRoom
      waiting_for_new_game_path(@current_room)
    when RoomStatus::Answering
      prompt = @current_room.current_game&.current_game_prompt
      if prompt
        @current_user&.audience? ? game_prompt_waiting_path(prompt) : game_prompt_path(prompt)
      else
        show_room_path
      end
    when RoomStatus::Voting
      prompt = @current_room.current_game&.current_game_prompt
      prompt ? game_prompt_voting_path(prompt) : show_room_path
    when RoomStatus::Results
      prompt = @current_room.current_game&.current_game_prompt
      prompt ? game_prompt_results_path(prompt) : show_room_path
    when RoomStatus::FinalResults
      room_story_path(@current_room)
    when RoomStatus::Credits
      room_game_credits_path(@current_room)
    else
      show_room_path
    end
  end
end

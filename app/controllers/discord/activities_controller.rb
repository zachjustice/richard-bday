module Discord
  class ActivitiesController < ApplicationController
    allow_unauthenticated_access
    # Auth callback is the initial authentication step — no Bearer token or session
    # exists yet. The request is secured by the Discord OAuth code exchange instead.
    skip_forgery_protection only: :auth_callback
    # The launch page loads before Discord auth, so set_discord_iframe_headers (which
    # requires discord_authenticated?) won't fire. Must explicitly allow framing here.
    after_action :allow_discord_iframe, only: [ :launch ]

    # GET /discord - Entry point when Discord launches the activity
    def launch
      @client_id = Rails.application.credentials.dig(:discord, :client_id)
      render layout: "discord_activity"
    end

    # POST /discord/auth/callback - Exchange Discord auth code for app token
    def auth_callback
      code = params[:code]
      instance_id = params[:instance_id]
      channel_id = params[:channel_id]

      discord_token_response = exchange_discord_code(code)
      unless discord_token_response
        return render json: { error: "Failed to exchange code" }, status: :unprocessable_entity
      end

      access_token = discord_token_response["access_token"]

      discord_user = fetch_discord_user(access_token)
      unless discord_user
        return render json: { error: "Failed to fetch Discord user" }, status: :unprocessable_entity
      end

      room = find_or_create_activity_room(instance_id, channel_id)
      find_or_create_room_creator(room)
      player = find_or_create_discord_player(room, discord_user)

      player.discord_activity_tokens.where("expires_at > ?", Time.current).destroy_all
      activity_token = DiscordActivityToken.create_for_user(player)

      render json: {
        token: activity_token.token,
        access_token: access_token,
        cable_url: cable_url,
        user: { id: player.id, name: player.name, avatar: player.avatar, role: player.role },
        room: { id: room.id, code: room.code }
      }
    end

    private

    def allow_discord_iframe
      response.headers.delete("X-Frame-Options")
      response.headers["Content-Security-Policy"] = "frame-ancestors https://discord.com https://*.discordsays.com"
    end

    def exchange_discord_code(code)
      uri = URI("https://discord.com/api/oauth2/token")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.open_timeout = 5
      http.read_timeout = 10

      request = Net::HTTP::Post.new(uri)
      request.set_form_data(
        client_id: Rails.application.credentials.dig(:discord, :client_id),
        client_secret: Rails.application.credentials.dig(:discord, :client_secret),
        grant_type: "authorization_code",
        code: code
      )

      response = http.request(request)
      return nil unless response.is_a?(Net::HTTPSuccess)

      JSON.parse(response.body)
    rescue Net::OpenTimeout, Net::ReadTimeout, SocketError, Errno::ECONNREFUSED, JSON::ParserError => e
      Rails.logger.error("Discord token exchange failed: #{e.message}")
      nil
    end

    def cable_url
      host = request.host
      port = request.port
      scheme = request.ssl? ? "wss" : "ws"
      if port == 80 || port == 443
        "#{scheme}://#{host}/cable"
      else
        "#{scheme}://#{host}:#{port}/cable"
      end
    end

    def fetch_discord_user(access_token)
      uri = URI("https://discord.com/api/users/@me")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.open_timeout = 5
      http.read_timeout = 10

      request = Net::HTTP::Get.new(uri)
      request["Authorization"] = "Bearer #{access_token}"

      response = http.request(request)
      return nil unless response.is_a?(Net::HTTPSuccess)

      JSON.parse(response.body)
    rescue Net::OpenTimeout, Net::ReadTimeout, SocketError, Errno::ECONNREFUSED, JSON::ParserError => e
      Rails.logger.error("Discord user fetch failed: #{e.message}")
      nil
    end

    def find_or_create_discord_player(room, discord_user)
      existing = User.find_by(discord_id: discord_user["id"], room_id: room.id)
      return existing if existing

      player_count = User.players.where(room_id: room.id).count
      role = player_count == 0 ? User::NAVIGATOR : User::PLAYER

      User.create!(
        name: discord_user["global_name"].presence || discord_user["username"],
        room_id: room.id,
        role: role,
        discord_id: discord_user["id"],
        discord_username: discord_user["username"]
      )
    end

    def find_or_create_room_creator(room)
      User.creator.find_by(room: room) ||
        User.create!(
          name: "Creator-#{room.code}",
          room_id: room.id,
          role: User::CREATOR
        )
    end

    def find_or_create_activity_room(instance_id, channel_id)
      room = Room.find_by(discord_instance_id: instance_id)
      return room if room

      Room.create!(
        code: Room.generate_unique_code,
        discord_instance_id: instance_id,
        discord_channel_id: channel_id,
        is_discord_activity: true
      )
    end
  end
end

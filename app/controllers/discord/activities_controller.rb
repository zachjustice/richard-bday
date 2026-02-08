module Discord
  class ActivitiesController < ApplicationController
    allow_unauthenticated_access
    skip_before_action :verify_authenticity_token, only: [ :auth_callback ]
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

      room = find_or_create_activity_room(instance_id, channel_id)
      creator = find_or_create_room_creator(room)
      activity_token = DiscordActivityToken.create_for_user(creator)

      render json: {
        token: activity_token.token,
        access_token: access_token,
        cable_url: cable_url,
        user: { id: creator.id, name: creator.name, avatar: creator.avatar, role: creator.role },
        room: { id: room.id, code: room.code }
      }
    end

    private

    def allow_discord_iframe
      response.headers.delete("X-Frame-Options")
    end

    def exchange_discord_code(code)
      uri = URI("https://discord.com/api/oauth2/token")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true

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
    rescue StandardError => e
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

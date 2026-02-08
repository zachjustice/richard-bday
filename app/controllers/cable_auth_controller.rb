class CableAuthController < ApplicationController
  allow_unauthenticated_access
  skip_before_action :verify_authenticity_token

  # POST /cable/auth - Exchange activity token for a one-time cable connection token
  def create
    token = request.headers["Authorization"]&.sub("Bearer ", "")
    activity_token = DiscordActivityToken.find_by_token(token)

    if activity_token&.valid_token?
      cable_token = SecureRandom.urlsafe_base64(32)
      Rails.cache.write("cable_token:#{cable_token}", activity_token.user_id, expires_in: 30.seconds)
      render json: { cable_token: cable_token }
    else
      render json: { error: "Invalid token" }, status: :unauthorized
    end
  end
end

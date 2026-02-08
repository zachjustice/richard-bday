require "test_helper"

class CableAuthControllerTest < ActionDispatch::IntegrationTest
  test "returns cable token for valid activity token" do
    user = users(:one)
    activity_token = DiscordActivityToken.create_for_user(user)

    post cable_auth_path, headers: {
      "Authorization" => "Bearer #{activity_token.token}"
    }

    assert_response :success
    assert response.parsed_body["cable_token"].present?
  end

  test "returns unauthorized for invalid token" do
    post cable_auth_path, headers: {
      "Authorization" => "Bearer invalid_token"
    }

    assert_response :unauthorized
  end

  test "returns unauthorized for expired token" do
    user = users(:one)
    activity_token = DiscordActivityToken.create_for_user(user)
    activity_token.update!(expires_at: 1.hour.ago)

    post cable_auth_path, headers: {
      "Authorization" => "Bearer #{activity_token.token}"
    }

    assert_response :unauthorized
  end
end

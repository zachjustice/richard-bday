require "test_helper"

class Discord::ActivitiesControllerTest < ActionDispatch::IntegrationTest
  test "launch renders without authentication" do
    get discord_activity_launch_path
    assert_response :success
  end

  test "redirects root with frame_id to discord path" do
    get "/?frame_id=abc123"
    assert_response :redirect
    assert_match %r{/discord\?frame_id=abc123}, response.location
  end

  test "auth_callback creates room and returns creator token" do
    success_response = Net::HTTPOK.new("1.1", "200", "OK")
    success_response.instance_variable_set(:@read, true)
    success_body = { "access_token" => "discord_access_123" }.to_json
    success_response.body = success_body

    Net::HTTP.stub_any_instance(:request, success_response) do
      assert_difference [ "Room.count", "User.count", "DiscordActivityToken.count" ], 1 do
        post discord_activity_auth_callback_path, params: {
          code: "valid_code",
          instance_id: "test-instance-new",
          channel_id: "test-channel-new"
        }, as: :json
      end

      assert_response :success
      data = response.parsed_body
      assert data["token"].present?
      assert_equal "discord_access_123", data["access_token"]
      assert_equal "Creator", data["user"]["role"]
      assert data["room"]["id"].present?

      room = Room.find(data["room"]["id"])
      assert room.is_discord_activity?
      assert_equal "test-instance-new", room.discord_instance_id
    end
  end

  test "auth_callback reuses existing room and creator for same instance_id" do
    room = Room.create!(
      code: Room.generate_unique_code,
      discord_instance_id: "test-instance-existing",
      discord_channel_id: "ch-123",
      is_discord_activity: true
    )
    creator = User.create!(
      name: "Creator-#{room.code}",
      room_id: room.id,
      role: User::CREATOR
    )

    success_response = Net::HTTPOK.new("1.1", "200", "OK")
    success_response.instance_variable_set(:@read, true)
    success_response.body = { "access_token" => "discord_access_456" }.to_json

    Net::HTTP.stub_any_instance(:request, success_response) do
      assert_no_difference "Room.count" do
        assert_no_difference "User.count" do
          post discord_activity_auth_callback_path, params: {
            code: "valid_code",
            instance_id: "test-instance-existing",
            channel_id: "ch-123"
          }, as: :json
        end
      end

      assert_response :success
      data = response.parsed_body
      assert_equal room.id, data["room"]["id"]
      assert_equal creator.id, data["user"]["id"]
    end
  end

  test "auth_callback returns error for invalid code" do
    bad_response = Net::HTTPBadRequest.new("1.1", "400", "Bad Request")

    Net::HTTP.stub_any_instance(:request, bad_response) do
      post discord_activity_auth_callback_path, params: {
        code: "invalid_code",
        instance_id: "test-instance-123",
        channel_id: "test-channel-456"
      }, as: :json

      assert_response :unprocessable_entity
      assert_includes response.parsed_body["error"], "Failed"
    end
  end
end

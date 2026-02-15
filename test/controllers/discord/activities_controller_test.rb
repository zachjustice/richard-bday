require "test_helper"

class Discord::ActivitiesControllerTest < ActionDispatch::IntegrationTest
  test "launch renders without authentication" do
    get discord_activity_launch_path
    assert_response :success
  end

  test "root with frame_id serves launch page" do
    get "/?frame_id=abc123"
    assert_response :success
  end

  test "auth_callback creates room, creator, and player" do
    call_count = 0
    token_response = Net::HTTPOK.new("1.1", "200", "OK")
    token_response.instance_variable_set(:@read, true)
    token_response.body = { "access_token" => "discord_access_123" }.to_json

    user_response = Net::HTTPOK.new("1.1", "200", "OK")
    user_response.instance_variable_set(:@read, true)
    user_response.body = { "id" => "discord_user_1", "username" => "testuser", "global_name" => "Test User" }.to_json

    responses = [ token_response, user_response ]

    Net::HTTP.stub_any_instance(:request, ->(_req) { responses[call_count].tap { call_count += 1 } }) do
      # Creates room + creator + player
      assert_difference "Room.count", 1 do
        assert_difference "User.count", 2 do
          assert_difference "DiscordActivityToken.count", 1 do
            post discord_activity_auth_callback_path, params: {
              code: "valid_code",
              instance_id: "test-instance-new",
              channel_id: "test-channel-new"
            }, as: :json
          end
        end
      end

      assert_response :success
      data = response.parsed_body
      assert data["token"].present?
      assert_equal "discord_access_123", data["access_token"]
      assert_equal "Navigator", data["user"]["role"]
      assert_equal "Test User", data["user"]["name"]
      assert data["room"]["id"].present?

      room = Room.find(data["room"]["id"])
      assert room.is_discord_activity?
      assert_equal "test-instance-new", room.discord_instance_id

      player = User.find(data["user"]["id"])
      assert_equal "discord_user_1", player.discord_id
      assert_equal "testuser", player.discord_username
    end
  end

  test "auth_callback reuses existing room and player for same instance_id and discord_id" do
    room = Room.create!(
      code: Room.generate_unique_code,
      discord_instance_id: "test-instance-existing",
      discord_channel_id: "ch-123",
      is_discord_activity: true
    )
    User.create!(name: "Creator-#{room.code}", room_id: room.id, role: User::CREATOR)
    player = User.create!(
      name: "Existing Player",
      room_id: room.id,
      role: User::NAVIGATOR,
      discord_id: "discord_user_existing",
      discord_username: "existinguser"
    )

    call_count = 0
    token_response = Net::HTTPOK.new("1.1", "200", "OK")
    token_response.instance_variable_set(:@read, true)
    token_response.body = { "access_token" => "discord_access_456" }.to_json

    user_response = Net::HTTPOK.new("1.1", "200", "OK")
    user_response.instance_variable_set(:@read, true)
    user_response.body = { "id" => "discord_user_existing", "username" => "existinguser", "global_name" => "Existing Player" }.to_json

    responses = [ token_response, user_response ]

    Net::HTTP.stub_any_instance(:request, ->(_req) { responses[call_count].tap { call_count += 1 } }) do
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
      assert_equal player.id, data["user"]["id"]
      assert_equal "Navigator", data["user"]["role"]
    end
  end

  test "second discord user gets Player role" do
    room = Room.create!(
      code: Room.generate_unique_code,
      discord_instance_id: "test-instance-roles",
      discord_channel_id: "ch-roles",
      is_discord_activity: true
    )
    User.create!(name: "Creator-#{room.code}", room_id: room.id, role: User::CREATOR)
    User.create!(
      name: "First Player",
      room_id: room.id,
      role: User::NAVIGATOR,
      discord_id: "discord_user_first",
      discord_username: "firstuser"
    )

    call_count = 0
    token_response = Net::HTTPOK.new("1.1", "200", "OK")
    token_response.instance_variable_set(:@read, true)
    token_response.body = { "access_token" => "discord_access_second" }.to_json

    user_response = Net::HTTPOK.new("1.1", "200", "OK")
    user_response.instance_variable_set(:@read, true)
    user_response.body = { "id" => "discord_user_second", "username" => "seconduser", "global_name" => "Second Player" }.to_json

    responses = [ token_response, user_response ]

    Net::HTTP.stub_any_instance(:request, ->(_req) { responses[call_count].tap { call_count += 1 } }) do
      assert_difference "User.count", 1 do
        post discord_activity_auth_callback_path, params: {
          code: "valid_code",
          instance_id: "test-instance-roles",
          channel_id: "ch-roles"
        }, as: :json
      end

      assert_response :success
      data = response.parsed_body
      assert_equal "Player", data["user"]["role"]
      assert_equal "Second Player", data["user"]["name"]
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

  test "auth_callback revokes old tokens on reconnect" do
    room = Room.create!(
      code: Room.generate_unique_code,
      discord_instance_id: "test-instance-retoken",
      discord_channel_id: "ch-retoken",
      is_discord_activity: true
    )
    User.create!(name: "Creator-#{room.code}", room_id: room.id, role: User::CREATOR)
    player = User.create!(
      name: "Retoken Player",
      room_id: room.id,
      role: User::NAVIGATOR,
      discord_id: "discord_user_retoken",
      discord_username: "retokenuser"
    )
    old_token = DiscordActivityToken.create_for_user(player)

    call_count = 0
    token_response = Net::HTTPOK.new("1.1", "200", "OK")
    token_response.instance_variable_set(:@read, true)
    token_response.body = { "access_token" => "discord_access_789" }.to_json

    user_response = Net::HTTPOK.new("1.1", "200", "OK")
    user_response.instance_variable_set(:@read, true)
    user_response.body = { "id" => "discord_user_retoken", "username" => "retokenuser", "global_name" => "Retoken Player" }.to_json

    responses = [ token_response, user_response ]

    Net::HTTP.stub_any_instance(:request, ->(_req) { responses[call_count].tap { call_count += 1 } }) do
      post discord_activity_auth_callback_path, params: {
        code: "valid_code",
        instance_id: "test-instance-retoken",
        channel_id: "ch-retoken"
      }, as: :json
    end

    assert_response :success
    assert_nil DiscordActivityToken.find_by(id: old_token.id)
  end

  test "launch sets CSP frame-ancestors and removes X-Frame-Options" do
    get discord_activity_launch_path
    assert_response :success
    assert_nil response.headers["X-Frame-Options"]
    assert_includes response.headers["Content-Security-Policy"], "frame-ancestors"
    assert_includes response.headers["Content-Security-Policy"], "discord.com"
  end

  test "valid discord bearer token authenticates through regular controller" do
    room = Room.create!(code: Room.generate_unique_code, discord_instance_id: "bearer-test", discord_channel_id: "ch-1", is_discord_activity: true)
    user = User.create!(name: "BearerTestPlayer", room_id: room.id, role: User::NAVIGATOR, discord_id: "bearer_discord_id", discord_username: "beareruser")
    token_record = DiscordActivityToken.create_for_user(user)

    get show_room_path, headers: { "Authorization" => "Bearer #{token_record.token}" }
    assert_response :success
  end

  test "fake bearer token does not authenticate" do
    get show_room_path, headers: { "Authorization" => "Bearer fake_token" }
    assert_response :unauthorized
  end
end

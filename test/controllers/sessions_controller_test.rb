require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @room = Room.create!(code: "sess", status: RoomStatus::WaitingRoom)
  end

  test "first player to join gets NAVIGATOR role" do
    post "/session", params: { code: @room.code, name: "FirstPlayer" }

    user = User.find_by(name: "FirstPlayer", room: @room)
    assert_equal User::NAVIGATOR, user.role
    assert_redirected_to show_room_path
  end

  test "second player to join gets PLAYER role" do
    User.create!(name: "FirstPlayer", room: @room, role: User::NAVIGATOR)

    post "/session", params: { code: @room.code, name: "SecondPlayer" }

    user = User.find_by(name: "SecondPlayer", room: @room)
    assert_equal User::PLAYER, user.role
  end

  test "audience joins with join_as_audience param and gets AUDIENCE role" do
    post "/session", params: { code: @room.code, name: "Watcher", join_as_audience: "1" }

    user = User.find_by(name: "Watcher", room: @room)
    assert_equal User::AUDIENCE, user.role
    assert_equal User::AUDIENCE_AVATAR, user.avatar
  end

  test "audience can join even when room has MAX_PLAYERS" do
    User::MAX_PLAYERS.times do |i|
      role = i == 0 ? User::NAVIGATOR : User::PLAYER
      User.create!(name: "Player#{i}", room: @room, role: role)
    end

    assert_difference("User.count", 1) do
      post "/session", params: { code: @room.code, name: "AudienceMember", join_as_audience: "1" }
    end

    user = User.find_by(name: "AudienceMember", room: @room)
    assert_equal User::AUDIENCE, user.role
  end

  test "audience capacity is enforced at MAX_AUDIENCE" do
    User::MAX_AUDIENCE.times do |i|
      User.create!(name: "Audience#{i}", room: @room, role: User::AUDIENCE)
    end

    assert_no_difference("User.count") do
      post "/session", params: { code: @room.code, name: "OneMore", join_as_audience: "1" }
    end

    assert_redirected_to new_session_path
  end

  test "invalid room code returns error flash" do
    post "/session", params: { code: "nope", name: "Nobody" }

    assert_redirected_to new_session_path
    assert_equal "Wrong room code.", flash[:alert]
  end

  test "duplicate player name redirects back" do
    User.create!(name: "Taken", room: @room, role: User::PLAYER)

    post "/session", params: { code: @room.code, name: "Taken" }

    assert_redirected_to new_session_path
  end

  test "duplicate name redirects back even for audience" do
    User.create!(name: "SameName", room: @room, role: User::AUDIENCE)

    assert_no_difference("User.count") do
      post "/session", params: { code: @room.code, name: "SameName", join_as_audience: "1" }
    end

    assert_redirected_to new_session_path
  end

  test "existing session with matching room code redirects to game" do
    post "/session", params: { code: @room.code, name: "Returning" }
    assert_redirected_to show_room_path

    # Post again with same room code -- should short-circuit via existing session
    post "/session", params: { code: @room.code, name: "Returning" }
    assert_redirected_to show_room_path
  end
end

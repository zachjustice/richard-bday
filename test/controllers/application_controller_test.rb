require "test_helper"
require "minitest/mock"

class ApplicationControllerDevPhaseShortcutTest < ActionDispatch::IntegrationTest
  setup do
    @room = rooms(:one)
    @user = User.create!(name: "Creator", room_id: @room.id, role: User::CREATOR)
    resume_session_as(@room.code, @user.name)
  end

  test "valid prefix drives room to target status and redirects to canonical path for creator" do
    @room.update!(status: RoomStatus::Answering)

    get show_room_path, params: { roomStatus: "Wait" }

    @room.reload
    assert_equal RoomStatus::WaitingRoom, @room.status
    assert_redirected_to "#{room_status_path(@room)}?roomStatus=Wait"
  end

  test "valid prefix is case-insensitive" do
    @room.update!(status: RoomStatus::Answering)

    get show_room_path, params: { roomStatus: "story" }

    @room.reload
    assert_equal RoomStatus::StorySelection, @room.status
  end

  test "rs alias triggers the dev shortcut" do
    @room.update!(status: RoomStatus::Answering)

    get show_room_path, params: { rs: "Wait" }

    @room.reload
    assert_equal RoomStatus::WaitingRoom, @room.status
    assert_redirected_to "#{room_status_path(@room)}?roomStatus=Wait"
  end

  test "RoomStatus alias triggers the dev shortcut and normalizes redirect key" do
    @room.update!(status: RoomStatus::Answering)

    get show_room_path, params: { RoomStatus: "Story" }

    @room.reload
    assert_equal RoomStatus::StorySelection, @room.status
    assert_equal "roomStatus=Story", URI(@response.location).query
  end

  test "ambiguous prefix raises ArgumentError" do
    RoomStatus.stub :constants, [ :Waiting, :Watching ] do
      assert_raises(ArgumentError) do
        get show_room_path, params: { roomStatus: "W" }
      end
    end
  end

  test "unknown prefix raises ArgumentError" do
    assert_raises(ArgumentError) do
      get show_room_path, params: { roomStatus: "ZZZ" }
    end
  end

  test "production env ignores the shortcut" do
    @room.update!(status: RoomStatus::Answering)

    Rails.env.stub :production?, true do
      get show_room_path, params: { roomStatus: "Wait" }
    end

    @room.reload
    assert_equal RoomStatus::Answering, @room.status
  end

  test "missing current_room is ignored" do
    end_session

    # Hit an unauthenticated route that does not set @current_room.
    assert_nothing_raised do
      get new_session_path, params: { roomStatus: "ZZZ" }
    end
    assert_response :success
  end

  test "no-op when already at target status still redirects to canonical (only if not already there)" do
    @room.update!(status: RoomStatus::WaitingRoom)

    # Hit room_status_path (the canonical creator path) — already at canonical, no redirect.
    get room_status_path(@room), params: { roomStatus: "Wait" }

    assert_response :success
    @room.reload
    assert_equal RoomStatus::WaitingRoom, @room.status
  end
end

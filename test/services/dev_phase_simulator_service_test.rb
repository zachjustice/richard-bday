require "test_helper"

class DevPhaseSimulatorServiceTest < ActiveSupport::TestCase
  def setup
    suffix = SecureRandom.hex(4)

    # Stub broadcasts to prevent ActionCable errors from after_commit callbacks
    Turbo::StreamsChannel.define_singleton_method(:broadcast_replace_to) { |*| }
    Turbo::StreamsChannel.define_singleton_method(:broadcast_action_to) { |*| }
    Turbo::StreamsChannel.define_singleton_method(:broadcast_append_to) { |*| }
    Turbo::StreamsChannel.define_singleton_method(:broadcast_remove_to) { |*| }

    @room = Room.create!(code: "dp#{suffix}", status: RoomStatus::Answering)
    @story = Story.create!(title: "DP #{suffix}", text: "test", original_text: "test", published: true)
    @game = Game.create!(story: @story, room: @room)
    @editor = Editor.create!(username: "dp#{suffix}", email: "dp#{suffix}@test.com", password: "password123", password_confirmation: "password123")
    @blank = Blank.create!(story: @story, tags: "noun")
    @prompt = Prompt.create!(description: "DP prompt #{suffix}", tags: "noun", creator: @editor)
    @game_prompt = GamePrompt.create!(game: @game, prompt: @prompt, blank: @blank, order: 0)
    @room.update!(current_game: @game)
    @game.update!(current_game_prompt: @game_prompt)
  end

  test "WaitingRoom target sets room status to WaitingRoom and clears current_game" do
    result = DevPhaseSimulatorService.new(
      room: @room, target_status: RoomStatus::WaitingRoom
    ).call

    assert_kind_of DevPhaseSimulatorService::Success, result
    @room.reload
    assert_equal RoomStatus::WaitingRoom, @room.status
    assert_nil @room.current_game_id
  end

  test "WaitingRoom target clears game.current_game_prompt and flags dev_seeded" do
    DevPhaseSimulatorService.new(
      room: @room, target_status: RoomStatus::WaitingRoom
    ).call

    @game.reload
    assert_nil @game.current_game_prompt_id
    assert @game.dev_seeded, "expected dev_seeded to be true"
  end

  test "StorySelection target sets room status to StorySelection and clears current_game" do
    result = DevPhaseSimulatorService.new(
      room: @room, target_status: RoomStatus::StorySelection
    ).call

    assert_kind_of DevPhaseSimulatorService::Success, result
    @room.reload
    assert_equal RoomStatus::StorySelection, @room.status
    assert_nil @room.current_game_id
  end

  test "is a no-op when room.status already equals target_status" do
    @room.update!(status: RoomStatus::WaitingRoom)
    original_current_game_id = @room.current_game_id

    result = DevPhaseSimulatorService.new(
      room: @room, target_status: RoomStatus::WaitingRoom
    ).call

    assert_kind_of DevPhaseSimulatorService::Success, result
    @room.reload
    assert_equal RoomStatus::WaitingRoom, @room.status
    # current_game intentionally not cleared because seeding was skipped
    assert_equal original_current_game_id, @room.current_game_id
  end

  test "unsupported target_status returns Failure" do
    result = DevPhaseSimulatorService.new(
      room: @room, target_status: RoomStatus::Voting
    ).call

    assert_kind_of DevPhaseSimulatorService::Failure, result
    assert_match(/Unsupported target_status/, result.error)
  end

  test "seeds additional players when player_count exceeds current count" do
    User.create!(room: @room, name: "Existing", role: User::PLAYER)

    DevPhaseSimulatorService.new(
      room: @room,
      target_status: RoomStatus::WaitingRoom,
      player_count: 4
    ).call

    assert_equal 4, User.players.where(room: @room).count
  end

  test "seeds additional audience when audience_count exceeds current count" do
    DevPhaseSimulatorService.new(
      room: @room,
      target_status: RoomStatus::StorySelection,
      audience_count: 3
    ).call

    assert_equal 3, User.audience.where(room: @room).count
  end

  test "does not remove users when counts are below current" do
    3.times { |i| User.create!(room: @room, name: "Existing#{i}", role: User::PLAYER) }

    DevPhaseSimulatorService.new(
      room: @room,
      target_status: RoomStatus::WaitingRoom,
      player_count: 1
    ).call

    assert_equal 3, User.players.where(room: @room).count
  end
end

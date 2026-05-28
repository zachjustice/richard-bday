require "test_helper"

class DevPhaseSimulatorServiceTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper
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

  test "Answering target seeds a fresh game on the first published story by title" do
    suffix = SecureRandom.hex(4)
    early_story = Story.create!(title: "A first #{suffix}", text: "{#{@blank.id}}", original_text: "_", published: true)
    early_blank = Blank.create!(story: early_story, tags: "noun")
    early_story.update!(text: "{#{early_blank.id}}")
    StoryPrompt.create!(story: early_story, blank: early_blank, prompt: @prompt)

    @room.update!(status: RoomStatus::WaitingRoom, current_game: nil)

    result = DevPhaseSimulatorService.new(
      room: @room,
      target_status: RoomStatus::Answering,
      player_count: 2
    ).call

    assert_kind_of DevPhaseSimulatorService::Success, result
    @room.reload
    assert_equal RoomStatus::Answering, @room.status
    assert_not_nil @room.current_game
    assert @room.current_game.dev_seeded, "expected game.dev_seeded to be true"
    assert_equal early_story.id, @room.current_game.story_id
    assert_not_nil @room.current_game.current_game_prompt_id
    assert_equal 0, @room.current_game.current_game_prompt.order
    assert_equal 1, GamePrompt.where(game_id: @room.current_game.id).count
  end

  test "Answering target raises when no published stories exist" do
    Story.where(published: true).update_all(published: false)
    @room.update!(status: RoomStatus::WaitingRoom, current_game: nil)

    err = assert_raises(RuntimeError) do
      DevPhaseSimulatorService.new(
        room: @room,
        target_status: RoomStatus::Answering,
        player_count: 1
      ).call
    end
    assert_match(/no published stories/i, err.message)
  end

  test "Answering target defaults player_count to User::MAX_PLAYERS" do
    StoryPrompt.create!(story: @story, blank: @blank, prompt: @prompt)
    @room.update!(status: RoomStatus::WaitingRoom, current_game: nil)

    DevPhaseSimulatorService.new(
      room: @room,
      target_status: RoomStatus::Answering
    ).call

    assert_equal User::MAX_PLAYERS, User.players.where(room: @room).count
  end

  test "Answering target trims fake players when count exceeds target" do
    StoryPrompt.create!(story: @story, blank: @blank, prompt: @prompt)
    @room.update!(status: RoomStatus::WaitingRoom, current_game: nil)

    DevPhaseSimulatorService.new(
      room: @room,
      target_status: RoomStatus::Answering,
      player_count: 5
    ).call

    assert_equal 5, User.players.where(room: @room).count

    DevPhaseSimulatorService.new(
      room: @room,
      target_status: RoomStatus::Answering,
      player_count: 2
    ).call

    assert_equal 2, User.players.where(room: @room).count
  end

  test "Answering target never trims real players (with sessions or discord_id)" do
    StoryPrompt.create!(story: @story, blank: @blank, prompt: @prompt)
    real_web = User.create!(room: @room, name: "RealWeb", role: User::PLAYER)
    Session.create!(user: real_web, ip_address: "127.0.0.1", user_agent: "test")
    real_discord = User.create!(room: @room, name: "RealDiscord", role: User::PLAYER, discord_id: "12345")

    DevPhaseSimulatorService.new(
      room: @room,
      target_status: RoomStatus::Answering,
      player_count: 5
    ).call
    assert_equal 5, User.players.where(room: @room).count

    DevPhaseSimulatorService.new(
      room: @room,
      target_status: RoomStatus::Answering,
      player_count: 2
    ).call

    remaining_ids = User.players.where(room: @room).pluck(:id)
    assert_includes remaining_ids, real_web.id
    assert_includes remaining_ids, real_discord.id
  end

  test "Answering target is idempotent when room already at dev-seeded Answering" do
    StoryPrompt.create!(story: @story, blank: @blank, prompt: @prompt)
    @room.update!(status: RoomStatus::WaitingRoom, current_game: nil)

    DevPhaseSimulatorService.new(
      room: @room,
      target_status: RoomStatus::Answering,
      player_count: 2
    ).call
    first_game_id = @room.reload.current_game_id

    DevPhaseSimulatorService.new(
      room: @room,
      target_status: RoomStatus::Answering,
      player_count: 2
    ).call

    assert_equal first_game_id, @room.reload.current_game_id
  end

  test "Answering target does not enqueue AnsweringTimesUpJob" do
    StoryPrompt.create!(story: @story, blank: @blank, prompt: @prompt)
    @room.update!(status: RoomStatus::WaitingRoom, current_game: nil)

    assert_no_enqueued_jobs only: AnsweringTimesUpJob do
      DevPhaseSimulatorService.new(
        room: @room,
        target_status: RoomStatus::Answering,
        player_count: 1
      ).call
    end
  end
end

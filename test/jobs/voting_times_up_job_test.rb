require "test_helper"

class VotingTimesUpJobTest < ActiveSupport::TestCase
  def setup
    suffix = SecureRandom.hex(4)

    Turbo::StreamsChannel.define_singleton_method(:broadcast_replace_to) { |*| }
    Turbo::StreamsChannel.define_singleton_method(:broadcast_action_to) { |*| }

    @room = Room.create!(code: "vt#{suffix}", status: RoomStatus::Voting)
    @story = Story.create!(title: "VTU #{suffix}", text: "test", original_text: "test", published: true)
    @game = Game.create!(story: @story, room: @room)
    @blank = Blank.create!(story: @story, tags: "noun")
    @editor = Editor.create!(username: "vt#{suffix}", email: "vt#{suffix}@test.com", password: "password123", password_confirmation: "password123")
    @prompt = Prompt.create!(description: "VTU prompt #{suffix}", tags: "noun", creator: @editor)
    @game_prompt = GamePrompt.create!(game: @game, prompt: @prompt, blank: @blank, order: 0)
    @room.update!(current_game: @game)
    @game.update!(current_game_prompt: @game_prompt)

    @creator = User.create!(name: "Creator-vt#{suffix}", room: @room, role: User::CREATOR)
  end

  test "calls move_to_results when status is Voting and game_prompt_id matches" do
    move_called = false
    GamePhasesService.stub_any_instance(:move_to_results, proc { move_called = true }) do
      VotingTimesUpJob.perform_now(@room, @game_prompt.id)
    end
    assert move_called
  end

  test "does nothing when room status is not Voting" do
    @room.update!(status: RoomStatus::Answering)

    move_called = false
    GamePhasesService.stub_any_instance(:move_to_results, proc { move_called = true }) do
      VotingTimesUpJob.perform_now(@room, @game_prompt.id)
    end
    assert_not move_called
  end

  test "does nothing when game_prompt_id does not match current" do
    move_called = false
    GamePhasesService.stub_any_instance(:move_to_results, proc { move_called = true }) do
      VotingTimesUpJob.perform_now(@room, @game_prompt.id + 999)
    end
    assert_not move_called
  end

  test "SelectWinnerService is called before move_to_results" do
    call_order = []
    SelectWinnerService.stub_any_instance(:call, proc { call_order << :select_winner }) do
      GamePhasesService.stub_any_instance(:move_to_results, proc { call_order << :move_to_results }) do
        VotingTimesUpJob.perform_now(@room, @game_prompt.id)
      end
    end

    assert_equal [ :select_winner, :move_to_results ], call_order
  end
end

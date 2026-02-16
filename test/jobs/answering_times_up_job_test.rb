require "test_helper"

class AnsweringTimesUpJobTest < ActiveSupport::TestCase
  def setup
    suffix = SecureRandom.hex(4)

    Turbo::StreamsChannel.define_singleton_method(:broadcast_replace_to) { |*| }
    Turbo::StreamsChannel.define_singleton_method(:broadcast_action_to) { |*| }

    @room = Room.create!(code: "at#{suffix}", status: RoomStatus::Answering)
    @story = Story.create!(title: "ATU #{suffix}", text: "test", original_text: "test", published: true)
    @game = Game.create!(story: @story, room: @room)
    @blank = Blank.create!(story: @story, tags: "noun")
    @prompt = Prompt.create!(description: "ATU prompt #{suffix}", tags: "noun")
    @game_prompt = GamePrompt.create!(game: @game, prompt: @prompt, blank: @blank, order: 0)
    @room.update!(current_game: @game)
    @game.update!(current_game_prompt: @game_prompt)
  end

  test "calls move_to_voting when status is Answering and game_prompt_id matches" do
    move_called = false
    GamePhasesService.stub_any_instance(:move_to_voting, proc { move_called = true }) do
      AnsweringTimesUpJob.perform_now(@room, @game_prompt.id)
    end
    assert move_called
  end

  test "does nothing when room status is not Answering" do
    @room.update!(status: RoomStatus::Voting)

    move_called = false
    GamePhasesService.stub_any_instance(:move_to_voting, proc { move_called = true }) do
      AnsweringTimesUpJob.perform_now(@room, @game_prompt.id)
    end
    assert_not move_called
  end

  test "does nothing when game_prompt_id does not match current" do
    move_called = false
    GamePhasesService.stub_any_instance(:move_to_voting, proc { move_called = true }) do
      AnsweringTimesUpJob.perform_now(@room, @game_prompt.id + 999)
    end
    assert_not move_called
  end
end

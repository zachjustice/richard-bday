require "test_helper"

class AnswerSubmittedJobTest < ActiveSupport::TestCase
  def setup
    suffix = SecureRandom.hex(4)

    # Stub broadcasts to prevent ActionCable errors
    Turbo::StreamsChannel.define_singleton_method(:broadcast_replace_to) { |*| }
    Turbo::StreamsChannel.define_singleton_method(:broadcast_action_to) { |*| }
    Turbo::StreamsChannel.define_singleton_method(:broadcast_append_to) { |*| }
    Turbo::StreamsChannel.define_singleton_method(:broadcast_remove_to) { |*| }

    @room = Room.create!(code: "as#{suffix}", status: RoomStatus::Answering)
    @story = Story.create!(title: "ASJ #{suffix}", text: "test", original_text: "test", published: true)
    @game = Game.create!(story: @story, room: @room)
    @blank = Blank.create!(story: @story, tags: "noun")
    @prompt = Prompt.create!(description: "ASJ prompt #{suffix}", tags: "noun")
    @game_prompt = GamePrompt.create!(game: @game, prompt: @prompt, blank: @blank, order: 0)
    @room.update!(current_game: @game)
    @game.update!(current_game_prompt: @game_prompt)

    @user1 = User.create!(name: "AS1#{suffix}", room: @room, role: User::PLAYER, status: UserStatus::Answering)
    @user2 = User.create!(name: "AS2#{suffix}", room: @room, role: User::PLAYER, status: UserStatus::Answering)

    @answer1 = Answer.create!(game_prompt: @game_prompt, game: @game, user: @user1, text: "hello")
  end

  test "returns early when room status is not Answering" do
    @room.update!(status: RoomStatus::Voting)

    AnswerSubmittedJob.perform_now(@answer1)

    @user1.reload
    assert_not_equal UserStatus::Answered, @user1.status
  end

  test "returns early when game_prompt has changed" do
    blank2 = Blank.create!(story: @story, tags: "adj")
    prompt2 = Prompt.create!(description: "ASJ prompt2 #{SecureRandom.hex(4)}", tags: "adj")
    gp2 = GamePrompt.create!(game: @game, prompt: prompt2, blank: blank2, order: 1)
    @game.update!(current_game_prompt: gp2)

    AnswerSubmittedJob.perform_now(@answer1)

    @user1.reload
    assert_not_equal UserStatus::Answered, @user1.status
  end

  test "updates user status to Answered" do
    AnswerSubmittedJob.perform_now(@answer1)

    @user1.reload
    assert_equal UserStatus::Answered, @user1.status
  end

  test "calls move_to_voting when all players have answered" do
    @user1.update!(status: UserStatus::Answered)
    answer2 = Answer.create!(game_prompt: @game_prompt, game: @game, user: @user2, text: "world")

    move_called = false
    GamePhasesService.stub_any_instance(:move_to_voting, proc { move_called = true }) do
      AnswerSubmittedJob.perform_now(answer2)
    end
    assert move_called
  end

  test "does not call move_to_voting when not all players answered" do
    move_called = false
    GamePhasesService.stub_any_instance(:move_to_voting, proc { move_called = true }) do
      AnswerSubmittedJob.perform_now(@answer1)
    end
    assert_not move_called
  end
end

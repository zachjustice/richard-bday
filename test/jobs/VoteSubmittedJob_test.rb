require "test_helper"

class VoteSubmittedJobTest < ActiveSupport::TestCase
  def setup
    suffix = SecureRandom.hex(4)

    # Stub broadcasts to prevent ActionCable errors
    Turbo::StreamsChannel.define_singleton_method(:broadcast_replace_to) { |*| }
    Turbo::StreamsChannel.define_singleton_method(:broadcast_action_to) { |*| }
    Turbo::StreamsChannel.define_singleton_method(:broadcast_append_to) { |*| }
    Turbo::StreamsChannel.define_singleton_method(:broadcast_remove_to) { |*| }

    @room = Room.create!(code: "vs#{suffix}", status: RoomStatus::Voting, voting_style: "vote_once")
    @story = Story.create!(title: "VSJ #{suffix}", text: "test", original_text: "test", published: true)
    @game = Game.create!(story: @story, room: @room)
    @blank = Blank.create!(story: @story, tags: "noun")
    @prompt = Prompt.create!(description: "VSJ prompt #{suffix}", tags: "noun")
    @game_prompt = GamePrompt.create!(game: @game, prompt: @prompt, blank: @blank, order: 0)
    @room.update!(current_game: @game)
    @game.update!(current_game_prompt: @game_prompt)

    @user1 = User.create!(name: "VS1#{suffix}", room: @room, role: User::PLAYER, status: UserStatus::Voting)
    @user2 = User.create!(name: "VS2#{suffix}", room: @room, role: User::PLAYER, status: UserStatus::Voting)

    @answer1 = Answer.create!(game_prompt: @game_prompt, game: @game, user: @user1, text: "alpha")
    @answer2 = Answer.create!(game_prompt: @game_prompt, game: @game, user: @user2, text: "bravo")
  end

  test "returns early when room status is not Voting" do
    @room.update!(status: RoomStatus::Answering)
    vote = Vote.create!(user: @user1, answer: @answer2, game: @game, game_prompt: @game_prompt)

    VoteSubmittedJob.perform_now(vote)

    @user1.reload
    assert_not_equal UserStatus::Voted, @user1.status
  end

  test "returns early when game_prompt has changed" do
    blank2 = Blank.create!(story: @story, tags: "adj")
    prompt2 = Prompt.create!(description: "VSJ prompt2 #{SecureRandom.hex(4)}", tags: "adj")
    gp2 = GamePrompt.create!(game: @game, prompt: prompt2, blank: blank2, order: 1)
    @game.update!(current_game_prompt: gp2)

    vote = Vote.create!(user: @user1, answer: @answer2, game: @game, game_prompt: @game_prompt)

    VoteSubmittedJob.perform_now(vote)

    @user1.reload
    assert_not_equal UserStatus::Voted, @user1.status
  end

  test "updates user status to Voted for vote_once style" do
    vote = Vote.create!(user: @user1, answer: @answer2, game: @game, game_prompt: @game_prompt)

    VoteSubmittedJob.perform_now(vote)

    @user1.reload
    assert_equal UserStatus::Voted, @user1.status
  end

  test "calls move_to_results when all players have voted" do
    @user1.update!(status: UserStatus::Voted)
    vote = Vote.create!(user: @user2, answer: @answer1, game: @game, game_prompt: @game_prompt)

    move_called = false
    GamePhasesService.stub_any_instance(:move_to_results, proc { move_called = true }) do
      VoteSubmittedJob.perform_now(vote)
    end
    assert move_called
  end

  test "does not call move_to_results when not all players voted" do
    vote = Vote.create!(user: @user1, answer: @answer2, game: @game, game_prompt: @game_prompt)

    move_called = false
    GamePhasesService.stub_any_instance(:move_to_results, proc { move_called = true }) do
      VoteSubmittedJob.perform_now(vote)
    end
    assert_not move_called
  end

  test "does not mark user as Voted until all ranks submitted for ranked_top_3" do
    @room.update!(voting_style: "ranked_top_3")
    # Add a 3rd user/answer so there are 2 other answers (user1 can vote on answer2 and answer3)
    user3 = User.create!(name: "VS3#{SecureRandom.hex(4)}", room: @room, role: User::PLAYER, status: UserStatus::Voting)
    answer3 = Answer.create!(game_prompt: @game_prompt, game: @game, user: user3, text: "charlie")

    # user1 has 2 other answers to rank, max_ranks is 3, so required_ranks = min(2, 3) = 2
    # Submit only rank 1 — should NOT be marked as Voted
    vote1 = Vote.create!(user: @user1, answer: @answer2, game: @game, game_prompt: @game_prompt, rank: 1)

    VoteSubmittedJob.perform_now(vote1)

    @user1.reload
    assert_not_equal UserStatus::Voted, @user1.status

    # Submit rank 2 — now all required ranks are in, should be marked Voted
    vote2 = Vote.create!(user: @user1, answer: answer3, game: @game, game_prompt: @game_prompt, rank: 2)

    VoteSubmittedJob.perform_now(vote2)

    @user1.reload
    assert_equal UserStatus::Voted, @user1.status
  end
end

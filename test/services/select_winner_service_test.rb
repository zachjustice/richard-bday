# frozen_string_literal: true

require "test_helper"

class SelectWinnerServiceTest < ActiveSupport::TestCase
  setup do
    @room = rooms(:one)
    @game = games(:one)
    @game_prompt = game_prompts(:one)

    @room.update!(status: RoomStatus::Voting, current_game: @game)
    @game.update!(current_game_prompt: @game_prompt)

    # Create a creator user for the room (needed for default answer fallback)
    @creator = User.create!(name: "Creator-test", room: @room, role: User::CREATOR, avatar: User::CREATOR_AVATAR)

    # Create player users with unique avatars
    @player1 = User.create!(name: "Player1", room: @room, role: User::PLAYER, avatar: User.available_avatars(@room.id).first)
    @player2 = User.create!(name: "Player2", room: @room, role: User::PLAYER, avatar: User.available_avatars(@room.id).first)

    # Clear fixture answers so tests have a known starting state
    Answer.where(game_prompt: @game_prompt).destroy_all

    # Create answers for the game prompt
    @answer1 = Answer.create!(game_prompt: @game_prompt, game: @game, user: @player1, text: "Answer 1")
    @answer2 = Answer.create!(game_prompt: @game_prompt, game: @game, user: @player2, text: "Answer 2")
  end

  test "selects winner by most votes" do
    # Player2's answer gets more votes
    Vote.create!(user: @player1, answer: @answer2, game: @game, game_prompt: @game_prompt, vote_type: "player", rank: 1)

    SelectWinnerService.new(@game_prompt, @room).call

    assert @answer2.reload.won?
    assert_not @answer1.reload.won?
  end

  test "selects a winner when tied (picks one of the candidates)" do
    # Both answers get equal votes -- each player votes for the other
    Vote.create!(user: @player1, answer: @answer2, game: @game, game_prompt: @game_prompt, vote_type: "player", rank: 1)
    Vote.create!(user: @player2, answer: @answer1, game: @game, game_prompt: @game_prompt, vote_type: "player", rank: 1)

    SelectWinnerService.new(@game_prompt, @room).call

    winners = Answer.where(game_prompt: @game_prompt, won: true)
    assert_equal 1, winners.count
    assert_includes [ @answer1.id, @answer2.id ], winners.first.id
  end

  test "picks a random answer when no votes exist but answers do" do
    # Answers exist but no votes -- picks a random answer
    SelectWinnerService.new(@game_prompt, @room).call

    winner = Answer.find_by(game_prompt: @game_prompt, won: true)
    assert_not_nil winner
    assert_includes [ @answer1.id, @answer2.id ], winner.id
  end

  test "creates default answer when no answers and no votes exist" do
    Answer.where(game_prompt: @game_prompt).destroy_all

    SelectWinnerService.new(@game_prompt, @room).call

    winner = Answer.find_by(game_prompt: @game_prompt, won: true)
    assert_not_nil winner
    assert_equal Answer::DEFAULT_ANSWER, winner.text
    assert_equal @creator.id, winner.user_id
  end

  test "is idempotent -- does not change already-selected winner" do
    @answer1.update!(won: true)

    SelectWinnerService.new(@game_prompt, @room).call

    assert @answer1.reload.won?
    assert_not @answer2.reload.won?
    # Only one winner
    assert_equal 1, Answer.where(game_prompt: @game_prompt, won: true).count
  end

  test "ignores audience votes when selecting winner" do
    audience_user = User.create!(name: "AudienceVoter", room: @room, role: User::AUDIENCE, avatar: User::AUDIENCE_AVATAR)

    # Audience gives stars to answer1, but player votes for answer2
    Vote.create!(user: audience_user, answer: @answer1, game: @game, game_prompt: @game_prompt, vote_type: "audience")
    Vote.create!(user: @player1, answer: @answer2, game: @game, game_prompt: @game_prompt, vote_type: "player", rank: 1)

    SelectWinnerService.new(@game_prompt, @room).call

    assert @answer2.reload.won?
    assert_not @answer1.reload.won?
  end
end

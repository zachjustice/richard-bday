require "test_helper"

class VoteTest < ActiveSupport::TestCase
  def setup
    suffix = SecureRandom.hex(4)

    # Stub broadcasts to prevent ActionCable errors from after_commit callbacks
    Turbo::StreamsChannel.define_singleton_method(:broadcast_replace_to) { |*| }
    Turbo::StreamsChannel.define_singleton_method(:broadcast_action_to) { |*| }
    Turbo::StreamsChannel.define_singleton_method(:broadcast_append_to) { |*| }
    Turbo::StreamsChannel.define_singleton_method(:broadcast_remove_to) { |*| }

    @room = Room.create!(code: "vt#{suffix}", status: RoomStatus::WaitingRoom)
    @story = Story.create!(title: "VoteTest #{suffix}", text: "test", original_text: "test", published: true)
    @game = Game.create!(story: @story, room: @room)
    @blank = Blank.create!(story: @story, tags: "noun")
    @editor = Editor.create!(username: "vt#{suffix}", email: "vt#{suffix}@test.com", password: "password123", password_confirmation: "password123")
    @prompt = Prompt.create!(description: "Vote test prompt #{suffix}", tags: "noun", creator: @editor)
    @game_prompt = GamePrompt.create!(game: @game, prompt: @prompt, blank: @blank, order: 0)
    @room.update!(current_game: @game)
    @game.update!(current_game_prompt: @game_prompt)

    @user1 = User.create!(name: "VU1#{suffix}", room: @room, role: User::PLAYER)
    @user2 = User.create!(name: "VU2#{suffix}", room: @room, role: User::PLAYER)

    @answer1 = Answer.create!(game_prompt: @game_prompt, game: @game, user: @user1, text: "answer1")
    @answer2 = Answer.create!(game_prompt: @game_prompt, game: @game, user: @user2, text: "answer2")
  end

  test "points returns 1 for vote_once room" do
    @room.update!(voting_style: "vote_once")
    vote = Vote.create!(user: @user1, answer: @answer2, game: @game, game_prompt: @game_prompt)
    assert_equal 1, vote.points
  end

  test "points returns rank-based points for ranked_top_3" do
    @room.update!(voting_style: "ranked_top_3")

    vote_rank1 = Vote.create!(user: @user1, answer: @answer2, game: @game, game_prompt: @game_prompt, rank: 1)
    assert_equal 30, vote_rank1.points

    vote_rank2 = Vote.create!(user: @user2, answer: @answer1, game: @game, game_prompt: @game_prompt, rank: 2)
    assert_equal 20, vote_rank2.points
  end

  test "points returns 0 for rank beyond top 3 in ranked_top_3" do
    @room.update!(voting_style: "ranked_top_3")
    vote = Vote.create!(user: @user1, answer: @answer2, game: @game, game_prompt: @game_prompt, rank: 4)
    assert_equal 0, vote.points
  end

  test "rank validation allows nil" do
    vote = Vote.new(user: @user1, answer: @answer2, game: @game, game_prompt: @game_prompt, rank: nil)
    assert vote.valid?
  end

  test "rank validation requires positive integer" do
    base = { user: @user1, answer: @answer2, game: @game, game_prompt: @game_prompt }

    vote_zero = Vote.new(**base, rank: 0)
    assert_not vote_zero.valid?

    vote_neg = Vote.new(**base, rank: -1)
    assert_not vote_neg.valid?

    vote_pos = Vote.new(**base, rank: 1)
    assert vote_pos.valid?
  end

  # --- Audience vote tests ---

  test "by_players scope returns only player votes" do
    suffix = SecureRandom.hex(4)
    audience_user = User.create!(name: "AU#{suffix}", room: @room, role: User::AUDIENCE)

    player_vote = Vote.create!(user: @user1, answer: @answer2, game: @game, game_prompt: @game_prompt, vote_type: "player")
    audience_vote = Vote.create!(user: audience_user, answer: @answer2, game: @game, game_prompt: @game_prompt, vote_type: "audience")

    player_votes = Vote.by_players
    assert_includes player_votes, player_vote
    assert_not_includes player_votes, audience_vote
  end

  test "by_audience scope returns only audience votes" do
    suffix = SecureRandom.hex(4)
    audience_user = User.create!(name: "AU#{suffix}", room: @room, role: User::AUDIENCE)

    player_vote = Vote.create!(user: @user1, answer: @answer2, game: @game, game_prompt: @game_prompt, vote_type: "player")
    audience_vote = Vote.create!(user: audience_user, answer: @answer2, game: @game, game_prompt: @game_prompt, vote_type: "audience")

    audience_votes = Vote.by_audience
    assert_includes audience_votes, audience_vote
    assert_not_includes audience_votes, player_vote
  end

  test "audience? returns true for audience vote_type" do
    suffix = SecureRandom.hex(4)
    audience_user = User.create!(name: "AU#{suffix}", room: @room, role: User::AUDIENCE)
    vote = Vote.create!(user: audience_user, answer: @answer2, game: @game, game_prompt: @game_prompt, vote_type: "audience")
    assert vote.audience?
  end

  test "audience? returns false for player vote_type" do
    vote = Vote.create!(user: @user1, answer: @answer2, game: @game, game_prompt: @game_prompt, vote_type: "player")
    assert_not vote.audience?
  end

  test "player? returns true for player vote_type" do
    vote = Vote.create!(user: @user1, answer: @answer2, game: @game, game_prompt: @game_prompt, vote_type: "player")
    assert vote.player?
  end

  test "player? returns false for audience vote_type" do
    suffix = SecureRandom.hex(4)
    audience_user = User.create!(name: "AU#{suffix}", room: @room, role: User::AUDIENCE)
    vote = Vote.create!(user: audience_user, answer: @answer2, game: @game, game_prompt: @game_prompt, vote_type: "audience")
    assert_not vote.player?
  end

  test "points returns 0 for audience votes" do
    suffix = SecureRandom.hex(4)
    audience_user = User.create!(name: "AU#{suffix}", room: @room, role: User::AUDIENCE)
    vote = Vote.create!(user: audience_user, answer: @answer2, game: @game, game_prompt: @game_prompt, vote_type: "audience")
    assert_equal 0, vote.points
  end

  test "vote_type validation rejects invalid values" do
    vote = Vote.new(user: @user1, answer: @answer2, game: @game, game_prompt: @game_prompt, vote_type: "invalid")
    assert_not vote.valid?
    assert vote.errors[:vote_type].any?
  end
end

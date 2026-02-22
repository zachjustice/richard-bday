require "test_helper"

class CreditsServiceTest < ActiveSupport::TestCase
  def setup
    suffix = SecureRandom.hex(4)

    # Stub broadcasts to prevent ActionCable errors from after_commit callbacks
    Turbo::StreamsChannel.define_singleton_method(:broadcast_replace_to) { |*| }
    Turbo::StreamsChannel.define_singleton_method(:broadcast_action_to) { |*| }
    Turbo::StreamsChannel.define_singleton_method(:broadcast_append_to) { |*| }
    Turbo::StreamsChannel.define_singleton_method(:broadcast_remove_to) { |*| }

    @room = Room.create!(code: "cs#{suffix}", status: RoomStatus::Credits, voting_style: "vote_once")
    @story = Story.create!(title: "Credits #{suffix}", text: "test", original_text: "test", published: true)
    @game = Game.create!(story: @story, room: @room)
    @blank1 = Blank.create!(story: @story, tags: "noun")
    @blank2 = Blank.create!(story: @story, tags: "adj")
    @editor = Editor.create!(username: "cs#{suffix}", email: "cs#{suffix}@test.com", password: "password123", password_confirmation: "password123")
    @prompt1 = Prompt.create!(description: "Credits prompt1 #{suffix}", tags: "noun", creator: @editor)
    @prompt2 = Prompt.create!(description: "Credits prompt2 #{suffix}", tags: "adj", creator: @editor)
    @gp1 = GamePrompt.create!(game: @game, prompt: @prompt1, blank: @blank1, order: 0)
    @gp2 = GamePrompt.create!(game: @game, prompt: @prompt2, blank: @blank2, order: 1)
    @room.update!(current_game: @game)
    @game.update!(current_game_prompt: @gp1)

    @user_a = User.create!(name: "CA#{suffix}", room: @room, role: User::PLAYER)
    @user_b = User.create!(name: "CB#{suffix}", room: @room, role: User::PLAYER)
    @user_c = User.create!(name: "CC#{suffix}", room: @room, role: User::PLAYER)
  end

  # --- Podium ---

  test "calculate_podium returns top 3 by received vote points" do
    a1 = Answer.create!(game_prompt: @gp1, game: @game, user: @user_a, text: "x")
    a2 = Answer.create!(game_prompt: @gp1, game: @game, user: @user_b, text: "y")
    a3 = Answer.create!(game_prompt: @gp1, game: @game, user: @user_c, text: "z")

    # user_a's answer gets 2 votes, user_b's gets 1, user_c gets 0
    Vote.create!(user: @user_b, answer: a1, game: @game, game_prompt: @gp1)
    Vote.create!(user: @user_c, answer: a1, game: @game, game_prompt: @gp1)
    Vote.create!(user: @user_a, answer: a2, game: @game, game_prompt: @gp1)

    result = CreditsService.new(@game).call
    podium = result[:podium]

    assert_equal 2, podium.length
    assert_equal @user_a, podium[0][:user]
    assert_equal 2, podium[0][:points]
    assert_equal @user_b, podium[1][:user]
    assert_equal 1, podium[1][:points]
  end

  test "calculate_podium returns empty array when no votes" do
    Answer.create!(game_prompt: @gp1, game: @game, user: @user_a, text: "x")

    result = CreditsService.new(@game).call
    assert_equal [], result[:podium]
  end

  # --- Swear words ---

  test "most_swear_words returns user with highest profanity count" do
    Answer.create!(game_prompt: @gp1, game: @game, user: @user_a, text: "fuck shit damn")
    Answer.create!(game_prompt: @gp1, game: @game, user: @user_b, text: "hello world")

    result = CreditsService.new(@game).call
    assert_equal @user_a, result[:most_swear_words][:user]
    assert_equal 3, result[:most_swear_words][:count]
  end

  test "most_swear_words returns nil when no profanity" do
    Answer.create!(game_prompt: @gp1, game: @game, user: @user_a, text: "hello world")

    result = CreditsService.new(@game).call
    assert_nil result[:most_swear_words]
  end

  # --- Characters ---

  test "most_characters returns user with most total characters" do
    Answer.create!(game_prompt: @gp1, game: @game, user: @user_a, text: "abc")
    Answer.create!(game_prompt: @gp1, game: @game, user: @user_b, text: "abcdefghij")

    result = CreditsService.new(@game).call
    assert_equal @user_b, result[:most_characters][:user]
    assert_equal 10, result[:most_characters][:count]
  end

  # --- Efficiency ---

  test "best_efficiency returns user with highest points-per-character ratio" do
    # user_a: 2 chars, receives 2 vote points (ratio 1.0)
    # user_b: 10 chars, receives 1 vote point (ratio 0.1)
    a1 = Answer.create!(game_prompt: @gp1, game: @game, user: @user_a, text: "ab")
    a2 = Answer.create!(game_prompt: @gp1, game: @game, user: @user_b, text: "abcdefghij")

    Vote.create!(user: @user_b, answer: a1, game: @game, game_prompt: @gp1)
    Vote.create!(user: @user_c, answer: a1, game: @game, game_prompt: @gp1)
    Vote.create!(user: @user_a, answer: a2, game: @game, game_prompt: @gp1)

    result = CreditsService.new(@game).call
    assert_equal @user_a, result[:best_efficiency][:user]
    assert_equal 1.0, result[:best_efficiency][:ratio]
  end

  test "best_efficiency excludes users with zero points" do
    a1 = Answer.create!(game_prompt: @gp1, game: @game, user: @user_a, text: "ab")
    a2 = Answer.create!(game_prompt: @gp1, game: @game, user: @user_b, text: "abcdefghij")

    # Only user_b gets votes
    Vote.create!(user: @user_a, answer: a2, game: @game, game_prompt: @gp1)

    result = CreditsService.new(@game).call
    assert_equal @user_b, result[:best_efficiency][:user]
  end

  test "best_efficiency returns nil when no users have points" do
    Answer.create!(game_prompt: @gp1, game: @game, user: @user_a, text: "hello")

    result = CreditsService.new(@game).call
    assert_nil result[:best_efficiency]
  end

  test "best_efficiency handles zero-length answer gracefully" do
    a1 = Answer.create!(game_prompt: @gp1, game: @game, user: @user_a, text: "")
    a2 = Answer.create!(game_prompt: @gp1, game: @game, user: @user_b, text: "hello")

    Vote.create!(user: @user_b, answer: a1, game: @game, game_prompt: @gp1)
    Vote.create!(user: @user_a, answer: a2, game: @game, game_prompt: @gp1)

    # Should not raise, user_b should win since user_a has 0 chars (ratio = 0)
    result = CreditsService.new(@game).call
    assert_not_nil result[:best_efficiency]
  end

  # --- Spelling ---

  test "most_spelling_mistakes counts words not in dictionary" do
    Answer.create!(game_prompt: @gp1, game: @game, user: @user_a, text: "xyznotaword anothernotaword")
    Answer.create!(game_prompt: @gp1, game: @game, user: @user_b, text: "hello world")

    result = CreditsService.new(@game).call
    assert_equal @user_a, result[:most_spelling_mistakes][:user]
    assert_equal 2, result[:most_spelling_mistakes][:count]
  end

  test "most_spelling_mistakes skips short and ALL_CAPS words" do
    Answer.create!(game_prompt: @gp1, game: @game, user: @user_a, text: "NASA FBI xz qw xyznotaword")

    result = CreditsService.new(@game).call
    # Only "xyznotaword" should count — "NASA", "FBI" are all caps, "xz", "qw" are <=2 chars
    assert_equal 1, result[:most_spelling_mistakes][:count]
  end

  test "most_spelling_mistakes returns nil when no mistakes" do
    Answer.create!(game_prompt: @gp1, game: @game, user: @user_a, text: "hello world")

    result = CreditsService.new(@game).call
    assert_nil result[:most_spelling_mistakes]
  end

  # --- Slowest player ---

  test "slowest_player returns user with highest avg submission percentile" do
    # User A always submits first, User B always submits last
    Answer.create!(game_prompt: @gp1, game: @game, user: @user_a, text: "fast", created_at: 1.minute.ago)
    Answer.create!(game_prompt: @gp1, game: @game, user: @user_b, text: "slow", created_at: Time.current)

    Answer.create!(game_prompt: @gp2, game: @game, user: @user_a, text: "fast2", created_at: 1.minute.ago)
    Answer.create!(game_prompt: @gp2, game: @game, user: @user_b, text: "slow2", created_at: Time.current)

    result = CreditsService.new(@game).call
    assert_equal @user_b, result[:slowest_player][:user]
    assert_equal 100, result[:slowest_player][:avg_percentile]
  end

  test "slowest_player returns 50 percentile for single submission per prompt" do
    Answer.create!(game_prompt: @gp1, game: @game, user: @user_a, text: "alone")

    result = CreditsService.new(@game).call
    assert_equal 50, result[:slowest_player][:avg_percentile]
  end

  test "slowest_player returns nil when no answers" do
    result = CreditsService.new(@game).call
    assert_nil result[:slowest_player]
  end

  # --- Audience favorite ---

  test "audience_favorite returns player with most audience kudos across game" do
    audience_user = User.create!(name: "AUD#{SecureRandom.hex(4)}", room: @room, role: User::AUDIENCE)
    a1 = Answer.create!(game_prompt: @gp1, game: @game, user: @user_a, text: "x")
    a2 = Answer.create!(game_prompt: @gp1, game: @game, user: @user_b, text: "y")
    a3 = Answer.create!(game_prompt: @gp2, game: @game, user: @user_a, text: "x2")

    # 2 audience kudos for user_a (via a1 and a3), 1 for user_b (via a2)
    Vote.create!(user: audience_user, answer: a1, game: @game, game_prompt: @gp1, vote_type: "audience")
    Vote.create!(user: audience_user, answer: a3, game: @game, game_prompt: @gp2, vote_type: "audience")
    Vote.create!(user: audience_user, answer: a2, game: @game, game_prompt: @gp1, vote_type: "audience")

    result = CreditsService.new(@game).call
    assert_equal @user_a, result[:audience_favorite][:user]
    assert_equal 2, result[:audience_favorite][:count]
  end

  test "audience_favorite returns nil when no audience votes" do
    Answer.create!(game_prompt: @gp1, game: @game, user: @user_a, text: "x")

    result = CreditsService.new(@game).call
    assert_nil result[:audience_favorite]
  end

  test "podium excludes audience votes from point calculations" do
    audience_user = User.create!(name: "AUD#{SecureRandom.hex(4)}", room: @room, role: User::AUDIENCE)
    a1 = Answer.create!(game_prompt: @gp1, game: @game, user: @user_a, text: "x")
    a2 = Answer.create!(game_prompt: @gp1, game: @game, user: @user_b, text: "y")

    # 1 player vote for user_b's answer
    Vote.create!(user: @user_a, answer: a2, game: @game, game_prompt: @gp1, vote_type: "player")
    # 3 audience votes for user_a's answer (should not count)
    Vote.create!(user: audience_user, answer: a1, game: @game, game_prompt: @gp1, vote_type: "audience")
    Vote.create!(user: audience_user, answer: a1, game: @game, game_prompt: @gp1, vote_type: "audience")
    Vote.create!(user: audience_user, answer: a1, game: @game, game_prompt: @gp1, vote_type: "audience")

    result = CreditsService.new(@game).call
    podium = result[:podium]

    assert_equal 1, podium.length
    assert_equal @user_b, podium[0][:user]
  end

  test "slowest_player excludes audience votes from percentile calculation" do
    audience_user = User.create!(name: "AUD#{SecureRandom.hex(4)}", room: @room, role: User::AUDIENCE)
    # user_a submits first, user_b second
    a1 = Answer.create!(game_prompt: @gp1, game: @game, user: @user_a, text: "fast", created_at: 2.minutes.ago)
    Answer.create!(game_prompt: @gp1, game: @game, user: @user_b, text: "slow", created_at: 1.minute.ago)

    # Audience vote submitted much later - should not affect slowest_player
    Vote.create!(user: audience_user, answer: a1, game: @game, game_prompt: @gp1, vote_type: "audience", created_at: Time.current)

    result = CreditsService.new(@game).call
    # user_b should still be slowest (100th percentile)
    assert_equal @user_b, result[:slowest_player][:user]
    assert_equal 100, result[:slowest_player][:avg_percentile]
  end
end

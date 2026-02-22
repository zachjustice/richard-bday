require "test_helper"

class GameTest < ActiveSupport::TestCase
  test "last_round_accolades returns nil IDs when no rounds completed" do
    game = games(:one)

    result = game.last_round_accolades

    assert_nil result[:winner_user_id]
    assert_nil result[:audience_favorite_user_id]
  end

  test "last_round_accolades returns correct winner after one round" do
    game = games(:one)
    answer = answers(:one)
    answer.update!(won: true)

    result = game.last_round_accolades

    assert_equal answer.user_id, result[:winner_user_id]
    assert_nil result[:audience_favorite_user_id]
  end

  test "last_round_accolades returns most recent winner across multiple rounds" do
    game = games(:one)
    # Mark first round winner
    answers(:one).update!(won: true)
    # Mark second round winner
    answers(:two).update!(won: true)

    result = game.last_round_accolades

    # answer :two belongs to game_prompt :two which has order=1 (higher)
    assert_equal users(:two).id, result[:winner_user_id]
  end

  test "last_round_accolades returns audience favorite alongside winner" do
    game = games(:one)
    winning_answer = answers(:one)
    winning_answer.update!(won: true)

    # Create a second answer on the same game_prompt for audience voting
    other_answer = Answer.create!(
      game_prompt: game_prompts(:one),
      game: game,
      user: users(:two),
      text: "Other answer"
    )

    # Cast audience votes for the other answer
    Vote.create!(
      user: users(:two),
      answer: other_answer,
      game: game,
      game_prompt: game_prompts(:one),
      vote_type: "audience"
    )

    result = game.last_round_accolades

    assert_equal users(:one).id, result[:winner_user_id]
    assert_equal users(:two).id, result[:audience_favorite_user_id]
  end

  test "last_round_accolades handles same user winning both" do
    game = games(:one)
    winning_answer = answers(:one)
    winning_answer.update!(won: true)

    # Cast audience votes for the winning answer (same user)
    Vote.create!(
      user: users(:two),
      answer: winning_answer,
      game: game,
      game_prompt: game_prompts(:one),
      vote_type: "audience"
    )

    result = game.last_round_accolades

    assert_equal users(:one).id, result[:winner_user_id]
    assert_equal users(:one).id, result[:audience_favorite_user_id]
  end

  # ── credits_accolades ──

  test "credits_accolades returns empty hash when no answers" do
    suffix = SecureRandom.hex(4)
    room = Room.create!(code: "c0#{suffix}", status: RoomStatus::Credits, voting_style: "vote_once")
    story = Story.create!(title: "C0 #{suffix}", text: "test", original_text: "test", published: true)
    game = Game.create!(story: story, room: room)
    room.update!(current_game: game)

    result = game.credits_accolades
    assert_equal({}, result)
  end

  test "credits_accolades returns podium tags for top scorers" do
    suffix = SecureRandom.hex(4)
    room = Room.create!(code: "ca#{suffix}", status: RoomStatus::Credits, voting_style: "vote_once")
    story = Story.create!(title: "CA #{suffix}", text: "test", original_text: "test", published: true)
    game = Game.create!(story: story, room: room)
    blank = Blank.create!(story: story, tags: "noun")
    editor = Editor.create!(username: "ca#{suffix}", email: "ca#{suffix}@test.com", password: "password123", password_confirmation: "password123")
    prompt = Prompt.create!(description: "CA prompt #{suffix}", tags: "noun", creator: editor)
    gp = GamePrompt.create!(game: game, prompt: prompt, blank: blank, order: 0)
    room.update!(current_game: game)

    user_a = User.create!(name: "A#{suffix}", room: room, role: User::PLAYER)
    user_b = User.create!(name: "B#{suffix}", room: room, role: User::PLAYER)
    user_c = User.create!(name: "C#{suffix}", room: room, role: User::PLAYER)

    a1 = Answer.create!(game_prompt: gp, game: game, user: user_a, text: "x")
    a2 = Answer.create!(game_prompt: gp, game: game, user: user_b, text: "y")
    a3 = Answer.create!(game_prompt: gp, game: game, user: user_c, text: "z")

    # user_a gets 2 votes, user_b gets 1, user_c gets 0
    Vote.create!(user: user_b, answer: a1, game: game, game_prompt: gp)
    Vote.create!(user: user_c, answer: a1, game: game, game_prompt: gp)
    Vote.create!(user: user_a, answer: a2, game: game, game_prompt: gp)

    result = game.credits_accolades

    assert_includes result[user_a.id], "podium_1st"
    assert_includes result[user_b.id], "podium_2nd"
    # user_c has no podium rank (0 votes) but may have superlative tags
    refute_includes(result[user_c.id] || "", "podium_")
  end

  test "credits_accolades returns superlative tags" do
    suffix = SecureRandom.hex(4)
    room = Room.create!(code: "cb#{suffix}", status: RoomStatus::Credits, voting_style: "vote_once")
    story = Story.create!(title: "CB #{suffix}", text: "test", original_text: "test", published: true)
    game = Game.create!(story: story, room: room)
    blank = Blank.create!(story: story, tags: "noun")
    editor = Editor.create!(username: "cb#{suffix}", email: "cb#{suffix}@test.com", password: "password123", password_confirmation: "password123")
    prompt = Prompt.create!(description: "CB prompt #{suffix}", tags: "noun", creator: editor)
    gp = GamePrompt.create!(game: game, prompt: prompt, blank: blank, order: 0)
    room.update!(current_game: game)

    user_a = User.create!(name: "A#{suffix}", room: room, role: User::PLAYER)
    user_b = User.create!(name: "B#{suffix}", room: room, role: User::PLAYER)

    # user_b writes way more characters → prolific
    Answer.create!(game_prompt: gp, game: game, user: user_a, text: "hi")
    Answer.create!(game_prompt: gp, game: game, user: user_b, text: "a very long answer indeed")

    result = game.credits_accolades

    assert_includes result[user_b.id], "prolific"
  end

  test "credits_accolades combines podium and superlative tags for same user" do
    suffix = SecureRandom.hex(4)
    room = Room.create!(code: "cc#{suffix}", status: RoomStatus::Credits, voting_style: "vote_once")
    story = Story.create!(title: "CC #{suffix}", text: "test", original_text: "test", published: true)
    game = Game.create!(story: story, room: room)
    blank = Blank.create!(story: story, tags: "noun")
    editor = Editor.create!(username: "cc#{suffix}", email: "cc#{suffix}@test.com", password: "password123", password_confirmation: "password123")
    prompt = Prompt.create!(description: "CC prompt #{suffix}", tags: "noun", creator: editor)
    gp = GamePrompt.create!(game: game, prompt: prompt, blank: blank, order: 0)
    room.update!(current_game: game)

    user_a = User.create!(name: "A#{suffix}", room: room, role: User::PLAYER)
    user_b = User.create!(name: "B#{suffix}", room: room, role: User::PLAYER)

    # user_a: most votes AND most characters → podium_1st + prolific
    a1 = Answer.create!(game_prompt: gp, game: game, user: user_a, text: "a really long winning answer")
    Answer.create!(game_prompt: gp, game: game, user: user_b, text: "short")

    Vote.create!(user: user_b, answer: a1, game: game, game_prompt: gp)

    result = game.credits_accolades

    assert_includes result[user_a.id], "podium_1st"
    assert_includes result[user_a.id], "prolific"
  end

  test "credits_accolades includes audience_fav tag" do
    suffix = SecureRandom.hex(4)
    room = Room.create!(code: "cd#{suffix}", status: RoomStatus::Credits, voting_style: "vote_once")
    story = Story.create!(title: "CD #{suffix}", text: "test", original_text: "test", published: true)
    game = Game.create!(story: story, room: room)
    blank = Blank.create!(story: story, tags: "noun")
    editor = Editor.create!(username: "cd#{suffix}", email: "cd#{suffix}@test.com", password: "password123", password_confirmation: "password123")
    prompt = Prompt.create!(description: "CD prompt #{suffix}", tags: "noun", creator: editor)
    gp = GamePrompt.create!(game: game, prompt: prompt, blank: blank, order: 0)
    room.update!(current_game: game)

    user_a = User.create!(name: "A#{suffix}", room: room, role: User::PLAYER)
    audience = User.create!(name: "AUD#{suffix}", room: room, role: User::AUDIENCE)

    a1 = Answer.create!(game_prompt: gp, game: game, user: user_a, text: "x")
    Vote.create!(user: audience, answer: a1, game: game, game_prompt: gp, vote_type: "audience")

    result = game.credits_accolades

    assert_includes result[user_a.id], "audience_fav"
  end
end

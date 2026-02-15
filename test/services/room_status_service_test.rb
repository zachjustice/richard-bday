require "test_helper"

class RoomStatusServiceTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper
  def setup
    suffix = SecureRandom.hex(4)

    # Stub broadcasts to prevent ActionCable errors
    Turbo::StreamsChannel.define_singleton_method(:broadcast_replace_to) { |*| }
    Turbo::StreamsChannel.define_singleton_method(:broadcast_action_to) { |*| }
    Turbo::StreamsChannel.define_singleton_method(:broadcast_append_to) { |*| }
    Turbo::StreamsChannel.define_singleton_method(:broadcast_remove_to) { |*| }

    @room = Room.create!(code: "rs#{suffix}", status: RoomStatus::Results, voting_style: "vote_once")
    @story = Story.create!(title: "RSS #{suffix}", text: "A {0} story", original_text: "A {0} story", published: true)
    @game = Game.create!(story: @story, room: @room)
    @blank = Blank.create!(story: @story, tags: "noun")
    @editor = Editor.create!(username: "rs#{suffix}", email: "rs#{suffix}@test.com", password: "password123", password_confirmation: "password123")
    @prompt = Prompt.create!(description: "RSS prompt #{suffix}", tags: "noun", creator: @editor)
    @game_prompt = GamePrompt.create!(game: @game, prompt: @prompt, blank: @blank, order: 0)
    @room.update!(current_game: @game)
    @game.update!(current_game_prompt: @game_prompt)

    @creator = User.create!(name: "Creator#{suffix[0..3]}", room: @room, role: User::CREATOR)
    @player1 = User.create!(name: "P1#{suffix}", room: @room, role: User::PLAYER)
    @player2 = User.create!(name: "P2#{suffix}", room: @room, role: User::PLAYER)
    @player3 = User.create!(name: "P3#{suffix}", room: @room, role: User::PLAYER)

    @answer1 = Answer.create!(game_prompt: @game_prompt, game: @game, user: @player1, text: "alpha")
    @answer2 = Answer.create!(game_prompt: @game_prompt, game: @game, user: @player2, text: "bravo")
    @answer3 = Answer.create!(game_prompt: @game_prompt, game: @game, user: @player3, text: "charlie")
  end

  test "picks answer with most vote points as winner" do
    # 2 votes for answer1, 1 for answer2, 0 for answer3
    Vote.create!(user: @player2, answer: @answer1, game: @game, game_prompt: @game_prompt)
    Vote.create!(user: @player3, answer: @answer1, game: @game, game_prompt: @game_prompt)
    Vote.create!(user: @player1, answer: @answer2, game: @game, game_prompt: @game_prompt)

    result = RoomStatusService.new(@room).call

    assert_equal @answer1, result[:winner]
    assert @answer1.reload.won
  end

  test "handles tie by picking one winner" do
    # 1 vote each for answer1 and answer2
    Vote.create!(user: @player2, answer: @answer1, game: @game, game_prompt: @game_prompt)
    Vote.create!(user: @player1, answer: @answer2, game: @game, game_prompt: @game_prompt)

    result = RoomStatusService.new(@room).call

    assert_includes [ @answer1, @answer2 ], result[:winner]
    assert_equal 1, Answer.where(game_prompt: @game_prompt, won: true).count
  end

  test "reuses existing winner on subsequent calls" do
    @answer2.update!(won: true)
    Vote.create!(user: @player2, answer: @answer1, game: @game, game_prompt: @game_prompt)
    Vote.create!(user: @player1, answer: @answer2, game: @game, game_prompt: @game_prompt)

    result = RoomStatusService.new(@room).call

    assert_equal @answer2, result[:winner]
  end

  test "picks a random answer as winner when no votes exist but answers do" do
    result = RoomStatusService.new(@room).call

    winner = result[:winner]
    assert_includes [ @answer1, @answer2, @answer3 ], winner
    assert winner.reload.won
  end

  test "creates default poop answer when no answers and no votes exist" do
    Answer.where(game_prompt: @game_prompt).destroy_all

    result = RoomStatusService.new(@room).call

    winner = result[:winner]
    assert_equal Answer::DEFAULT_ANSWER, winner.text
    assert winner.won
    assert_equal @creator, winner.user
  end

  test "sorts answers by points with winner pinned first" do
    Vote.create!(user: @player2, answer: @answer1, game: @game, game_prompt: @game_prompt)
    Vote.create!(user: @player3, answer: @answer1, game: @game, game_prompt: @game_prompt)
    Vote.create!(user: @player1, answer: @answer2, game: @game, game_prompt: @game_prompt)

    result = RoomStatusService.new(@room).call

    sorted = result[:answers_sorted_by_votes]
    assert_equal result[:winner], sorted.first
  end

  test "calculates points correctly for ranked_top_3" do
    @room.update!(voting_style: "ranked_top_3")

    # player2 ranks: answer1=1st(30), answer3=2nd(20)
    Vote.create!(user: @player2, answer: @answer1, game: @game, game_prompt: @game_prompt, rank: 1)
    Vote.create!(user: @player2, answer: @answer3, game: @game, game_prompt: @game_prompt, rank: 2)
    # player1 ranks: answer2=1st(30)
    Vote.create!(user: @player1, answer: @answer2, game: @game, game_prompt: @game_prompt, rank: 1)

    result = RoomStatusService.new(@room).call

    assert_equal 30, result[:points_by_answer][@answer1.id]
    assert_equal 30, result[:points_by_answer][@answer2.id]
    assert_equal 20, result[:points_by_answer][@answer3.id]
  end

  test "enqueues AnswerSmoothingJob when smooth_answers enabled" do
    @room.update!(smooth_answers: true)
    Vote.create!(user: @player2, answer: @answer1, game: @game, game_prompt: @game_prompt)

    assert_enqueued_with(job: AnswerSmoothingJob) do
      RoomStatusService.new(@room).call
    end
  end
end

class RoomStatusServiceFinalResultsTest < ActiveSupport::TestCase
  def setup
    suffix = SecureRandom.hex(4)

    Turbo::StreamsChannel.define_singleton_method(:broadcast_replace_to) { |*| }
    Turbo::StreamsChannel.define_singleton_method(:broadcast_action_to) { |*| }
    Turbo::StreamsChannel.define_singleton_method(:broadcast_append_to) { |*| }
    Turbo::StreamsChannel.define_singleton_method(:broadcast_remove_to) { |*| }

    @room = Room.create!(code: "fr#{suffix}", status: RoomStatus::FinalResults, voting_style: "vote_once")
    @story = Story.create!(title: "FR #{suffix}", text: "placeholder", original_text: "original", published: true)
    @game = Game.create!(story: @story, room: @room)

    @blank1 = Blank.create!(story: @story, tags: "noun")
    @blank2 = Blank.create!(story: @story, tags: "adj")

    @editor = Editor.create!(username: "fr#{suffix}", email: "fr#{suffix}@test.com", password: "password123", password_confirmation: "password123")
    @prompt1 = Prompt.create!(description: "FR prompt1 #{suffix}", tags: "noun", creator: @editor)
    @prompt2 = Prompt.create!(description: "FR prompt2 #{suffix}", tags: "adj", creator: @editor)
    @gp1 = GamePrompt.create!(game: @game, prompt: @prompt1, blank: @blank1, order: 0)
    @gp2 = GamePrompt.create!(game: @game, prompt: @prompt2, blank: @blank2, order: 1)

    @room.update!(current_game: @game)
    @game.update!(current_game_prompt: @gp1)

    @creator = User.create!(name: "Creator-FR#{suffix[0..3]}", room: @room, role: User::CREATOR)
    @player1 = User.create!(name: "FRP1#{suffix}", room: @room, role: User::PLAYER)
  end

  test "maps single winning answer to blank placeholder" do
    @story.update!(text: "The {#{@blank1.id}} was great.")
    answer = Answer.create!(game_prompt: @gp1, game: @game, user: @player1, text: "dog", won: true)

    result = RoomStatusService.new(@room).call

    mapping = result[:blank_id_to_answer_text]
    assert_equal 1, mapping.size
    assert_equal [ "dog", @gp1.id ], mapping["{#{@blank1.id}}"]
  end

  test "maps multiple blanks to their winning answers" do
    @story.update!(text: "The {#{@blank1.id}} was very {#{@blank2.id}}.")
    Answer.create!(game_prompt: @gp1, game: @game, user: @player1, text: "cat", won: true)
    Answer.create!(game_prompt: @gp2, game: @game, user: @player1, text: "fluffy", won: true)

    result = RoomStatusService.new(@room).call

    mapping = result[:blank_id_to_answer_text]
    assert_equal 2, mapping.size
    assert_equal "cat", mapping["{#{@blank1.id}}"].first
    assert_equal "fluffy", mapping["{#{@blank2.id}}"].first
  end

  test "uses smoothed_text via display_text when available" do
    @story.update!(text: "The {#{@blank1.id}} was great.")
    answer = Answer.create!(game_prompt: @gp1, game: @game, user: @player1, text: "dog", won: true)
    answer.update!(smoothed_text: "adorable puppy")

    result = RoomStatusService.new(@room).call

    mapping = result[:blank_id_to_answer_text]
    assert_equal "adorable puppy", mapping["{#{@blank1.id}}"].first
  end

  test "returns empty mapping when no winning answers exist" do
    @story.update!(text: "The {#{@blank1.id}} was great.")
    Answer.create!(game_prompt: @gp1, game: @game, user: @player1, text: "dog", won: false)

    result = RoomStatusService.new(@room).call

    assert_equal({}, result[:blank_id_to_answer_text])
    assert_equal "The {#{@blank1.id}} was great.", result[:story_text]
  end
end

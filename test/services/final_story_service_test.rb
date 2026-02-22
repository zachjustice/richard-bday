require "test_helper"

class FinalStoryServiceTest < ActiveSupport::TestCase
  def setup
    suffix = SecureRandom.hex(4)

    Turbo::StreamsChannel.define_singleton_method(:broadcast_replace_to) { |*| }
    Turbo::StreamsChannel.define_singleton_method(:broadcast_action_to) { |*| }

    @room = Room.create!(code: "fs#{suffix}", status: RoomStatus::FinalResults, voting_style: "vote_once")
    @story = Story.create!(title: "FS #{suffix}", text: "placeholder", original_text: "original", published: true)
    @game = Game.create!(story: @story, room: @room)

    @blank1 = Blank.create!(story: @story, tags: "noun")
    @blank2 = Blank.create!(story: @story, tags: "adj")

    @editor = Editor.create!(username: "fs#{suffix}", email: "fs#{suffix}@test.com", password: "password123", password_confirmation: "password123")
    @prompt1 = Prompt.create!(description: "FS prompt1 #{suffix}", tags: "noun", creator: @editor)
    @prompt2 = Prompt.create!(description: "FS prompt2 #{suffix}", tags: "adj", creator: @editor)
    @gp1 = GamePrompt.create!(game: @game, prompt: @prompt1, blank: @blank1, order: 0)
    @gp2 = GamePrompt.create!(game: @game, prompt: @prompt2, blank: @blank2, order: 1)

    @room.update!(current_game: @game)
    @game.update!(current_game_prompt: @gp1)

    @player = User.create!(name: "FSP#{suffix}", room: @room, role: User::PLAYER)
  end

  test "maps winning answers to blank placeholders" do
    @story.update!(text: "The {#{@blank1.id}} was very {#{@blank2.id}}.")
    Answer.create!(game_prompt: @gp1, game: @game, user: @player, text: "cat", won: true)
    Answer.create!(game_prompt: @gp2, game: @game, user: @player, text: "fluffy", won: true)

    result = FinalStoryService.new(@game).call

    mapping = result[:blank_id_to_answer_text]
    assert_equal 2, mapping.size
    assert_equal "cat", mapping["{#{@blank1.id}}"].first
    assert_equal "fluffy", mapping["{#{@blank2.id}}"].first
  end

  test "uses smoothed_text when available" do
    @story.update!(text: "The {#{@blank1.id}} was great.")
    answer = Answer.create!(game_prompt: @gp1, game: @game, user: @player, text: "dog", won: true)
    answer.update!(smoothed_text: "adorable puppy")

    result = FinalStoryService.new(@game).call

    mapping = result[:blank_id_to_answer_text]
    assert_equal "adorable puppy", mapping["{#{@blank1.id}}"].first
  end

  test "returns empty mapping when no winning answers" do
    @story.update!(text: "The {#{@blank1.id}} was great.")
    Answer.create!(game_prompt: @gp1, game: @game, user: @player, text: "dog", won: false)

    result = FinalStoryService.new(@game).call

    assert_equal({}, result[:blank_id_to_answer_text])
  end

  test "returns original story text" do
    @story.update!(text: "The {#{@blank1.id}} was great.")

    result = FinalStoryService.new(@game).call

    assert_equal "The {#{@blank1.id}} was great.", result[:story_text]
  end
end

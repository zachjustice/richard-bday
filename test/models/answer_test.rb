require "test_helper"

class AnswerTest < ActiveSupport::TestCase
  def setup
    @game_prompt = game_prompts(:one)
    @game = games(:one)
    @user = users(:two)
  end

  # Slur filtering
  test "text cannot contain slurs" do
    SlurDetectorService.stub_any_instance(:contains_slur?, true) do
      answer = Answer.new(
        text: "BadAnswer",
        game_prompt: @game_prompt,
        game: @game,
        user: @user
      )
      assert_not answer.valid?
      assert_includes answer.errors[:text], "contains inappropriate language"
    end
  end

  test "text allows normal content" do
    # Use a different user/game_prompt combo to avoid uniqueness constraint
    room = Room.create!(code: "answertest", status: "WaitingRoom")
    game = Game.create!(story: stories(:one), room: room)
    game_prompt = GamePrompt.create!(game: game, prompt: prompts(:one), blank: blanks(:one), order: 0)
    user = User.create!(name: "AnswerTester", room: room, role: User::PLAYER)

    answer = Answer.new(
      text: "A funny cat",
      game_prompt: game_prompt,
      game: game,
      user: user
    )
    assert answer.valid?, "Answer with normal text should be valid: #{answer.errors.full_messages}"
  end

  # display_text helper
  test "display_text returns smoothed_text when present" do
    answer = answers(:one)
    answer.smoothed_text = "smoothed version"
    assert_equal "smoothed version", answer.display_text
  end

  test "display_text returns text when smoothed_text is nil" do
    answer = answers(:one)
    answer.smoothed_text = nil
    assert_equal answer.text, answer.display_text
  end

  test "display_text returns text when smoothed_text is blank" do
    answer = answers(:one)
    answer.smoothed_text = ""
    assert_equal answer.text, answer.display_text
  end
end

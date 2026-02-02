require "test_helper"

class GamePromptTest < ActiveSupport::TestCase
  setup do
    @game = games(:one)
    @prompt = prompts(:one)
    @blank = blanks(:one)
    @game_prompt = game_prompts(:one)
  end

  # Validation tests

  test "valid game_prompt with all required attributes" do
    game_prompt = GamePrompt.new(
      game: games(:one),
      prompt: prompts(:two),
      blank: blanks(:two)
    )
    # Need to use a unique combination since fixtures already have some combinations
    game_prompt.game = Game.create!(room: rooms(:one), story: stories(:one))
    assert game_prompt.valid?
  end

  test "requires prompt_id" do
    game_prompt = GamePrompt.new(game: @game, blank: @blank)
    assert_not game_prompt.valid?
    assert_includes game_prompt.errors[:prompt_id], "can't be blank"
  end

  test "requires game_id" do
    game_prompt = GamePrompt.new(prompt: @prompt, blank: @blank)
    assert_not game_prompt.valid?
    assert_includes game_prompt.errors[:game_id], "can't be blank"
  end

  test "requires blank_id" do
    game_prompt = GamePrompt.new(prompt: @prompt, game: @game)
    assert_not game_prompt.valid?
    assert_includes game_prompt.errors[:blank_id], "can't be blank"
  end

  test "enforces uniqueness of prompt_id within game and blank scope" do
    # @game_prompt already has prompt: one, game: one, blank: one
    duplicate = GamePrompt.new(
      prompt: @game_prompt.prompt,
      game: @game_prompt.game,
      blank: @game_prompt.blank
    )
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:prompt_id], "has already been taken"
  end

  test "allows same prompt in different games" do
    new_game = Game.create!(room: rooms(:one), story: stories(:one))
    game_prompt = GamePrompt.new(
      prompt: @prompt,
      game: new_game,
      blank: @blank
    )
    assert game_prompt.valid?
  end

  test "allows same prompt with different blank in same game" do
    game_prompt = GamePrompt.new(
      prompt: @prompt,
      game: @game,
      blank: blanks(:two)
    )
    assert game_prompt.valid?
  end

  # Association tests

  test "belongs to prompt" do
    assert_respond_to @game_prompt, :prompt
    assert_equal @prompt, @game_prompt.prompt
  end

  test "belongs to game" do
    assert_respond_to @game_prompt, :game
    assert_equal @game, @game_prompt.game
  end

  test "belongs to blank" do
    assert_respond_to @game_prompt, :blank
    assert_equal @blank, @game_prompt.blank
  end

  # Order attribute test

  test "can have an order attribute" do
    assert_respond_to @game_prompt, :order
    assert_equal 0, @game_prompt.order
  end
end

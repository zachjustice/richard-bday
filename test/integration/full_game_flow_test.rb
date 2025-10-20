require "test_helper"

class FullGameFlowTest < ActionDispatch::IntegrationTest
  setup do
    @room = rooms(:one)
    @story = stories(:one)

    # Create multiple users for the game with unique names
    @player1 = User.create!(name: "IntegrationAlice", room: @room)
    @player2 = User.create!(name: "IntegrationBob", room: @room)
    @player3 = User.create!(name: "IntegrationCharlie", room: @room)

    # Use existing blanks from fixtures
    @blank1 = blanks(:one)
    @blank2 = blanks(:two)
  end

  test "full game flow from login to final results" do
    # Step 1: Player 1 joins the room
    login_player(@player1)
    assert_response :success
    assert_match @player1.name, response.body

    # Step 2: Player 1 starts the game (simplified - test as single player)
    # In reality, multiple players would join, but we'll focus on one player's journey
    post start_room_path(@room), params: { story: @story.id }
    follow_redirect!

    @room.reload
    assert_equal RoomStatus::Answering, @room.status
    @game = @room.current_game
    assert_not_nil @game

    # Step 3: Player answers first prompt
    @game.reload
    first_prompt = @game.current_game_prompt
    assert_not_nil first_prompt

    get "/prompts/#{first_prompt.id}"
    assert_response :success
    assert_match first_prompt.prompt.description, response.body

    post "/answer", params: {
      prompt_id: first_prompt.id,
      text: "Alice's creative answer"
    }
    follow_redirect!
    assert_match "Answer Submitted", response.body

    # Other players answer (simulated by creating answers directly)
    Answer.create!(text: "Bob's funny answer", user: @player2, game_prompt: first_prompt, game: @game)
    Answer.create!(text: "Charlie's wild answer", user: @player3, game_prompt: first_prompt, game: @game)

    # Step 4: Manually transition to Voting (in real app, this happens via callbacks/events)
    @room.update!(status: RoomStatus::Voting)

    # Step 5: Player votes on answers
    first_prompt.reload
    answers = Answer.where(game_prompt: first_prompt)
    assert_equal 3, answers.count

    get "/prompts/#{first_prompt.id}/voting"
    assert_response :success
    assert_match first_prompt.prompt.description, response.body
    assert_match /Bob.*funny answer/, response.body
    assert_match /Charlie.*wild answer/, response.body

    # Vote for Bob's answer
    post "/vote", params: {
      game_prompt_id: first_prompt.id,
      answer_id: answers.find_by(text: "Bob's funny answer").id
    }
    follow_redirect!
    assert_match "Counting Votes", response.body

    # Other players vote (simulated)
    Vote.create!(user: @player2, answer: answers.find_by(text: "Charlie's wild answer"), game: @game, game_prompt: first_prompt)
    Vote.create!(user: @player3, answer: answers.find_by(text: "Bob's funny answer"), game: @game, game_prompt: first_prompt)

    # Step 6: Manually transition to Results
    @room.update!(status: RoomStatus::Results)

    get "/prompts/#{first_prompt.id}/results"
    assert_response :success
    assert_match "Round Complete!", response.body

    # Step 7: Move to next prompt
    @game.reload
    assert_not_nil @game.current_game_prompt_id
    second_prompt = @game.current_game_prompt

    # If there's a second prompt, test another round
    if second_prompt && second_prompt != first_prompt
      # Manually transition back to Answering for next round
      @room.update!(status: RoomStatus::Answering)

      # Player answers second prompt
      get "/prompts/#{second_prompt.id}"
      assert_response :success
      assert_match second_prompt.prompt.description, response.body

      post "/answer", params: {
        prompt_id: second_prompt.id,
        text: "Answer 2 from Alice"
      }
      follow_redirect!

      # Other players answer (simulated)
      Answer.create!(text: "Answer 2 from Bob", user: @player2, game_prompt: second_prompt, game: @game)
      Answer.create!(text: "Answer 2 from Charlie", user: @player3, game_prompt: second_prompt, game: @game)

      # Vote on second round - manually transition to Voting
      @room.update!(status: RoomStatus::Voting)

      second_prompt.reload
      second_answers = Answer.where(game_prompt: second_prompt)

      post "/vote", params: {
        game_prompt_id: second_prompt.id,
        answer_id: second_answers.first.id
      }
      follow_redirect!

      # Other players vote (simulated)
      Vote.create!(user: @player2, answer: second_answers.first, game: @game, game_prompt: second_prompt)
      Vote.create!(user: @player3, answer: second_answers.first, game: @game, game_prompt: second_prompt)

      # Manually transition to FinalResults
      @room.update!(status: RoomStatus::FinalResults)
    end

    # Step 8: Check if game reached FinalResults
    @room.reload
    if @room.status == RoomStatus::FinalResults
      # Use the last prompt for results path
      last_prompt = @game.game_prompts.last
      get "/prompts/#{last_prompt.id}/results"
      assert_response :success
      assert_match "Game Complete!", response.body
    end
  end

  private

  def login_player(player)
    post "/sessions/resume", params: {
      name: player.name,
      code: @room.code
    }
    follow_redirect!
  end
end

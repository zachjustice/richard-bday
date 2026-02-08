require "test_helper"

class GameFlowIntegrationTest < ActionDispatch::IntegrationTest
  setup do
    # Load fixtures
    @story = stories(:one)
    @blank1 = blanks(:one)  # animal,noun
    @blank2 = blanks(:two)  # adjective
    @prompt1 = prompts(:one)  # Name an animal
    @prompt2 = prompts(:two)  # Give me an adjective

    # Update story text with actual blank IDs (like seeds.rb does)
    @story.update!(
      text: "Once upon a time there was a {#{@blank1.id}} creature who was very {#{@blank2.id}}."
    )

    # Create a fresh room for testing
    @room = Room.create!(code: "test#{rand(1000)}", status: RoomStatus::WaitingRoom)
    @creator = User.create!(name: "Creator", room: @room, role: User::CREATOR)

    # Create two players
    @player1 = User.create!(name: "Player1", room: @room)
    @player2 = User.create!(name: "Player2", room: @room)
  end

  test "complete game flow from start to finish" do
    # Step 1: Creator can view room status page showing players
    resume_session_as(@room.code, @creator.name)

    get room_status_path(@room)
    assert_response :success
    assert_select "body", text: /Player1/
    assert_select "body", text: /Player2/

    # Step 2: Start the game
    post start_room_path(@room), params: { story: @story.id }
    assert_redirected_to room_status_path(@room)

    @room.reload
    assert_equal RoomStatus::Answering, @room.status
    assert_not_nil @room.current_game_id

    game = @room.current_game
    first_prompt = game.current_game_prompt
    assert_equal 0, first_prompt.order

    # Step 3: Player 1 submits answer to first prompt
    resume_session_as(@room.code, @player1.name)
    post answer_path, params: { text: "unicorn", prompt_id: first_prompt.id }
    assert_redirected_to "/game_prompts/#{first_prompt.id}/waiting"

    answer1 = Answer.find_by(user: @player1, game_prompt: first_prompt)
    assert_equal "unicorn", answer1.text

    # Step 4: Player 2 submits answer to first prompt
    end_session
    resume_session_as(@room.code, @player2.name)

    post answer_path, params: { text: "dragon", prompt_id: first_prompt.id }
    # Redirects to voting (all answers in), but room status hasn't changed yet
    assert_redirected_to "/game_prompts/#{first_prompt.id}/voting"

    answer2 = Answer.find_by(user: @player2, game_prompt: first_prompt)
    assert_equal "dragon", answer2.text

    # Step 5: Simulate room transitioning to Voting (normally done by job)
    @room.update!(status: RoomStatus::Voting)

    # Now voting page displays answers
    get "/game_prompts/#{first_prompt.id}/voting"
    assert_response :success
    # Player 2 should see Player 1's answer but not their own
    assert_select "body", text: /unicorn/
    assert_select "body", text: /dragon/, count: 0  # Own answer should not appear

    # Step 6: Player 2 votes for Player 1's answer
    post votes_path, params: { answer_id: answer1.id, game_prompt_id: first_prompt.id }
    assert_redirected_to "/game_prompts/#{first_prompt.id}/results"

    vote2 = Vote.find_by(user: @player2, answer: answer1)
    assert_not_nil vote2

    # Player 1 votes for Player 2's answer
    end_session
    resume_session_as(@room.code, @player1.name)

    post votes_path, params: { answer_id: answer2.id, game_prompt_id: first_prompt.id }
    assert_redirected_to "/game_prompts/#{first_prompt.id}/results"

    vote1 = Vote.find_by(user: @player1, answer: answer2)
    assert_not_nil vote1

    # Step 7: Verify results page shows votes
    resume_session_as(@room.code, @creator.name)
    @room.reload
    @room.update!(status: RoomStatus::Results)

    get room_status_path(@room)
    assert_response :success
    # Results should show both answers
    assert_select "body", text: /unicorn/
    assert_select "body", text: /dragon/

    # One answer should be marked as winner
    assert_equal 1, Answer.where(game_prompt: first_prompt, won: true).count

    # Step 8: Advance to next prompt
    post next_room_path(@room)
    # Creator is redirected back to status page
    second_prompt = GamePrompt.find_by(game_id: @room.current_game_id, order: 1)
    assert_redirected_to room_status_path(@room)

    @room.reload
    game.reload
    assert_equal 1, game.current_game_prompt.order
    assert_equal RoomStatus::Answering, @room.status

    # Quick second round: both players submit answers
    end_session
    resume_session_as(@room.code, @player1.name)
    post answer_path, params: { text: "sparkly", prompt_id: second_prompt.id }

    end_session
    resume_session_as(@room.code, @player2.name)
    post answer_path, params: { text: "fluffy", prompt_id: second_prompt.id }

    # Simulate room transitioning to Voting
    @room.update!(status: RoomStatus::Voting)

    # Both players vote
    answer1_p2 = Answer.find_by(user: @player1, game_prompt: second_prompt)
    answer2_p2 = Answer.find_by(user: @player2, game_prompt: second_prompt)

    post votes_path, params: { answer_id: answer1_p2.id, game_prompt_id: second_prompt.id }

    end_session
    resume_session_as(@room.code, @player1.name)
    post votes_path, params: { answer_id: answer2_p2.id, game_prompt_id: second_prompt.id }

    # Mark one as winner (simulate results)
    answer1_p2.update!(won: true)

    # Step 9: Advance to final results (no more prompts)
    resume_session_as(@room.code, @creator.name)
    post next_room_path(@room)
    # Creator is redirected back to status page
    assert_redirected_to room_status_path(@room)

    @room.reload
    assert_equal RoomStatus::FinalResults, @room.status

    # Verify final results page shows complete story
    get room_status_path(@room)
    assert_response :success
    assert_select "body", text: /#{@story.title}/

    # Step 10: End game and return to waiting room
    post end_room_game_path(@room)
    assert_redirected_to room_status_path(@room)

    @room.reload
    assert_equal RoomStatus::WaitingRoom, @room.status
    assert_nil @room.current_game_id
  end
end

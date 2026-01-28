require "application_system_test_case"

class GameFlowTest < ApplicationSystemTestCase
  setup do
    @story = stories(:one)
    @blank1 = blanks(:one)
    @blank2 = blanks(:two)

    @story.update!(
      text: "Once upon a time there was a {#{@blank1.id}} creature who was very {#{@blank2.id}}."
    )
  end

  test "complete game flow from room creation to final story" do
    room = nil

    # Step 1: Host creates a room
    using_session(:host) do
      visit create_room_path
      click_button "Start a Game"
      assert_text "C'MON, GET IN HERE!"
      room = Room.last
    end

    # Step 2: Players join the room
    using_session(:player1) do
      join_room_as("Player1", room.code)
      assert_text "Welcome, Player1!"
    end

    using_session(:player2) do
      join_room_as("Player2", room.code)
      assert_text "Welcome, Player2!"
    end

    # Step 3: Host sees players and advances to story selection
    using_session(:host) do
      visit room_status_path(room)
      assert_text "Player1"
      assert_text "Player2"

      click_button "Let's Go!"
      assert_text "PICK A STORY"
    end

    # Step 4: Host selects a story and starts the game
    using_session(:host) do
      # Select story radio via JS (scroll container overlaps elements in headless browser)
      page.execute_script("document.querySelector('input[name=\"story\"][value=\"#{@story.id}\"]').checked = true")
      page.execute_script("document.querySelector('button[type=\"submit\"]').click()")
      assert_text "Answer the prompt on your device"
    end

    ############
    # PROMPT 1 #
    ############

    room.reload
    game_prompt_1_id = room.current_game.current_game_prompt_id

    # Step 5: Player1 submits answer for prompt 1
    using_session(:player1) do
      visit "/prompts/#{game_prompt_1_id}"
      fill_in "text", with: "unicorn"
      click_button "Submit Answer"
      assert_text "Answer submitted"
    end

    # Step 6: Player2 submits answer for prompt 1
    using_session(:player2) do
      visit "/prompts/#{game_prompt_1_id}"
      fill_in "text", with: "dragon"
      click_button "Submit Answer"
    end

    # Simulate background job: transition to Voting
    simulate_move_to_voting(room)

    # Step 7: Host sees voting phase
    using_session(:host) do
      visit room_status_path(room)
      assert_text "Vote for the best answer"
    end

    # Step 8: Player1 votes (can't see own answer "unicorn", sees "dragon")
    using_session(:player1) do
      visit "/prompts/#{game_prompt_1_id}/voting"
      assert_text "dragon"
      find("label.answer-option", text: "dragon").click
      click_button "Submit Vote"
    end

    # Step 9: Player2 votes (can't see own answer "dragon", sees "unicorn")
    using_session(:player2) do
      visit "/prompts/#{game_prompt_1_id}/voting"
      assert_text "unicorn"
      find("label.answer-option", text: "unicorn").click
      click_button "Submit Vote"
    end

    # Simulate background job: transition to Results
    simulate_move_to_results(room)

    # Step 10: Navigator (Player1) sees results and advances to next prompt
    using_session(:player1) do
      visit "/prompts/#{game_prompt_1_id}/results"
      assert_text "Round Complete!"
      click_button "Next Round"
    end

    ############
    # PROMPT 2 #
    ############

    room.reload
    game_prompt_2_id = room.current_game.current_game_prompt_id
    assert_not_equal game_prompt_1_id, game_prompt_2_id

    # Step 11: Host sees answering phase for prompt 2
    using_session(:host) do
      visit room_status_path(room)
      assert_text "Answer the prompt on your device"
    end

    # Step 12: Player1 submits answer for prompt 2
    using_session(:player1) do
      visit "/prompts/#{game_prompt_2_id}"
      fill_in "text", with: "sparkly"
      click_button "Submit Answer"
      assert_text "Answer submitted"
    end

    # Step 13: Player2 submits answer for prompt 2
    using_session(:player2) do
      visit "/prompts/#{game_prompt_2_id}"
      fill_in "text", with: "fluffy"
      click_button "Submit Answer"
    end

    # Simulate background job: transition to Voting
    simulate_move_to_voting(room)

    # Step 14: Player1 votes in round 2
    using_session(:player1) do
      visit "/prompts/#{game_prompt_2_id}/voting"
      assert_text "fluffy"
      find("label.answer-option", text: "fluffy").click
      click_button "Submit Vote"
    end

    # Step 15: Player2 votes in round 2
    using_session(:player2) do
      visit "/prompts/#{game_prompt_2_id}/voting"
      assert_text "sparkly"
      find("label.answer-option", text: "sparkly").click
      click_button "Submit Vote"
    end

    # Simulate background job: transition to Results
    simulate_move_to_results(room)

    # Step 16: Navigator (Player1) advances - last prompt triggers FinalResults
    using_session(:player1) do
      visit "/prompts/#{game_prompt_2_id}/results"
      assert_text "Round Complete!"
      click_button "Next Round"
      # After the last prompt, room transitions to FinalResults
      assert_text "Game Complete!"
    end

    # Step 17: Host sees the final story
    room.reload
    using_session(:host) do
      visit room_status_path(room)
      assert_text @story.title
    end

    # Step 18: Navigator ends the game
    using_session(:player1) do
      visit "/prompts/#{game_prompt_2_id}/results"
      click_button "Start New Game"
      assert_text "Between Games"
    end

    # Step 19: Host sees waiting room again
    using_session(:host) do
      visit room_status_path(room)
      assert_text "C'MON, GET IN HERE!"
    end
  end

  private

  def join_room_as(name, room_code)
    visit new_session_path
    fill_in "name", with: name
    fill_in "code", with: room_code
    click_button "Join Game"
  end

  # Simulate AnswerSubmittedJob + GamePhasesService#move_to_voting
  def simulate_move_to_voting(room)
    room.reload
    User.players.where(room: room).update_all(status: UserStatus::Voting)
    room.update!(status: RoomStatus::Voting)
    room.current_game.update!(next_game_phase_time: Time.now + room.time_to_vote_seconds + GameConstants::COUNTDOWN_FORGIVENESS_SECONDS)
  end

  # Simulate VoteSubmittedJob + GamePhasesService#move_to_results
  # Also triggers winner selection that normally happens when status page renders Results
  def simulate_move_to_results(room)
    room.reload
    room.update!(status: RoomStatus::Results)
    # Trigger RoomStatusService to select a winner (same as when status page renders)
    RoomStatusService.new(room).call
  end
end

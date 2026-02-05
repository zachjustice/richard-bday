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
    # Run real background jobs (AnswerSubmittedJob, VoteSubmittedJob, JoinRoomJob)
    # but exclude timer-based fallback jobs that would interfere with the test flow.
    perform_enqueued_jobs(except: [ AnsweringTimesUpJob, VotingTimesUpJob ]) do
      room = nil

      # Step 1: Host creates a room
      using_session(:host) do
        visit create_room_path
        click_button "Start a Game"
        assert_text "C'MON, GET IN HERE!"
        room = Room.last
      end

      # Step 2: Players join the room (JoinRoomJob runs for each)
      # Players land on /rooms/:id which subscribes to nav-updates
      using_session(:player1) do
        join_room_as("Player1", room.code)
        assert_text "Welcome, Player1!"
        wait_for_turbo_cable_connection  # Ensure subscribed to nav-updates before game starts
      end

      using_session(:player2) do
        join_room_as("Player2", room.code)
        assert_text "Welcome, Player2!"
        wait_for_turbo_cable_connection  # Ensure subscribed to nav-updates before game starts
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
      # This broadcasts navigate action to all players subscribed to nav-updates
      using_session(:host) do
        # Wait for Stimulus controller to be fully connected before interacting
        wait_for_page_ready(controller: "story-selection")

        # Select the story and dispatch change event so Stimulus handles it
        page.execute_script(<<~JS)
          const radio = document.querySelector('input[name="story"][value="#{@story.id}"]');
          radio.checked = true;
          radio.dispatchEvent(new Event('change', { bubbles: true }));
        JS

        # Submit the form via requestSubmit to ensure Turbo handles it
        page.execute_script("document.querySelector('form[action*=\"start\"]').requestSubmit()")

        # Wait for Turbo navigation to complete (long wait for CI)
        assert_text "Answer the prompt on your device", wait: 30
      end

      ############
      # PROMPT 1 #
      ############

      room.reload
      game_prompt_1 = room.current_game.current_game_prompt
      prompt_1_description = game_prompt_1.prompt.description

      # Step 5: Player1 receives Turbo navigation to prompt page, submits answer
      # This tests that WebSocket auth works - if cookies mismatch, navigation won't happen
      using_session(:player1) do
        # Wait for Turbo Streams to auto-navigate from /rooms/:id to /prompts/:id
        assert_text prompt_1_description, wait: 15
        fill_in "text", with: "unicorn"
        click_button "Submit Answer"
        assert_text "Answer submitted"
        # Wait for cable connection on the waiting page before Player2 triggers move_to_voting
        wait_for_turbo_cable_connection
      end

      # Step 6: Player2 receives Turbo navigation, submits answer
      # When all players answer, AnswerSubmittedJob triggers move_to_voting broadcast
      using_session(:player2) do
        # Wait for Turbo Streams to auto-navigate from /rooms/:id to /prompts/:id
        assert_text prompt_1_description, wait: 15
        fill_in "text", with: "dragon"
        click_button "Submit Answer"
        # After submit, player may briefly see waiting page before auto-navigating to voting
        # Don't assert "Answer submitted" as the game may transition to voting immediately
      end

      # Step 7: Host sees voting phase (jobs already transitioned the room)
      using_session(:host) do
        # Status page updates via Turbo Streams on rooms:#{room.id}:status channel
        assert_text "Vote for the best answer", wait: 15
      end

      # Step 8: Player1 auto-navigated to voting (Turbo broadcast from move_to_voting)
      # This is the critical test - if WebSocket auth fails, player won't be navigated
      using_session(:player1) do
        # Wait for auto-navigation from waiting page to voting page
        assert_text "dragon", wait: 15
        find("label.answer-option", text: "dragon").click
        click_button "Submit Vote"
        # Wait for cable connection on waiting page before Player2 triggers move_to_results
        wait_for_turbo_cable_connection
      end

      # Step 9: Player2 auto-navigated to voting, submits vote
      # VoteSubmittedJob detects all voted, triggers move_to_results
      using_session(:player2) do
        # Wait for auto-navigation from waiting page to voting page
        assert_text "unicorn", wait: 15
        find("label.answer-option", text: "unicorn").click
        click_button "Submit Vote"
        # Wait for auto-navigation to results page and cable connection
        assert_text "Round Complete!", wait: 15
        wait_for_turbo_cable_connection
      end

      # Step 10: Navigator (Player1) auto-navigated to results, advances to next prompt
      using_session(:player1) do
        # Wait for auto-navigation to results page
        assert_text "Round Complete!", wait: 15
        click_button "Next Round"
      end

      ############
      # PROMPT 2 #
      ############

      room.reload
      game_prompt_2 = room.current_game.current_game_prompt
      prompt_2_description = game_prompt_2.prompt.description
      assert_not_equal game_prompt_1.id, game_prompt_2.id

      # Step 11: Host sees answering phase for prompt 2
      using_session(:host) do
        assert_text "Answer the prompt on your device", wait: 15
      end

      # Step 12: Player1 auto-navigated to prompt 2, submits answer
      using_session(:player1) do
        # Wait for auto-navigation to next prompt
        assert_text prompt_2_description, wait: 15
        fill_in "text", with: "sparkly"
        click_button "Submit Answer"
        assert_text "Answer submitted"
        # Wait for cable connection on the waiting page before Player2 triggers move_to_voting
        wait_for_turbo_cable_connection
      end

      # Step 13: Player2 auto-navigated to prompt 2, submits answer (triggers move_to_voting)
      using_session(:player2) do
        # Wait for auto-navigation to next prompt
        assert_text prompt_2_description, wait: 15
        fill_in "text", with: "fluffy"
        click_button "Submit Answer"
        # After submit, player may briefly see waiting page before auto-navigating to voting
        # Don't assert "Answer submitted" as the game may transition to voting immediately
      end

      # Step 14: Player1 auto-navigated to voting, votes
      using_session(:player1) do
        assert_text "fluffy", wait: 15
        find("label.answer-option", text: "fluffy").click
        click_button "Submit Vote"
        # Wait for cable connection on waiting page before Player2 triggers move_to_results
        wait_for_turbo_cable_connection
      end

      # Step 15: Player2 auto-navigated to voting, votes (triggers move_to_results)
      using_session(:player2) do
        assert_text "sparkly", wait: 15
        find("label.answer-option", text: "sparkly").click
        click_button "Submit Vote"
      end

      # Step 16: Navigator (Player1) advances - last prompt triggers FinalResults
      using_session(:player1) do
        assert_text "Round Complete!", wait: 15
        click_button "Next Round"
        # After the last prompt, room transitions to FinalResults
        assert_text "Game Complete!", wait: 15
      end

      # Step 17: Host sees the final story
      room.reload
      using_session(:host) do
        assert_text @story.title, wait: 15
      end

      # Step 18: Navigator ends the game
      using_session(:player1) do
        click_button "Start New Game"
        assert_text "Between Games", wait: 15
      end

      # Step 19: Host sees waiting room again
      using_session(:host) do
        assert_text "C'MON, GET IN HERE!", wait: 15
      end
    end
  end

  private

  def join_room_as(name, room_code)
    visit new_session_path
    fill_in "name", with: name
    fill_in "code", with: room_code
    click_button "Join Game"
  end
end

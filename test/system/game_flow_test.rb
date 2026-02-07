require "application_system_test_case"

class GameFlowTest < ApplicationSystemTestCase
  # Timeouts - increased for CI environments
  TURBO_NAVIGATION_TIMEOUT = 15  # seconds - for Turbo Stream auto-navigation
  FORM_SUBMISSION_TIMEOUT = 30   # seconds - for slower CI job processing

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
        wait_for_page_ready(controller: "story-selection")
        select_story_via_stimulus(@story)
        page.execute_script("document.querySelector('form[action*=\"start\"]').requestSubmit()")
        assert_text "Answer the prompt on your device", wait: FORM_SUBMISSION_TIMEOUT
      end

      ############
      # PROMPT 1 #
      ############

      # Wait for game to be created before accessing it
      assert room.reload.current_game.present?, "Game should exist after story selection"
      game_prompt_1 = room.current_game.current_game_prompt
      prompt_1_description = game_prompt_1.prompt.description

      # Step 5: Player1 receives Turbo navigation to prompt page, submits answer
      # Tests WebSocket auth - if cookies mismatch, navigation won't happen
      submit_answer_as(:player1, prompt_1_description, "unicorn")

      # Step 6: Player2 submits answer (triggers move_to_voting via AnswerSubmittedJob)
      submit_answer_as(:player2, prompt_1_description, "dragon", wait_for_cable: false)

      # Step 7: Host sees voting phase (jobs already transitioned the room)
      using_session(:host) do
        assert_text "Vote for the best answer", wait: TURBO_NAVIGATION_TIMEOUT
      end

      # Step 8: Player1 auto-navigated to voting (critical WebSocket auth test)
      submit_vote_as(:player1, "dragon")

      # Step 9: Player2 votes (triggers move_to_results via VoteSubmittedJob)
      submit_vote_as(:player2, "unicorn")
      using_session(:player2) do
        assert_text "Round Complete!", wait: TURBO_NAVIGATION_TIMEOUT
        wait_for_turbo_cable_connection
      end

      # Step 10: Navigator (Player1) advances to next prompt
      # Player1 must have cable connection to receive the navigation broadcast after clicking
      using_session(:player1) do
        assert_text "Round Complete!", wait: TURBO_NAVIGATION_TIMEOUT
        wait_for_turbo_cable_connection
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
        assert_text "Answer the prompt on your device", wait: TURBO_NAVIGATION_TIMEOUT
      end

      # Step 12: Player1 submits answer for prompt 2
      # Player1 auto-navigated to prompt after clicking "Next Round"
      submit_answer_as(:player1, prompt_2_description, "sparkly")

      # Step 13: Player2 auto-navigated to prompt, submits answer (triggers move_to_voting)
      submit_answer_as(:player2, prompt_2_description, "fluffy", wait_for_cable: false)

      # Step 14: Player1 votes
      submit_vote_as(:player1, "fluffy")

      # Step 15: Player2 votes (triggers move_to_results)
      submit_vote_as(:player2, "sparkly", wait_for_cable: false)

      # Step 16: Navigator (Player1) advances - last prompt triggers FinalResults
      using_session(:player1) do
        assert_text "Round Complete!", wait: TURBO_NAVIGATION_TIMEOUT
        click_button "Next Round"
        assert_text "Game Complete!", wait: TURBO_NAVIGATION_TIMEOUT
      end

      # Step 17: Host sees the final story
      room.reload
      using_session(:host) do
        assert_text @story.title, wait: TURBO_NAVIGATION_TIMEOUT
      end

      # Step 18: Navigator ends the game
      using_session(:player1) do
        click_button "Start New Game"
        assert_text "Between Games", wait: TURBO_NAVIGATION_TIMEOUT
      end

      # Step 19: Host sees waiting room again
      using_session(:host) do
        assert_text "C'MON, GET IN HERE!", wait: TURBO_NAVIGATION_TIMEOUT
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

  def submit_answer_as(session_name, prompt_description, answer_text, wait_for_cable: true)
    using_session(session_name) do
      assert_text prompt_description, wait: TURBO_NAVIGATION_TIMEOUT
      fill_in "text", with: answer_text
      click_button "Submit Answer"
      if wait_for_cable
        assert_text "Answer submitted"
        wait_for_turbo_cable_connection
      end
    end
  end

  def submit_vote_as(session_name, answer_text, wait_for_cable: true)
    using_session(session_name) do
      assert_text answer_text, wait: TURBO_NAVIGATION_TIMEOUT
      find("label.answer-option", text: answer_text).click
      click_button "Submit Vote"
      wait_for_turbo_cable_connection if wait_for_cable
    end
  end

  def select_story_via_stimulus(story)
    page.execute_script(<<~JS)
      const radio = document.querySelector('input[name="story"][value="#{story.id}"]');
      if (radio) {
        radio.checked = true;
        radio.dispatchEvent(new Event('change', { bubbles: true }));
      }
    JS
  end
end

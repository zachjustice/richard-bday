require "application_system_test_case"

class GameFlowTest < ApplicationSystemTestCase
  setup do
    # Create a fresh room for testing
    @story = stories(:one)
    @blank1 = blanks(:one)
    @blank2 = blanks(:two)

    @story.update!(
      text: "Once upon a time there was a {#{@blank1.id}} creature who was very {#{@blank2.id}}."
    )
  end

  test "complete game flow from room creation to final story" do
    # Step 1: Create a room
    room = nil

    # Host joins the room
    using_session(:host) do
      visit create_room_path
      click_on "New Game"
      assert_text "Room Code:"
      room = Room.last
    end

    # Step 2: Players join the room
    using_session(:player1) do
      join_room_as("Player1", room.code)
      assert_text "Player1"
    end

    using_session(:player2) do
      join_room_as("Player2", room.code)
      assert_text "Player2"
    end

    # Verify all players appear in the waiting room
    using_session(:host) do
      visit "/rooms/#{room.id}/status"
      connect_turbo_cable_stream_sources
      assert_text "Player1"
      assert_text "Player2"
    end

    # Step 3: Host starts the game
    using_session(:host) do
      select @story.title, from: "story"
      click_button "Start Game"
      assert_text "Answering"
    end

    # Step 4: Players submit answers for first prompt

    ############
    # PROMPT 1 #
    ############

    # Player1 submits answer
    using_session(:player1) do
      visit show_room_path
      fill_in "text", with: "unicorn"
      click_button "Submit"
      assert_text "Waiting"
    end

    # Player2 submits answer (last one)
    using_session(:player2) do
      visit show_room_path
      fill_in "text", with: "dragon"
      click_button "Submit"

      # All answers in, should advance to voting
      assert_text "Vote"
    end

    # Step 5: Players vote on answers
    room.reload
    room.update!(status: RoomStatus::Voting)
    current_game_prompt_id = room.current_game.current_game_prompt_id

    using_session(:host) do
      visit "/rooms/#{room.id}/status"
      connect_turbo_cable_stream_sources
      assert_text "Vote"
    end

    # Player1 votes
    using_session(:player1) do
      visit "/prompts/#{current_game_prompt_id}/voting"
      assert_text "Vote"
      assert_text "dragon"
      assert_no_text "unicorn"

      # choose "dragon", visible: false
      find("label.answer-option", text: "dragon").click
      click_button "Vote", match: :first
      assert_text "Counting Votes"
    end

    # Player2 votes (last vote)
    using_session(:player2) do
      visit "/prompts/#{current_game_prompt_id}/voting"
      assert_text "unicorn"
      assert_no_text "dragon"

      # choose "unicorn", visible: false
      find("label.answer-option", text: "unicorn").click
      click_button "Vote", match: :first
    end

    room.reload
    room.update!(status: RoomStatus::Results)

    # Step 6: View results and advance to next prompt
    using_session(:host) do
      visit "/rooms/#{room.id}/status"
      connect_turbo_cable_stream_sources
      assert_text "Results"

      click_button "Next"
      assert_text "Answering"
    end

    # Manually update room status to Results (ActionCable would do this in real app)
    room.reload
    room.update!(status: RoomStatus::Answering)

    ############
    # PROMPT 2 #
    ############

    # Step 7: Complete second round (second prompt)
    # Player1 submits answer in round 2
    using_session(:player1) do
      visit show_room_path
      fill_in "text", with: "sparkly"
      click_button "Submit"
      assert_text "Waiting"
    end

    # Player2 submits answer in round 2
    using_session(:player2) do
      visit show_room_path
      fill_in "text", with: "fluffy"
      click_button "Submit"
      assert_text "Vote"
    end

    # Vote in second round
    room.reload
    current_game_prompt_id = room.current_game.current_game_prompt_id

    room.reload
    room.update!(status: RoomStatus::Voting)

    # Player1 votes in round 2
    using_session(:player1) do
      visit "/prompts/#{current_game_prompt_id}/voting"
      assert_text "Vote"
      assert_text "fluffy"
      assert_no_text "sparkly"

      # choose "dragon", visible: false
      find("label.answer-option", text: "fluffy").click
      click_button "Vote", match: :first
      assert_text "Counting Votes"
    end

    # Player2 votes in round 2
    using_session(:player2) do
      visit "/prompts/#{current_game_prompt_id}/voting"
      assert_text "sparkly"
      assert_no_text "fluffly"

      # choose "unicorn", visible: false
      find("label.answer-option", text: "sparkly").click
      click_button "Vote", match: :first
    end

    # Step 8: Advance to final results
    # Manually update room status to Results
    room.reload
    room.update!(status: RoomStatus::Results)

    using_session(:host) do
      visit "/rooms/#{room.id}/status"
      connect_turbo_cable_stream_sources
      assert_text "Results"
      click_button "Next"

      # Should see final story
      assert_text @story.title
      winning_answers = Answer.where(game: room.current_game, won: true)
      assert_equal 2, winning_answers.size
      assert text "Once upon a time there was a #{winning_answers.first.text} creature who was very #{winning_answers.last.text}."
    end

    # Step 9: End game
    using_session(:host) do
      connect_turbo_cable_stream_sources
      click_button "Start New Game"
      assert_text "Stories"
      assert_text "Players"
    end
  end

  private

  def join_room_as(name, room_code)
    visit new_session_path
    fill_in "name", with: name
    fill_in "code", with: room_code
    click_button "Join"
  end
end

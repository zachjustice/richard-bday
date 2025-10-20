require "test_helper"

class PromptsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @room = rooms(:one)
    @user = users(:one)
    @game = games(:one)
    @game_prompt = game_prompts(:one)

    # Clean up any existing answers and votes for this user to avoid unique constraint issues
    Answer.where(user_id: @user.id).delete_all
    Vote.where(user_id: @user.id).delete_all

    # Set up the room with the current game
    @room.update!(current_game_id: @game.id, status: RoomStatus::Answering)
    @game.update!(current_game_prompt_id: @game_prompt.id)
    @user.update!(room_id: @room.id)
    resume_session_as(@room.code, @user.name)
  end

  # Tests for PromptsController#show

  test "show should display the prompt when no answer exists" do
    # Ensure no answer exists
    Answer.where(user_id: @user.id, game_prompt_id: @game_prompt.id).delete_all

    get "/prompts/#{@game_prompt.id}"

    assert_response :success
    assert_select "body" # Just verify page renders
  end

  test "show should redirect to waiting when answer already exists" do
    # Create an answer for this user and prompt
    Answer.create!(
      user_id: @user.id,
      game_prompt_id: @game_prompt.id,
      game_id: @game.id,
      text: "Test answer"
    )

    get "/prompts/#{@game_prompt.id}"

    assert_redirected_to controller: "prompts", action: "waiting", id: @game_prompt.id
  end

  test "show should check answer existence for current user only" do
    # Create answer for different user
    other_user = users(:two)
    Answer.create!(
      user_id: other_user.id,
      game_prompt_id: @game_prompt.id,
      game_id: @game.id,
      text: "Other user answer"
    )

    # Ensure current user has no answer
    Answer.where(user_id: @user.id, game_prompt_id: @game_prompt.id).delete_all

    get "/prompts/#{@game_prompt.id}"

    # Should show the prompt, not redirect
    assert_response :success
  end

  test "show should require authentication" do
    # Create a new session without authentication
    end_session

    get "/prompts/#{@game_prompt.id}"

    # Will redirect to login or waiting (if fixtures have answer)
    assert_response :redirect
  end

  # Tests for PromptsController#waiting

  test "waiting should display waiting page when room status is Answering" do
    @room.update!(status: RoomStatus::Answering)

    get "/prompts/#{@game_prompt.id}/waiting"

    assert_response :success
  end

  test "waiting should redirect to voting when room status is Voting" do
    @room.update!(status: RoomStatus::Voting)

    get "/prompts/#{@game_prompt.id}/waiting"

    assert_redirected_to controller: "prompts", action: "voting", id: @game_prompt.id
  end

  test "waiting should load the correct game prompt" do
    @room.update!(status: RoomStatus::Answering)

    get "/prompts/#{@game_prompt.id}/waiting"

    assert_response :success
    # The page should render without error, implying game_prompt was loaded
  end

  test "waiting should require authentication" do
    end_session

    get "/prompts/#{@game_prompt.id}/waiting"

    assert_response :redirect
  end

  # Tests for PromptsController#voting

  test "voting should display voting page when no vote exists" do
    # Ensure no vote exists
    Vote.where(user_id: @user.id, game_prompt_id: @game_prompt.id).delete_all

    # Create some answers to vote on
    Answer.where(user_id: users(:two).id, game_prompt_id: @game_prompt.id).delete_all
    Answer.create!(
      user_id: users(:two).id,
      game_prompt_id: @game_prompt.id,
      game_id: @game.id,
      text: "Answer 1"
    )

    get "/prompts/#{@game_prompt.id}/voting"

    assert_response :success
  end

  test "voting should redirect to results when vote already exists" do
    # Create a vote for this user
    answer = Answer.create!(
      user_id: users(:two).id,
      game_prompt_id: @game_prompt.id,
      game_id: @game.id,
      text: "Answer to vote for"
    )
    Vote.create!(
      user_id: @user.id,
      answer_id: answer.id,
      game_id: @game.id,
      game_prompt_id: @game_prompt.id
    )

    get "/prompts/#{@game_prompt.id}/voting"

    assert_redirected_to controller: "prompts", action: "results", id: @game_prompt.id
  end

  test "voting should exclude current user's answer from voting options" do
    # Ensure no vote exists
    Vote.where(user_id: @user.id, game_prompt_id: @game_prompt.id).delete_all

    # Create answer from current user
    Answer.create!(
      user_id: @user.id,
      game_prompt_id: @game_prompt.id,
      game_id: @game.id,
      text: "Current user answer"
    )

    # Create answer from other user
    Answer.where(user_id: users(:two).id, game_prompt_id: @game_prompt.id).delete_all
    Answer.create!(
      user_id: users(:two).id,
      game_prompt_id: @game_prompt.id,
      game_id: @game.id,
      text: "Other user answer"
    )

    get "/prompts/#{@game_prompt.id}/voting"

    assert_response :success
    # Verify that current user's answer is not shown as a voting option
    assert_select "body" do
      assert_select "*", text: /Current user answer/, count: 0
      assert_select "*", text: /Other user answer/
    end
  end

  test "voting should load answers for current game and prompt" do
    # Ensure no vote exists
    Vote.where(user_id: @user.id, game_prompt_id: @game_prompt.id).delete_all

    # Create answer for current game prompt
    Answer.where(user_id: users(:two).id, game_prompt_id: @game_prompt.id).delete_all
    Answer.create!(
      user_id: users(:two).id,
      game_prompt_id: @game_prompt.id,
      game_id: @game.id,
      text: "Answer for current prompt"
    )

    # Create answer for different game prompt (shouldn't appear)
    other_prompt = game_prompts(:two)
    Answer.where(user_id: users(:two).id, game_prompt_id: other_prompt.id).delete_all
    Answer.create!(
      user_id: users(:two).id,
      game_prompt_id: other_prompt.id,
      game_id: @game.id,
      text: "Answer for different prompt"
    )

    get "/prompts/#{@game_prompt.id}/voting"

    assert_response :success
    # Verify only answers for current game prompt are shown
    assert_select "body" do
      assert_select "*", text: /Answer for current prompt/
      assert_select "*", text: /Answer for different prompt/, count: 0
    end
  end

  test "voting should require authentication" do
    end_session

    get "/prompts/#{@game_prompt.id}/voting"

    assert_response :redirect
  end

  # Tests for PromptsController#results

  test "results should display results page when room status is not Answering" do
    @room.update!(status: RoomStatus::Results)

    get "/prompts/#{@game_prompt.id}/results"

    assert_response :success
  end

  test "results should redirect to show when room status is Answering" do
    @room.update!(status: RoomStatus::Answering)

    get "/prompts/#{@game_prompt.id}/results"

    assert_redirected_to controller: "prompts", action: "show", id: @game_prompt.id
  end

  test "results should use current game prompt id for redirect when status is Answering" do
    @room.update!(status: RoomStatus::Answering)
    current_prompt = @game.current_game_prompt

    get "/prompts/#{@game_prompt.id}/results"

    assert_redirected_to controller: "prompts", action: "show", id: current_prompt.id
  end

  test "results should handle missing current game prompt gracefully" do
    @room.update!(status: RoomStatus::Results)

    get "/prompts/#{@game_prompt.id}/results"

    # Should render successfully when status is not Answering
    assert_response :success
  end

  test "results should require authentication" do
    end_session
    @room.update!(status: RoomStatus::Results)

    get "/prompts/#{@game_prompt.id}/results"

    # Results page should still render or redirect
    assert_response :redirect
  end

  # Tests for different room status transitions

  test "should handle full workflow from show to waiting to voting to results" do
    # Start at show (Answering status)
    @room.update!(status: RoomStatus::Answering)
    Answer.where(user_id: @user.id, game_prompt_id: @game_prompt.id).delete_all

    get "/prompts/#{@game_prompt.id}"
    assert_response :success

    # Create answer, go to waiting
    Answer.create!(
      user_id: @user.id,
      game_prompt_id: @game_prompt.id,
      game_id: @game.id,
      text: "My answer"
    )

    get "/prompts/#{@game_prompt.id}"
    assert_redirected_to controller: "prompts", action: "waiting", id: @game_prompt.id

    # Room transitions to Voting
    @room.update!(status: RoomStatus::Voting)

    get "/prompts/#{@game_prompt.id}/waiting"
    assert_redirected_to controller: "prompts", action: "voting", id: @game_prompt.id

    # Vote on an answer
    other_answer = Answer.create!(
      user_id: users(:two).id,
      game_prompt_id: @game_prompt.id,
      game_id: @game.id,
      text: "Other answer"
    )
    Vote.create!(
      user_id: @user.id,
      answer_id: other_answer.id,
      game_id: @game.id,
      game_prompt_id: @game_prompt.id
    )

    get "/prompts/#{@game_prompt.id}/voting"
    assert_redirected_to controller: "prompts", action: "results", id: @game_prompt.id

    # View results
    @room.update!(status: RoomStatus::Results)
    get "/prompts/#{@game_prompt.id}/results"
    assert_response :success
  end
end

require "test_helper"

class AnswersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @room = rooms(:one)
    @user = users(:one)
    @game = games(:one)
    @game_prompt = game_prompts(:one)

    # Clean up existing data to avoid constraint issues
    Answer.where(user_id: @user.id).delete_all

    # Set up the room and game
    @room.update!(current_game_id: @game.id, status: RoomStatus::Answering)
    @game.update!(current_game_prompt_id: @game_prompt.id)
    @user.update!(room_id: @room.id)
    resume_session_as(@room.code, @user.name)
  end

  # Critical Path 1: Successfully creating an answer

  test "create should save new answer when valid" do
    assert_difference("Answer.count", 1) do
      post "/answer", params: {
        text: "Test answer",
        prompt_id: @game_prompt.id
      }
    end
  end

  test "create should associate answer with correct user, game, and prompt" do
    post "/answer", params: {
      text: "My answer",
      prompt_id: @game_prompt.id
    }

    answer = Answer.last
    assert_equal "My answer", answer.text
    assert_equal @user.id, answer.user_id
    assert_equal @game.id, answer.game_id
    assert_equal @game_prompt.id, answer.game_prompt_id
  end

  test "create should redirect to waiting page when not all users have answered" do
    # Add another user to the room so we're not the last one
    User.create!(name: "TestUser2", room_id: @room.id)

    post "/answer", params: {
      text: "Test answer",
      prompt_id: @game_prompt.id
    }

    # Should redirect to waiting since not all users have answered yet
    assert_redirected_to controller: "prompts", action: "waiting", id: @game_prompt.id
  end

  # Critical Path 2: Preventing duplicate answers

  test "create should not save duplicate answer for same user and prompt" do
    # Add another user so we don't redirect to voting
    User.create!(name: "TestUser2", room_id: @room.id)

    # Create first answer
    Answer.create!(
      text: "First answer",
      user_id: @user.id,
      game_id: @game.id,
      game_prompt_id: @game_prompt.id
    )

    # Attempt duplicate
    assert_no_difference("Answer.count") do
      post "/answer", params: {
        text: "Duplicate answer",
        prompt_id: @game_prompt.id
      }
    end

    # Should redirect to waiting since answer exists and not all users answered
    assert_redirected_to controller: "prompts", action: "waiting", id: @game_prompt.id
  end

  # Critical Path 3: Redirect to voting when all users have answered

  test "create should redirect to voting when all users in room have answered" do
    # Create another user in the same room
    user2 = User.create!(name: "TestUser2", room_id: @room.id)

    # User 2 submits answer first
    Answer.create!(
      text: "User 2 answer",
      user_id: user2.id,
      game_id: @game.id,
      game_prompt_id: @game_prompt.id
    )

    # User 1 submits answer (last one)
    post "/answer", params: {
      text: "User 1 answer",
      prompt_id: @game_prompt.id
    }

    # Should redirect to voting since all users have answered
    assert_redirected_to controller: "prompts", action: "voting", id: @game_prompt.id
  end

  # Critical Path 4: Authentication

  test "create should require authentication" do
    end_session

    post "/answer", params: {
      text: "Test answer",
      prompt_id: @game_prompt.id
    }

    assert_redirected_to new_session_path
  end

  # Critical Path 5: Job triggering

  test "create should trigger AnswerSubmittedJob after answer is created" do
    assert_enqueued_with(job: AnswerSubmittedJob) do
      post "/answer", params: {
        text: "Test answer",
        prompt_id: @game_prompt.id
      }
    end
  end
end

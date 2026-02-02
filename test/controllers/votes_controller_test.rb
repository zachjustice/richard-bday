require "test_helper"
require "minitest/stub_any_instance"

class VotesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @room = rooms(:one)
    @user = users(:one)
    @game = games(:one)
    @game_prompt = game_prompts(:one)
    @answer = answers(:one)

    # Set up the room with the current game
    @room.update!(current_game_id: @game.id)
    @user.update!(room_id: @room.id)
    resume_session_as(@room.code, @user.name)
  end

  # Tests for VotesController#create - successful vote submission

  test "create should save a new vote when valid" do
    assert_difference("Vote.count", 1) do
      post "/vote", params: {
        answer_id: @answer.id,
        game_prompt_id: @game_prompt.id
      }
    end
  end

  test "create should associate vote with correct answer" do
    post "/vote", params: {
      answer_id: @answer.id,
      game_prompt_id: @game_prompt.id
    }

    vote = Vote.last
    assert_equal @answer.id, vote.answer_id
  end

  test "create should associate vote with current user" do
    post "/vote", params: {
      answer_id: @answer.id,
      game_prompt_id: @game_prompt.id
    }

    vote = Vote.last
    assert_equal @user.id, vote.user_id
  end

  test "create should associate vote with current game" do
    post "/vote", params: {
      answer_id: @answer.id,
      game_prompt_id: @game_prompt.id
    }

    vote = Vote.last
    assert_equal @game.id, vote.game_id
  end

  test "create should associate vote with correct game prompt" do
    post "/vote", params: {
      answer_id: @answer.id,
      game_prompt_id: @game_prompt.id
    }

    vote = Vote.last
    assert_equal @game_prompt.id, vote.game_prompt_id
  end

  test "create should redirect to results page after successful vote" do
    post "/vote", params: {
      answer_id: @answer.id,
      game_prompt_id: @game_prompt.id
    }

    assert_redirected_to controller: "game_prompts", action: "results", id: @game_prompt.id
  end

  # Tests for VotesController#create - duplicate vote prevention

  test "create should not save duplicate vote for same user, answer, game, and game_prompt" do
    # Create initial vote
    Vote.create!(
      answer_id: @answer.id,
      user_id: @user.id,
      game_id: @game.id,
      game_prompt_id: @game_prompt.id
    )

    # Attempt to create duplicate vote
    assert_no_difference("Vote.count") do
      post votes_path, params: {
        answer_id: @answer.id,
        game_prompt_id: @game_prompt.id
      }
    end
  end

  test "create should redirect to results page when vote already exists" do
    # Create initial vote
    Vote.create!(
      answer_id: @answer.id,
      user_id: @user.id,
      game_id: @game.id,
      game_prompt_id: @game_prompt.id
    )

    # Attempt duplicate vote
    post votes_path, params: {
      answer_id: @answer.id,
      game_prompt_id: @game_prompt.id
    }

    assert_redirected_to controller: "game_prompts", action: "results", id: @game_prompt.id
  end

  # Tests for VotesController#create - redirect to results when all users voted

  test "create should redirect to results when all users in room have voted" do
    # Create another user in the same room
    user2 = User.create!(name: "TestUser2", room_id: @room.id)

    # User 1 votes (via the post request)
    post votes_path, params: {
      answer_id: @answer.id,
      game_prompt_id: @game_prompt.id
    }

    # User 2 votes
    Vote.create!(
      answer_id: @answer.id,
      user_id: user2.id,
      game_id: @game.id,
      game_prompt_id: @game_prompt.id
    )

    # Verify redirect happens
    assert_redirected_to controller: "game_prompts", action: "results", id: @game_prompt.id
  end

  test "create should redirect to results when vote count equals user count" do
    # Pre-create votes for all users except current user
    # Room has 1 user (@user) in setup

    # Now submit the final vote
    users_count = User.where(room_id: @room.id).count
    Vote.new(
      user_id: 1,
      game: @answer.game,
      answer: @answer,
      game_prompt: @game_prompt
    ).save!
    post votes_path, params: {
      answer_id: @answer.id,
      game_prompt_id: @game_prompt.id
    }

    # Since all users have now voted, should redirect to results
    votes_count = Vote.where(game_prompt: @game_prompt).count
    assert votes_count >= users_count

    assert_redirected_to controller: "game_prompts", action: "results", id: @game_prompt.id
  end

  # Tests for VotesController#create - failed vote scenarios
  test "create should redirect to prompt show page when vote fails to save v2" do
    # Force a validation failure by temporarily patching the save method
    Vote.stub_any_instance :save, false do
      post "/vote", params: {
        answer_id: @answer.id,
        game_prompt_id: @game_prompt.id
      }

      assert_redirected_to controller: "game_prompts", action: "show", id: @game_prompt.id
    end
  end

  test "create should trigger VoteSubmittedJob after vote is created" do
    assert_enqueued_with(job: VoteSubmittedJob) do
      post votes_path, params: {
        answer_id: @answer.id,
        game_prompt_id: @game_prompt.id
      }
    end
  end
end

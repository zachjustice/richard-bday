# frozen_string_literal: true

require "test_helper"

class AnswerSmoothingJobTest < ActiveSupport::TestCase
  def setup
    # Create isolated test data to avoid fixture conflicts
    suffix = SecureRandom.hex(4)
    @room = Room.create!(code: "job#{suffix}", status: RoomStatus::WaitingRoom, smooth_answers: true)
    @story = Story.create!(title: "JobTest Story #{suffix}", text: "Test text", original_text: "Test", published: true)
    @game = Game.create!(story: @story, room: @room)
    @blank = Blank.create!(story: @story, tags: "noun")
    @editor = Editor.create!(username: "job#{suffix}", email: "job#{suffix}@test.com", password: "password123", password_confirmation: "password123")
    @prompt = Prompt.create!(description: "Test prompt", tags: "action", creator: @editor)
    @game_prompt = GamePrompt.create!(game: @game, prompt: @prompt, blank: @blank, order: 0)
    @user = User.create!(name: "Job#{suffix[0..5]}", room: @room, role: User::PLAYER)

    @answer = Answer.create!(
      game_prompt: @game_prompt,
      game: @game,
      user: @user,
      text: "I go to the doctor",
      won: true
    )
  end

  test "skips non-winning answers" do
    @answer.update!(won: false)

    AnswerSmoothingService.stub_any_instance(:call, "smoothed text") do
      AnswerSmoothingJob.perform_now(@answer)
    end

    @answer.reload
    assert_nil @answer.smoothed_text
  end

  test "skips if smoothed_text already present" do
    @answer.update!(smoothed_text: "already smoothed")

    service_called = false
    AnswerSmoothingService.stub_any_instance(:call, -> { service_called = true; "new smoothed" }) do
      AnswerSmoothingJob.perform_now(@answer)
    end

    @answer.reload
    assert_equal "already smoothed", @answer.smoothed_text
  end

  test "skips if room has smooth_answers disabled" do
    @room.update!(smooth_answers: false)

    AnswerSmoothingService.stub_any_instance(:call, "smoothed text") do
      AnswerSmoothingJob.perform_now(@answer)
    end

    @answer.reload
    assert_nil @answer.smoothed_text
  end

  test "calls service and saves result when text differs" do
    AnswerSmoothingService.stub_any_instance(:call, "went to the doctor") do
      AnswerSmoothingJob.perform_now(@answer)
    end

    @answer.reload
    assert_equal "went to the doctor", @answer.smoothed_text
  end

  test "does not update if smoothed matches original" do
    AnswerSmoothingService.stub_any_instance(:call, @answer.text) do
      AnswerSmoothingJob.perform_now(@answer)
    end

    @answer.reload
    assert_nil @answer.smoothed_text
  end
end

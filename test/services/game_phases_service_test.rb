# frozen_string_literal: true

require "test_helper"

class GamePhasesServiceTest < ActiveSupport::TestCase
  setup do
    suffix = SecureRandom.hex(4)

    Turbo::StreamsChannel.define_singleton_method(:broadcast_replace_to) { |*| }
    Turbo::StreamsChannel.define_singleton_method(:broadcast_action_to) { |*| }
    Turbo::StreamsChannel.define_singleton_method(:broadcast_append_to) { |*| }
    Turbo::StreamsChannel.define_singleton_method(:broadcast_remove_to) { |*| }

    @room = Room.create!(code: "gp#{suffix}", status: RoomStatus::Answering, voting_style: "vote_once")
    @story = Story.create!(title: "GP #{suffix}", text: "test", original_text: "test", published: true)
    @game = Game.create!(story: @story, room: @room)
    @blank = Blank.create!(story: @story, tags: "noun")
    @editor = Editor.create!(username: "gp#{suffix}", email: "gp#{suffix}@test.com", password: "password123", password_confirmation: "password123")
    @prompt = Prompt.create!(description: "GP prompt #{suffix}", tags: "noun", creator: @editor)
    @game_prompt = GamePrompt.create!(game: @game, prompt: @prompt, blank: @blank, order: 0)

    @room.update!(current_game: @game)
    @game.update!(current_game_prompt: @game_prompt)
  end

  test "cancel_scheduled_job returns early when job_id is nil" do
    service = GamePhasesService.new(@room)

    # Should not raise any errors when job_id is nil
    assert_nothing_raised do
      service.send(:cancel_scheduled_job, nil)
    end
  end

  test "cancel_scheduled_job returns early when job_id is blank string" do
    service = GamePhasesService.new(@room)

    # Should not raise any errors when job_id is blank
    assert_nothing_raised do
      service.send(:cancel_scheduled_job, "")
    end
  end

  test "cancel_scheduled_job handles missing SolidQueue gracefully" do
    service = GamePhasesService.new(@room)

    # Even with a valid-looking job_id, should not raise if SolidQueue tables don't exist
    assert_nothing_raised do
      service.send(:cancel_scheduled_job, "some-fake-job-id")
    end
  end

  test "move_to_voting attempts to cancel answering timer job" do
    @game.update!(answering_timer_job_id: "test-answering-job-id")

    service = GamePhasesService.new(@room)

    # Track if cancel_scheduled_job was called with the correct job_id
    called_with = nil
    service.define_singleton_method(:cancel_scheduled_job) do |job_id|
      called_with = job_id
    end

    # Stub broadcast methods to avoid ActionCable errors in test
    service.define_singleton_method(:update_room_status_view) { |*| }

    service.move_to_voting

    assert_equal "test-answering-job-id", called_with
  end

  test "move_to_results attempts to cancel voting timer job" do
    @room.update!(status: RoomStatus::Voting)
    @game.update!(voting_timer_job_id: "test-voting-job-id")

    service = GamePhasesService.new(@room)

    # Track if cancel_scheduled_job was called with the correct job_id
    called_with = nil
    service.define_singleton_method(:cancel_scheduled_job) do |job_id|
      called_with = job_id
    end

    # Stub broadcast methods to avoid ActionCable errors in test
    service.define_singleton_method(:update_room_status_view) { |*| }

    service.move_to_results

    assert_equal "test-voting-job-id", called_with
  end
end

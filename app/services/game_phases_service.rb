class GamePhasesService
  def initialize(room)
    if room.is_a?(Integer)
      @room = Room.find(room)
    elsif room.is_a?(Room)
      @room = room
    else
      raise "Invalid parameter. 'room': #{room}."
    end
  end

  def move_to_voting
    User.players.where(room: @room).update_all(status: UserStatus::Voting)

    # Cancel answering timer if everyone answered early
    cancel_scheduled_job(@room.current_game.answering_timer_job_id)

    # Schedule deadline for voting
    next_game_phase_time = Time.now + @room.time_to_vote_seconds + GameConstants::COUNTDOWN_FORGIVENESS_SECONDS
    @room.update!(status: RoomStatus::Voting)

    status_data = RoomStatusService.new(@room).call
    update_room_status_view("rooms/status/voting", status_data)

    Turbo::StreamsChannel.broadcast_action_to(
      "rooms:#{@room.id}:nav-updates",
      action: :navigate,
      target: "/game_prompts/#{@room.current_game.current_game_prompt.id}/voting",
    )

    # Start timer for voting
    job = VotingTimesUpJob.set(wait_until: next_game_phase_time).perform_later(@room, @room.current_game.current_game_prompt_id)
    @room.current_game.update!(next_game_phase_time: next_game_phase_time, voting_timer_job_id: job.job_id)
  end

  def move_to_results
    # Cancel voting timer if everyone voted early
    cancel_scheduled_job(@room.current_game.voting_timer_job_id)

    @room.update!(status: RoomStatus::Results)

    status_data = RoomStatusService.new(@room).call
    update_room_status_view("rooms/status/results", status_data)

    Turbo::StreamsChannel.broadcast_action_to(
      "rooms:#{@room.id}:nav-updates",
      action: :navigate,
      target: "/game_prompts/#{@room.current_game.current_game_prompt.id}/results",
    )
  end

  # Broadcast Turbo Stream to update the status page with the given partial and status_data
  def update_room_status_view(partial, status_data, remove_sidebar = false)
    Turbo::StreamsChannel.broadcast_action_to(
      "rooms:#{@room.id}:status",
      action: :update,
      target: "turbo-target-status-page",
      partial: partial,
      locals: status_data
    )

    if remove_sidebar
      Turbo::StreamsChannel.broadcast_action_to(
        "rooms:#{@room.id}:status",
        action: :remove,
        target: "turbo-target-sidebar"
      )
    else
      Turbo::StreamsChannel.broadcast_action_to(
        "rooms:#{@room.id}:status",
        action: :update,
        target: "turbo-target-sidebar",
        partial: "rooms/status/sidebar",
        locals: status_data
      )
    end
  end

  private

  def cancel_scheduled_job(job_id)
    return if job_id.blank?
    return unless defined?(SolidQueue::ScheduledExecution)

    SolidQueue::ScheduledExecution.joins(:job)
      .where(solid_queue_jobs: { active_job_id: job_id })
      .delete_all
  rescue ActiveRecord::StatementInvalid
    # SolidQueue tables may not exist in test environment
  end
end

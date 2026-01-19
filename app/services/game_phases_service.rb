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

    # Schedule deadline for voting
    next_game_phase_time = Time.now + @room.time_to_vote_seconds + GameConstants::COUNTDOWN_FORGIVENESS_SECONDS
    @room.update!(status: RoomStatus::Voting)
    @room.current_game.update!(next_game_phase_time: next_game_phase_time)

    status_data = RoomStatusService.new(@room).call
    update_room_status_view("rooms/status/voting", status_data)

    # Keep ActionCable broadcast for backward compatibility
    ActionCable.server.broadcast(
      "rooms:#{@room.id.to_i}",
      Events.create_start_voting_event(@room.current_game.current_game_prompt.id)
    )

    # Start timer for answers
    VotingTimesUpJob.set(wait_until: next_game_phase_time).perform_later(@room, @room.current_game.current_game_prompt_id)
  end

  def move_to_results
    @room.update!(status: RoomStatus::Results)

    status_data = RoomStatusService.new(@room).call
    update_room_status_view("rooms/status/results", status_data)

    # Keep ActionCable broadcast for backward compatibility
    ActionCable.server.broadcast(
      "rooms:#{@room.id.to_i}",
      Events.create_voting_done_event(@room.current_game.current_game_prompt_id)
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
end

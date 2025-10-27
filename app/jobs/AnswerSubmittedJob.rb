class AnswerSubmittedJob < ApplicationJob
  def perform(answer)
    room = answer.game.room

    Turbo::StreamsChannel.broadcast_replace_to(
      "rooms:#{room.id}:answers",
      target: "user_list_user_#{answer.user.id}",
      partial: "rooms/partials/user_with_status_item",
      locals: { user: answer.user, completed: true }
    )

    ActionCable.server.broadcast(
      "rooms:#{room.id.to_i}",
      Events.create_answer_submitted_event(answer.user.name)
    )

    # if the room is in "Answering" status, return early,
    # To avoid potential bugs if this job is triggered twice for some reason
    if room.status != RoomStatus::Answering
      return
    end

    users_in_room = User.players.where(room: room).count
    submitted_answers = Answer.where(game_prompt_id: answer.game_prompt_id).count

    # Check if its time to start voting!
    if submitted_answers >= users_in_room && room.status == RoomStatus::Answering
      room.update!(status: RoomStatus::Voting)

      # Broadcast Turbo Stream to update the status page to voting view
      status_data = RoomStatusService.new(room.id).call
      Turbo::StreamsChannel.broadcast_action_to(
        "rooms:#{room.id}:status",
        action: :update,
        target: "status-content-inner",
        partial: "rooms/status/voting",
        locals: status_data
      )

      # Keep ActionCable broadcast for backward compatibility
      ActionCable.server.broadcast(
        "rooms:#{room.id.to_i}",
        Events.create_start_voting_event(answer.game_prompt_id)
      )
    end
  end
end

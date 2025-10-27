class VoteSubmittedJob < ApplicationJob
  def perform(vote)
    room = vote.game.room
    user = vote.user

    Turbo::StreamsChannel.broadcast_replace_to(
      "rooms:#{room.id}:votes",
      target: "user_list_user_#{user.id}",
      partial: "rooms/partials/user_with_status_item",
      locals: { user: user, completed: true }
    )

    ActionCable.server.broadcast(
      "rooms:#{room.id.to_i}",
      Events.create_vote_submitted_event(vote)
    )

    # Check the room status to avoid bugs from re-running this job
    if room.status != RoomStatus::Voting
      return
    end

    users_in_room = User.players.where(room_id: room.id).count
    submitted_votes = Vote.where(game_prompt_id: vote.game_prompt_id).count

    # Check if its time to view the results!
    if submitted_votes >= users_in_room && room.status == RoomStatus::Voting
      room.update!(status: RoomStatus::Results)

      # Broadcast Turbo Stream to update the status page to results view
      status_data = RoomStatusService.new(room.id).call
      Turbo::StreamsChannel.broadcast_action_to(
        "rooms:#{room.id}:status",
        action: :update,
        target: "status-content-inner",
        partial: "rooms/status/results",
        locals: status_data
      )

      # Keep ActionCable broadcast for backward compatibility
      ActionCable.server.broadcast(
        "rooms:#{room.id.to_i}",
        Events.create_voting_done_event(vote)
      )
    end
  end
end

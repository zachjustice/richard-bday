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

    users_in_room = User.where(room_id: room.id).count
    submitted_votes = Vote.where(game_prompt_id: vote.game_prompt_id).count

    if submitted_votes >= users_in_room && room.status == RoomStatus::Voting
      Room.find_by(id: room.id).update!(
        status: RoomStatus::Results
      )
      ActionCable.server.broadcast(
        "rooms:#{room.id.to_i}",
        Events.create_voting_done_event(vote)
      )
    end
  end
end

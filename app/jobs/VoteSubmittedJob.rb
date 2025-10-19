class VoteSubmittedJob < ApplicationJob
  def perform(vote)
    ActionCable.server.broadcast(
      "rooms:#{vote.game.room.id.to_i}",
      Events.create_vote_submitted_event(vote)
    )

    # Check the room status to avoid bugs from re-running this job
    if vote.game.room.status != RoomStatus::Voting
      return
    end

    users_in_room = User.where(room_id: vote.game.room.id).count
    submitted_votes = Vote.where(game_prompt_id: vote.game_prompt_id).count

    if submitted_votes >= users_in_room && vote.game.room.status == RoomStatus::Voting
      Room.find_by(id: vote.game.room_id).update!(
        status: RoomStatus::Results
      )
      ActionCable.server.broadcast(
        "rooms:#{vote.game.room.id.to_i}",
        Events.create_voting_done_event(vote)
      )
    end
  end
end

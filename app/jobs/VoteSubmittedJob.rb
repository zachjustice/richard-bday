class VoteSubmittedJob < ApplicationJob
  def perform(vote)
    ActionCable.server.broadcast(
      "rooms:#{vote.room_id.to_i}",
      Events.create_vote_submitted_event(vote)
    )

    users_in_room = User.where(room_id: vote.room_id).count
    submitted_votes = Vote.where(prompt_id: vote.prompt_id, room_id: vote.room_id).count

    if submitted_votes >= users_in_room
      Room.find_by(id: vote.room_id).update!(
        status: RoomStatus::Results
      )
      ActionCable.server.broadcast(
        "rooms:#{vote.room_id.to_i}",
        Events.create_voting_done_event(vote)
      )
    end
  end
end

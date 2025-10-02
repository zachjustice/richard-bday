class AnswerSubmittedJob < ApplicationJob
  def perform(answer)
    ActionCable.server.broadcast(
      "rooms:#{answer.room_id.to_i}",
      Events.create_answer_submitted_event(answer.user.name)
    )

    users_in_room = User.where(room_id: answer.room_id).count
    submitted_answers = Answer.where(prompt_id: answer.prompt_id, room_id: answer.room_id).count
    if submitted_answers >= users_in_room
      Room.find(answer.room_id).update!(status: RoomStatus::Voting)
      ActionCable.server.broadcast(
        "rooms:#{answer.room_id.to_i}",
        Events.create_start_voting_event(answer.prompt_id)
      )
    end
  end
end

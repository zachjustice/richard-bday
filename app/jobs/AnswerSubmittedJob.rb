class AnswerSubmittedJob < ApplicationJob
  def perform(answer)
    room = answer.game.room
    ActionCable.server.broadcast(
      "rooms:#{room.id.to_i}",
      Events.create_answer_submitted_event(answer.user.name)
    )

    # if the room is in "Answering" status, return early,
    # To avoid potential bugs if this job is triggered twice for some reason
    if room.status != RoomStatus::Answering
      return
    end

    users_in_room = User.where(room: room).count
    submitted_answers = Answer.where(game_prompt_id: answer.game_prompt_id).count
    if submitted_answers >= users_in_room && room.status == RoomStatus::Answering
      room.update!(status: RoomStatus::Voting)
      ActionCable.server.broadcast(
        "rooms:#{room.id.to_i}",
        Events.create_start_voting_event(answer.game_prompt_id)
      )
    end
  end
end

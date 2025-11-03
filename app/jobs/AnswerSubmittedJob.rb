class AnswerSubmittedJob < ApplicationJob
  def perform(answer)
    room = answer.game.room

    # if the room is in "Answering" status, return early.
    # if the room has moved on passed the game_prompt for which the answer was submitted, return early.
    room.reload
    if room.status != RoomStatus::Answering || room.current_game.current_game_prompt_id != answer.game_prompt_id
      return
    end

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

    users_in_room = User.players.where(room: room).count
    submitted_answers = Answer.where(game_prompt_id: answer.game_prompt_id).count

    # Check if its time to start voting!
    if submitted_answers >= users_in_room && room.status == RoomStatus::Answering
      GamePhasesService.new(room).move_to_voting
    end
  end
end

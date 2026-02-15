class AnswerSubmittedJob < ApplicationJob
  def perform(answer)
    room = answer.game.room

    # if the room is in "Answering" status, return early.
    # if the room has moved on passed the game_prompt for which the answer was submitted, return early.
    room.reload
    if room.status != RoomStatus::Answering || room.current_game.current_game_prompt_id != answer.game_prompt_id
      return
    end

    answer.user.update!(status: UserStatus::Answered)

    Turbo::StreamsChannel.broadcast_replace_to(
      "rooms:#{room.id}:answers",
      target: "user_list_user_#{answer.user.id}",
      partial: "rooms/partials/user_with_status_item",
      locals: { user: answer.user, completed: true, color: "blue" }
    )

    # Update roaming avatar status badge
    Turbo::StreamsChannel.broadcast_replace_to(
      "rooms:#{room.id}:avatar-status",
      target: "waiting_room_user_#{answer.user.id}",
      partial: "rooms/partials/user_list_item",
      locals: { user: answer.user }
    )

    users_in_room = User.players.where(room: room).count
    answered_users = User.players.where(room: room, status: UserStatus::Answered).count

    # Update "X of N done" counter
    Turbo::StreamsChannel.broadcast_action_to(
      "rooms:#{room.id}:avatar-status",
      action: :update,
      target: "players-done-count",
      html: "#{answered_users} of #{users_in_room}"
    )

    # Check if its time to start voting!
    if answered_users >= users_in_room && room.status == RoomStatus::Answering
      GamePhasesService.new(room).move_to_voting
    end
  end
end

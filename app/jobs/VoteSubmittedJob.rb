class VoteSubmittedJob < ApplicationJob
  def perform(vote)
    room = vote.game.room
    user = vote.user

    # if the room is in "Answering" status, return early.
    # if the room has moved on passed the game_prompt for which the answer was submitted, return early.
    room.reload
    if room.status != RoomStatus::Voting || room.current_game.current_game_prompt_id != vote.game_prompt_id
      return
    end

    vote.user.update!(status: UserStatus::Voted)

    Turbo::StreamsChannel.broadcast_replace_to(
      "rooms:#{room.id}:votes",
      target: "user_list_user_#{user.id}",
      partial: "rooms/partials/user_with_status_item",
      locals: { user: user, completed: true, color: "indigo" }
    )

    ActionCable.server.broadcast(
      "rooms:#{room.id.to_i}",
      Events.create_vote_submitted_event(vote)
    )

    users_in_room = User.players.where(room_id: room.id).count
    voted_users = User.players.where(room_id: room.id, status: UserStatus::Voted).count

    # Check if its time to view the results!
    if voted_users >= users_in_room && room.status == RoomStatus::Voting
      GamePhasesService.new(room).move_to_results
    end
  end
end

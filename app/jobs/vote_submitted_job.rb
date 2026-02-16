class VoteSubmittedJob < ApplicationJob
  def perform(vote)
    room = vote.game.room

    # Audience votes are cosmetic - skip status updates and auto-advance
    return if vote.audience?

    user = vote.user

    # if the room is in "Answering" status, return early.
    # if the room has moved on passed the game_prompt for which the answer was submitted, return early.
    room.reload
    if room.status != RoomStatus::Voting || room.current_game.current_game_prompt_id != vote.game_prompt_id
      return
    end

    # For ranked voting, check if user has submitted all required ranks before marking as voted
    if room.ranked_voting?
      answers_count = Answer.where(
        game_prompt_id: vote.game_prompt_id
      ).where.not(user_id: user.id).count  # Exclude user's own answer
      required_ranks = [ answers_count, room.max_ranks ].min
      submitted_ranks = Vote.where(
        user_id: user.id,
        game_prompt_id: vote.game_prompt_id
      ).count

      # Only mark as voted when all ranks are submitted
      return unless submitted_ranks >= required_ranks
    end

    vote.user.update!(status: UserStatus::Voted)

    Turbo::StreamsChannel.broadcast_replace_to(
      "rooms:#{room.id}:votes",
      target: "user_list_user_#{user.id}",
      partial: "rooms/partials/user_with_status_item",
      locals: { user: user, completed: true, color: "indigo" }
    )

    # Update roaming avatar status badge
    Turbo::StreamsChannel.broadcast_replace_to(
      "rooms:#{room.id}:avatar-status",
      target: "waiting_room_user_#{user.id}",
      partial: "rooms/partials/user_list_item",
      locals: { user: user }
    )

    users_in_room = User.players.where(room_id: room.id).count
    voted_users = User.players.where(room_id: room.id, status: UserStatus::Voted).count

    # Update "X of N done" counter
    Turbo::StreamsChannel.broadcast_action_to(
      "rooms:#{room.id}:avatar-status",
      action: :update,
      target: "players-done-count",
      html: "#{voted_users} of #{users_in_room}"
    )

    # Check if its time to view the results!
    if voted_users >= users_in_room && room.status == RoomStatus::Voting
      GamePhasesService.new(room).move_to_results
    end
  end
end

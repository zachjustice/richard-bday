class JoinRoomJob < ApplicationJob
  def perform(user)
    room = user.room

    if user.audience?
      room.broadcast_audience_count
      return
    end

    # Broadcast Turbo Stream to append user to the waiting room list
    Turbo::StreamsChannel.broadcast_append_to(
      "rooms:#{room.id}:users",
      target: "waiting-room",
      partial: "rooms/partials/user_list_item",
      locals: { user: user, action: "joined!" }
    )
    Turbo::StreamsChannel.broadcast_action_to(
      "rooms:#{room.id}:users",
      action: :update,
      target: "waiting-room-players-count",
      html: "#{User.players.where(room: room).count} joined"
    )

    # Remove "no users yet" message via Turbo Stream
    Turbo::StreamsChannel.broadcast_remove_to(
      "rooms:#{room.id}:users",
      target: "no-users-yet"
    )
  end
end

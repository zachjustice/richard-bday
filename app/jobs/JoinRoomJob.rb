class JoinRoomJob < ApplicationJob
  def perform(user)
    room = user.room

    # Broadcast Turbo Stream to append user to the waiting room list
    Turbo::StreamsChannel.broadcast_prepend_to(
      "rooms:#{room.id}:users",
      target: "waiting-room",
      partial: "rooms/partials/user_list_item",
      locals: { user: user, action: "joined!" }
    )
    Turbo::StreamsChannel.broadcast_action_to(
      "rooms:#{room.id}:users",
      action: :update,
      target: "waiting-room-players-count",
      html: "Players (#{User.players.where(room: room).count})"
    )

    # Remove "no users yet" message via Turbo Stream
    Turbo::StreamsChannel.broadcast_remove_to(
      "rooms:#{room.id}:users",
      target: "no-users-yet"
    )

    # Keep existing ActionCable broadcast for backward compatibility
    ActionCable.server.broadcast(
      "rooms:#{room.id.to_i}",
      Events.create_user_joined_room_event(user.name)
    )
  end
end

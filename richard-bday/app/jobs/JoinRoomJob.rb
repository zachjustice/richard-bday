class JoinRoomJob < ApplicationJob
  def perform(user)
    ActionCable.server.broadcast(
      "rooms:#{user.room_id.to_i}",
      Events.create_user_joined_room_event(user.name)
      # TODO: return html?
      # room: RoomsController.render(partial: "rooms/room", locals: { user: user })
    )
  end
end

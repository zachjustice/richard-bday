class JoinRoomJob < ApplicationJob
  def perform(user)
    puts("rooms:#{user.room_id}:new-user")
    ActionCable.server.broadcast(
      "rooms:#{user.room_id.to_i}:new-user",
      { newUser: user.name }
      # TODO: return html?
      # room: RoomsController.render(partial: "rooms/room", locals: { user: user })
    )
  end
end

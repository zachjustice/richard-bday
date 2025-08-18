class AnswerSubmittedJob < ApplicationJob
  def perform(answer)
    ActionCable.server.broadcast(
      "rooms:#{answer.room_id.to_i}",
      Events.create_answer_submitted_event(answer.user.name)
      # TODO: return html?
      # room: RoomsController.render(partial: "rooms/room", locals: { user: user })
    )
  end
end

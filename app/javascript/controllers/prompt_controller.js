import { RoomMessageHub, EventType } from "controllers/application"
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.listenerAId = RoomMessageHub.register(EventType.AnswerSubmitted, (event) => {
      console.log("RoomMessageHub:PromptController:Listener:AnswerSubmitted", event)
      return $("#users-with-submitted-answers").append(`<li>${event.user}</li>`)
    })
    this.listenerBId = RoomMessageHub.register(EventType.StartVoting, (event) => {
      console.log("RoomMessageHub:PromptController:Listener:StartVoting", event)
      window.location.href = `/prompts/${event.prompt}/voting`
    })
  }

  disconnect() {
    RoomMessageHub.deregister(EventType.NewUser, this.listenerAId)
    RoomMessageHub.deregister(EventType.StartVoting, this.listenerBId)
  }
}

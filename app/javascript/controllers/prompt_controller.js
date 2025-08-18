import { RoomMessageHub, EventType } from "controllers/application"
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.listenerId = RoomMessageHub.register(EventType.AnswerSubmitted, (event) => {
      console.log("RoomMessageHub:PromptController:Listener:AnswerSubmitted", event)
      return $("[data-channel='waiting-room']").append(`<li>${event.newUser}</li>`)
    })
    this.listenerBId = RoomMessageHub.register(EventType.NextPrompt, (event) => {
      console.log("RoomMessageHub:PromptController:Listener:NextPrompt", event)
      window.location.href = `/prompts/${event.prompt}`
    })
  }

  disconnect() {
    RoomMessageHub.deregister(EventType.NewUser, this.listenerId)
  }
}

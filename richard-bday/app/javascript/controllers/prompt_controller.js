import { RoomMessageHub, EventType } from "controllers/application"
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    RoomMessageHub.register(EventType.NewPrompt, (event) => {
      console.log("RoomMessageHub:PromptController:Listener:NewPrompt", event)
      // refresh the page, let the controller show the new correct view
      window.location.href = `/prompts/${event.prompt}`
    })

    RoomMessageHub.register(EventType.StartVoting, (event) => {
      console.log("RoomMessageHub:PromptController:Listener:StartVoting", event)
      window.location.href = `/prompts/${event.prompt}/voting`
    })
  }

  disconnect() {
  }
}

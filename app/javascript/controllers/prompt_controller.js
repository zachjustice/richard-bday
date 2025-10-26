import { RoomMessageHub, EventType } from "controllers/application"
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    RoomMessageHub.register(EventType.NewPrompt, (event) => {
      console.log("RoomMessageHub:PromptController:Listener:NewPrompt", event)
      // Should these actions happen server side?
      Turbo.visit(`/prompts/${event.prompt}`)
    })

    RoomMessageHub.register(EventType.StartVoting, (event) => {
      console.log("RoomMessageHub:PromptController:Listener:StartVoting", event)
      // Should these actions happen server side?
      Turbo.visit(`/prompts/${event.prompt}/voting`)
    })
  }

  disconnect() {
  }
}

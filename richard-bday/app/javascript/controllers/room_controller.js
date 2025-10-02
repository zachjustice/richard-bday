import { RoomMessageHub, EventType } from "controllers/application"
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    console.log("RoomMessageHub:RoomController:Connect")
    RoomMessageHub.register(EventType.NextPrompt, (event) => {
      console.log("RoomMessageHub:RoomController:Listener:NextPrompt", event)
      window.location.href = `/prompts/${event.prompt}`
    })
  }
  disconnect() {
  }
}

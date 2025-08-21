import { RoomMessageHub, EventType } from "controllers/application"
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    RoomMessageHub.register(EventType.NewUser, (event) => {
      console.log("RoomMessageHub:RoomController:Listener:NewUser", event)
      return $("[data-channel='waiting-room']").append(`<li>${event.newUser}</li>`)
    })

    RoomMessageHub.register(EventType.NextPrompt, (event) => {
      console.log("RoomMessageHub:RoomController:Listener:NextPrompt", event)
      window.location.href = `/prompts/${event.prompt}`
    })
  }
  disconnect() {
  }
}

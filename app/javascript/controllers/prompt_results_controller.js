import { RoomMessageHub, EventType } from "controllers/application"
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    RoomMessageHub.register(EventType.VotingDone, (event) => {
      console.log("RoomMessageHub:PromptController:Listener:VotingDone", event)
      Turbo.visit(`/prompts/${event.prompt}/results`)
    })

    RoomMessageHub.register(EventType.NextPrompt, (event) => {
      console.log("RoomMessageHub:RoomController:Listener:NextPrompt", event)
      Turbo.visit(`/prompts/${event.prompt}`)
    })

    RoomMessageHub.register(EventType.FinalResults, (event) => {
      console.log("RoomMessageHub:RoomController:Listener:FinalResults", event)
      Turbo.visit(`/prompts/${event.prompt}/results`)
    })

    // TODO: handle refreshing the page when/if a new game is started
  }

  disconnect() {
  }
}

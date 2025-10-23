import { RoomMessageHub, EventType } from "controllers/application"
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    RoomMessageHub.register(EventType.VotingDone, (event) => {
      console.log("RoomMessageHub:PromptController:Listener:VotingDone", event)
      $('#waiting-on-results').remove()
      // TODO tell the winner they won
      if ($('#done').length === 0) {
        // $("#results").append(`<h3 id="done">See the big screen for the Winner!</h3>`)
      }
    })

    RoomMessageHub.register(EventType.NextPrompt, (event) => {
      console.log("RoomMessageHub:RoomController:Listener:NextPrompt", event)
      window.location.href = `/prompts/${event.prompt}`
    })
  }

  disconnect() {
  }
}

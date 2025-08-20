import { RoomMessageHub, EventType } from "controllers/application"
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.listenerCId = RoomMessageHub.register(EventType.VoteSubmitted, (event) => {
      // user has voted; is on /results page
      console.log("RoomMessageHub:PromptController:Listener:VoteSubmitted", event)
      return $("#votes").append(`<li>${event.user}</li>`)
    })
    this.listenerDId = RoomMessageHub.register(EventType.VotingDone, (event) => {
      console.log("RoomMessageHub:PromptController:Listener:VotingDone", event)
      // refresh the page, let the controller show the new correct view
      window.location.reload();
    })
  }

  disconnect() {
    RoomMessageHub.deregister(EventType.VoteSubmitted, this.listenerCId)
    RoomMessageHub.deregister(EventType.VotingDone, this.listenerDId)
  }
}

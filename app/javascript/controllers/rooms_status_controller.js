
import { RoomMessageHub, EventType } from "controllers/application"
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    RoomMessageHub.register(EventType.NewUser, (event) => {
      console.log("RoomMessageHub:RoomController:Listener:NewUser", event)
    })

    RoomMessageHub.register(EventType.AnswerSubmitted, (event) => {
      console.log("RoomMessageHub:PromptController:Listener:AnswerSubmitted", event)
    })

    RoomMessageHub.register(EventType.StartVoting, (event) => {
      console.log("RoomMessageHub:PromptController:Listener:StartVoting", event)
      location.reload();
    })

    RoomMessageHub.register(EventType.VoteSubmitted, (event) => {
      // user has voted and is on their /results page
      console.log("RoomMessageHub:PromptController:Listener:VoteSubmitted", event)
    })

    RoomMessageHub.register(EventType.VotingDone, (event) => {
      console.log("RoomMessageHub:PromptController:Listener:VotingDone", event)
      // refresh the page, let the controller show the new correct view
      window.location.reload();
    })
  }
}
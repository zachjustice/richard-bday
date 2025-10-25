
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
      // DOM update handled automatically by Turbo Streams
    })

    RoomMessageHub.register(EventType.VoteSubmitted, (event) => {
      console.log("RoomMessageHub:PromptController:Listener:VoteSubmitted", event)
      // DOM update handled automatically by Turbo Streams
    })

    RoomMessageHub.register(EventType.VotingDone, (event) => {
      console.log("RoomMessageHub:PromptController:Listener:VotingDone", event)
      // DOM update handled automatically by Turbo Streams
    })
  }
}
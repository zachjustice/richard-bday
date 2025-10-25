
import { RoomMessageHub, EventType } from "controllers/application"
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    RoomMessageHub.register(EventType.NewUser, (event) => {
      console.log("RoomMessageHub:RoomController:Listener:NewUser", event)
      // DOM update handled automatically by Turbo Streams
    })

    RoomMessageHub.register(EventType.AnswerSubmitted, (event) => {
      console.log("RoomMessageHub:PromptController:Listener:AnswerSubmitted", event)
      if ($(`#submitted-answer-${event.user}`).length === 0) {
        // $("#users-with-status-list").append(`<li id="submitted-answer-${event.user}">${event.user}</li>`)
      }
    })

    RoomMessageHub.register(EventType.StartVoting, (event) => {
      console.log("RoomMessageHub:PromptController:Listener:StartVoting", event)
      location.reload();
    })

    RoomMessageHub.register(EventType.VoteSubmitted, (event) => {
      // user has voted; is on their /results page
      console.log("RoomMessageHub:PromptController:Listener:VoteSubmitted", event)
      if ($(`#vote-${event.user}`).length === 0) {
        // $("#votes").append(`<li id="vote-${event.user}">${event.user}</li>`)
      }
    })

    RoomMessageHub.register(EventType.VotingDone, (event) => {
      console.log("RoomMessageHub:PromptController:Listener:VotingDone", event)
      // refresh the page, let the controller show the new correct view
      window.location.reload();
    })
  }
}
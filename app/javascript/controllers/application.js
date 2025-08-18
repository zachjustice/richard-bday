import { Application } from "@hotwired/stimulus"
import { createConsumer } from "@rails/actioncable"

const application = Application.start()

// Configure Stimulus development experience
application.debug = false
window.Stimulus   = application

const EventType = Object.freeze({
  NewUser: "NewUser",
  NextPrompt: "NextPrompt",
  AnswerSubmitted: "AnswerSubmitted",
  StartVoting: "StartVoting",
  VoteSubmitted: "VoteSubmitted",
  VotingDone: "VotingDone"
})

class MessageHub {
  constructor() {
    this.listeners = {}
  }

  register(eventType, callback) {
    console.log(`registering ${eventType}`)
    if (!this.listeners[eventType]) {
      this.listeners[eventType] = []
    }
    this.listeners[eventType].push(callback)
    return this.listeners[eventType].length - 1
  }

  emit(eventType, event) {
    if (!this.listeners[eventType]) {
      return
    }

    this.listeners[eventType].forEach(callback => {
      callback(event) 
    });
  }

  deregister(eventType, index) {
    // hacky; improve
    this.listeners[eventType][index] = () => {}
  }
}

const RoomMessageHub = new MessageHub();

createConsumer().subscriptions.create("RoomChannel", {
  connected: function () {
    // FIXME: While we wait for cable subscriptions to always be finalized before sending messages
    return setTimeout(() => {
      console.log('connecting...')
      this.followCurrentMessage();
      return this.installPageChangeCallback();
    }, 1000);
  },
  received: function (data) {
    console.log('received', data)

    RoomMessageHub.emit(data.messageType, data)
    // if (data.messageType == "NewUser") {
    //   console.log("new user", data.name)
    // } else if (data.messageType == "NextPrompt") {
    // } else if (data.messageType == "AnswerSubmitted") {
    //   console.log("Answer Submitted", data.name)
    // } else if (data.messageType == "StartVoting") {
    //   window.location.href = `/prompts/${data.prompt}/voting`
    // } else if (data.messageType == "VoteSubmitted") {
    //   console.log("Vote Submitted", data.name)
    // } else if (data.messageType == "VotingDone") {
    //   window.location.href = `/prompts/${data.prompt}/results`
    // } else {
    //   console.error("This shouldn't happen.", data)
    // }
  },
  followCurrentMessage: function () {
    const roomId = $('meta[name=room]').attr('id')
    console.log('follow', roomId)
    if (roomId) {
      return this.perform('follow', {
        room_id: roomId
      });
    } else {
      return this.perform('unfollow');
    }
  },
  installPageChangeCallback: function () {
    console.log('installPageChangeCallback')
    if (!this.installedPageChangeCallback) {
      this.installedPageChangeCallback = true;
      return $(document).on('turbolinks:load', function () {
        return App.comments.followCurrentMessage();
      });
    }
  }
});

export { application, RoomMessageHub, EventType }

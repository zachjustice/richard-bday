import { Application } from "@hotwired/stimulus"

const application = Application.start()

// Configure Stimulus development experience
application.debug = false
window.Stimulus = application

// TODO: need to figure out how to get @hotwired/turbo imported and added to the import map.
//       then I should be able to trigger navigate events server side by broadcasting an update to `room:#{id}:nav-updates`
// import { StreamActions } from "@hotwired/turbo"
// StreamActions.navigate = function () {
//   const url = this.getAttribute("url")
//   Turbo.visit(url)
// }

const EventType = Object.freeze({
  NewUser: "NewUser",
  NextPrompt: "NextPrompt",
  AnswerSubmitted: "AnswerSubmitted",
  StartVoting: "StartVoting",
  VoteSubmitted: "VoteSubmitted",
  VotingDone: "VotingDone",
  FinalResults: "FinalResults",
  NewGame: "NewGame",
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
  }

  emit(eventType, event) {
    if (!this.listeners[eventType]) {
      return
    }

    this.listeners[eventType].forEach(callback => {
      callback(event)
    });
  }
}

const RoomMessageHub = new MessageHub();

const subscribe = (eventType, callback, channel = "RoomChannel") => {
  return createConsumer().subscriptions.create(channel, {
    connected: function () {
      // FIXME: While we wait for cable subscriptions to always be finalized before sending messages
      return setTimeout(() => {
        console.log('connecting...')
        this.followCurrentMessage();
        return this.installPageChangeCallback();
      }, 500);
    },
    received: function (data) {
      console.log('received', data)
      // RoomMessageHub.emit(data.messageType, data)
      if (data.messageType === eventType) {
        callback(data);
      }
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
          console.log('turbolinks:load callback')
          return this.followCurrentMessage();
        });
      }
    }
  });
}

export { application, RoomMessageHub, EventType, subscribe }

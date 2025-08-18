
import { createConsumer } from "@rails/actioncable"
import { Controller } from "@hotwired/stimulus"
console.log('Room Controller')

export default class extends Controller {
  connect() {
    console.log('Room Controller. connect')
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
        if (data.messageType == "NextPrompt") {
          window.location.href = `/prompts/${data.prompt}`
        } else if (data.messageType == "NewUser") {
          return $("[data-channel='waiting-room']").append(`<li>${data.newUser}`)
        }
      },
      userIsCurrentUser: function (comment) {
        return $(comment).attr('data-user-id') === $('meta[name=current-user]').attr('id');
      },
      followCurrentMessage: function () {
        const roomId = $("[data-channel='waiting-room']").data('room-id')
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
  }
}

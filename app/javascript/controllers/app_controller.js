
import { RoomMessageHub } from "controllers/application"
import { Controller } from "@hotwired/stimulus"
import { createConsumer } from "@rails/actioncable"

export default class extends Controller {
  connect() {
    createConsumer().subscriptions.create("RoomChannel", {
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

        RoomMessageHub.emit(data.messageType, data)
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
            return this.followCurrentMessage();
          });
        }
      }
    });
  }
}
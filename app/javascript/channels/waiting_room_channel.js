// import consumer from "./consumer"
console.log('waiting room');
import { createConsumer } from "@rails/actioncable"

export default createConsumer()

consumer.subscriptions.create("WaitingRoomChannel", {
  collection: function() {
    return $("[data-channel='waiting-room']");
  },
  connected: function() {
    // FIXME: While we wait for cable subscriptions to always be finalized before sending messages
    return setTimeout(() => {
      this.followCurrentMessage();
      return this.installPageChangeCallback();
    }, 1000);
  },
  received: function(data) {
    return this.collection().append(data.comment); //unless @userIsCurrentUser(data.comment)
  },
  userIsCurrentUser: function(comment) {
    return $(comment).attr('data-user-id') === $('meta[name=current-user]').attr('id');
  },
  followCurrentMessage: function() {
    var roomId;
    if (roomId = this.collection().data('room-id')) {
      return this.perform('follow', {
        room_id: roomId
      });
    } else {
      return this.perform('unfollow');
    }
  },
  installPageChangeCallback: function() {
    if (!this.installedPageChangeCallback) {
      this.installedPageChangeCallback = true;
      return $(document).on('turbolinks:load', function() {
        return App.comments.followCurrentMessage();
      });
    }
  }
});

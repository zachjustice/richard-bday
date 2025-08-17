// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"
import $ from 'jquery';
// import "channels"
// import consumer from "./consumer"

// export for others scripts to use
window.$ = $;
window.jQuery = $;

console.log('application.js')

// createConsumer().subscriptions.create("GameStateChannel", {
//   connected: function() {
//     // FIXME: While we wait for cable subscriptions to always be finalized before sending messages
//     return setTimeout(() => {
//       this.followCurrentMessage();
//       return this.installPageChangeCallback();
//     }, 1000);
//   },
//   received: function(data) {
//     console.log('data', data)
//     return $("[data-channel='waiting-room']").append(`<li>${data.newUser}`)
//   },
//   userIsCurrentUser: function(comment) {
//     return $(comment).attr('data-user-id') === $('meta[name=current-user]').attr('id');
//   },
//   followCurrentMessage: function() {
//     const roomId = $("[data-channel='waiting-room']").data('room-id')
//     if (roomId) {
//       return this.perform('follow', {
//         room_id: roomId
//       });
//     } else {
//       return this.perform('unfollow');
//     }
//   },
//   installPageChangeCallback: function() {
//     if (!this.installedPageChangeCallback) {
//       this.installedPageChangeCallback = true;
//       return $(document).on('turbolinks:load', function() {
//         return App.comments.followCurrentMessage();
//       });
//     }
//   }
// })

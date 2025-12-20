// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "@rails/request.js"
import "@hotwired/turbo-rails"

import "controllers"
import $ from 'jquery';

// export for others scripts to use
window.$ = $;
window.jQuery = $;

// Register custom Turbo Stream actions for modal
Turbo.StreamActions.close_modal = function() {
  const modalElement = document.querySelector(`#${this.target}`)
  if (modalElement) {
    modalElement.classList.add("hidden")
  }
}

Turbo.StreamActions.open_modal = function() {
  const modalElement = document.querySelector(`#${this.target}`)
  if (modalElement) {
    modalElement.classList.remove("hidden")
    const firstInput = modalElement.querySelector("input[type='text']")
    if (firstInput) {
      setTimeout(() => firstInput.focus(), 100)
    }
  }
}

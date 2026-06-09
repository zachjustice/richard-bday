import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  openMusicPlayer() {
    window.dispatchEvent(new CustomEvent("open-music-player"))
  }

  openSettings() {
    window.dispatchEvent(new CustomEvent("open-settings-modal"))
  }
}

import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="background-audio"
export default class extends Controller {
  static targets = [
    "audio",
    "playIcon",
    "pauseIcon",
  ]

  connect() {
    this.targetVolume = 0.25
    this.audioTarget.loop = true

    // Try to autoplay (may be blocked until user interacts)
    this.audioTarget.play().catch(() => {
      this.audioTarget.pause();
      console.log(this.audioTarget.paused)
      this.updatePlayButton();
      console.log("Autoplay blocked. Waiting for user interaction...")
      // optional: show a "Play Music" button
    })

    this.updatePlayButton()
  }

  fadeInAudio() {
    this.audioTarget.volume = 0
    const audioSwellTimer = setInterval(() => {
      this.audioTarget.volume += 0.01;
      if (this.audioTarget.volume >= this.targetVolume) {
        this.audioTarget.volume = this.targetVolume;
        clearInterval(audioSwellTimer);
      }
    }, 100)
  }
  // PLAY/PAUSE TOGGLE
  togglePlay() {
    if (this.audioTarget.paused) {
      this.audioTarget.play()
    } else {
      this.audioTarget.pause()
    }
    this.updatePlayButton()
  }

  updatePlayButton() {
    if (this.audioTarget.paused && this.pauseIconTarget.classList.contains("hidden")) {
      // audio paused
      console.log('remove pause')
      this.pauseIconTarget.classList.remove("hidden")
    } else if (!this.audioTarget.paused && !this.pauseIconTarget.classList.contains("hidden")) {
      console.log('adding pause')
      this.pauseIconTarget.classList.add("hidden")
    }
  }
}
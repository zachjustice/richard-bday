import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    text: String
  }

  connect() {
  }

  speak() {
    if (!this.textValue) {
      console.warn("No text provided for speech")
      return
    }

    // Check if the browser supports TTS
    if (!("speechSynthesis" in window)) {
      alert("Your browser does not support text-to-speech.")
      return
    }

    const utterance = new SpeechSynthesisUtterance(this.textValue)
    window.speechSynthesis.speak(utterance)
  }
}

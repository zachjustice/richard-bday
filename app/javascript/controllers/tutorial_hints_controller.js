import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    editorAuthenticated: Boolean
  }

  static targets = ["settingsHint", "musicHint", "dismissCheckbox"]

  connect() {
    this.isConnected = true

    // Skip hints for authenticated editors
    if (this.editorAuthenticatedValue) return

    // Check localStorage preference
    if (this.hintsDismissed()) return

    // Show hints after delay
    this.showTimeout = setTimeout(() => this.showHints(), 800)

    // Click anywhere to dismiss (except on the hints themselves)
    this.boundDismissOnClick = this.dismissOnClick.bind(this)
  }

  disconnect() {
    this.isConnected = false
    if (this.showTimeout) clearTimeout(this.showTimeout)
    document.removeEventListener("click", this.boundDismissOnClick)
  }

  showHints() {
    // Guard against showing hints after disconnect
    if (!this.isConnected) return

    if (this.hasSettingsHintTarget) {
      this.settingsHintTarget.classList.remove("hidden")
    }
    if (this.hasMusicHintTarget) {
      this.musicHintTarget.classList.remove("hidden")
    }
    // Add click listener to dismiss (with guard for disconnect during delay)
    setTimeout(() => {
      if (this.isConnected) {
        document.addEventListener("click", this.boundDismissOnClick)
      }
    }, 100)
  }

  dismissOnClick(event) {
    // Don't dismiss if clicking inside a hint
    if (event.target.closest(".tutorial-hint")) return
    this.hideHints()
  }

  dismissSettings(event) {
    event.stopPropagation()
    if (this.hasSettingsHintTarget) {
      this.settingsHintTarget.classList.add("hidden")
    }
    // Check if all hints are now hidden, then persist
    if (!this.hasMusicHintTarget || this.musicHintTarget.classList.contains("hidden")) {
      this.setHintsDismissed(true)
    }
  }

  dismissMusic(event) {
    event.stopPropagation()
    if (this.hasMusicHintTarget) {
      this.musicHintTarget.classList.add("hidden")
    }
    // Check if all hints are now hidden, then persist
    if (!this.hasSettingsHintTarget || this.settingsHintTarget.classList.contains("hidden")) {
      this.setHintsDismissed(true)
    }
  }

  hideHints() {
    if (this.hasSettingsHintTarget) {
      this.settingsHintTarget.classList.add("hidden")
    }
    if (this.hasMusicHintTarget) {
      this.musicHintTarget.classList.add("hidden")
    }
    document.removeEventListener("click", this.boundDismissOnClick)
    this.setHintsDismissed(true)
  }

  // Called when checkbox changes in settings
  updatePreference(event) {
    if (event.target.checked) {
      this.setHintsDismissed(true)
      this.hideHints()
    } else {
      this.setHintsDismissed(false)
    }
  }

  // Sync checkbox state when settings modal opens
  syncCheckbox() {
    if (this.hasDismissCheckboxTarget) {
      this.dismissCheckboxTarget.checked = this.hintsDismissed()
    }
  }

  hintsDismissed() {
    try {
      return localStorage.getItem("blanksies_hints_dismissed") === "true"
    } catch {
      return false
    }
  }

  setHintsDismissed(value) {
    try {
      if (value) {
        localStorage.setItem("blanksies_hints_dismissed", "true")
      } else {
        localStorage.removeItem("blanksies_hints_dismissed")
      }
    } catch {
      // localStorage unavailable
    }
  }
}

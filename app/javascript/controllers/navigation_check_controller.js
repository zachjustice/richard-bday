import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { roomId: Number }

  connect() {
    this.handleVisibilityChange = this.handleVisibilityChange.bind(this)
    document.addEventListener("visibilitychange", this.handleVisibilityChange)
  }

  disconnect() {
    document.removeEventListener("visibilitychange", this.handleVisibilityChange)
  }

  handleVisibilityChange() {
    if (document.visibilityState === "visible") {
      this.checkNavigation()
    }
  }

  async checkNavigation() {
    const currentPath = window.location.pathname
    const url = `/rooms/${this.roomIdValue}/check_navigation?current_path=${encodeURIComponent(currentPath)}`

    try {
      const response = await fetch(url)
      const data = await response.json()

      if (data.redirect_to) {
        Turbo.visit(data.redirect_to)
      }
    } catch (error) {
      console.error("Navigation check failed:", error)
    }
  }
}

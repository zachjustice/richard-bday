import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { roomId: Number }
  static targets = ["icon"]

  connect() {
    this.cooldown = false
  }

  async refresh() {
    if (this.cooldown) return

    this.cooldown = true
    this.iconTarget.classList.add("animate-spin")

    const currentPath = window.location.pathname
    const url = `/rooms/${this.roomIdValue}/check_navigation?current_path=${encodeURIComponent(currentPath)}`

    let success = false
    try {
      const response = await fetch(url)
      const data = await response.json()

      if (data.redirect_to) {
        Turbo.visit(data.redirect_to)
        return
      }
      success = true
    } catch (error) {
      console.error("Refresh navigation failed:", error)
    }

    this.iconTarget.classList.remove("animate-spin")
    this.flash(success ? "text-accent-green" : "text-accent-red")

    setTimeout(() => { this.cooldown = false }, 5000)
  }

  flash(colorClass) {
    this.iconTarget.classList.add(colorClass)
    setTimeout(() => { this.iconTarget.classList.remove(colorClass) }, 600)
  }
}

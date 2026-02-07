import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "clearButton"]
  static values = {
    url: String,
    frameId: String,
    debounce: { type: Number, default: 300 }
  }

  connect() {
    this.timeout = null
  }

  disconnect() {
    clearTimeout(this.timeout)
  }

  search() {
    clearTimeout(this.timeout)
    this.toggleClearButton()

    this.timeout = setTimeout(() => {
      this.performSearch()
    }, this.debounceValue)
  }

  clear() {
    this.inputTarget.value = ""
    this.toggleClearButton()
    this.performSearch()
    this.inputTarget.focus()
  }

  toggleClearButton() {
    if (!this.hasClearButtonTarget) return
    const hasText = this.inputTarget.value.trim().length > 0
    this.clearButtonTarget.classList.toggle("hidden", !hasText)
  }

  performSearch() {
    const query = this.inputTarget.value.trim()
    const url = new URL(this.urlValue, window.location.origin)

    if (query) {
      url.searchParams.set("query", query)
    } else {
      url.searchParams.delete("query")
    }

    const frame = document.getElementById(this.frameIdValue)
    if (frame) frame.src = url.toString()
  }
}

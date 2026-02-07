import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "clear"]
  static values = { url: String, debounce: { type: Number, default: 300 } }

  connect() {
    this.timeout = null
  }

  search() {
    clearTimeout(this.timeout)
    const query = this.inputTarget.value

    // Toggle clear button visibility
    this.clearTarget.classList.toggle("hidden", !query)

    this.timeout = setTimeout(() => {
      const frame = document.querySelector("turbo-frame#results_list")
      if (frame) {
        const url = new URL(this.urlValue, window.location.origin)
        if (query) url.searchParams.set("query", query)
        frame.src = url.toString()
      }
    }, this.debounceValue)
  }

  clear() {
    this.inputTarget.value = ""
    this.clearTarget.classList.add("hidden")
    this.search()
    this.inputTarget.focus()
  }
}

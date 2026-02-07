import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["display", "form", "input"]
  static values = {
    promptId: Number,
    updateUrl: String
  }

  edit(event) {
    event.preventDefault()
    this.displayTarget.classList.add("hidden")
    this.formTarget.classList.remove("hidden")
    if (this.hasInputTarget) {
      this.inputTarget.focus()
      this.inputTarget.select()
    }
  }

  cancel(event) {
    if (event) event.preventDefault()
    this.displayTarget.classList.remove("hidden")
    this.formTarget.classList.add("hidden")
  }

  async save(event) {
    event.preventDefault()
    const form = event.target
    const formData = new FormData(form)

    try {
      const response = await fetch(this.updateUrlValue, {
        method: "PATCH",
        body: formData,
        headers: {
          "Accept": "text/vnd.turbo-stream.html, text/html, application/xhtml+xml",
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content
        }
      })

      if (response.ok) {
        // Flash success state
        this.displayTarget.classList.remove("hidden")
        this.formTarget.classList.add("hidden")
        this.displayTarget.classList.add("bg-green-100")
        setTimeout(() => {
          this.displayTarget.classList.remove("bg-green-100")
        }, 1000)

        // Update the display text
        const newDescription = formData.get("prompt[description]")
        const textElement = this.displayTarget.querySelector(".prompt-text")
        if (textElement) {
          textElement.textContent = newDescription
        }
      } else {
        console.error("Failed to save prompt")
      }
    } catch (error) {
      console.error("Error saving prompt:", error)
    }
  }
}

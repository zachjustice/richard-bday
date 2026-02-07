// app/javascript/controllers/prompt_editor_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["display", "form", "description"]

  connect() {
    if (this.element.dataset.flashSuccess === "true") {
      this.flashGreen()
      delete this.element.dataset.flashSuccess
    }
  }

  edit() {
    this.displayTarget.style.overflow = "hidden"
    this.displayTarget.style.maxHeight = this.displayTarget.scrollHeight + "px"

    requestAnimationFrame(() => {
      this.displayTarget.style.transition = "max-height 0.25s ease-out, opacity 0.2s ease-out"
      this.displayTarget.style.maxHeight = "0px"
      this.displayTarget.style.opacity = "0"
    })

    setTimeout(() => {
      this.displayTarget.classList.add("hidden")
      this.formTarget.classList.remove("hidden")
      this.formTarget.style.overflow = "hidden"
      this.formTarget.style.maxHeight = "0px"
      this.formTarget.style.opacity = "0"

      requestAnimationFrame(() => {
        this.formTarget.style.transition = "max-height 0.3s ease-out, opacity 0.25s ease-out"
        this.formTarget.style.maxHeight = this.formTarget.scrollHeight + "px"
        this.formTarget.style.opacity = "1"
      })

      setTimeout(() => {
        this.#cleanupStyles(this.formTarget)
      }, 350)
    }, 250)
  }

  cancelEdit() {
    this.formTarget.style.overflow = "hidden"
    this.formTarget.style.transition = "max-height 0.25s ease-out, opacity 0.2s ease-out"
    this.formTarget.style.maxHeight = this.formTarget.scrollHeight + "px"

    requestAnimationFrame(() => {
      this.formTarget.style.maxHeight = "0px"
      this.formTarget.style.opacity = "0"
    })

    setTimeout(() => {
      this.formTarget.classList.add("hidden")
      this.displayTarget.classList.remove("hidden")
      this.displayTarget.style.overflow = "hidden"
      this.displayTarget.style.maxHeight = "0px"
      this.displayTarget.style.opacity = "0"

      requestAnimationFrame(() => {
        this.displayTarget.style.transition = "max-height 0.3s ease-out, opacity 0.25s ease-out"
        this.displayTarget.style.maxHeight = this.displayTarget.scrollHeight + "px"
        this.displayTarget.style.opacity = "1"
      })

      setTimeout(() => {
        this.#cleanupStyles(this.displayTarget)
      }, 350)
    }, 250)
  }

  flashGreen() {
    if (!this.hasDescriptionTarget) return

    const el = this.descriptionTarget
    el.style.transition = "background-color 0.3s ease"
    el.style.backgroundColor = "var(--color-success-light, #c8e6c9)"
    el.style.borderRadius = "4px"
    el.style.padding = "2px 4px"

    setTimeout(() => {
      el.style.backgroundColor = "transparent"
      setTimeout(() => {
        el.style.removeProperty("transition")
        el.style.removeProperty("background-color")
        el.style.removeProperty("border-radius")
        el.style.removeProperty("padding")
      }, 300)
    }, 1200)
  }

  #cleanupStyles(el) {
    el.style.removeProperty("max-height")
    el.style.removeProperty("overflow")
    el.style.removeProperty("transition")
    el.style.removeProperty("opacity")
  }
}

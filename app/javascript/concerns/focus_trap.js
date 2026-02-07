// Reusable focus trap mixin for modal controllers
// Usage: Object.assign(this, FocusTrap) in connect(), then call setupFocusTrap(modalElement)

export const FocusTrap = {
  setupFocusTrap(modalElement) {
    this.focusTrapModal = modalElement
    this.previouslyFocusedElement = null
    this.boundTrapFocus = this.trapFocus.bind(this)
  },

  activateFocusTrap() {
    this.previouslyFocusedElement = document.activeElement
    this.focusTrapModal.addEventListener("keydown", this.boundTrapFocus)

    // Focus first focusable element after a short delay
    const focusable = this.getFocusableElements()
    if (focusable.length) {
      setTimeout(() => focusable[0].focus(), 100)
    }
  },

  deactivateFocusTrap() {
    if (this.focusTrapModal) {
      this.focusTrapModal.removeEventListener("keydown", this.boundTrapFocus)
    }
    if (this.previouslyFocusedElement && typeof this.previouslyFocusedElement.focus === "function") {
      this.previouslyFocusedElement.focus()
    }
  },

  trapFocus(event) {
    if (event.key !== "Tab") return

    const focusable = this.getFocusableElements()
    if (focusable.length === 0) return

    const first = focusable[0]
    const last = focusable[focusable.length - 1]

    if (event.shiftKey && document.activeElement === first) {
      event.preventDefault()
      last.focus()
    } else if (!event.shiftKey && document.activeElement === last) {
      event.preventDefault()
      first.focus()
    }
  },

  getFocusableElements() {
    const selector = [
      'button:not([disabled])',
      '[href]',
      'input:not([disabled])',
      'select:not([disabled])',
      'textarea:not([disabled])',
      '[tabindex]:not([tabindex="-1"])'
    ].join(", ")

    return Array.from(this.focusTrapModal.querySelectorAll(selector))
      .filter(el => !el.closest(".hidden") && el.offsetParent !== null)
  }
}

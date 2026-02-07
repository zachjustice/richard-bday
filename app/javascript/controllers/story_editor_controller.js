// app/javascript/controllers/story_editor_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["text", "title", "originalText", "status"]
  static values = {
    storyId: Number,
    updatedAt: String
  }

  connect() {
    this.hideStatusTimeout = null
    this.restoreDraftIfNewer()

    this.boundClearDraft = this.clearDraftFromLocalStorage.bind(this)
    document.addEventListener("turbo:submit-start", this.boundClearDraft)
  }

  disconnect() {
    clearTimeout(this.hideStatusTimeout)
    document.removeEventListener("turbo:submit-start", this.boundClearDraft)
  }

  // --- Existing methods ---

  highlightBlanks() {
    const text = this.textTarget.value
    const blanks = text.match(/\{\d+\}/g) || []
  }

  insertBlank(event) {
    const blankId = event.params.id
    const textarea = this.textTarget
    const cursorPos = textarea.selectionStart
    const textBefore = textarea.value.substring(0, cursorPos)
    const textAfter = textarea.value.substring(cursorPos)

    textarea.value = textBefore + `{${blankId}}` + textAfter
    textarea.focus()
    textarea.selectionStart = textarea.selectionEnd = cursorPos + `{${blankId}}`.length

    this.highlightBlanks()
    this.saveDraft()
  }

  // --- Local draft ---

  saveDraft() {
    this.saveDraftToLocalStorage()
    this.showStatus("unsaved")
  }

  // --- Status indicator ---

  showStatus(state) {
    if (!this.hasStatusTarget) return

    const el = this.statusTarget
    el.classList.remove("opacity-0")
    el.classList.add("opacity-100")
    clearTimeout(this.hideStatusTimeout)

    switch (state) {
      case "unsaved":
        el.innerHTML = `
          <span class="inline-block w-2 h-2 rounded-full bg-accent-tertiary"></span>
          <span class="text-ink/50">Unsaved changes</span>
        `
        break
      case "draft-restored":
        el.innerHTML = `
          <svg class="w-4 h-4 text-accent-secondary" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
            <path stroke-linecap="round" stroke-linejoin="round" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
          </svg>
          <span class="text-ink/50">Draft restored</span>
        `
        this.hideStatusAfterDelay()
        break
    }
  }

  hideStatusAfterDelay() {
    this.hideStatusTimeout = setTimeout(() => {
      if (this.hasStatusTarget) {
        this.statusTarget.classList.remove("opacity-100")
        this.statusTarget.classList.add("opacity-0")
      }
    }, 3000)
  }

  // --- localStorage ---

  get localStorageKey() {
    return `blanksies-draft-story-${this.storyIdValue}`
  }

  saveDraftToLocalStorage() {
    const draft = {
      title: this.hasTitleTarget ? this.titleTarget.value : null,
      text: this.hasTextTarget ? this.textTarget.value : null,
      originalText: this.hasOriginalTextTarget ? this.originalTextTarget.value : null,
      savedAt: new Date().toISOString()
    }
    try {
      localStorage.setItem(this.localStorageKey, JSON.stringify(draft))
    } catch (e) {
      // localStorage unavailable or full
    }
  }

  clearDraftFromLocalStorage() {
    try {
      localStorage.removeItem(this.localStorageKey)
    } catch (e) {
      // silently fail
    }
  }

  restoreDraftIfNewer() {
    try {
      const stored = localStorage.getItem(this.localStorageKey)
      if (!stored) return

      const draft = JSON.parse(stored)
      const draftTime = new Date(draft.savedAt)
      const serverTime = new Date(this.updatedAtValue)

      if (draftTime <= serverTime) {
        this.clearDraftFromLocalStorage()
        return
      }

      if (draft.title && this.hasTitleTarget) this.titleTarget.value = draft.title
      if (draft.text && this.hasTextTarget) this.textTarget.value = draft.text
      if (draft.originalText && this.hasOriginalTextTarget) this.originalTextTarget.value = draft.originalText

      this.showStatus("draft-restored")
    } catch (e) {
      this.clearDraftFromLocalStorage()
    }
  }
}

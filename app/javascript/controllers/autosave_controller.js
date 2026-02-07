// app/javascript/controllers/autosave_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "textarea", "status"]
  static values = {
    storyId: Number,
    localSaveInterval: { type: Number, default: 10000 },
    serverSaveInterval: { type: Number, default: 60000 }
  }

  connect() {
    this.lastSavedContent = this.getTextareaContent()
    this.loadDraft()

    this.localSaveTimer = setInterval(() => this.saveToLocal(), this.localSaveIntervalValue)
    this.serverSaveTimer = setInterval(() => this.saveToServer(), this.serverSaveIntervalValue)
  }

  disconnect() {
    if (this.localSaveTimer) clearInterval(this.localSaveTimer)
    if (this.serverSaveTimer) clearInterval(this.serverSaveTimer)
  }

  getStorageKey() {
    return `blanksies_story_draft_${this.storyIdValue}`
  }

  getTextareaContent() {
    if (!this.hasTextareaTarget) return ""
    return this.textareaTarget.value
  }

  saveToLocal() {
    const content = this.getTextareaContent()
    if (!content) return

    try {
      localStorage.setItem(this.getStorageKey(), JSON.stringify({
        content: content,
        savedAt: new Date().toISOString()
      }))
    } catch (e) {
      console.warn("Failed to save draft to localStorage:", e)
    }
  }

  async saveToServer() {
    const content = this.getTextareaContent()

    // Only save if content has changed since last server save
    if (content === this.lastSavedContent) return
    if (!this.hasFormTarget) return

    this.updateStatus("saving")

    try {
      const formData = new FormData(this.formTarget)
      const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content

      const response = await fetch(this.formTarget.action, {
        method: "PATCH",
        body: formData,
        headers: {
          "Accept": "application/json",
          "X-CSRF-Token": csrfToken
        }
      })

      if (response.ok) {
        this.lastSavedContent = content
        this.updateStatus("saved")
        // Clear localStorage draft after successful server save
        localStorage.removeItem(this.getStorageKey())
      } else {
        this.updateStatus("error")
      }
    } catch (e) {
      console.error("Autosave failed:", e)
      this.updateStatus("error")
    }
  }

  loadDraft() {
    try {
      const stored = localStorage.getItem(this.getStorageKey())
      if (!stored) return

      const draft = JSON.parse(stored)
      const currentContent = this.getTextareaContent()

      // Only restore if draft is different from current content
      if (draft.content && draft.content !== currentContent && this.hasTextareaTarget) {
        this.textareaTarget.value = draft.content
        this.updateStatus("restored")
      }
    } catch (e) {
      console.warn("Failed to load draft from localStorage:", e)
    }
  }

  retrySave() {
    this.saveToServer()
  }

  updateStatus(state) {
    if (!this.hasStatusTarget) return

    const statusHTML = {
      saving: `<span class="flex items-center gap-2 text-sm text-ink/50">
        <span class="w-2 h-2 rounded-full bg-accent-secondary animate-pulse"></span>
        Saving...
      </span>`,

      saved: `<span class="flex items-center gap-2 text-sm text-green-600">
        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"/>
        </svg>
        Saved
      </span>`,

      error: `<span class="flex items-center gap-2 text-sm text-accent-primary">
        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"/>
        </svg>
        Failed to save
        <button class="underline hover:no-underline" data-action="autosave#retrySave">Retry</button>
      </span>`,

      restored: `<span class="flex items-center gap-2 text-sm text-amber-600">
        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15"/>
        </svg>
        Draft restored from local storage
      </span>`
    }

    this.statusTarget.innerHTML = statusHTML[state] || ""

    // Auto-clear success/restored messages after 3 seconds
    if (state === "saved" || state === "restored") {
      setTimeout(() => {
        if (this.hasStatusTarget) {
          this.statusTarget.innerHTML = ""
        }
      }, 3000)
    }
  }
}

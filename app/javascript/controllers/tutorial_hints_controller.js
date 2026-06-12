import { Controller } from "@hotwired/stimulus"

const SHOW_DELAY_MS = 800
const VIEWPORT_MARGIN = 16
const FINAL_STORY_ARROW_GAP = 14

const HINT_KEYS = ["settings", "music", "finalStory"]
const SEEN_LS_KEY = {
  settings: "blanksies_hint_seen_settings",
  music: "blanksies_hint_seen_music",
  finalStory: "blanksies_hint_seen_final_story"
}
const DISMISSED_LS_KEY = "blanksies_hints_dismissed"

const hasTargetProp = (key) => `has${key.charAt(0).toUpperCase()}${key.slice(1)}HintTarget`
const targetProp = (key) => `${key}HintTarget`

export default class extends Controller {
  static values = {
    editorAuthenticated: Boolean
  }

  static targets = ["settingsHint", "musicHint", "finalStoryHint", "dismissCheckbox"]

  connect() {
    this.isConnected = true
    this.clickDismissalAttached = false
    this.boundDismissOnClick = this.dismissOnClick.bind(this)

    if (this.editorAuthenticatedValue) return
    if (this.hintsDismissed()) return

    this.showTimeout = setTimeout(() => this.showInitialHints(), SHOW_DELAY_MS)
  }

  disconnect() {
    this.isConnected = false
    if (this.showTimeout) clearTimeout(this.showTimeout)
    if (this.finalStoryShowTimeout) clearTimeout(this.finalStoryShowTimeout)
    document.removeEventListener("click", this.boundDismissOnClick)
    this.detachFinalStoryListeners()
  }

  // settings + music hints are present from initial page load; show them after the delay
  showInitialHints() {
    if (!this.isConnected) return

    if (this.hasSettingsHintTarget && !this.isSeen("settings")) {
      this.settingsHintTarget.classList.remove("hidden")
    }
    if (this.hasMusicHintTarget && !this.isSeen("music")) {
      this.musicHintTarget.classList.remove("hidden")
    }
    this.attachClickDismissal()
  }

  // Driven by Stimulus target lifecycle — fires when the final story partial is rendered
  finalStoryHintTargetConnected(target) {
    if (this.editorAuthenticatedValue) return
    if (this.hintsDismissed()) return
    if (this.isSeen("finalStory")) return

    this.finalStoryShowTimeout = setTimeout(() => {
      if (!this.isConnected) return
      const blank = document.querySelector(".game-prompt-answer")
      if (!blank) return

      this.positionFinalStoryHint(target, blank)
      target.classList.remove("hidden")
      this.attachClickDismissal()
      this.attachFirstHoverDismissal()
      this.attachScrollDismissal()
    }, SHOW_DELAY_MS)

    this.boundRepositionFinalStory = () => {
      const blank = document.querySelector(".game-prompt-answer")
      if (blank) this.positionFinalStoryHint(target, blank)
    }
    window.addEventListener("resize", this.boundRepositionFinalStory)
  }

  finalStoryHintTargetDisconnected() {
    if (this.finalStoryShowTimeout) clearTimeout(this.finalStoryShowTimeout)
    this.detachFinalStoryListeners()
  }

  positionFinalStoryHint(hint, blank) {
    const blankRect = blank.getBoundingClientRect()

    // Park at origin and measure (visibility:hidden keeps it offscreen-invisible if still .hidden)
    const wasHidden = hint.classList.contains("hidden")
    if (wasHidden) {
      hint.style.visibility = "hidden"
      hint.classList.remove("hidden")
    }
    hint.style.left = "0px"
    hint.style.top = "0px"
    const hintRect = hint.getBoundingClientRect()
    if (wasHidden) {
      hint.classList.add("hidden")
      hint.style.visibility = ""
    }

    let left = blankRect.left + blankRect.width / 2 - hintRect.width / 2
    left = Math.max(
      VIEWPORT_MARGIN,
      Math.min(window.innerWidth - VIEWPORT_MARGIN - hintRect.width, left)
    )
    const top = Math.max(VIEWPORT_MARGIN, blankRect.top - hintRect.height - FINAL_STORY_ARROW_GAP)

    hint.style.left = `${left}px`
    hint.style.top = `${top}px`

    // Slide the arrow horizontally so it points at the blank's center
    const arrow = hint.querySelector(".tutorial-hint-arrow--down")
    if (arrow) {
      const blankCenter = blankRect.left + blankRect.width / 2
      const arrowLeft = Math.max(
        8,
        Math.min(hintRect.width - 24, blankCenter - left - 8)
      )
      arrow.style.left = `${arrowLeft}px`
      arrow.style.right = "auto"
    }
  }

  attachFirstHoverDismissal() {
    if (this.firstHoverAttached) return
    this.boundFirstHoverDismiss = (event) => {
      if (event.target.closest(".game-prompt-answer")) {
        this.dismissFinalStoryHint()
      }
    }
    document.addEventListener("mouseover", this.boundFirstHoverDismiss)
    this.firstHoverAttached = true
  }

  attachScrollDismissal() {
    if (this.scrollDismissalAttached) return
    this.boundScrollDismiss = () => this.dismissFinalStoryHint()
    window.addEventListener("scroll", this.boundScrollDismiss, { capture: true, passive: true })
    this.scrollDismissalAttached = true
  }

  detachFinalStoryListeners() {
    if (this.boundRepositionFinalStory) {
      window.removeEventListener("resize", this.boundRepositionFinalStory)
      this.boundRepositionFinalStory = null
    }
    if (this.boundFirstHoverDismiss) {
      document.removeEventListener("mouseover", this.boundFirstHoverDismiss)
      this.boundFirstHoverDismiss = null
      this.firstHoverAttached = false
    }
    if (this.boundScrollDismiss) {
      window.removeEventListener("scroll", this.boundScrollDismiss, { capture: true, passive: true })
      this.boundScrollDismiss = null
      this.scrollDismissalAttached = false
    }
  }

  attachClickDismissal() {
    if (this.clickDismissalAttached) return
    // Defer briefly so the click that triggered show doesn't immediately dismiss
    setTimeout(() => {
      if (!this.isConnected) return
      document.addEventListener("click", this.boundDismissOnClick)
      this.clickDismissalAttached = true
    }, 100)
  }

  dismissOnClick(event) {
    if (event.target.closest(".tutorial-hint")) return
    this.hideAllVisibleHints()
  }

  dismissSettings(event) {
    event.stopPropagation()
    if (this.hasSettingsHintTarget) {
      this.settingsHintTarget.classList.add("hidden")
    }
    this.setSeen("settings")
  }

  dismissMusic(event) {
    event.stopPropagation()
    if (this.hasMusicHintTarget) {
      this.musicHintTarget.classList.add("hidden")
    }
    this.setSeen("music")
  }

  dismissFinalStory(event) {
    event.stopPropagation()
    this.dismissFinalStoryHint()
  }

  dismissFinalStoryHint() {
    if (this.hasFinalStoryHintTarget) {
      this.finalStoryHintTarget.classList.add("hidden")
    }
    this.setSeen("finalStory")
    if (this.boundFirstHoverDismiss) {
      document.removeEventListener("mouseover", this.boundFirstHoverDismiss)
      this.boundFirstHoverDismiss = null
      this.firstHoverAttached = false
    }
    if (this.boundScrollDismiss) {
      window.removeEventListener("scroll", this.boundScrollDismiss, { capture: true, passive: true })
      this.boundScrollDismiss = null
      this.scrollDismissalAttached = false
    }
  }

  hideAllVisibleHints() {
    HINT_KEYS.forEach((key) => {
      if (this[hasTargetProp(key)] && !this[targetProp(key)].classList.contains("hidden")) {
        this[targetProp(key)].classList.add("hidden")
        this.setSeen(key)
      }
    })
    // Tear down per-hint listeners that are no longer relevant
    if (this.boundFirstHoverDismiss) {
      document.removeEventListener("mouseover", this.boundFirstHoverDismiss)
      this.boundFirstHoverDismiss = null
      this.firstHoverAttached = false
    }
    if (this.boundScrollDismiss) {
      window.removeEventListener("scroll", this.boundScrollDismiss, { capture: true, passive: true })
      this.boundScrollDismiss = null
      this.scrollDismissalAttached = false
    }
  }

  hideAllHintsRegardlessOfState() {
    HINT_KEYS.forEach((key) => {
      if (this[hasTargetProp(key)]) {
        this[targetProp(key)].classList.add("hidden")
      }
    })
  }

  updatePreference(event) {
    if (event.target.checked) {
      this.setHintsDismissed(true)
      this.hideAllHintsRegardlessOfState()
    } else {
      this.setHintsDismissed(false)
      this.clearAllSeen()
    }
  }

  syncCheckbox() {
    if (this.hasDismissCheckboxTarget) {
      this.dismissCheckboxTarget.checked = this.hintsDismissed()
    }
  }

  hintsDismissed() {
    try { return localStorage.getItem(DISMISSED_LS_KEY) === "true" } catch { return false }
  }

  setHintsDismissed(value) {
    try {
      if (value) {
        localStorage.setItem(DISMISSED_LS_KEY, "true")
      } else {
        localStorage.removeItem(DISMISSED_LS_KEY)
      }
    } catch {}
  }

  isSeen(key) {
    try { return localStorage.getItem(SEEN_LS_KEY[key]) === "true" } catch { return false }
  }

  setSeen(key) {
    try { localStorage.setItem(SEEN_LS_KEY[key], "true") } catch {}
  }

  clearAllSeen() {
    HINT_KEYS.forEach((key) => {
      try { localStorage.removeItem(SEEN_LS_KEY[key]) } catch {}
    })
  }
}

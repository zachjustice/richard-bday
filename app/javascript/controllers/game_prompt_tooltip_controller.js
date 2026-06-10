import { Controller } from "@hotwired/stimulus"

const VIEWPORT_MARGIN = 16
const CURSOR_GAP = 12
const HIDE_DELAY_MS = 80

export default class extends Controller {
  static values = {
    gamePromptId: String,
    url: String
  }

  async connect() {
    this.tooltipReady = false
    this.hideTimer = null

    this.buildTooltip()
    this.buildBridge()

    this.boundOnScroll = this.onScroll.bind(this)
    window.addEventListener("scroll", this.boundOnScroll, { capture: true, passive: true })

    await this.loadTooltipContent()
  }

  buildTooltip() {
    const id = `game-prompt-${this.gamePromptIdValue}`
    const existing = document.querySelector(`#${id}`)

    if (existing) {
      this.tooltipFrame = existing
      this.tooltipReady = !!this.tooltipFrame.querySelector(".tooltip-content")
    } else {
      this.tooltipFrame = document.createElement("div")
      this.tooltipFrame.id = id
      this.tooltipFrame.className = "prompt-tooltip hidden"
      document.body.appendChild(this.tooltipFrame)
    }

    this.tooltipFrame.addEventListener("mouseenter", () => this.cancelHide())
    this.tooltipFrame.addEventListener("mouseleave", () => this.scheduleHide())
  }

  buildBridge() {
    this.bridge = document.createElement("div")
    this.bridge.className = "prompt-tooltip-bridge hidden"
    document.body.appendChild(this.bridge)
    this.bridge.addEventListener("mouseenter", () => this.cancelHide())
    this.bridge.addEventListener("mouseleave", () => this.scheduleHide())
  }

  async loadTooltipContent() {
    if (this.tooltipReady) return

    try {
      const response = await fetch(this.urlValue)
      if (!response.ok) return

      const html = await response.text()
      const doc = new DOMParser().parseFromString(html, "text/html")
      const content = doc.querySelector(".tooltip-content")
      if (!content) return

      this.tooltipFrame.innerHTML = ""
      this.tooltipFrame.appendChild(content)
      this.tooltipReady = true
    } catch (error) {
      console.error("Failed to load tooltip:", error)
    }
  }

  show(event) {
    this.cancelHide()
    if (!this.tooltipReady) return
    this.tooltipFrame.classList.remove("hidden")
    this.position(event)
  }

  hide() {
    this.scheduleHide()
  }

  scheduleHide() {
    this.cancelHide()
    this.hideTimer = setTimeout(() => this.hideImmediately(), HIDE_DELAY_MS)
  }

  cancelHide() {
    if (this.hideTimer) {
      clearTimeout(this.hideTimer)
      this.hideTimer = null
    }
  }

  hideImmediately() {
    this.cancelHide()
    if (this.tooltipFrame) this.tooltipFrame.classList.add("hidden")
    if (this.bridge) this.bridge.classList.add("hidden")
  }

  onScroll(event) {
    if (this.tooltipFrame?.classList.contains("hidden")) return
    if (this.tooltipFrame?.contains(event.target)) return
    this.hideImmediately()
  }

  position(event) {
    const cursorX = event.clientX
    const cursorY = event.clientY
    const vw = window.innerWidth
    const vh = window.innerHeight

    // Park at origin so we can measure the natural size
    this.tooltipFrame.style.left = "0px"
    this.tooltipFrame.style.top = "0px"
    const rect = this.tooltipFrame.getBoundingClientRect()
    const tipW = rect.width
    const tipH = rect.height

    // Place on whichever side of the cursor has more room
    const placeRight = (vw - cursorX) >= cursorX

    let x
    if (placeRight) {
      x = cursorX + CURSOR_GAP
      if (x + tipW > vw - VIEWPORT_MARGIN) {
        x = Math.max(VIEWPORT_MARGIN, vw - VIEWPORT_MARGIN - tipW)
      }
    } else {
      x = cursorX - CURSOR_GAP - tipW
      if (x < VIEWPORT_MARGIN) {
        x = VIEWPORT_MARGIN
      }
    }

    let y = cursorY
    if (y + tipH > vh - VIEWPORT_MARGIN) {
      y = vh - VIEWPORT_MARGIN - tipH
    }
    if (y < VIEWPORT_MARGIN) {
      y = VIEWPORT_MARGIN
    }

    this.tooltipFrame.style.left = `${x}px`
    this.tooltipFrame.style.top = `${y}px`

    this.positionBridge(cursorX, cursorY, x, y, tipW, tipH)
  }

  positionBridge(cursorX, cursorY, tipX, tipY, tipW, tipH) {
    // Bridge spans the gap between the cursor and the tooltip so the cursor
    // can traverse it without triggering hide. Derived from final positions
    // so clamp-induced side flips work.
    const tipRight = tipX + tipW
    let bx, bw

    if (tipX >= cursorX) {
      bx = cursorX
      bw = tipX - cursorX
    } else if (tipRight <= cursorX) {
      bx = tipRight
      bw = cursorX - tipRight
    } else {
      this.bridge.classList.add("hidden")
      return
    }

    if (bw <= 0) {
      this.bridge.classList.add("hidden")
      return
    }

    const by = Math.min(cursorY, tipY)
    const bh = Math.max(cursorY, tipY + tipH) - by

    this.bridge.style.left = `${bx}px`
    this.bridge.style.top = `${by}px`
    this.bridge.style.width = `${bw}px`
    this.bridge.style.height = `${bh}px`
    this.bridge.classList.remove("hidden")
  }

  disconnect() {
    this.cancelHide()
    if (this.boundOnScroll) {
      window.removeEventListener("scroll", this.boundOnScroll, { capture: true, passive: true })
    }
    if (this.tooltipFrame) {
      this.tooltipFrame.remove()
      this.tooltipFrame = null
    }
    if (this.bridge) {
      this.bridge.remove()
      this.bridge = null
    }
  }
}

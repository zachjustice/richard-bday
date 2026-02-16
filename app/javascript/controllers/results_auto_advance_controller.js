import { Controller } from "@hotwired/stimulus"
import { timerPhase } from "lib/timer_phase"

export default class extends Controller {
  static targets = ["display", "circle", "form", "pauseIcon", "playIcon", "timerButton"]
  static values = {
    duration: { type: Number, default: 15 }
  }

  connect() {
    this.paused = false
    this.pausedAtRemaining = null
    this.timeRemaining = this.durationValue
    this.circumference = 2 * Math.PI * 45
    this.circleTarget.style.strokeDasharray = this.circumference
    this.circleTarget.style.strokeDashoffset = 0
    this.updateDisplay()
    this.startTime = Date.now()
    this.animate()

    this._onKeydown = this._handleKeydown.bind(this)
    document.addEventListener("keydown", this._onKeydown)
  }

  disconnect() {
    if (this.animationFrame) {
      cancelAnimationFrame(this.animationFrame)
      this.animationFrame = null
    }
    document.removeEventListener("keydown", this._onKeydown)
  }

  toggle() {
    if (this.paused) {
      this.resume()
    } else {
      this.pause()
    }
  }

  pause() {
    if (this.paused) return
    this.paused = true
    this.pausedAtRemaining = this.timeRemaining

    if (this.animationFrame) {
      cancelAnimationFrame(this.animationFrame)
      this.animationFrame = null
    }

    this.element.querySelector(".countdown-timer").setAttribute("data-paused", "")
    this.pauseIconTarget.classList.add("hidden")
    this.playIconTarget.classList.remove("hidden")
    this.timerButtonTarget.setAttribute("aria-label", "Resume auto-advance timer")
  }

  resume() {
    if (!this.paused) return
    this.paused = false

    // Back-calculate startTime so existing animate() math works unchanged
    const elapsedBeforePause = this.durationValue - this.pausedAtRemaining
    this.startTime = Date.now() - (elapsedBeforePause * 1000)
    this.pausedAtRemaining = null

    this.element.querySelector(".countdown-timer").removeAttribute("data-paused")
    this.playIconTarget.classList.add("hidden")
    this.pauseIconTarget.classList.remove("hidden")
    this.timerButtonTarget.setAttribute("aria-label", "Pause auto-advance timer")
    this.animate()
  }

  animate() {
    const elapsed = (Date.now() - this.startTime) / 1000
    this.timeRemaining = Math.max(0, this.durationValue - elapsed)

    this.updateDisplay()
    this.updateCircle()
    this.updateColor()

    if (this.timeRemaining > 0) {
      this.animationFrame = requestAnimationFrame(() => this.animate())
    } else {
      this.formTarget.requestSubmit()
    }
  }

  updateDisplay() {
    this.displayTarget.textContent = Math.ceil(this.timeRemaining)
  }

  updateCircle() {
    const progress = this.timeRemaining / this.durationValue
    const offset = this.circumference * (1 - progress)
    this.circleTarget.style.strokeDashoffset = offset
  }

  updateColor() {
    const phase = timerPhase(this.timeRemaining, this.durationValue)
    this.element.querySelector("[data-phase]").setAttribute("data-phase", phase)
  }

  _handleKeydown(event) {
    if (event.key !== " ") return

    const tag = event.target.tagName
    if (tag === "INPUT" || tag === "TEXTAREA" || tag === "SELECT" || tag === "BUTTON") return
    if (event.target.isContentEditable) return

    event.preventDefault()
    this.toggle()
  }
}

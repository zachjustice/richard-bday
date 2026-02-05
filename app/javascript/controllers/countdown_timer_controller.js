import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["display", "circle"]
  static values = {
    duration: { type: Number, default: 60 },
    autoStart: { type: Boolean, default: true }
  }

  connect() {
    this.timeRemaining = Math.round(this.durationValue)
    this.startTime = null
    this.currentPhase = null
    this.updateDisplay()
    this.setupCircle()
    this.createAnnouncer()

    if (this.autoStartValue) {
      this.start()
    }
  }

  createAnnouncer() {
    this.announcer = document.createElement("span")
    this.announcer.setAttribute("role", "status")
    this.announcer.setAttribute("aria-live", "polite")
    this.announcer.setAttribute("aria-atomic", "true")
    this.announcer.className = "sr-only"
    this.element.appendChild(this.announcer)
  }

  disconnect() {
    this.stop()
    this.announcer?.remove()
  }

  start() {
    if (this.animationFrame) return // Already running
    
    this.startTime = Date.now()
    this.animate()
  }

  stop() {
    if (this.animationFrame) {
      cancelAnimationFrame(this.animationFrame)
      this.animationFrame = null
    }
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
      this.stop()
    }
  }

  setupCircle() {
    // SVG circle circumference = 2πr, where r = 45 (radius)
    this.circumference = 2 * Math.PI * 45
    this.circleTarget.style.strokeDasharray = this.circumference
    this.circleTarget.style.strokeDashoffset = 0
  }

  updateDisplay() {
    const minutes = Math.floor(this.timeRemaining / 60)
    const seconds = Math.round(this.timeRemaining % 60)
    this.displayTarget.textContent = `${minutes}:${seconds.toString().padStart(2, '0')}`
  }

  updateCircle() {
    const progress = this.timeRemaining / this.durationValue
    const offset = this.circumference * (1 - progress)
    this.circleTarget.style.strokeDashoffset = offset
  }

  updateColor() {
    const progress = this.timeRemaining / this.durationValue
    let newPhase

    if (this.timeRemaining <= 0) {
      newPhase = "zero"
    } else if (progress > 0.5) {
      newPhase = "green"
    } else if (progress > 0.25) {
      newPhase = "orange"
    } else {
      newPhase = "red"
    }

    this.element.setAttribute("data-phase", newPhase)

    // Announce phase changes to screen readers
    if (this.currentPhase !== newPhase) {
      this.announcePhaseChange(newPhase)
      this.currentPhase = newPhase
    }
  }

  announcePhaseChange(phase) {
    const messages = {
      orange: "Warning: Half time remaining",
      red: "Urgent: Less than 25% time remaining",
      zero: "Time is up!"
    }
    if (messages[phase] && this.announcer) {
      this.announcer.textContent = ""
      setTimeout(() => {
        this.announcer.textContent = messages[phase]
      }, 50)
    }
  }
}
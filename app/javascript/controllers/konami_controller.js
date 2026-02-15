import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.sequence = [
      "ArrowUp", "ArrowUp", "ArrowDown", "ArrowDown",
      "ArrowLeft", "ArrowRight", "ArrowLeft", "ArrowRight",
      "b", "a"
    ]
    this.inputBuffer = []
    this.boundHandleKeydown = this.handleKeydown.bind(this)
    document.addEventListener("keydown", this.boundHandleKeydown)
  }

  disconnect() {
    document.removeEventListener("keydown", this.boundHandleKeydown)
    this.cleanup()
  }

  handleKeydown(event) {
    this.inputBuffer.push(event.key)

    if (this.inputBuffer.length > this.sequence.length) {
      this.inputBuffer.shift()
    }

    if (this.inputBuffer.length === this.sequence.length &&
      this.inputBuffer.every((key, i) => key === this.sequence[i])) {
      this.inputBuffer = []
      this.activate()
    }
  }

  activate() {
    if (this.overlay) return

    const compliments = [
      "Way to go! You did it!",
      "Only a smart person could have figured this out!",
      "Your intellect exceeds all others!",
      "I'm proud of you.",
      "Your life has value!",
      "Everything you've ever done has led to this precise moment! Way to go!",
      "Congrats!",
      "Good job!",
      "Secret unlocked!",
      "Your existence is purposeful."
    ]

    const compliment = compliments[Math.floor(Math.random() * compliments.length)]

    this.overlay = this.buildOverlay(compliment)
    document.body.appendChild(this.overlay)

    this.spawnConfetti()
    this.confettiInterval = setInterval(() => this.spawnConfetti(), 600)

    this.launchFireworks()

    this.overlay.addEventListener("click", () => this.dismiss())
    this.autoDismissTimer = setTimeout(() => this.dismiss(), 8000)
  }

  buildOverlay(text) {
    const overlay = document.createElement("div")
    overlay.className = "konami-overlay"
    overlay.setAttribute("role", "status")
    overlay.setAttribute("aria-live", "polite")

    const canvas = document.createElement("canvas")
    canvas.className = "konami-canvas"
    overlay.appendChild(canvas)

    const textEl = document.createElement("div")
    textEl.className = "konami-text"
    textEl.textContent = text

    const hint = document.createElement("div")
    hint.className = "konami-hint"

    overlay.appendChild(textEl)
    overlay.appendChild(hint)

    return overlay
  }

  spawnConfetti() {
    const colors = [
      "#D63040", "#2196F3", "#FFD60A", "#4CAF50",
      "#FF6B35", "#7C4DFF", "#E040FB"
    ]
    const shapes = ["square", "circle", "strip", "large-square", "large-circle"]

    for (let i = 0; i < 200; i++) {
      const particle = document.createElement("div")
      const shape = shapes[Math.floor(Math.random() * shapes.length)]
      const useTumble = Math.random() > 0.5
      particle.className = `konami-confetti konami-confetti--${shape}${useTumble ? " konami-confetti--tumble" : ""}`
      particle.style.left = `${Math.random() * 100}%`
      particle.style.backgroundColor = colors[Math.floor(Math.random() * colors.length)]
      particle.style.animationDelay = `${Math.random() * 1.5}s`
      particle.style.animationDuration = `${3 + Math.random() * 3}s`
      particle.style.setProperty("--drift", `${(Math.random() - 0.5) * 600}px`)
      particle.style.setProperty("--spin", `${Math.random() * 2160 - 1080}deg`)
      this.overlay.appendChild(particle)
    }
  }

  launchFireworks() {
    const canvas = this.overlay.querySelector(".konami-canvas")
    if (!canvas) return

    const ctx = canvas.getContext("2d")
    const colors = [
      "#D63040", "#2196F3", "#FFD60A", "#4CAF50",
      "#FF6B35", "#7C4DFF", "#E040FB", "#FFFFFF"
    ]

    const resize = () => {
      canvas.width = window.innerWidth
      canvas.height = window.innerHeight
    }
    resize()
    window.addEventListener("resize", resize)
    this.fireworkResizeHandler = resize

    const rockets = []
    const sparks = []
    let lastLaunch = 0
    let nextInterval = 3

    const tick = (timestamp) => {
      ctx.globalCompositeOperation = "destination-out"
      ctx.fillStyle = "rgba(0, 0, 0, 0.15)"
      ctx.fillRect(0, 0, canvas.width, canvas.height)
      ctx.globalCompositeOperation = "lighter"

      // Launch new rockets
      if (timestamp - lastLaunch > nextInterval) {
        lastLaunch = timestamp
        nextInterval = 3 + Math.random() * 4
        rockets.push({
          x: Math.random() * canvas.width,
          y: canvas.height,
          vx: (Math.random() - 0.5) * 3,
          vy: -(8 + Math.random() * 6),
          color: colors[Math.floor(Math.random() * colors.length)],
          targetY: canvas.height * (0.15 + Math.random() * 0.35)
        })
      }

      // Update and draw rockets
      for (let i = rockets.length - 1; i >= 0; i--) {
        const r = rockets[i]
        r.x += r.vx
        r.y += r.vy

        // Trail
        ctx.beginPath()
        ctx.arc(r.x, r.y, 2, 0, Math.PI * 2)
        ctx.fillStyle = r.color
        ctx.fill()

        // Explode when reaching target
        if (r.y <= r.targetY) {
          const sparkCount = 30 + Math.floor(Math.random() * 30)
          for (let j = 0; j < sparkCount; j++) {
            const angle = (Math.PI * 2 * j) / sparkCount + (Math.random() - 0.5) * 0.5
            const speed = 2 + Math.random() * 5
            sparks.push({
              x: r.x,
              y: r.y,
              vx: Math.cos(angle) * speed,
              vy: Math.sin(angle) * speed,
              color: Math.random() > 0.3 ? r.color : colors[Math.floor(Math.random() * colors.length)],
              life: 1.0,
              decay: 0.01 + Math.random() * 0.02,
              size: 1.5 + Math.random() * 2
            })
          }
          rockets.splice(i, 1)
        }
      }

      // Update and draw sparks
      for (let i = sparks.length - 1; i >= 0; i--) {
        const s = sparks[i]
        s.vx *= 0.98
        s.vy *= 0.98
        s.vy += 0.06 // gravity
        s.x += s.vx
        s.y += s.vy
        s.life -= s.decay

        if (s.life <= 0) {
          sparks.splice(i, 1)
          continue
        }

        ctx.globalAlpha = s.life
        ctx.beginPath()
        ctx.arc(s.x, s.y, s.size * s.life, 0, Math.PI * 2)
        ctx.fillStyle = s.color
        ctx.fill()
      }

      ctx.globalAlpha = 1

      this.fireworkFrame = requestAnimationFrame(tick)
    }

    this.fireworkFrame = requestAnimationFrame(tick)
  }

  dismiss() {
    if (!this.overlay) return

    if (this.autoDismissTimer) {
      clearTimeout(this.autoDismissTimer)
      this.autoDismissTimer = null
    }

    this.overlay.classList.add("konami-overlay--dismissing")
    setTimeout(() => this.cleanup(), 400)
  }

  cleanup() {
    if (this.autoDismissTimer) {
      clearTimeout(this.autoDismissTimer)
      this.autoDismissTimer = null
    }
    if (this.confettiInterval) {
      clearInterval(this.confettiInterval)
      this.confettiInterval = null
    }
    if (this.fireworkFrame) {
      cancelAnimationFrame(this.fireworkFrame)
      this.fireworkFrame = null
    }
    if (this.fireworkResizeHandler) {
      window.removeEventListener("resize", this.fireworkResizeHandler)
      this.fireworkResizeHandler = null
    }
    if (this.overlay) {
      this.overlay.remove()
      this.overlay = null
    }
  }
}

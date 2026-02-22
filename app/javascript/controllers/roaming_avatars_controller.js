import { Controller } from "@hotwired/stimulus"

const STORAGE_KEY = "roaming-avatar-positions"

// Floating emoji avatars that roam around all Discord game pages.
// Avatars bounce off walls and each other using a simple physics simulation.
// Positions persist across Turbo navigations via sessionStorage.
export default class extends Controller {
  static targets = ["source"]

  static values = {
    colors: {
      type: Array, default: [
        "#D63040", "#FF6B35", "#FFD60A", "#4CAF50", "#2196F3", "#7C4DFF", "#E040FB"
      ]
    },
    phase: { type: String, default: "" },
    currentUser: { type: String, default: "" }
  }

  connect() {
    // Map<id, { el, x, y, vx, vy, w, h, tooltip, tooltipTimer, statusBadge }>
    this.avatars = new Map()
    this.colorIndex = 0
    this.prefersReducedMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches
    this.lastTimestamp = 0
    this.animFrameId = null
    this.obstacles = []
    this.obstacleRefreshCounter = 0

    // Cache z-index from theme token
    this.zAvatars = getComputedStyle(document.documentElement)
      .getPropertyValue('--z-index-avatars').trim() || "10"

    // Restore saved positions from previous page
    this.savedPositions = this.loadPositions()
    this.updateObstacles()

    // Create floating avatars for users already in the room
    this.sourceTarget.querySelectorAll("li").forEach(li => this.addFloatingAvatar(li, false))

    // Watch for Turbo Stream mutations (new users joining, avatar/status changes)
    this.observer = new MutationObserver(this.handleMutations.bind(this))
    this.observer.observe(this.sourceTarget, {
      childList: true,
      subtree: true,
      attributes: true,
      attributeFilter: ["data-status", "data-avatar", "data-accolade"]
    })

    // Sync phase value from incoming pages (element is data-turbo-permanent)
    this.boundUpdatePhase = this.updatePhaseFromNewPage.bind(this)
    document.addEventListener("turbo:before-render", this.boundUpdatePhase)

    // Clamp avatars when the window is resized
    this.boundResize = this.handleResize.bind(this)
    window.addEventListener("resize", this.boundResize)

    // Start physics loop
    if (!this.prefersReducedMotion) {
      this.animFrameId = requestAnimationFrame(this.tick.bind(this))
    }
  }

  disconnect() {
    this.stopFireworks()
    this.savePositions()
    this.observer?.disconnect()
    document.removeEventListener("turbo:before-render", this.boundUpdatePhase)
    window.removeEventListener("resize", this.boundResize)
    if (this.animFrameId) cancelAnimationFrame(this.animFrameId)

    // Re-parent active sparks to the container so they survive avatar removal
    const container = this.element
    this.avatars.forEach(a => {
      a.el.querySelectorAll(".roaming-avatar-spark").forEach(spark => {
        const rect = spark.getBoundingClientRect()
        const containerRect = container.getBoundingClientRect()
        spark.style.left = `${rect.left - containerRect.left}px`
        spark.style.top = `${rect.top - containerRect.top}px`
        spark.style.marginTop = "0"
        spark.style.marginLeft = "0"
        container.appendChild(spark)
      })
      a.el.remove()
    })
    this.avatars.clear()
  }

  // ── Position persistence ──

  savePositions() {
    const data = {}
    this.avatars.forEach((a, id) => {
      data[id] = { x: a.x, y: a.y, vx: a.vx, vy: a.vy, colorIndex: a.colorIndex, speedMultiplier: a.speedMultiplier, accolade: a.accolade }
    })
    try { sessionStorage.setItem(STORAGE_KEY, JSON.stringify(data)) } catch (_) {}
  }

  loadPositions() {
    try {
      const raw = sessionStorage.getItem(STORAGE_KEY)
      sessionStorage.removeItem(STORAGE_KEY)
      return raw ? JSON.parse(raw) : {}
    } catch (_) { return {} }
  }

  // ── Phase sync (turbo-permanent doesn't update server-rendered attributes) ──

  updatePhaseFromNewPage(event) {
    const newContainer = event.detail.newBody.querySelector("#roaming-avatars")
    if (newContainer) {
      const newPhase = newContainer.dataset.roamingAvatarsPhaseValue
      if (newPhase !== undefined) this.phaseValue = newPhase
    }
  }

  phaseValueChanged() {
    this.stopFireworks()
    this.avatars?.forEach((entry, id) => {
      const li = this.sourceTarget.querySelector(`#${id}`)
      const status = li?.dataset?.status || ""
      this.updateStatusBadge(entry, status)
    })
    if (this.phaseValue === "FinalResults") {
      this.startFireworks()
    }
  }

  // ── Mutation handling ──

  handleMutations(mutations) {
    const added = new Map()
    const removed = new Set()

    for (const mutation of mutations) {
      if (mutation.type === "attributes") {
        const li = mutation.target.closest("li")
        if (li && li.id) {
          if (mutation.attributeName === "data-status") {
            this.updateAvatarStatus(li)
          } else if (mutation.attributeName === "data-avatar") {
            this.updateAvatarEmoji(li)
          } else if (mutation.attributeName === "data-accolade") {
            this.updateAvatarAccolade(li)
          }
        }
        continue
      }

      if (mutation.type !== "childList") continue

      mutation.addedNodes.forEach(node => {
        if (node.nodeType === Node.ELEMENT_NODE && node.tagName === "LI" && node.id) {
          added.set(node.id, node)
        }
      })

      mutation.removedNodes.forEach(node => {
        if (node.nodeType === Node.ELEMENT_NODE && node.id) {
          removed.add(node.id)
        }
      })
    }

    // IDs in both added + removed = in-place replacement (e.g. broadcast_replace_to)
    for (const [id, li] of added) {
      if (removed.has(id) && this.avatars.has(id)) {
        removed.delete(id)
        added.delete(id)
        this.updateAvatarStatus(li)
        this.updateAvatarEmoji(li)
        if (li.hasAttribute("data-accolade")) {
          this.updateAvatarAccolade(li)
        }
      }
    }

    for (const id of removed) {
      this.removeFloatingAvatar(id)
    }

    for (const [, li] of added) {
      this.addFloatingAvatar(li, true)
    }
  }

  addFloatingAvatar(li, animate) {
    const id = li.id
    const avatar = li.dataset.avatar || li.textContent.trim().split(" ")[0]
    const name = li.dataset.name || li.textContent.trim().split(" ").slice(1).join(" ")
    const status = li.dataset.status || ""

    // Replace existing avatar element (e.g. avatar change via Turbo replace)
    // Preserve prevStatus so transition detection (sparks) still works
    let existingPrevStatus = null
    if (this.avatars.has(id)) {
      existingPrevStatus = this.avatars.get(id).prevStatus
      this.avatars.get(id).el.remove()
    }

    const el = document.createElement("div")
    el.className = "roaming-avatar absolute select-none cursor-pointer pointer-events-auto text-3xl max-sm:text-2xl leading-none"
    el.textContent = avatar
    el.dataset.userId = id
    el.dataset.name = name
    el.setAttribute("aria-label", name)
    el.setAttribute("role", "button")
    el.style.zIndex = this.zAvatars
    el.style.top = "0"
    el.style.left = "0"
    el.style.overflow = "visible"
    el.style.willChange = "transform"

    // Tinted circular background from rainbow colors
    const saved = this.savedPositions[id]
    const ci = saved?.colorIndex ?? this.colorIndex
    const color = this.colorsValue[ci % this.colorsValue.length]
    if (!saved) this.colorIndex++
    const isSelf = this.currentUserValue && id === this.currentUserValue
    el.style.backgroundColor = color + (isSelf ? "60" : "30")
    el.style.borderRadius = "50%"
    el.style.padding = "6px"
    if (isSelf) el.classList.add("roaming-avatar--self", "ring-2", "ring-yellow-400")

    if (animate && !saved) {
      el.classList.add("animate-bouncy")
    }

    el.addEventListener("click", (e) => {
      e.stopPropagation()
      const entry = this.findEntryByEl(el)
      if (entry && entry.tooltip) {
        this.hideTooltip(entry)
      } else {
        this.showTooltip(id, name)
      }
    })

    this.element.appendChild(el)

    // Measure actual rendered size after DOM insertion
    const w = el.offsetWidth
    const h = el.offsetHeight

    let pos, vx, vy
    if (saved) {
      // Restore position from previous page
      pos = { x: saved.x, y: saved.y }
      vx = saved.vx
      vy = saved.vy
      // Clamp to current viewport
      const maxX = Math.max(0, this.element.clientWidth - w)
      const maxY = Math.max(0, this.element.clientHeight - h)
      pos.x = Math.max(0, Math.min(pos.x, maxX))
      pos.y = Math.max(0, Math.min(pos.y, maxY))
    } else {
      pos = this.getRandomPosition(w, h)
      // Random velocity — slow amble
      const speed = 0.5 + 1.0
      const angle = Math.random() * Math.PI * 2
      vx = Math.cos(angle) * speed
      vy = Math.sin(angle) * speed
    }

    el.style.transform = `translate(${pos.x}px, ${pos.y}px)`
    const entry = { el, x: pos.x, y: pos.y, vx, vy, w, h, colorIndex: ci, tooltip: null, tooltipTimer: null, statusBadge: null, prevStatus: existingPrevStatus ?? status, crownEl: null, partyHatEl: null, accolade: "", speedMultiplier: 1.0 }
    this.avatars.set(id, entry)

    // Restore accolade from saved positions (Turbo navigation persistence)
    if (saved?.accolade) {
      this.applyAccolade(entry, saved.accolade)
    }

    // Apply accolade from initial server render
    const initialAccolade = li.dataset.accolade
    if (initialAccolade !== undefined) {
      this.applyAccolade(entry, initialAccolade)
    }

    // Update status badge
    this.updateStatusBadge(entry, status)

    // Auto-show name badge on entry (only for genuinely new avatars)
    if (!saved) {
      this.showTooltip(id, name, 15000)
    }
  }

  removeFloatingAvatar(id) {
    const avatar = this.avatars.get(id)
    if (!avatar) return

    this.hideTooltip(avatar)
    avatar.el.style.transition = "opacity 0.3s"
    avatar.el.style.opacity = "0"
    setTimeout(() => avatar.el.remove(), 300)
    this.avatars.delete(id)
  }

  // ── Status badges ──

  updateAvatarStatus(li) {
    const entry = this.avatars.get(li.id)
    if (!entry) return
    this.updateStatusBadge(entry, li.dataset.status || "")
  }

  updateAvatarEmoji(li) {
    const entry = this.avatars.get(li.id)
    if (!entry) return
    const newAvatar = li.dataset.avatar || li.textContent.trim().split(" ")[0]
    // Update only the text node (first child), preserve badge/tooltip children
    entry.el.childNodes.forEach(node => {
      if (node.nodeType === Node.TEXT_NODE) node.textContent = newAvatar
    })
  }

  updateStatusBadge(entry, status) {
    const prev = entry.prevStatus || ""
    entry.prevStatus = status

    // Detect status transitions for visual effects
    const submitted = (status === "Answered" || status === "Voted") && prev !== status
    const changedAnswer = (status === "Answering" && prev === "Answered") ||
                          (status === "Voting" && prev === "Voted")

    if (submitted) this.spawnSparks(entry)
    if (changedAnswer) this.flashRed(entry)

    // Remove existing badge
    if (entry.statusBadge) {
      entry.statusBadge.remove()
      entry.statusBadge = null
    }

    const phase = this.phaseValue
    // Only show badges during answering/voting phases
    if (!phase || phase === "WaitingRoom" || phase === "StorySelection" || phase === "Results" || phase === "FinalResults" || phase === "Credits") return

    const badge = document.createElement("div")
    badge.className = "roaming-avatar-status"

    if (status === "Answered" || status === "Voted") {
      badge.classList.add("roaming-avatar-status--done")
      badge.textContent = "✓"
    } else if (status === "Answering" || status === "Voting") {
      badge.classList.add("roaming-avatar-status--pending")
      badge.textContent = "..."
    } else {
      return // No badge for unknown status
    }

    entry.el.appendChild(badge)
    entry.statusBadge = badge
  }

  // ── Visual effects ──

  spawnSparks(entry) {
    if (this.prefersReducedMotion) return
    const colors = [
      "var(--color-accent-primary)",    // red
      "var(--color-accent-tertiary)",   // yellow
      "var(--color-accent-secondary)",  // blue
    ]
    const count = 12
    for (let i = 0; i < count; i++) {
      const spark = document.createElement("div")
      spark.className = "roaming-avatar-spark"
      const angle = (i / count) * Math.PI * 2 + (Math.random() - 0.5) * 0.5
      const dist = 55 + Math.random() * 40
      const color = colors[Math.floor(Math.random() * colors.length)]
      spark.style.setProperty("--spark-x", `${Math.cos(angle) * dist}px`)
      spark.style.setProperty("--spark-y", `${Math.sin(angle) * dist}px`)
      spark.style.setProperty("--spark-scale", `${0.8 + Math.random()}`)
      spark.style.setProperty("--spark-duration", `${0.8 + Math.random() * 0.8}s`)
      spark.style.setProperty("--spark-color", color)
      entry.el.appendChild(spark)
      spark.addEventListener("animationend", () => spark.remove(), { once: true })
    }
  }

  flashRed(entry) {
    if (this.prefersReducedMotion) return
    entry.el.classList.add("roaming-avatar--flash-red")
    entry.el.addEventListener("animationend", () => {
      entry.el.classList.remove("roaming-avatar--flash-red")
    }, { once: true })
  }

  // ── Fireworks (FinalResults phase) ──

  startFireworks() {
    if (this.prefersReducedMotion) return
    this.scheduleNextFirework()
  }

  scheduleNextFirework() {
    const delay = 2000 + Math.random() * 13000 // 2-15s
    this.fireworkTimer = setTimeout(() => {
      this.fireRandomFirework()
      this.scheduleNextFirework()
    }, delay)
  }

  stopFireworks() {
    if (this.fireworkTimer) {
      clearTimeout(this.fireworkTimer)
      this.fireworkTimer = null
    }
  }

  fireRandomFirework() {
    const entries = Array.from(this.avatars.values())
    if (entries.length === 0) return
    const entry = entries[Math.floor(Math.random() * entries.length)]
    this.spawnFirework(entry)
  }

  spawnFirework(entry) {
    const colors = [
      "var(--color-accent-red)",
      "var(--color-accent-yellow)",
      "var(--color-accent-blue)",
      "var(--color-accent-green)",
      "var(--color-accent-orange)"
    ]

    // Rocket phase — small dot launches upward
    const rocket = document.createElement("div")
    rocket.className = "roaming-avatar-rocket"
    rocket.style.width = "6px"
    rocket.style.height = "6px"
    rocket.style.borderRadius = "50%"
    const rocketColor = colors[Math.floor(Math.random() * colors.length)]
    rocket.style.backgroundColor = rocketColor
    rocket.style.boxShadow = `0 0 6px ${rocketColor}`
    rocket.setAttribute("aria-hidden", "true")
    entry.el.appendChild(rocket)

    // After rocket finishes, spawn burst particles
    rocket.addEventListener("animationend", () => {
      rocket.remove()
      this.spawnBurst(entry, colors)
    }, { once: true })
  }

  spawnBurst(entry, colors) {
    const count = 15 + Math.floor(Math.random() * 6) // 15-20 particles
    // Burst origin is above the avatar (where rocket ended)
    const burstOriginY = -(entry.h + 90)

    for (let i = 0; i < count; i++) {
      const particle = document.createElement("div")
      particle.className = "roaming-avatar-burst"
      const angle = (i / count) * Math.PI * 2 + (Math.random() - 0.5) * 0.6
      const dist = 60 + Math.random() * 60 // 60-120px travel
      const color = colors[Math.floor(Math.random() * colors.length)]
      particle.style.setProperty("--burst-x", `${Math.cos(angle) * dist}px`)
      particle.style.setProperty("--burst-y", `${Math.sin(angle) * dist}px`)
      particle.style.setProperty("--burst-color", color)
      particle.style.setProperty("--burst-duration", `${0.6 + Math.random() * 0.6}s`)
      // Position at burst origin (above avatar center)
      particle.style.top = `${burstOriginY}px`
      particle.style.left = "50%"
      particle.style.marginTop = "0"
      particle.style.marginLeft = "-3px"
      entry.el.appendChild(particle)
      particle.addEventListener("animationend", () => particle.remove(), { once: true })
    }
  }

  // ── Accolade decorations (crown & party hat) ──

  updateAvatarAccolade(li) {
    const entry = this.avatars.get(li.id)
    if (!entry) return
    this.applyAccolade(entry, li.dataset.accolade || "")
  }

  applyAccolade(entry, accolade) {
    entry.accolade = accolade

    // Remove existing decorations
    if (entry.crownEl) { entry.crownEl.remove(); entry.crownEl = null }
    if (entry.partyHatEl) { entry.partyHatEl.remove(); entry.partyHatEl = null }
    if (entry.creditsDecorations) {
      entry.creditsDecorations.forEach(el => el.remove())
      entry.creditsDecorations = null
    }
    entry.el.classList.remove("roaming-avatar--winner", "roaming-avatar--podium-1st", "roaming-avatar--podium-2nd", "roaming-avatar--podium-3rd")

    // Detect credits-phase accolades
    const creditsTags = ["podium_1st", "podium_2nd", "podium_3rd", "naughty", "prolific", "efficient", "misspeller", "slowpoke", "audience_fav"]
    const isCredits = creditsTags.some(tag => accolade.includes(tag))

    if (isCredits) {
      this.applyCreditsDecorations(entry, accolade)
      return
    }

    // Round-based accolades (winner/audience_favorite)
    const isWinner = accolade.includes("winner")
    const isFavorite = accolade.includes("audience_favorite")
    const hasBoth = isWinner && isFavorite

    // Speed multiplier: winners move 50% faster
    entry.speedMultiplier = isWinner ? 1.5 : 1.0

    if (isWinner) {
      entry.crownEl = this.createCrownElement()
      if (hasBoth) entry.crownEl.style.transform = "translateX(-70%)"
      entry.el.appendChild(entry.crownEl)
      entry.el.classList.add("roaming-avatar--winner")
    }

    if (isFavorite) {
      entry.partyHatEl = this.createPartyHatElement()
      if (hasBoth) entry.partyHatEl.style.transform = "translateX(-30%)"
      entry.el.appendChild(entry.partyHatEl)
    }
  }

  applyCreditsDecorations(entry, accolade) {
    entry.creditsDecorations = []
    const tags = accolade.split(" ").filter(Boolean)

    // Determine podium rank
    const podiumTag = tags.find(t => t.startsWith("podium_"))
    if (podiumTag === "podium_1st") {
      entry.speedMultiplier = 1.5
      entry.el.classList.add("roaming-avatar--podium-1st")
    } else if (podiumTag === "podium_2nd") {
      entry.speedMultiplier = 1.25
      entry.el.classList.add("roaming-avatar--podium-2nd")
    } else if (podiumTag === "podium_3rd") {
      entry.speedMultiplier = 1.1
      entry.el.classList.add("roaming-avatar--podium-3rd")
    } else {
      entry.speedMultiplier = 1.0
    }

    // Collect decorations: podium first, then superlatives
    const decoTags = []
    if (podiumTag) decoTags.push(podiumTag)
    const superlativeTags = tags.filter(t => !t.startsWith("podium_"))
    decoTags.push(...superlativeTags)

    // Render up to 2 decorations (primary centered, secondary offset right)
    decoTags.slice(0, 2).forEach((tag, i) => {
      const el = this.createCreditsDecoration(tag)
      if (!el) return
      if (i === 1) {
        el.style.transform = "translateX(-20%)"
      } else if (decoTags.length > 1) {
        el.style.transform = "translateX(-80%)"
      }
      entry.el.appendChild(el)
      entry.creditsDecorations.push(el)
    })
  }

  createCrownElement() {
    const wrap = document.createElement("div")
    wrap.className = "roaming-avatar-crown"
    wrap.setAttribute("aria-hidden", "true")
    wrap.innerHTML = `<svg width="22" height="16" viewBox="0 0 22 16" fill="none" xmlns="http://www.w3.org/2000/svg">
      <path d="M1 14L3 4L7 8L11 1L15 8L19 4L21 14H1Z" fill="#FFD60A" stroke="#1A1A2E" stroke-width="1.5" stroke-linejoin="round"/>
      <circle cx="3" cy="3.5" r="1.5" fill="#FFD60A" stroke="#1A1A2E" stroke-width="1"/>
      <circle cx="11" cy="0.5" r="1.5" fill="#FFD60A" stroke="#1A1A2E" stroke-width="1"/>
      <circle cx="19" cy="3.5" r="1.5" fill="#FFD60A" stroke="#1A1A2E" stroke-width="1"/>
    </svg>`
    return wrap
  }

  createPartyHatElement() {
    const wrap = document.createElement("div")
    wrap.className = "roaming-avatar-party-hat"
    wrap.setAttribute("aria-hidden", "true")
    wrap.innerHTML = `<svg width="18" height="22" viewBox="0 0 18 22" fill="none" xmlns="http://www.w3.org/2000/svg">
      <path d="M9 1L2 20H16L9 1Z" fill="#D63040" stroke="#1A1A2E" stroke-width="1.5" stroke-linejoin="round"/>
      <path d="M5 13L13 13" stroke="#FFD60A" stroke-width="1.5" stroke-linecap="round"/>
      <path d="M6.5 8L11.5 8" stroke="#2196F3" stroke-width="1.5" stroke-linecap="round"/>
      <circle cx="9" cy="1" r="2" fill="#FFD60A" stroke="#1A1A2E" stroke-width="1"/>
      <path d="M1 20H17" stroke="#1A1A2E" stroke-width="2" stroke-linecap="round"/>
    </svg>`
    return wrap
  }

  createCreditsDecoration(tag) {
    const svgMap = {
      podium_1st: { svg: this.svgTrophy(), cls: "roaming-avatar-trophy" },
      podium_2nd: { svg: this.svgMedalSilver(), cls: "roaming-avatar-medal" },
      podium_3rd: { svg: this.svgMedalBronze(), cls: "roaming-avatar-medal" },
      naughty: { svg: this.svgDevilHorns(), cls: "roaming-avatar-horns" },
      prolific: { svg: this.svgMortarboard(), cls: "roaming-avatar-mortarboard" },
      efficient: { svg: this.svgBolt(), cls: "roaming-avatar-bolt" },
      misspeller: { svg: this.svgEraser(), cls: "roaming-avatar-eraser" },
      slowpoke: { svg: this.svgNightcap(), cls: "roaming-avatar-nightcap" },
      audience_fav: { svg: this.svgStar(), cls: "roaming-avatar-star" },
    }
    const info = svgMap[tag]
    if (!info) return null

    const wrap = document.createElement("div")
    wrap.className = `roaming-avatar-decoration ${info.cls}`
    wrap.setAttribute("aria-hidden", "true")
    wrap.innerHTML = info.svg
    return wrap
  }

  // ── Credits SVGs ──

  svgTrophy() {
    return `<svg width="20" height="20" viewBox="0 0 20 20" fill="none" xmlns="http://www.w3.org/2000/svg">
      <path d="M5 2h10v6c0 2.8-2.2 5-5 5s-5-2.2-5-5V2z" fill="#FFD60A" stroke="#1A1A2E" stroke-width="1.5"/>
      <path d="M5 4H2c0 2.5 1.5 4 3 4" stroke="#1A1A2E" stroke-width="1.5" stroke-linecap="round"/>
      <path d="M15 4h3c0 2.5-1.5 4-3 4" stroke="#1A1A2E" stroke-width="1.5" stroke-linecap="round"/>
      <rect x="8" y="13" width="4" height="3" fill="#FFD60A" stroke="#1A1A2E" stroke-width="1"/>
      <rect x="6" y="16" width="8" height="2" rx="1" fill="#FFD60A" stroke="#1A1A2E" stroke-width="1"/>
    </svg>`
  }

  svgMedalSilver() {
    return `<svg width="18" height="22" viewBox="0 0 18 22" fill="none" xmlns="http://www.w3.org/2000/svg">
      <path d="M6 1L9 8L12 1" stroke="#1A1A2E" stroke-width="1.5" fill="#2196F3"/>
      <circle cx="9" cy="14" r="6" fill="#C0C0C0" stroke="#1A1A2E" stroke-width="1.5"/>
      <text x="9" y="17" text-anchor="middle" font-size="8" font-weight="bold" fill="#1A1A2E">2</text>
    </svg>`
  }

  svgMedalBronze() {
    return `<svg width="18" height="22" viewBox="0 0 18 22" fill="none" xmlns="http://www.w3.org/2000/svg">
      <path d="M6 1L9 8L12 1" stroke="#1A1A2E" stroke-width="1.5" fill="#D63040"/>
      <circle cx="9" cy="14" r="6" fill="#CD7F32" stroke="#1A1A2E" stroke-width="1.5"/>
      <text x="9" y="17" text-anchor="middle" font-size="8" font-weight="bold" fill="#1A1A2E">3</text>
    </svg>`
  }

  svgDevilHorns() {
    return `<svg width="22" height="16" viewBox="0 0 22 16" fill="none" xmlns="http://www.w3.org/2000/svg">
      <path d="M3 14C2 8 1 2 4 1c2-0.5 3 3 4 6" stroke="#D63040" stroke-width="2" fill="#D63040" stroke-linecap="round"/>
      <path d="M19 14c1-6 2-12-1-13-2-0.5-3 3-4 6" stroke="#D63040" stroke-width="2" fill="#D63040" stroke-linecap="round"/>
    </svg>`
  }

  svgMortarboard() {
    return `<svg width="22" height="18" viewBox="0 0 22 18" fill="none" xmlns="http://www.w3.org/2000/svg">
      <polygon points="11,2 1,8 11,14 21,8" fill="#1A1A2E" stroke="#1A1A2E" stroke-width="1"/>
      <rect x="5" y="9" width="12" height="4" fill="none" stroke="#1A1A2E" stroke-width="1.5" rx="0"/>
      <line x1="19" y1="8" x2="19" y2="16" stroke="#FFD60A" stroke-width="1.5" stroke-linecap="round"/>
      <circle cx="19" cy="16" r="1.5" fill="#FFD60A"/>
    </svg>`
  }

  svgBolt() {
    return `<svg width="16" height="22" viewBox="0 0 16 22" fill="none" xmlns="http://www.w3.org/2000/svg">
      <path d="M10 1L2 12h5l-3 9L14 9H9l1-8z" fill="#FFD60A" stroke="#1A1A2E" stroke-width="1.5" stroke-linejoin="round"/>
    </svg>`
  }

  svgEraser() {
    return `<svg width="20" height="20" viewBox="0 0 20 20" fill="none" xmlns="http://www.w3.org/2000/svg">
      <rect x="3" y="12" width="14" height="6" rx="2" fill="#FFB6C1" stroke="#1A1A2E" stroke-width="1.5"/>
      <rect x="7" y="2" width="4" height="12" rx="1" fill="#FFD60A" stroke="#1A1A2E" stroke-width="1.5"/>
      <polygon points="7,4 11,4 11,2 7,2" fill="#1A1A2E"/>
    </svg>`
  }

  svgNightcap() {
    return `<svg width="20" height="22" viewBox="0 0 20 22" fill="none" xmlns="http://www.w3.org/2000/svg">
      <path d="M2 18C2 18 3 4 10 2c0 0 8 8 8 16" fill="#2196F3" stroke="#1A1A2E" stroke-width="1.5" stroke-linecap="round"/>
      <circle cx="10" cy="2" r="2" fill="#FFD60A" stroke="#1A1A2E" stroke-width="1"/>
      <path d="M2 18h16" stroke="#1A1A2E" stroke-width="2" stroke-linecap="round"/>
      <text x="16" y="10" font-size="6" font-weight="bold" fill="#1A1A2E">z</text>
      <text x="18" y="7" font-size="5" font-weight="bold" fill="#1A1A2E">z</text>
    </svg>`
  }

  svgStar() {
    return `<svg width="20" height="20" viewBox="0 0 20 20" fill="none" xmlns="http://www.w3.org/2000/svg">
      <path d="M10 1l2.5 5.5L18 7.5l-4 4 1 6-5-3-5 3 1-6-4-4 5.5-1z" fill="#FFD60A" stroke="#1A1A2E" stroke-width="1.5" stroke-linejoin="round"/>
    </svg>`
  }

  scaleForAccolade(accolade) {
    if (!accolade) return ""
    if (accolade.includes("podium_1st")) return " scale(1.3)"
    if (accolade.includes("podium_2nd")) return " scale(1.15)"
    if (accolade.includes("podium_3rd")) return " scale(1.1)"
    if (accolade.includes("winner")) return " scale(1.2)"
    return ""
  }

  // ── Physics loop ──

  tick(timestamp) {
    if (!this.lastTimestamp) this.lastTimestamp = timestamp
    const rawDt = (timestamp - this.lastTimestamp) / 16
    const dt = Math.max(0.5, Math.min(rawDt, 3))
    this.lastTimestamp = timestamp

    // Refresh obstacle rects periodically (handles dynamic layout changes)
    if (++this.obstacleRefreshCounter >= 60) {
      this.obstacleRefreshCounter = 0
      this.updateObstacles()
    }

    const visibleWidth = this.element.clientWidth
    const visibleHeight = this.element.clientHeight

    // Move each avatar
    this.avatars.forEach(a => {
      let { x, y, vx, vy, w, h } = a
      const maxX = visibleWidth - w
      const maxY = visibleHeight - h

      const sm = a.speedMultiplier || 1.0
      x += vx * sm * dt
      y += vy * sm * dt

      // Obstacle collision
      for (const obs of this.obstacles) {
        const overlapX = Math.min(x + w, obs.right) - Math.max(x, obs.left)
        const overlapY = Math.min(y + h, obs.bottom) - Math.max(y, obs.top)

        if (overlapX > 0 && overlapY > 0) {
          // Rounded corner check — let avatars pass through cut corners
          if (obs.borderRadius > 0) {
            const br = obs.borderRadius
            const cx = x + w / 2
            const cy = y + h / 2
            const avatarR = w / 2

            let arcCx, arcCy
            if (cx < obs.left + br && cy < obs.top + br) {
              arcCx = obs.left + br; arcCy = obs.top + br
            } else if (cx > obs.right - br && cy < obs.top + br) {
              arcCx = obs.right - br; arcCy = obs.top + br
            } else if (cx < obs.left + br && cy > obs.bottom - br) {
              arcCx = obs.left + br; arcCy = obs.bottom - br
            } else if (cx > obs.right - br && cy > obs.bottom - br) {
              arcCx = obs.right - br; arcCy = obs.bottom - br
            }

            if (arcCx !== undefined) {
              const dx = cx - arcCx
              const dy = cy - arcCy
              const dist = Math.sqrt(dx * dx + dy * dy)
              const minDist = br + avatarR

              if (dist >= minDist) continue // In cut corner — no collision

              // Bounce off the rounded corner
              if (dist > 0) {
                const nx = dx / dist
                const ny = dy / dist
                x = arcCx + nx * minDist - w / 2
                y = arcCy + ny * minDist - h / 2
                const dot = vx * nx + vy * ny
                if (dot < 0) {
                  vx -= 2 * dot * nx
                  vy -= 2 * dot * ny
                }
              }
              continue
            }
          }

          // Flat edge response (AABB)
          if (overlapX < overlapY) {
            if (x + w / 2 < (obs.left + obs.right) / 2) {
              x = obs.left - w
            } else {
              x = obs.right
            }
            vx = -vx
          } else {
            if (y + h / 2 < (obs.top + obs.bottom) / 2) {
              y = obs.top - h
            } else {
              y = obs.bottom
            }
            vy = -vy
          }
        }
      }

      // Wall bounce
      if (x < 0) { x = 0; vx = Math.abs(vx) }
      else if (x > maxX) { x = maxX; vx = -Math.abs(vx) }
      if (y < 0) { y = 0; vy = Math.abs(vy) }
      else if (y > maxY) { y = maxY; vy = -Math.abs(vy) }

      a.x = x; a.y = y; a.vx = vx; a.vy = vy
      const scaleStr = this.scaleForAccolade(a.accolade)
      a.el.style.transform = `translate(${x}px, ${y}px)${scaleStr}`
    })

    // Avatar-avatar collisions (center-to-center)
    const entries = Array.from(this.avatars.values())
    for (let i = 0; i < entries.length; i++) {
      for (let j = i + 1; j < entries.length; j++) {
        const a = entries[i], b = entries[j]
        const ax = a.x + a.w / 2, ay = a.y + a.h / 2
        const bx = b.x + b.w / 2, by = b.y + b.h / 2
        const dx = ax - bx
        const dy = ay - by
        const dist = Math.sqrt(dx * dx + dy * dy)
        const collisionDist = (a.w + b.w) / 2
        if (dist < collisionDist && dist > 0) {
          const overlap = collisionDist - dist
          const nx = dx / dist
          const ny = dy / dist
          a.x += nx * overlap * 0.5
          a.y += ny * overlap * 0.5
          b.x -= nx * overlap * 0.5
          b.y -= ny * overlap * 0.5

          // Swap velocity components along collision normal (equal-mass elastic)
          const aDotn = a.vx * nx + a.vy * ny
          const bDotn = b.vx * nx + b.vy * ny
          a.vx += (bDotn - aDotn) * nx
          a.vy += (bDotn - aDotn) * ny
          b.vx += (aDotn - bDotn) * nx
          b.vy += (aDotn - bDotn) * ny

          // Ensure minimum separation speed so collisions are always visible
          const minSep = 0.5
          const aSep = a.vx * nx + a.vy * ny
          const bSep = -(b.vx * nx + b.vy * ny)
          if (aSep < minSep) {
            a.vx += (minSep - aSep) * nx
            a.vy += (minSep - aSep) * ny
          }
          if (bSep < minSep) {
            b.vx -= (minSep - bSep) * nx
            b.vy -= (minSep - bSep) * ny
          }
        }
      }
    }

    // Clamp all positions after collision resolution
    for (const a of entries) {
      const maxX = visibleWidth - a.w
      const maxY = visibleHeight - a.h
      a.x = Math.max(0, Math.min(a.x, maxX))
      a.y = Math.max(0, Math.min(a.y, maxY))
      const scaleStr = this.scaleForAccolade(a.accolade)
      a.el.style.transform = `translate(${a.x}px, ${a.y}px)${scaleStr}`
    }

    this.animFrameId = requestAnimationFrame(this.tick.bind(this))
  }

  handleResize() {
    this.updateObstacles()
    const visibleWidth = this.element.clientWidth
    const visibleHeight = this.element.clientHeight

    this.avatars.forEach(a => {
      const maxX = visibleWidth - a.w
      const maxY = visibleHeight - a.h
      a.x = Math.max(0, Math.min(a.x, maxX))
      a.y = Math.max(0, Math.min(a.y, maxY))
      a.el.style.transform = `translate(${a.x}px, ${a.y}px)`
    })
  }

  updateObstacles() {
    const containerRect = this.element.getBoundingClientRect()
    this.obstacles = []

    const navbar = document.querySelector(".discord-navbar")
    if (navbar) {
      const r = navbar.getBoundingClientRect()
      this.obstacles.push({
        left: r.left - containerRect.left,
        top: r.top - containerRect.top,
        right: r.right - containerRect.left,
        bottom: r.bottom - containerRect.top + 4
      })
    }

    // Padding matches visual footprint: box-shadow is 8px 8px 0px (right & down only),
    // border is included in getBoundingClientRect, so top/left need no extra padding.
    const card = document.querySelector(".card-primary")
    if (card) {
      const r = card.getBoundingClientRect()
      const borderRadius = parseFloat(getComputedStyle(card).borderRadius) || 0
      this.obstacles.push({
        left: r.left - containerRect.left,
        top: r.top - containerRect.top,
        right: r.right - containerRect.left + 8,
        bottom: r.bottom - containerRect.top + 8,
        borderRadius
      })
    }
  }

  getRandomPosition(w, h) {
    const visibleWidth = this.element.clientWidth
    const visibleHeight = this.element.clientHeight
    const maxX = Math.max(0, visibleWidth - w)
    const maxY = Math.max(0, visibleHeight - h)

    for (let attempt = 0; attempt < 10; attempt++) {
      const x = Math.random() * maxX
      const y = Math.random() * maxY
      const hit = this.obstacles.some(obs =>
        x + w > obs.left && x < obs.right && y + h > obs.top && y < obs.bottom
      )
      if (!hit) return { x, y }
    }

    return { x: Math.random() * maxX, y: Math.random() * maxY }
  }

  // ── Tooltip ──

  findEntryByEl(el) {
    for (const entry of this.avatars.values()) {
      if (entry.el === el) return entry
    }
    return null
  }

  showTooltip(id, name, duration = 2000) {
    const entry = this.avatars.get(id)
    if (!entry) return

    // Clear any existing tooltip on this avatar
    this.hideTooltip(entry)

    const tooltipId = `tooltip-${id}`
    const tooltip = document.createElement("div")
    tooltip.className = "roaming-avatar-tooltip"
    tooltip.id = tooltipId
    tooltip.setAttribute("role", "tooltip")
    tooltip.textContent = name

    entry.el.setAttribute("aria-describedby", tooltipId)
    entry.el.appendChild(tooltip)
    entry.tooltip = tooltip
    entry.tooltipTimer = setTimeout(() => this.hideTooltip(entry), duration)
  }

  hideTooltip(entry) {
    if (entry.tooltipTimer) {
      clearTimeout(entry.tooltipTimer)
      entry.tooltipTimer = null
    }
    if (entry.tooltip) {
      entry.el.removeAttribute("aria-describedby")
      entry.tooltip.remove()
      entry.tooltip = null
    }
  }
}

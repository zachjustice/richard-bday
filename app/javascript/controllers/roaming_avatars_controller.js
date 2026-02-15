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

    // Cache z-index from theme token
    this.zAvatars = getComputedStyle(document.documentElement)
      .getPropertyValue('--z-index-avatars').trim() || "10"

    // Restore saved positions from previous page
    this.savedPositions = this.loadPositions()

    // Create floating avatars for users already in the room
    this.sourceTarget.querySelectorAll("li").forEach(li => this.addFloatingAvatar(li, false))

    // Watch for Turbo Stream mutations (new users joining, avatar/status changes)
    this.observer = new MutationObserver(this.handleMutations.bind(this))
    this.observer.observe(this.sourceTarget, {
      childList: true,
      subtree: true,
      attributes: true,
      attributeFilter: ["data-status", "data-avatar"]
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
      data[id] = { x: a.x, y: a.y, vx: a.vx, vy: a.vy, colorIndex: a.colorIndex }
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
    this.avatars?.forEach((entry, id) => {
      const li = this.sourceTarget.querySelector(`#${id}`)
      const status = li?.dataset?.status || ""
      this.updateStatusBadge(entry, status)
    })
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
    const entry = { el, x: pos.x, y: pos.y, vx, vy, w, h, colorIndex: ci, tooltip: null, tooltipTimer: null, statusBadge: null, prevStatus: existingPrevStatus ?? status }
    this.avatars.set(id, entry)

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

  // ── Physics loop ──

  tick(timestamp) {
    if (!this.lastTimestamp) this.lastTimestamp = timestamp
    const rawDt = (timestamp - this.lastTimestamp) / 16
    const dt = Math.max(0.5, Math.min(rawDt, 3))
    this.lastTimestamp = timestamp

    const visibleWidth = this.element.clientWidth
    const visibleHeight = this.element.clientHeight

    // Move each avatar
    this.avatars.forEach(a => {
      let { x, y, vx, vy, w, h } = a
      const maxX = visibleWidth - w
      const maxY = visibleHeight - h

      x += vx * dt
      y += vy * dt

      // Wall bounce
      if (x < 0) { x = 0; vx = Math.abs(vx) }
      else if (x > maxX) { x = maxX; vx = -Math.abs(vx) }
      if (y < 0) { y = 0; vy = Math.abs(vy) }
      else if (y > maxY) { y = maxY; vy = -Math.abs(vy) }

      a.x = x; a.y = y; a.vx = vx; a.vy = vy
      a.el.style.transform = `translate(${x}px, ${y}px)`
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
      a.el.style.transform = `translate(${a.x}px, ${a.y}px)`
    }

    this.animFrameId = requestAnimationFrame(this.tick.bind(this))
  }

  handleResize() {
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

  getRandomPosition(w, h) {
    const visibleWidth = this.element.clientWidth
    const visibleHeight = this.element.clientHeight
    const maxX = Math.max(0, visibleWidth - w)
    const maxY = Math.max(0, visibleHeight - h)

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

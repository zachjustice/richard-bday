import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["display", "form", "indicator", "loading", "carousel"]
  static values = {
    avatars: Array,
    taken: Array,
    current: String,
    index: Number,
    justSelected: Boolean
  }

  connect() {
    this.setupTouchEvents()
    this.setupKeyboardEvents()
    this.isFirstLoad = true
    this.spinDuration = 1000

    // Wait for DOM to be fully ready, then show carousel and spin
    if (document.readyState === 'complete') {
      this.initializeCarousel()
    } else {
      window.addEventListener('load', () => this.initializeCarousel(), { once: true })
    }
  }

  initializeCarousel() {
    // Hide loading, show carousel
    if (this.hasLoadingTarget) {
      this.loadingTarget.classList.add('hidden')
    }
    if (this.hasCarouselTarget) {
      this.carouselTarget.classList.remove('hidden')
    }

    // If just selected, show current avatar in selected state without spinning
    if (this.justSelectedValue) {
      this.isFirstLoad = false
      this.updateIndicators()
      this.updateVisualState(false, true)
      return
    }

    // Start the spin animation
    requestAnimationFrame(() => {
      this.spinToRandom()
    })
  }

  disconnect() {
    this.teardownTouchEvents()
    this.teardownKeyboardEvents()
  }

  // Navigation
  previous() {
    this.navigate(-1)
  }

  next() {
    this.navigate(1)
  }

  navigate(direction) {
    const avatars = this.avatarsValue
    const newIndex = (this.indexValue + direction + avatars.length) % avatars.length
    this.indexValue = newIndex
    this.updateDisplay(direction)
  }

  updateDisplay(direction = 0) {
    const avatar = this.avatarsValue[this.indexValue]
    const isTaken = this.takenValue.includes(avatar)
    const isCurrent = avatar === this.currentValue

    // Animate the transition
    const display = this.displayTarget
    const slideClass = direction > 0 ? 'slide-out-left' : direction < 0 ? 'slide-out-right' : ''

    if (slideClass) {
      display.classList.add(slideClass)

      setTimeout(() => {
        display.textContent = avatar
        display.classList.remove(slideClass)
        display.classList.add(direction > 0 ? 'slide-in-right' : 'slide-in-left')

        setTimeout(() => {
          display.classList.remove('slide-in-right', 'slide-in-left')
        }, 200)
      }, 150)
    } else {
      display.textContent = avatar
    }

    // Update visual state
    this.updateVisualState(isTaken, isCurrent)
    this.updateIndicators()
  }

  updateVisualState(isTaken, isCurrent) {
    const container = this.element.querySelector('[data-avatar-container]')
    if (!container) return

    // Remove all state classes
    container.classList.remove('avatar-taken', 'avatar-current', 'avatar-available')

    if (isTaken) {
      container.classList.add('avatar-taken')
    } else if (isCurrent && !this.isFirstLoad) {
      // Only show as "current" after first interaction
      container.classList.add('avatar-current')
    } else {
      container.classList.add('avatar-available')
    }

    // Update the hidden input
    const input = this.formTarget.querySelector('input[name="avatar"]')
    if (input) {
      input.value = this.avatarsValue[this.indexValue]
    }

    // Update button states
    const submitBtn = this.element.querySelector('button[type="submit"]')
    if (submitBtn) {
      if (isTaken) {
        submitBtn.disabled = true
        submitBtn.textContent = 'Taken'
        submitBtn.classList.add('opacity-50', 'cursor-not-allowed')
      } else if (isCurrent) {
        submitBtn.disabled = true
        submitBtn.textContent = 'Selected'
        submitBtn.classList.add('opacity-50', 'cursor-not-allowed')
      } else {
        submitBtn.disabled = false
        submitBtn.textContent = 'Submit'
        submitBtn.classList.remove('opacity-50', 'cursor-not-allowed')
      }
    }
  }

  updateIndicators() {
    const avatars = this.avatarsValue
    const currentIndex = this.indexValue

    // We have 2 indicators: left (-1) and right (+1)
    this.indicatorTargets.forEach((indicator, i) => {
      const offset = i === 0 ? -1 : 1
      const avatarIndex = (currentIndex + offset + avatars.length) % avatars.length
      const avatar = avatars[avatarIndex]
      const isTaken = this.takenValue.includes(avatar)

      indicator.textContent = avatar

      // Reset classes - grayscale for taken avatars
      indicator.classList.remove('grayscale')

      if (isTaken) {
        indicator.classList.add('grayscale')
      }
    })
  }

  select() {
    const avatar = this.avatarsValue[this.indexValue]
    const isTaken = this.takenValue.includes(avatar)
    const isCurrent = avatar === this.currentValue

    if (!isTaken && !isCurrent) {
      this.formTarget.requestSubmit()
    }
  }

  // Touch/Swipe support
  setupTouchEvents() {
    this.touchStartX = 0
    this.touchEndX = 0
    this.minSwipeDistance = 50

    this.boundTouchStart = this.handleTouchStart.bind(this)
    this.boundTouchMove = this.handleTouchMove.bind(this)
    this.boundTouchEnd = this.handleTouchEnd.bind(this)

    this.element.addEventListener('touchstart', this.boundTouchStart, { passive: true })
    this.element.addEventListener('touchmove', this.boundTouchMove, { passive: true })
    this.element.addEventListener('touchend', this.boundTouchEnd)
  }

  teardownTouchEvents() {
    this.element.removeEventListener('touchstart', this.boundTouchStart)
    this.element.removeEventListener('touchmove', this.boundTouchMove)
    this.element.removeEventListener('touchend', this.boundTouchEnd)
  }

  handleTouchStart(e) {
    this.touchStartX = e.changedTouches[0].screenX
  }

  handleTouchMove(e) {
    this.touchEndX = e.changedTouches[0].screenX
  }

  handleTouchEnd() {
    const diff = this.touchStartX - this.touchEndX

    if (Math.abs(diff) > this.minSwipeDistance) {
      if (diff > 0) {
        this.next()
      } else {
        this.previous()
      }
    }
  }

  // Keyboard support
  setupKeyboardEvents() {
    this.boundKeydown = this.handleKeydown.bind(this)
    this.element.addEventListener('keydown', this.boundKeydown)
  }

  teardownKeyboardEvents() {
    this.element.removeEventListener('keydown', this.boundKeydown)
  }

  handleKeydown(e) {
    if (e.key === 'ArrowLeft') {
      e.preventDefault()
      this.previous()
    } else if (e.key === 'ArrowRight') {
      e.preventDefault()
      this.next()
    } else if (e.key === 'Enter') {
      e.preventDefault()
      this.select()
    }
  }

  shuffle() {
    this.isFirstLoad = false
    this.spinToRandom()
  }

  spinToRandom() {
    const avatars = this.avatarsValue
    const taken = this.takenValue
    const current = this.currentValue
    const duration = this.spinDuration

    // Get available avatars (exclude taken, but include current for first load)
    const available = avatars.filter(a => !taken.includes(a))
    if (available.length === 0) return

    // Pick a random target
    const randomAvatar = available[Math.floor(Math.random() * available.length)]
    const targetIndex = avatars.indexOf(randomAvatar)

    // Calculate steps - enough for a good spin effect
    const totalSteps = 15 + Math.floor(Math.random() * 10)

    const startTime = performance.now()
    let lastStepIndex = -1

    const spin = (currentTime) => {
      const elapsed = currentTime - startTime
      const progress = Math.min(elapsed / duration, 1)

      // Ease out cubic for natural deceleration
      const easeOut = 1 - Math.pow(1 - progress, 3)
      const currentStep = Math.floor(easeOut * totalSteps)

      // Only update if we've moved to a new step
      if (currentStep !== lastStepIndex) {
        lastStepIndex = currentStep

        // Calculate which avatar to show
        const startIndex = this.indexValue
        const stepsFromStart = currentStep % avatars.length
        const displayIndex = (startIndex + stepsFromStart) % avatars.length

        // Update display
        this.displayTarget.textContent = avatars[displayIndex]
        this.updateIndicatorsForIndex(displayIndex)
      }

      if (progress < 1) {
        requestAnimationFrame(spin)
      } else {
        // Final position - always show as available (not current) after spin
        this.indexValue = targetIndex
        const finalAvatar = avatars[this.indexValue]
        const isTaken = taken.includes(finalAvatar)
        this.displayTarget.textContent = finalAvatar
        this.updateIndicators()
        this.updateVisualState(isTaken, false)
      }
    }

    requestAnimationFrame(spin)
  }

  updateIndicatorsForIndex(index) {
    const avatars = this.avatarsValue

    this.indicatorTargets.forEach((indicator, i) => {
      const offset = i === 0 ? -1 : 1
      const avatarIndex = (index + offset + avatars.length) % avatars.length
      const avatar = avatars[avatarIndex]
      const isTaken = this.takenValue.includes(avatar)

      indicator.textContent = avatar
      indicator.classList.remove('grayscale')
      if (isTaken) {
        indicator.classList.add('grayscale')
      }
    })
  }
}

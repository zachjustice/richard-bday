import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["slot", "answer", "answersContainer", "input", "submit", "form", "placeholder", "hintText"]
  static values = { maxSlots: Number, medals: Array }

  connect() {
    this.isDragging = false
    this.currentDraggingAnswer = null
    this.touchStartPos = null
    this.currentTouchTarget = null
    this.originalNextSibling = null // Track original position for click-release
    this.originalParent = null
    this.touchClone = null // Visual clone for touch dragging
    this.hasMoved = false // Track if user actually moved during touch
    this.selectedAnswer = null // Keyboard selection state

    // Store initial order of answers for restoring positions
    this.initialAnswerOrder = this.answerTargets.map(a => a.dataset.answerId)

    // Angry-tap detection for hint shake
    this.tapTimestamps = []
    this.hintShown = false

    this.setupDragHandlers()
    this.setupKeyboardHandlers()
    this.updateSubmitState()
  }

  setupDragHandlers() {
    // For each answer, implement drag
    this.answerTargets.forEach(answer => {
      // Make entire answer draggable
      answer.setAttribute("draggable", "true")

      answer.addEventListener("dragstart", (e) => {
        // Store original position for restoring on click-release
        this.originalParent = answer.parentElement
        this.originalNextSibling = answer.nextElementSibling

        // Store the answer ID for drag/drop
        e.dataTransfer.effectAllowed = "move"
        e.dataTransfer.setData("text/plain", answer.dataset.answerId)
        this.currentDraggingAnswer = answer
        this.isDragging = true
        answer.classList.add("dragging")

        // Create a clone for the drag image with full opacity
        const clone = answer.cloneNode(true)
        clone.style.position = "fixed"
        clone.style.top = "0"
        clone.style.left = "-9999px"
        clone.style.opacity = "1"
        clone.style.transform = "none"
        clone.style.pointerEvents = "none"
        clone.style.zIndex = "-1"
        clone.style.width = `${answer.offsetWidth}px`
        clone.classList.remove("dragging")
        this.applyCloneTruncation(clone)
        document.body.appendChild(clone)

        // Force browser to render the clone before using it as drag image
        clone.offsetHeight

        // Calculate offset so the handle is always under the cursor
        const handle = answer.querySelector(".ranking-handle")
        const answerRect = answer.getBoundingClientRect()
        const handleRect = handle.getBoundingClientRect()

        // Position cursor at the center of the handle
        const offsetX = (handleRect.left - answerRect.left) + (handleRect.width / 2)
        const offsetY = (handleRect.top - answerRect.top) + (handleRect.height / 2)

        // Set the clone as the drag image
        e.dataTransfer.setDragImage(clone, offsetX, offsetY)

        // Store clone for cleanup
        this.dragClone = clone
      })

      // Touch events for mobile
      answer.addEventListener("touchstart", (e) => this.startTouch(e, answer), { passive: false })
      answer.addEventListener("touchmove", (e) => this.onTouchMove(e), { passive: false })
      answer.addEventListener("touchend", (e) => this.onTouchEnd(e))
      answer.addEventListener("touchcancel", () => this.cancelTouch())

      // Drag events
      answer.addEventListener("dragend", (e) => this.onDragEnd(e, answer))
    })

    // Setup drop zones (slots)
    this.slotTargets.forEach(slot => {
      slot.addEventListener("dragover", (e) => this.onDragOver(e, slot))
      slot.addEventListener("dragleave", (e) => this.onDragLeave(e, slot))
      slot.addEventListener("drop", (e) => this.onDrop(e, slot))
    })

    // Allow dropping back to answers container
    this.answersContainerTarget.addEventListener("dragover", (e) => this.onDragOver(e, null))
    this.answersContainerTarget.addEventListener("drop", (e) => this.onDropToContainer(e))

    // Track frustrated taps on answers and slots for hint shake
    this.answersContainerTarget.addEventListener("click", () => this.trackTap())
    this.slotTargets.forEach(slot => {
      slot.addEventListener("click", () => this.trackTap())
    })
  }

  setupKeyboardHandlers() {
    // Make answers focusable and add ARIA attributes
    this.answerTargets.forEach(answer => {
      answer.setAttribute("tabindex", "0")
      answer.setAttribute("role", "option")
      answer.setAttribute("aria-selected", "false")

      answer.addEventListener("keydown", (e) => this.handleAnswerKeydown(e, answer))
    })

    // Make slots focusable for keyboard navigation
    this.slotTargets.forEach(slot => {
      slot.setAttribute("tabindex", "0")
      slot.setAttribute("role", "listbox")
      slot.setAttribute("aria-label", `Rank ${slot.dataset.rank} slot`)

      slot.addEventListener("keydown", (e) => this.handleSlotKeydown(e, slot))
    })
  }

  handleAnswerKeydown(event, answer) {
    switch (event.key) {
      case "Enter":
      case " ":
        event.preventDefault()
        this.toggleAnswerSelection(answer)
        break
      case "ArrowUp":
        event.preventDefault()
        this.moveFocusToPreviousAnswer(answer)
        break
      case "ArrowDown":
        event.preventDefault()
        this.moveFocusToNextAnswer(answer)
        break
      case "Escape":
        event.preventDefault()
        this.clearKeyboardSelection()
        break
    }
  }

  handleSlotKeydown(event, slot) {
    switch (event.key) {
      case "Enter":
      case " ":
        event.preventDefault()
        if (this.selectedAnswer) {
          this.placeSelectedAnswerInSlot(slot)
        } else {
          // If slot has an answer, select it for moving
          const existingAnswer = slot.querySelector(".ranking-answer")
          if (existingAnswer) {
            this.toggleAnswerSelection(existingAnswer)
          }
        }
        break
      case "ArrowUp":
        event.preventDefault()
        this.moveFocusToPreviousSlot(slot)
        break
      case "ArrowDown":
        event.preventDefault()
        this.moveFocusToNextSlot(slot)
        break
      case "Escape":
        event.preventDefault()
        this.clearKeyboardSelection()
        break
      case "Backspace":
      case "Delete":
        event.preventDefault()
        this.removeAnswerFromSlot(slot)
        break
    }
  }

  toggleAnswerSelection(answer) {
    if (this.selectedAnswer === answer) {
      this.clearKeyboardSelection()
      this.announceToScreenReader("Selection cleared")
    } else {
      this.clearKeyboardSelection()
      this.selectedAnswer = answer
      answer.setAttribute("aria-selected", "true")
      answer.classList.add("keyboard-selected")

      const answerText = answer.querySelector(".answer-text")?.textContent || "Answer"
      const isInSlot = answer.closest(".ranking-slot")
      const instruction = isInSlot
        ? "Press arrow keys to navigate to a different slot, or Escape to cancel"
        : "Press arrow keys to navigate to a rank slot, then Enter to place"
      this.announceToScreenReader(`${answerText} selected. ${instruction}`)
    }
  }

  clearKeyboardSelection() {
    if (this.selectedAnswer) {
      this.selectedAnswer.setAttribute("aria-selected", "false")
      this.selectedAnswer.classList.remove("keyboard-selected")
      this.selectedAnswer = null
    }
  }

  placeSelectedAnswerInSlot(slot) {
    if (!this.selectedAnswer) return

    const answer = this.selectedAnswer
    const existingAnswer = slot.querySelector(".ranking-answer")

    if (existingAnswer && existingAnswer !== answer) {
      this.swapAnswers(answer, existingAnswer, slot)
    } else if (existingAnswer !== answer) {
      this.performDrop(answer, slot)
    }

    const rank = slot.dataset.rank
    this.announceToScreenReader(`Answer placed in rank ${rank}`)

    this.clearKeyboardSelection()
    this.updateSubmitState()

    // Keep focus on slot for continued navigation
    slot.focus()
  }

  removeAnswerFromSlot(slot) {
    const answer = slot.querySelector(".ranking-answer")
    if (!answer) return

    this.removeFromCurrentSlot(answer)
    this.restoreToInitialOrder(answer)
    this.removeAnswerMedal(answer)
    this.updateSubmitState()

    this.announceToScreenReader(`Answer removed from rank ${slot.dataset.rank}`)
  }

  moveFocusToPreviousAnswer(currentAnswer) {
    const answers = this.getAllFocusableAnswers()
    const currentIndex = answers.indexOf(currentAnswer)
    const prevIndex = currentIndex > 0 ? currentIndex - 1 : answers.length - 1
    answers[prevIndex]?.focus()
  }

  moveFocusToNextAnswer(currentAnswer) {
    const answers = this.getAllFocusableAnswers()
    const currentIndex = answers.indexOf(currentAnswer)
    const nextIndex = currentIndex < answers.length - 1 ? currentIndex + 1 : 0
    answers[nextIndex]?.focus()
  }

  moveFocusToPreviousSlot(currentSlot) {
    const currentIndex = this.slotTargets.indexOf(currentSlot)
    if (currentIndex > 0) {
      this.slotTargets[currentIndex - 1].focus()
    } else {
      // Wrap to answers container
      const answers = this.getAllFocusableAnswers()
      if (answers.length > 0) {
        answers[answers.length - 1].focus()
      }
    }
  }

  moveFocusToNextSlot(currentSlot) {
    const currentIndex = this.slotTargets.indexOf(currentSlot)
    if (currentIndex < this.slotTargets.length - 1) {
      this.slotTargets[currentIndex + 1].focus()
    } else {
      // Wrap to first answer
      const answers = this.getAllFocusableAnswers()
      if (answers.length > 0) {
        answers[0].focus()
      }
    }
  }

  getAllFocusableAnswers() {
    // Get answers in both the container and slots
    return Array.from(this.element.querySelectorAll(".ranking-answer"))
  }

  announceToScreenReader(message) {
    let announcer = document.getElementById("sr-announcer")
    if (!announcer) {
      announcer = document.createElement("div")
      announcer.id = "sr-announcer"
      announcer.setAttribute("role", "status")
      announcer.setAttribute("aria-live", "polite")
      announcer.setAttribute("aria-atomic", "true")
      announcer.className = "sr-only"
      document.body.appendChild(announcer)
    }
    // Clear and set to trigger announcement
    announcer.textContent = ""
    setTimeout(() => {
      announcer.textContent = message
    }, 50)
  }

  trackTap() {
    if (this.hintShown) return
    if (this.inputTargets.some(i => i.value !== "")) return

    const now = Date.now()
    this.tapTimestamps.push(now)
    // Keep only taps within the last 2 seconds
    this.tapTimestamps = this.tapTimestamps.filter(t => now - t < 2000)

    if (this.tapTimestamps.length >= 5) {
      this.hintShown = true
      this.tapTimestamps = []
      if (this.hasHintTextTarget) {
        this.hintTextTarget.classList.add("animate-hint-shake")
        this.hintTextTarget.addEventListener("animationend", () => {
          this.hintTextTarget.classList.remove("animate-hint-shake")
        }, { once: true })
      }
    }
  }

  startTouch(event, answer) {
    // Only initiate drag if touch started on the drag handle
    if (!event.target.closest(".ranking-handle")) {
      this.isDragging = false
      return
    }

    event.preventDefault()
    this.currentDraggingAnswer = answer
    this.isDragging = true
    this.hasMoved = false

    // Prevent page scrolling during drag
    document.body.style.overflow = "hidden"
    document.body.style.touchAction = "none"

    // Store original position
    this.originalParent = answer.parentElement
    this.originalNextSibling = answer.nextElementSibling

    // Store touch position for mobile
    this.touchStartPos = {
      x: event.touches[0].clientX,
      y: event.touches[0].clientY
    }

    // Visual feedback on original
    answer.classList.add("dragging")

    // Create visual clone that follows finger
    this.createTouchClone(answer)

    // Haptic feedback on mobile if available
    if (navigator.vibrate) {
      navigator.vibrate(50)
    }
  }

  createTouchClone(answer) {
    const clone = answer.cloneNode(true)
    clone.classList.remove("dragging")
    clone.classList.add("touch-dragging")
    clone.style.position = "fixed"
    clone.style.zIndex = "9999"
    clone.style.pointerEvents = "none"
    clone.style.width = `${answer.offsetWidth}px`
    clone.style.opacity = "0.9"
    clone.style.transform = "rotate(2deg) scale(1.02)"
    clone.style.boxShadow = "0 8px 24px rgba(0,0,0,0.3)"
    this.applyCloneTruncation(clone)

    // Position clone at the original element's position
    const rect = answer.getBoundingClientRect()
    clone.style.left = `${rect.left}px`
    clone.style.top = `${rect.top}px`

    document.body.appendChild(clone)
    this.touchClone = clone
  }

  applyCloneTruncation(clone) {
    const answerText = clone.querySelector(".answer-text")
    if (answerText) {
      answerText.style.overflow = "hidden"
      answerText.style.textOverflow = "ellipsis"
      answerText.style.whiteSpace = "nowrap"
      answerText.style.display = "block"
    }
  }

  cancelTouch() {
    this.isDragging = false
    this.currentDraggingAnswer = null
    this.touchStartPos = null
    this.currentTouchTarget = null
    this.hasMoved = false
    this.originalParent = null
    this.originalNextSibling = null

    // Restore page scrolling
    document.body.style.overflow = ""
    document.body.style.touchAction = ""

    // Cleanup touch clone
    if (this.touchClone) {
      this.touchClone.remove()
      this.touchClone = null
    }

    // Reset any visual feedback
    this.answerTargets.forEach(answer => {
      answer.classList.remove("dragging")
    })
  }

  onDragEnd(event, answer) {
    this.isDragging = false
    answer.classList.remove("dragging")
    this.slotTargets.forEach(s => s.classList.remove("drag-over"))
    this.currentDraggingAnswer = null

    // Cleanup drag clone
    if (this.dragClone) {
      this.dragClone.remove()
      this.dragClone = null
    }
  }

  onDragOver(event, slot) {
    event.preventDefault()
    if (slot) slot.classList.add("drag-over")
  }

  onDragLeave(event, slot) {
    if (slot) slot.classList.remove("drag-over")
  }

  onDrop(event, slot) {
    event.preventDefault()
    slot.classList.remove("drag-over")

    const answerId = event.dataTransfer.getData("text/plain")

    // Find the answer element
    const answer = this.answerTargets.find(a => a.dataset.answerId === answerId)
    if (!answer) return

    // Check if slot already has an answer - if so, swap them
    const existingAnswer = slot.querySelector(".ranking-answer")
    if (existingAnswer && existingAnswer !== answer) {
      this.swapAnswers(answer, existingAnswer, slot)
    } else {
      this.performDrop(answer, slot)
    }

    this.updateSubmitState()
  }

  onDropToContainer(event) {
    event.preventDefault()

    const answerId = event.dataTransfer.getData("text/plain")
    const answer = this.answerTargets.find(a => a.dataset.answerId === answerId)
    if (!answer) return

    // Check if answer was in a slot (actual unranking action)
    const wasInSlot = answer.closest(".ranking-slot")

    if (wasInSlot) {
      // Moving from slot back to container - restore to original order
      this.removeFromCurrentSlot(answer)
      this.restoreToInitialOrder(answer)
      this.removeAnswerMedal(answer)
    } else {
      // Was already in container - restore to original position
      this.restoreToOriginalPosition(answer)
    }

    this.updateSubmitState()
  }

  restoreToOriginalPosition(answer) {
    if (this.originalParent === this.answersContainerTarget) {
      if (this.originalNextSibling) {
        this.originalParent.insertBefore(answer, this.originalNextSibling)
      } else {
        this.originalParent.appendChild(answer)
      }
    }
  }

  // Restore answer to its original position based on initial order
  restoreToInitialOrder(answer) {
    const answerId = answer.dataset.answerId
    const targetIndex = this.initialAnswerOrder.indexOf(answerId)

    // Get current answers in the container
    const containerAnswers = Array.from(
      this.answersContainerTarget.querySelectorAll(".ranking-answer")
    )

    // Find the right position to insert
    let insertBefore = null
    for (const existing of containerAnswers) {
      const existingIndex = this.initialAnswerOrder.indexOf(existing.dataset.answerId)
      if (existingIndex > targetIndex) {
        insertBefore = existing
        break
      }
    }

    if (insertBefore) {
      this.answersContainerTarget.insertBefore(answer, insertBefore)
    } else {
      this.answersContainerTarget.appendChild(answer)
    }
  }

  removeFromCurrentSlot(answer) {
    const currentSlot = answer.closest(".ranking-slot")
    if (currentSlot) {
      this.clearSlotInput(currentSlot)

      // Restore ranking slot decorations
      const medal = currentSlot.querySelector(".ranking-medal")
      const points = currentSlot.querySelector(".ranking-points")
      const placeholder = currentSlot.querySelector(".ranking-placeholder")
      if (medal) medal.style.display = ""
      if (points) points.style.display = ""
      if (placeholder) placeholder.style.display = "block"

      // Restore border styling
      currentSlot.classList.remove("ranking-slot-filled")
    }
  }

  clearSlotInput(slot) {
    const input = slot.querySelector("input[name^='rankings']")
    if (input) input.value = ""
  }

  updateAnswerMedal(answer, rank) {
    let medalEl = answer.querySelector(".answer-medal")

    if (rank) {
      if (!medalEl) {
        medalEl = document.createElement("span")
        medalEl.className = "answer-medal"
        answer.insertBefore(medalEl, answer.firstChild)
      }
      medalEl.textContent = this.medalsValue[parseInt(rank) - 1]
    }
  }

  removeAnswerMedal(answer) {
    const medalEl = answer.querySelector(".answer-medal")
    if (medalEl) {
      medalEl.remove()
    }
  }

  onTouchMove(event) {
    if (!this.isDragging || !this.currentDraggingAnswer) return

    event.preventDefault()

    const touch = event.touches[0]

    // Track if user has moved enough to distinguish tap vs drag
    if (!this.hasMoved && this.touchStartPos) {
      const dx = touch.clientX - this.touchStartPos.x
      const dy = touch.clientY - this.touchStartPos.y
      if (Math.abs(dx) > 5 || Math.abs(dy) > 5) {
        this.hasMoved = true
      }
    }

    // Move the touch clone to follow finger
    if (this.touchClone) {
      const cloneWidth = this.touchClone.offsetWidth
      const cloneHeight = this.touchClone.offsetHeight
      this.touchClone.style.left = `${touch.clientX - cloneWidth / 2}px`
      this.touchClone.style.top = `${touch.clientY - cloneHeight / 2}px`
    }

    // Hide the clone temporarily to detect element underneath
    if (this.touchClone) this.touchClone.style.display = "none"
    const element = document.elementFromPoint(touch.clientX, touch.clientY)
    if (this.touchClone) this.touchClone.style.display = ""

    // Remove drag-over from all slots
    this.slotTargets.forEach(s => s.classList.remove("drag-over"))

    // Find if we're over a slot
    const slot = element?.closest(".ranking-slot")
    if (slot && this.slotTargets.includes(slot)) {
      slot.classList.add("drag-over")
      this.currentTouchTarget = slot
    } else if (element?.closest(".ranking-answers-scrollable")) {
      this.currentTouchTarget = this.answersContainerTarget
    } else {
      this.currentTouchTarget = null
    }
  }

  onTouchEnd(event) {
    if (!this.isDragging || !this.currentDraggingAnswer) {
      this.cancelTouch()
      return
    }

    event.preventDefault()

    const answer = this.currentDraggingAnswer

    // If user didn't actually move, restore to original position
    if (!this.hasMoved) {
      this.restoreToOriginalPosition(answer)
      this.cleanupTouch(answer)
      return
    }

    // If dropped on a slot
    if (this.currentTouchTarget && this.slotTargets.includes(this.currentTouchTarget)) {
      const slot = this.currentTouchTarget

      // Check if slot already has an answer - if so, swap them
      const existingAnswer = slot.querySelector(".ranking-answer")
      if (existingAnswer && existingAnswer !== answer) {
        this.swapAnswers(answer, existingAnswer, slot)
      } else {
        this.performDrop(answer, slot)
      }
    }
    // If dropped back on answers container
    else if (this.currentTouchTarget === this.answersContainerTarget) {
      const wasInSlot = answer.closest(".ranking-slot")
      if (wasInSlot) {
        this.removeFromCurrentSlot(answer)
        this.restoreToInitialOrder(answer)
        this.removeAnswerMedal(answer)
      } else {
        this.restoreToOriginalPosition(answer)
      }
    }
    // Dropped nowhere - restore to original position
    else {
      this.restoreToOriginalPosition(answer)
    }

    this.cleanupTouch(answer)
  }

  cleanupTouch(answer) {
    // Cleanup touch clone
    if (this.touchClone) {
      this.touchClone.remove()
      this.touchClone = null
    }

    // Cleanup
    this.slotTargets.forEach(s => s.classList.remove("drag-over"))
    answer.classList.remove("dragging")
    this.cancelTouch()
    this.updateSubmitState()
  }

  swapAnswers(draggedAnswer, targetAnswer, targetSlot) {
    // Get the source slot (where dragged answer came from)
    const sourceSlot = draggedAnswer.closest(".ranking-slot")

    // Add swap animation class
    draggedAnswer.classList.add("swapping")
    targetAnswer.classList.add("swapping")

    // Wait for animation to complete
    setTimeout(() => {
      // If dragged answer came from a slot, swap positions
      if (sourceSlot) {
        // Move target answer to source slot
        this.placeAnswerInSlot(targetAnswer, sourceSlot)
      } else {
        // Dragged answer came from container, send target answer back to container
        this.removeFromCurrentSlot(targetAnswer)
        this.restoreToInitialOrder(targetAnswer)
        this.removeAnswerMedal(targetAnswer)
      }

      // Move dragged answer to target slot
      this.placeAnswerInSlot(draggedAnswer, targetSlot)

      // Remove animation classes
      draggedAnswer.classList.remove("swapping")
      targetAnswer.classList.remove("swapping")
    }, 150)
  }

  placeAnswerInSlot(answer, slot) {
    // Hide all ranking slot decorations
    const medal = slot.querySelector(".ranking-medal")
    const points = slot.querySelector(".ranking-points")
    const placeholder = slot.querySelector(".ranking-placeholder")
    if (medal) medal.style.display = "none"
    if (points) points.style.display = "none"
    if (placeholder) placeholder.style.display = "none"

    // Remove border styling
    slot.classList.add("ranking-slot-filled")

    // Place answer in slot
    slot.appendChild(answer)

    // Update hidden input
    const input = slot.querySelector("input[name^='rankings']")
    if (input) input.value = answer.dataset.answerId

    // Add medal to answer
    const rank = slot.dataset.rank
    this.updateAnswerMedal(answer, rank)
  }

  performDrop(answer, slot) {
    // Remove from current location
    this.removeFromCurrentSlot(answer)

    // If slot already has an answer, move it back to original position
    const existingAnswer = slot.querySelector(".ranking-answer")
    if (existingAnswer) {
      this.restoreToInitialOrder(existingAnswer)
      this.clearSlotInput(slot)
      this.removeAnswerMedal(existingAnswer)
    }

    // Place answer in slot using shared method
    this.placeAnswerInSlot(answer, slot)
  }

  updateSubmitState() {
    const filledSlots = this.inputTargets.filter(i => i.value !== "").length
    const requiredSlots = Math.min(this.maxSlotsValue, this.answerTargets.length)

    // Require all available slots to be filled
    this.submitTarget.disabled = filledSlots < requiredSlots
  }
}

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["slot", "answer", "answersContainer", "input", "submit", "form", "placeholder"]
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

    // Store initial order of answers for restoring positions
    this.initialAnswerOrder = this.answerTargets.map(a => a.dataset.answerId)

    this.setupDragHandlers()
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
  }

  startTouch(event, answer) {
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

    // Check if user has moved enough to consider it a drag
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

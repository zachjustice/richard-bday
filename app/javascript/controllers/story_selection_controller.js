import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "searchInput",
    "storySection",
    "storySectionContent",
    "storySectionSummary",
    "storyItem",
    "votingSection",
    "votingSectionContent",
    "votingSectionSummary",
    "noResults",
    "selectedStoryName",
    "selectedVotingStyle",
    "storyChevron",
    "votingChevron"
  ]

  connect() {
    this.storySectionExpanded = true
    this.votingSectionExpanded = false
    this.filterTimeout = null
    this._transitionHandlers = new Map()
    this.initializeVotingStyleSummary()
  }

  disconnect() {
    clearTimeout(this.filterTimeout)
    this._transitionHandlers.forEach((handler, el) => el.removeEventListener('transitionend', handler))
    this._transitionHandlers.clear()
  }

  initializeVotingStyleSummary() {
    const checkedInput = this.element.querySelector('input[name="room[voting_style]"]:checked')
    if (checkedInput) {
      const label = checkedInput.closest('label')
      const styleName = label?.dataset.votingStyleName || ''
      this.selectedVotingStyleTarget.textContent = styleName
    }
  }

  filterStories(event) {
    clearTimeout(this.filterTimeout)
    this.filterTimeout = setTimeout(() => {
      this.performFilter(event.target.value)
    }, 150)
  }

  performFilter(value) {
    const query = value.toLowerCase().trim()

    let visibleCount = 0
    this.storyItemTargets.forEach(item => {
      const title = (item.dataset.storyTitle || '').toLowerCase()
      const author = (item.dataset.storyAuthor || '').toLowerCase()
      const genres = (item.dataset.storyGenres || '').toLowerCase()

      const matches = !query ||
        title.includes(query) ||
        author.includes(query) ||
        genres.includes(query)

      item.classList.toggle('hidden', !matches)
      if (matches) visibleCount++
    })

    this.noResultsTarget.classList.toggle('hidden', visibleCount > 0)
  }

  selectStory(event) {
    const input = event.target
    const label = input.closest('label')
    const title = label.dataset.storyTitle || ''
    const author = label.dataset.storyAuthor || ''

    if (input.dataset.wasChecked === 'true') {
      this._setState({ story: false, voting: this.votingSectionExpanded })
      return
    }

    this.element.querySelectorAll('input[name="story"]').forEach(el => {
      el.dataset.wasChecked = 'false'
    })
    input.dataset.wasChecked = 'true'

    const summaryText = author ? `${title} by ${author}` : title
    this.selectedStoryNameTarget.textContent = summaryText

    this._setState({ story: false, voting: true })
  }

  selectVotingStyle(event) {
    const input = event.target
    const label = input.closest('label')
    const styleName = label.dataset.votingStyleName || ''

    if (input.dataset.wasChecked === 'true') {
      this._setState({ story: this.storySectionExpanded, voting: false })
      return
    }

    this.element.querySelectorAll('input[name="room[voting_style]"]').forEach(el => {
      el.dataset.wasChecked = 'false'
    })
    input.dataset.wasChecked = 'true'

    this.selectedVotingStyleTarget.textContent = styleName
    this._setState({ story: this.storySectionExpanded, voting: false })
  }

  toggleStorySection() {
    if (this.storySectionExpanded) {
      this._setState({ story: false, voting: this.votingSectionExpanded })
    } else {
      this._setState({ story: true, voting: false })
    }
  }

  toggleVotingSection() {
    if (this.votingSectionExpanded) {
      this._setState({ story: this.storySectionExpanded, voting: false })
    } else {
      this._setState({ story: false, voting: true })
    }
  }

  expandStorySection() { this._setState({ story: true, voting: false }) }
  collapseStorySection() { this._setState({ story: false, voting: this.votingSectionExpanded }) }
  expandVotingSection() { this._setState({ story: false, voting: true }) }
  collapseVotingSection() { this._setState({ story: this.storySectionExpanded, voting: false }) }

  _storyParts() {
    return {
      section: this.storySectionTarget,
      content: this.storySectionContentTarget,
      summary: this.storySectionSummaryTarget,
      chevron: this.storyChevronTarget,
    }
  }

  _votingParts() {
    return {
      section: this.votingSectionTarget,
      content: this.votingSectionContentTarget,
      summary: this.votingSectionSummaryTarget,
      chevron: this.votingChevronTarget,
    }
  }

  _setState({ story, voting }) {
    let opening = null
    let closing = null

    if (this.storySectionExpanded !== story) {
      if (story) opening = this._storyParts()
      else closing = this._storyParts()
    }

    if (this.votingSectionExpanded !== voting) {
      if (voting) opening = this._votingParts()
      else closing = this._votingParts()
    }

    this.storySectionExpanded = story
    this.votingSectionExpanded = voting

    if (!opening && !closing) return

    this._animateSwap({ opening, closing })
  }

  // Coordinated open/close. Uses a FLIP-style pass so the opening section's animation
  // target reflects the layout AFTER the closing section has fully collapsed — otherwise
  // a flex-allocated opening would jump from the mid-collapse measurement to its final size
  // when the inline max-height is cleared.
  _animateSwap({ opening, closing }) {
    const reducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches

    this._cancelTransition(opening?.content)
    this._cancelTransition(closing?.content)

    const closingStart = closing ? closing.content.offsetHeight : 0
    let openingTarget = 0

    if (opening) {
      opening.content.style.transition = 'none'
      if (closing) closing.content.style.transition = 'none'

      // Apply final layout state to measure opening's settled height
      if (closing) {
        closing.section.classList.remove('accordion-section-expanded')
        closing.content.style.maxHeight = '0px'
      }
      opening.section.classList.add('accordion-section-expanded')
      opening.content.classList.remove('accordion-content-collapsed')
      opening.content.style.maxHeight = ''

      void this.element.offsetHeight
      openingTarget = opening.content.offsetHeight

      // Restore initial state so the animation can replay from the visible starting point
      if (closing) {
        closing.section.classList.add('accordion-section-expanded')
        closing.content.style.maxHeight = `${closingStart}px`
      }
      opening.section.classList.remove('accordion-section-expanded')
      opening.content.classList.add('accordion-content-collapsed')
      opening.content.style.maxHeight = ''

      void this.element.offsetHeight

      opening.content.style.transition = ''
      if (closing) closing.content.style.transition = ''
    }

    // Apply the real state change, pinning content heights so the transition starts cleanly
    if (closing) {
      closing.content.style.maxHeight = `${closingStart}px`
      closing.section.classList.remove('accordion-section-expanded')
      closing.summary.classList.remove('hidden')
      closing.chevron.classList.remove('accordion-chevron-expanded')
    }
    if (opening) {
      opening.content.style.maxHeight = '0px'
      opening.section.classList.add('accordion-section-expanded')
      opening.content.classList.remove('accordion-content-collapsed')
      opening.summary.classList.add('hidden')
      opening.chevron.classList.add('accordion-chevron-expanded')
    }

    void this.element.offsetHeight

    if (reducedMotion) {
      if (closing) {
        closing.content.classList.add('accordion-content-collapsed')
        closing.content.style.maxHeight = ''
      }
      if (opening) {
        opening.content.style.maxHeight = ''
      }
      return
    }

    if (closing) {
      closing.content.style.maxHeight = '0px'
      this._onTransitionEnd(closing.content, () => {
        closing.content.classList.add('accordion-content-collapsed')
        closing.content.style.maxHeight = ''
      })
    }
    if (opening) {
      opening.content.style.maxHeight = `${openingTarget}px`
      this._onTransitionEnd(opening.content, () => {
        opening.content.style.maxHeight = ''
      })
    }
  }

  _onTransitionEnd(el, fn) {
    this._cancelTransition(el)
    const handler = (event) => {
      if (event.propertyName !== 'max-height' || event.target !== el) return
      el.removeEventListener('transitionend', handler)
      this._transitionHandlers.delete(el)
      fn()
    }
    this._transitionHandlers.set(el, handler)
    el.addEventListener('transitionend', handler)
  }

  _cancelTransition(el) {
    if (!el) return
    const handler = this._transitionHandlers.get(el)
    if (handler) {
      el.removeEventListener('transitionend', handler)
      this._transitionHandlers.delete(el)
    }
  }
}

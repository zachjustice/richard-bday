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
  }

  filterStories(event) {
    const query = event.target.value.toLowerCase().trim()

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
    const label = event.target.closest('label')
    const title = label.dataset.storyTitle || ''
    const author = label.dataset.storyAuthor || ''

    const summaryText = author ? `${title} by ${author}` : title
    this.selectedStoryNameTarget.textContent = summaryText

    this.collapseStorySection()
    this.expandVotingSection()
  }

  selectVotingStyle(event) {
    const label = event.target.closest('label')
    const styleName = label.dataset.votingStyleName || ''

    this.selectedVotingStyleTarget.textContent = styleName
    this.collapseVotingSection()
  }

  toggleStorySection() {
    if (this.storySectionExpanded) {
      this.collapseStorySection()
    } else {
      this.expandStorySection()
    }
  }

  toggleVotingSection() {
    if (this.votingSectionExpanded) {
      this.collapseVotingSection()
    } else {
      this.expandVotingSection()
    }
  }

  expandStorySection() {
    this.storySectionExpanded = true
    this.storySectionContentTarget.classList.remove('accordion-content-collapsed')
    this.storySectionSummaryTarget.classList.add('hidden')
    this.storyChevronTarget.classList.add('accordion-chevron-expanded')
  }

  collapseStorySection() {
    this.storySectionExpanded = false
    this.storySectionContentTarget.classList.add('accordion-content-collapsed')
    this.storySectionSummaryTarget.classList.remove('hidden')
    this.storyChevronTarget.classList.remove('accordion-chevron-expanded')
  }

  expandVotingSection() {
    this.votingSectionExpanded = true
    this.votingSectionContentTarget.classList.remove('accordion-content-collapsed')
    this.votingSectionSummaryTarget.classList.add('hidden')
    this.votingChevronTarget.classList.add('accordion-chevron-expanded')
  }

  collapseVotingSection() {
    this.votingSectionExpanded = false
    this.votingSectionContentTarget.classList.add('accordion-content-collapsed')
    this.votingSectionSummaryTarget.classList.remove('hidden')
    this.votingChevronTarget.classList.remove('accordion-chevron-expanded')
  }
}

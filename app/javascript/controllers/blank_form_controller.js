import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "tagsInput",
    "promptsList",
    "promptCount",
    "newPromptsList",
    "newPromptField",
    "newPromptInput",
    "submitButton",
    "validationHint"
  ]

  static values = {
    storyId: Number,
    blankId: Number,
    editMode: Boolean,
    existingPromptIds: Array
  }

  connect() {
    this.promptsCache = null
    this.filterDebounceTimer = null

    // If edit mode and tags exist, trigger initial filter
    if (this.editModeValue && this.tagsInputTarget.value.trim().length > 0) {
      this.filterPrompts()
    }
  }

  filterPrompts(event) {
    clearTimeout(this.filterDebounceTimer)

    this.filterDebounceTimer = setTimeout(() => {
      const tags = this.tagsInputTarget.value
        .split(',')
        .map(t => t.trim().toLowerCase())
        .filter(t => t.length > 0)

      if (tags.length === 0) {
        this.showEmptyPromptsMessage()
        return
      }

      this.fetchAndFilterPrompts(tags)
    }, 300)
  }

  async fetchAndFilterPrompts(tags) {
    try {
      if (!this.promptsCache) {
        const response = await fetch(`/stories/${this.storyIdValue}/prompts`)
        this.promptsCache = await response.json()
      }

      let matchingPrompts = this.promptsCache.filter(prompt => {
        const promptTags = prompt.tags.split(',').map(t => t.trim().toLowerCase())
        return promptTags.some(pt => tags.includes(pt))
      })

      matchingPrompts = matchingPrompts.sort((a, b)=> {
        return b.tags.split(',').filter(t => tags.includes(t)).length 
        - a.tags.split(',').filter(t => tags.includes(t)).length;
      })

      this.renderPromptsList(matchingPrompts)
      this.updatePromptCount(matchingPrompts.length)
    } catch (error) {
      console.error('Failed to fetch prompts:', error)
      this.showErrorMessage()
    }
  }

  renderPromptsList(prompts) {
    if (prompts.length === 0) {
      this.promptsListTarget.innerHTML =
        '<p class="text-secondary">No matching prompts found. Create new ones below!</p>'
      return
    }

    const html = prompts.map(prompt => this.promptCheckboxTemplate(prompt)).join('')
    this.promptsListTarget.innerHTML = html

    // Pre-check existing prompts if in edit mode
    if (this.editModeValue && this.hasExistingPromptIdsValue) {
      this.preCheckExistingPrompts()
    }
  }

  preCheckExistingPrompts() {
    const existingIds = this.existingPromptIdsValue || []
    existingIds.forEach(id => {
      const checkbox = this.element.querySelector(
        `input[name="blank[existing_prompt_ids][]"][value="${id}"]`
      )
      if (checkbox) {
        checkbox.checked = true
      }
    })
    this.validateSelection()
  }

  promptCheckboxTemplate(prompt) {
    const tags = prompt.tags.split(',').map(t =>
      `<span class="tag">${t.trim()}</span>`
    ).join('')

    const usageText = prompt.usage_count ? ` (Used in ${prompt.usage_count} ${prompt.usage_count === 1 ? 'story' : 'stories'})` : ''

    return `
      <label class="prompt-checkbox">
        <input type="checkbox"
               name="blank[existing_prompt_ids][]"
               value="${prompt.id}"
               class="form-checkbox"
               data-action="change->blank-form#validateSelection">
        <span class="prompt-checkbox-label">
          ${this.escapeHtml(prompt.description)}${usageText}
          <span class="prompt-checkbox-tags">${tags}</span>
        </span>
      </label>
    `
  }

  escapeHtml(text) {
    const div = document.createElement('div')
    div.textContent = text
    return div.innerHTML
  }

  updatePromptCount(count) {
    this.promptCountTarget.textContent = `(${count} matching)`
  }

  showEmptyPromptsMessage() {
    this.promptsListTarget.innerHTML =
      '<p class="text-secondary">Enter tags above to see matching prompts</p>'
    this.updatePromptCount(0)
  }

  addNewPromptField(event) {
    event.preventDefault()

    const template = document.createElement('div')
    template.className = 'new-prompt-field'
    template.dataset.blankFormTarget = 'newPromptField'
    template.innerHTML = `
      <textarea name="blank[new_prompts][][description]"
                class="story-form-textarea w-full border-2 border-ink"
                rows="2"
                placeholder="What is a funny animal?"
                data-blank-form-target="newPromptInput"
                data-action="input->blank-form#validateSelection"></textarea>
      <button type="button"
              class="btn-icon remove-prompt"
              data-action="click->blank-form#removeNewPromptField">
        🗑️
      </button>
    `

    this.newPromptsListTarget.appendChild(template)
    template.querySelector('textarea').focus()
    this.validateSelection()
  }

  removeNewPromptField(event) {
    event.preventDefault()
    const field = event.target.closest('.new-prompt-field')
    field.remove()
    this.validateSelection()
  }

  validateSelection() {
    const hasExistingSelected = this.element.querySelectorAll(
      'input[name="blank[existing_prompt_ids][]"]:checked'
    ).length > 0
    const hasNewPrompts = Array.from(this.element.querySelectorAll('.form-textarea')).some(input => input.value.trim().length > 0)

    const isValid = hasExistingSelected || hasNewPrompts

    this.submitButtonTarget.disabled = !isValid

    if (isValid) {
      this.validationHintTarget.style.display = 'none'
    } else {
      this.validationHintTarget.style.display = 'block'
    }

    return isValid
  }

  showErrorMessage() {
    this.promptsListTarget.innerHTML =
      '<p class="text-error">Failed to load prompts. Please refresh the page.</p>'
  }
}

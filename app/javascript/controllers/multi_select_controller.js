import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container", "pills", "input", "dropdown", "options"]
  static values = { options: Array, fieldName: String, emptyMessage: String }

  connect() {
    this.selectedIds = new Set(
      Array.from(this.pillsTarget.querySelectorAll('[data-id]'))
        .map(el => parseInt(el.dataset.id))
    )
    this.highlightedIndex = -1
    this.clickOutsideHandler = this.handleClickOutside.bind(this)
  }

  disconnect() {
    document.removeEventListener('click', this.clickOutsideHandler)
  }

  onFocus() {
    this.showDropdown()
    this.filterOptions('')
  }

  onInput(event) {
    const query = event.target.value.toLowerCase().trim()
    this.filterOptions(query)
    this.showDropdown()
  }

  onKeydown(event) {
    const options = this.optionsTarget.querySelectorAll('.multi-select-option:not(.hidden)')

    switch(event.key) {
      case 'ArrowDown':
        event.preventDefault()
        this.highlightedIndex = Math.min(this.highlightedIndex + 1, options.length - 1)
        this.updateHighlight(options)
        break
      case 'ArrowUp':
        event.preventDefault()
        this.highlightedIndex = Math.max(this.highlightedIndex - 1, 0)
        this.updateHighlight(options)
        break
      case 'Enter':
        event.preventDefault()
        if (this.highlightedIndex >= 0 && options[this.highlightedIndex]) {
          this.selectOption({ currentTarget: options[this.highlightedIndex] })
        }
        break
      case 'Escape':
        this.hideDropdown()
        this.inputTarget.blur()
        break
      case 'Backspace':
        if (event.target.value === '' && this.selectedIds.size > 0) {
          const pills = this.pillsTarget.querySelectorAll('.multi-select-pill')
          if (pills.length > 0) {
            const lastPill = pills[pills.length - 1]
            this.removePillById(parseInt(lastPill.dataset.id))
          }
        }
        break
    }
  }

  filterOptions(query) {
    const available = this.optionsValue.filter(opt => !this.selectedIds.has(opt.id))

    const filtered = query
      ? available.filter(opt => opt.name.toLowerCase().includes(query))
      : available

    this.renderOptions(filtered)
    this.highlightedIndex = filtered.length > 0 ? 0 : -1
    this.updateHighlight(this.optionsTarget.querySelectorAll('.multi-select-option'))
  }

  renderOptions(options) {
    if (options.length === 0) {
      const emptyMessage = this.hasEmptyMessageValue ? this.emptyMessageValue : "No options available"
      this.optionsTarget.innerHTML = `
        <div class="multi-select-empty">${this.escapeHtml(emptyMessage)}</div>
      `
      return
    }

    this.optionsTarget.innerHTML = options.map((opt, i) => `
      <button type="button"
              class="multi-select-option ${i === 0 ? 'highlighted' : ''}"
              data-action="click->multi-select#selectOption"
              data-id="${opt.id}"
              data-name="${this.escapeHtml(opt.name)}">
        ${this.escapeHtml(opt.name)}
      </button>
    `).join('')
  }

  selectOption(event) {
    const id = parseInt(event.currentTarget.dataset.id)
    const name = event.currentTarget.dataset.name

    if (this.selectedIds.has(id)) return

    this.selectedIds.add(id)
    this.addPill(id, name)
    this.inputTarget.value = ''
    this.filterOptions('')
    this.inputTarget.focus()
  }

  addPill(id, name) {
    const pill = document.createElement('span')
    pill.className = 'multi-select-pill animate-pop'
    pill.dataset.id = id
    pill.innerHTML = `
      ${this.escapeHtml(name)}
      <button type="button"
              class="multi-select-pill-remove"
              data-action="click->multi-select#removePill"
              data-id="${id}"
              aria-label="Remove ${this.escapeHtml(name)}">
        <svg width="12" height="12" viewBox="0 0 12 12" fill="currentColor">
          <path d="M9.5 3.2L8.8 2.5 6 5.3 3.2 2.5 2.5 3.2 5.3 6 2.5 8.8l.7.7L6 6.7l2.8 2.8.7-.7L6.7 6z"/>
        </svg>
      </button>
      <input type="hidden" name="${this.fieldNameValue}" value="${id}">
    `
    this.pillsTarget.appendChild(pill)
  }

  removePill(event) {
    event.stopPropagation()
    const id = parseInt(event.currentTarget.dataset.id)
    this.removePillById(id)
  }

  removePillById(id) {
    this.selectedIds.delete(id)
    const pill = this.pillsTarget.querySelector(`[data-id="${id}"]`)
    if (pill) {
      pill.classList.add('animate-shrink')
      setTimeout(() => pill.remove(), 150)
    }
    this.filterOptions(this.inputTarget.value)
  }

  showDropdown() {
    this.dropdownTarget.classList.remove('hidden')
    document.addEventListener('click', this.clickOutsideHandler)
  }

  hideDropdown() {
    this.dropdownTarget.classList.add('hidden')
    document.removeEventListener('click', this.clickOutsideHandler)
    this.highlightedIndex = -1
  }

  handleClickOutside(event) {
    if (!this.element.contains(event.target)) {
      this.hideDropdown()
    }
  }

  updateHighlight(options) {
    options.forEach((opt, i) => {
      opt.classList.toggle('highlighted', i === this.highlightedIndex)
    })
    if (this.highlightedIndex >= 0 && options[this.highlightedIndex]) {
      options[this.highlightedIndex].scrollIntoView({ block: 'nearest' })
    }
  }

  escapeHtml(text) {
    const div = document.createElement('div')
    div.textContent = text
    return div.innerHTML
  }
}

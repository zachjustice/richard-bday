// app/javascript/controllers/story_editor_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["text"]

  highlightBlanks() {
    // Optional: Add visual feedback for blanks in the textarea
    const text = this.textTarget.value
    const blanks = text.match(/\{\d+\}/g) || []
    console.log('Found blanks:', blanks)
  }

  insertBlank(event) {
    const blankId = event.params.id
    const textarea = this.textTarget
    const cursorPos = textarea.selectionStart
    const textBefore = textarea.value.substring(0, cursorPos)
    const textAfter = textarea.value.substring(cursorPos)

    textarea.value = textBefore + `{${blankId}}` + textAfter
    textarea.focus()
    textarea.selectionStart = textarea.selectionEnd = cursorPos + `{${blankId}}`.length

    this.highlightBlanks()
  }
}
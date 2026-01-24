import { Controller } from "@hotwired/stimulus";
import html2canvas from "html2canvas";

export default class extends Controller {
  static targets = ["exportContainer", "shareButton"]

  connect() {
    if (typeof html2canvas === 'undefined') {
      console.error('html2canvas library not loaded')
    }
  }

  async share(event) {
    event.preventDefault()

    const button = this.hasShareButtonTarget ? this.shareButtonTarget : event.currentTarget
    const originalText = button.innerHTML
    button.innerHTML = 'Generating...'
    button.disabled = true

    try {
      // Position off-screen instead of removing hidden class
      this.exportContainerTarget.style.position = 'absolute'
      this.exportContainerTarget.style.left = '-9999px'
      this.exportContainerTarget.style.top = '0'
      this.exportContainerTarget.classList.remove('hidden')

      const canvas = await html2canvas(this.exportContainerTarget, {
        backgroundColor: '#FFFFFF',
        scale: 2,
        logging: false,
        useCORS: true
      })

      // Hide again
      this.exportContainerTarget.classList.add('hidden')
      this.exportContainerTarget.style.position = ''
      this.exportContainerTarget.style.left = ''
      this.exportContainerTarget.style.top = ''

      canvas.toBlob((blob) => {
        const url = URL.createObjectURL(blob)
        const link = document.createElement('a')
        const timestamp = new Date().toISOString().slice(0, 10)
        link.download = `blanksies-story-${timestamp}.png`
        link.href = url
        link.click()
        URL.revokeObjectURL(url)

        button.innerHTML = '✓ Downloaded!'
        setTimeout(() => {
          button.innerHTML = originalText
          button.disabled = false
        }, 2000)
      })

    } catch (error) {
      console.error('Failed to generate image:', error)
      this.exportContainerTarget.classList.add('hidden')
      button.innerHTML = '✗ Failed'
      setTimeout(() => {
        button.innerHTML = originalText
        button.disabled = false
      }, 2000)
    }
  }
}

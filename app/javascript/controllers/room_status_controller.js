import { Controller } from "@hotwired/stimulus"
import { Byte, Encoder } from '@nuintun/qrcode';

export default class extends Controller {
  connect() {
    this.generateQrCode()

    // Watch for QR code element being added (e.g., when waiting room re-renders via Turbo Streams)
    this.observer = new MutationObserver((mutations) => {
      for (const mutation of mutations) {
        for (const node of mutation.addedNodes) {
          if (node.nodeType === Node.ELEMENT_NODE) {
            if (node.id === 'qr-code' || node.querySelector?.('#qr-code')) {
              this.generateQrCode()
            }
          }
        }
      }
    })

    this.observer.observe(this.element, { childList: true, subtree: true })
  }

  disconnect() {
    this.observer?.disconnect()
  }

  generateQrCode() {
    const qrElement = document.getElementById('qr-code')
    // Use getAttribute to get the literal attribute value, not the resolved URL
    if (!qrElement || qrElement.getAttribute('src')) return

    const encoder = new Encoder({ level: 'H' });
    const roomCode = $('meta[name=room]').attr('code')

    const qrcode = encoder.encode(
      new Byte(`${window.location.origin}/session/new?code=${roomCode}`),
    );

    qrElement.src = qrcode.toDataURL(8, {
      margin: 0,
      background: [255, 255, 255]
    });
  }
}

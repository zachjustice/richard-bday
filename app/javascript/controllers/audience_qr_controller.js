import { Controller } from "@hotwired/stimulus"
import { Byte, Encoder } from "@nuintun/qrcode"

export default class extends Controller {
  static values = { roomCode: String }
  static targets = ["image"]

  connect() {
    this.generateQrCode()
  }

  generateQrCode() {
    if (!this.hasImageTarget || this.imageTarget.getAttribute("src")) return

    const encoder = new Encoder({ level: "H" })
    const qrcode = encoder.encode(
      new Byte(`${window.location.origin}/session/new?code=${this.roomCodeValue}`)
    )
    this.imageTarget.src = qrcode.toDataURL(4, { margin: 0, background: [255, 255, 255] })
  }
}

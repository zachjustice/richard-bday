import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { roomCode: String }
  static targets = ["image"]

  connect() {
    if (this.#isDismissed()) {
      this.element.style.display = "none"
      window.dispatchEvent(new CustomEvent("audience-qr-dismissed"))
      return
    }
    this.generateQrCode()
  }

  async generateQrCode() {
    if (!this.hasImageTarget || this.imageTarget.getAttribute("src")) return

    const { Byte, Encoder } = await import("@nuintun/qrcode")
    const encoder = new Encoder({ level: "H" })
    const qrcode = encoder.encode(
      new Byte(`${window.location.origin}/${this.roomCodeValue}`)
    )
    this.imageTarget.src = qrcode.toDataURL(4, { margin: 0, background: [255, 255, 255] })
  }

  dismiss() {
    sessionStorage.setItem(this.#storageKey(), "1")
    this.element.style.display = "none"
    window.dispatchEvent(new CustomEvent("audience-qr-dismissed"))
  }

  restore() {
    sessionStorage.removeItem(this.#storageKey())
    this.element.style.display = ""
    window.dispatchEvent(new CustomEvent("audience-qr-restored"))
    this.generateQrCode()
  }

  #storageKey() {
    return `audience_qr_dismissed_${this.roomCodeValue}`
  }

  #isDismissed() {
    return sessionStorage.getItem(this.#storageKey()) === "1"
  }
}

import { Controller } from "@hotwired/stimulus"
import html2canvas from "html2canvas"
import { discordActivity } from "discord/sdk"

export default class extends Controller {
  static targets = ["exportContainer", "shareButton"]
  static values = { uploadUrl: String, message: String }

  async share(event) {
    event.preventDefault()

    const button = this.hasShareButtonTarget ? this.shareButtonTarget : event.currentTarget
    const originalHTML = button.innerHTML
    button.disabled = true

    try {
      // 1. Generate image
      button.innerHTML = "Generating..."
      this.exportContainerTarget.style.position = "absolute"
      this.exportContainerTarget.style.left = "-9999px"
      this.exportContainerTarget.style.top = "0"
      this.exportContainerTarget.classList.remove("hidden")

      const canvas = await html2canvas(this.exportContainerTarget, {
        backgroundColor: "#FFFFFF",
        scale: 2,
        logging: false,
        useCORS: true
      })

      this.exportContainerTarget.classList.add("hidden")
      this.exportContainerTarget.style.position = ""
      this.exportContainerTarget.style.left = ""
      this.exportContainerTarget.style.top = ""

      // 2. Upload image
      button.innerHTML = "Uploading..."
      const blob = await new Promise((resolve) => canvas.toBlob(resolve, "image/png"))
      const formData = new FormData()
      formData.append("image", blob, "story.png")

      const response = await fetch(this.uploadUrlValue, {
        method: "POST",
        body: formData
      })

      if (!response.ok) throw new Error("Upload failed")

      const { image_url } = await response.json()

      // 3. Try openShareMomentDialog
      button.innerHTML = "Sharing..."
      try {
        await discordActivity.sdk.commands.openShareMomentDialog({ mediaUrl: image_url })
        button.innerHTML = "Shared!"
      } catch (dialogError) {
        console.warn("openShareMomentDialog failed, falling back to shareLink:", dialogError)
        await discordActivity.sdk.commands.shareLink({ message: this.messageValue })
        button.innerHTML = "Shared!"
      }
    } catch (error) {
      console.error("Discord image share failed:", error)
      // Final fallback: just share text link
      try {
        await discordActivity.sdk.commands.shareLink({ message: this.messageValue })
        button.innerHTML = "Shared!"
      } catch {
        button.innerHTML = "Failed"
      }
    }

    setTimeout(() => {
      button.innerHTML = originalHTML
      button.disabled = false
    }, 2000)
  }
}

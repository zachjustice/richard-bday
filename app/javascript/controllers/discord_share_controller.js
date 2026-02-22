import { Controller } from "@hotwired/stimulus"
import { discordActivity } from "discord/sdk"

export default class extends Controller {
  static values = { message: String }

  async share(event) {
    const button = event.currentTarget
    const originalHTML = button.innerHTML
    button.disabled = true

    try {
      const { success } = await discordActivity.sdk.commands.shareLink({
        message: this.messageValue
      })

      if (success) {
        button.innerHTML = "Shared!"
        setTimeout(() => {
          button.innerHTML = originalHTML
          button.disabled = false
        }, 2000)
      } else {
        button.innerHTML = originalHTML
        button.disabled = false
      }
    } catch (error) {
      console.error("Discord shareLink failed:", error)
      button.innerHTML = "Failed"
      setTimeout(() => {
        button.innerHTML = originalHTML
        button.disabled = false
      }, 2000)
    }
  }
}

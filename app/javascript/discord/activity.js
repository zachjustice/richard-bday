import { discordActivity } from "discord/sdk"
import { setupDiscordFetch, setupDiscordTurbo } from "discord/fetch"
import { createDiscordCable } from "discord/cable"
import { patchUrlMappings } from "@discord/embedded-app-sdk"
import { adapters } from "@rails/actioncable"

async function initializeDiscordActivity() {
  const clientIdMeta = document.querySelector('meta[name="discord-client-id"]')
  if (!clientIdMeta) return

  const clientId = clientIdMeta.content
  const loadingEl = document.getElementById("discord-loading")
  const errorEl = document.getElementById("discord-error")

  try {
    await discordActivity.initialize(clientId)
    const auth = await discordActivity.authenticate()

    // Patch WebSocket/fetch/XHR to route through Discord's proxy so connections
    // comply with the iframe CSP (which only allows *.discordsays.com).
    const cableUrl = discordActivity.getCableUrl()
    if (cableUrl) {
      const target = new URL(cableUrl).host
      patchUrlMappings([{ prefix: '/', target: target }])
      // ActionCable captures WebSocket at module load time, before patchUrlMappings
      // runs. Update its reference so it uses Discord's proxy-aware WebSocket.
      adapters.WebSocket = window.WebSocket
    }

    setupDiscordFetch()
    setupDiscordTurbo()

    // Replace default ActionCable consumer with token-based one
    const { Turbo } = await import("@hotwired/turbo-rails")
    window.discordCable = await createDiscordCable()

    if (loadingEl) loadingEl.classList.add("hidden")

    // Navigate to the player lobby
    Turbo.visit(`/rooms`)
  } catch (error) {
    console.error("Discord Activity initialization failed:", error)
    if (loadingEl) loadingEl.classList.add("hidden")
    if (errorEl) {
      errorEl.classList.remove("hidden")
      const msgEl = errorEl.querySelector("#discord-error-message")
      if (msgEl) msgEl.textContent = "Failed to connect to Discord. Please try again."
    }
  }
}

if (document.readyState === "loading") {
  document.addEventListener("DOMContentLoaded", initializeDiscordActivity)
} else {
  initializeDiscordActivity()
}

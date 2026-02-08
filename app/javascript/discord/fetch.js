import { discordActivity } from "discord/sdk"

function isSameOrigin(url) {
  try {
    if (url instanceof Request) url = url.url
    if (typeof url === "string" && !url.startsWith("http")) return true
    const parsed = new URL(url, window.location.origin)
    return parsed.origin === window.location.origin
  } catch {
    return true
  }
}

// Inject Authorization header into same-origin fetch requests for Discord context
export function setupDiscordFetch() {
  const originalFetch = window.fetch

  window.fetch = function(url, options = {}) {
    const token = discordActivity.getAuthToken()
    if (token && isSameOrigin(url)) {
      options.headers = options.headers || {}
      if (typeof options.headers.set === "function") {
        options.headers.set("Authorization", `Bearer ${token}`)
      } else {
        options.headers["Authorization"] = `Bearer ${token}`
      }
    }
    return originalFetch.call(window, url, options)
  }
}

// Inject Authorization header into Turbo fetch requests
export function setupDiscordTurbo() {
  document.addEventListener("turbo:before-fetch-request", (event) => {
    const token = discordActivity.getAuthToken()
    if (token) {
      event.detail.fetchOptions.headers["Authorization"] = `Bearer ${token}`
    }
  })
}

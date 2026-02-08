import { DiscordSDK } from "@discord/embedded-app-sdk"

class DiscordActivityManager {
  constructor() {
    this.sdk = null
    this.auth = null
    this.ready = false
  }

  async initialize(clientId) {
    this.sdk = new DiscordSDK(clientId)
    await this.sdk.ready()
    this.ready = true
    return this
  }

  async authenticate() {
    const { code } = await this.sdk.commands.authorize({
      client_id: this.sdk.clientId,
      response_type: "code",
      state: "",
      prompt: "none",
      scope: ["identify"]
    })

    const response = await fetch("/discord/auth/callback", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        code: code,
        instance_id: this.sdk.instanceId,
        channel_id: this.sdk.channelId
      })
    })

    if (!response.ok) {
      throw new Error("Authentication failed")
    }

    const data = await response.json()

    await this.sdk.commands.authenticate({
      access_token: data.access_token
    })

    this.auth = data
    return data
  }

  async getCableToken() {
    const response = await fetch("/cable/auth", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Authorization": `Bearer ${this.auth.token}`
      }
    })

    const data = await response.json()
    return data.cable_token
  }

  getAuthToken() {
    return this.auth?.token
  }

  getUserInfo() {
    return this.auth?.user
  }

  getCableUrl() {
    return this.auth?.cable_url
  }

  getRoomInfo() {
    return this.auth?.room
  }
}

const discordActivity = new DiscordActivityManager()
export { discordActivity }

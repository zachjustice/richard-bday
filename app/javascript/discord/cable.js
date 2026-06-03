import { discordActivity } from "discord/sdk"
import { createConsumer } from "@rails/actioncable"

export async function createDiscordCable() {
  const cableToken = await discordActivity.getCableToken()
  // Discord's CDN (discordsays.com) requires the /.proxy prefix so the WebSocket
  // satisfies the iframe CSP. With Activity URL Override (e.g. https://localhost:3000),
  // the iframe loads our server directly — no proxy, so connect to /cable straight.
  const usingDiscordProxy = window.location.hostname.endsWith(".discordsays.com")
  const path = usingDiscordProxy ? "/.proxy/cable" : "/cable"
  const consumer = createConsumer(`${path}?cable_token=${cableToken}`)

  // Connect this consumer to Turbo so <turbo-cable-stream-source> elements work
  const { cable } = await import("@hotwired/turbo-rails")
  cable.setConsumer(consumer)

  return consumer
}

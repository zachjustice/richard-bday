import { discordActivity } from "discord/sdk"
import { createConsumer } from "@rails/actioncable"

export async function createDiscordCable() {
  const cableToken = await discordActivity.getCableToken()
  // Use /.proxy prefix so the connection routes through Discord's proxy
  // to the actual app server (CSP blocks direct WebSocket connections)
  const consumer = createConsumer(`/.proxy/cable?cable_token=${cableToken}`)

  // Connect this consumer to Turbo so <turbo-cable-stream-source> elements work
  const { cable } = await import("@hotwired/turbo-rails")
  cable.setConsumer(consumer)

  return consumer
}

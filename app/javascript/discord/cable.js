import { discordActivity } from "discord/sdk"
import { createConsumer } from "@rails/actioncable"

export async function createDiscordCable() {
  const cableToken = await discordActivity.getCableToken()
  const consumer = createConsumer(`/cable?cable_token=${cableToken}`)

  // Connect this consumer to Turbo so <turbo-cable-stream-source> elements work
  const { cable } = await import("@hotwired/turbo-rails")
  cable.setConsumer(consumer)

  return consumer
}

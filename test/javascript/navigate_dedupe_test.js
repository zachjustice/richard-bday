import { assertEquals } from "https://deno.land/std/assert/mod.ts"
import { shouldDedupeNavigate } from "../../app/javascript/lib/navigate_dedupe.js"

Deno.test("dedupes when same url arrives within the threshold window", () => {
  assertEquals(shouldDedupeNavigate("/game_prompts/1/voting", "/game_prompts/1/voting", 1000, 1500, 1000), true)
})

Deno.test("does not dedupe when url differs", () => {
  assertEquals(shouldDedupeNavigate("/game_prompts/2/voting", "/game_prompts/1/voting", 1000, 1500, 1000), false)
})

Deno.test("does not dedupe when same url arrives outside the threshold window", () => {
  assertEquals(shouldDedupeNavigate("/game_prompts/1/voting", "/game_prompts/1/voting", 1000, 5000, 1000), false)
})

Deno.test("does not dedupe at the exact threshold boundary", () => {
  assertEquals(shouldDedupeNavigate("/game_prompts/1/voting", "/game_prompts/1/voting", 1000, 2000, 1000), false)
})

Deno.test("does not dedupe on the very first navigate (no previous url)", () => {
  assertEquals(shouldDedupeNavigate("/game_prompts/1/voting", null, 0, 500, 1000), false)
})

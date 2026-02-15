import { assertEquals } from "https://deno.land/std/assert/mod.ts"
import { shouldEnableSubmit } from "../../app/javascript/lib/voting_state.js"

Deno.test("enabled when all slots filled", () => {
  assertEquals(shouldEnableSubmit(3, 3, 5), true)
})

Deno.test("disabled when not all slots filled", () => {
  assertEquals(shouldEnableSubmit(2, 3, 5), false)
})

Deno.test("disabled when no slots filled", () => {
  assertEquals(shouldEnableSubmit(0, 3, 5), false)
})

Deno.test("uses maxSlots as threshold when fewer than totalAnswers", () => {
  assertEquals(shouldEnableSubmit(3, 3, 10), true)
  assertEquals(shouldEnableSubmit(2, 3, 10), false)
})

Deno.test("uses totalAnswers as threshold when fewer than maxSlots", () => {
  assertEquals(shouldEnableSubmit(2, 5, 2), true)
  assertEquals(shouldEnableSubmit(1, 5, 2), false)
})

Deno.test("enabled when filled exceeds required", () => {
  assertEquals(shouldEnableSubmit(5, 3, 5), true)
})

Deno.test("handles edge case of 1 slot and 1 answer", () => {
  assertEquals(shouldEnableSubmit(1, 1, 1), true)
  assertEquals(shouldEnableSubmit(0, 1, 1), false)
})

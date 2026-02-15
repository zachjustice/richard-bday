import { assertEquals } from "https://deno.land/std/assert/mod.ts"
import { timerPhase } from "../../app/javascript/lib/timer_phase.js"

Deno.test("returns 'green' when more than 50% time remaining", () => {
  assertEquals(timerPhase(60, 60), "green")
  assertEquals(timerPhase(31, 60), "green")
})

Deno.test("returns 'orange' when 25-50% time remaining", () => {
  assertEquals(timerPhase(30, 60), "orange")
  assertEquals(timerPhase(16, 60), "orange")
})

Deno.test("returns 'red' when less than 25% time remaining", () => {
  assertEquals(timerPhase(15, 60), "red")
  assertEquals(timerPhase(1, 60), "red")
})

Deno.test("returns 'zero' when time is up", () => {
  assertEquals(timerPhase(0, 60), "zero")
  assertEquals(timerPhase(-1, 60), "zero")
})

Deno.test("handles boundary at exactly 50%", () => {
  // 30/60 = 0.5, which is NOT > 0.5, so "orange"
  assertEquals(timerPhase(30, 60), "orange")
})

Deno.test("handles boundary at exactly 25%", () => {
  // 15/60 = 0.25, which is NOT > 0.25, so "red"
  assertEquals(timerPhase(15, 60), "red")
})

Deno.test("works with different durations", () => {
  assertEquals(timerPhase(100, 120), "green")
  assertEquals(timerPhase(50, 120), "orange")
  assertEquals(timerPhase(20, 120), "red")
  assertEquals(timerPhase(0, 120), "zero")
})

Deno.test("handles zero duration (division by zero)", () => {
  // 10/0 = Infinity, Infinity > 0.5 is true, so "green"
  assertEquals(timerPhase(10, 0), "green")
  // 0/0 = NaN, timeRemaining <= 0 check catches this first
  assertEquals(timerPhase(0, 0), "zero")
})

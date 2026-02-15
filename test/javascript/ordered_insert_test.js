import { assertEquals } from "https://deno.land/std/assert/mod.ts"
import { findInsertionIndex } from "../../app/javascript/lib/ordered_insert.js"

Deno.test("inserts at beginning when item was originally first", () => {
  assertEquals(findInsertionIndex("a", ["b", "c"], ["a", "b", "c"]), 0)
})

Deno.test("inserts at end when item was originally last", () => {
  assertEquals(findInsertionIndex("c", ["a", "b"], ["a", "b", "c"]), 2)
})

Deno.test("inserts in middle preserving original order", () => {
  assertEquals(findInsertionIndex("b", ["a", "c"], ["a", "b", "c"]), 1)
})

Deno.test("inserts into empty list", () => {
  assertEquals(findInsertionIndex("a", [], ["a", "b", "c"]), 0)
})

Deno.test("inserts into single-element list before", () => {
  assertEquals(findInsertionIndex("a", ["b"], ["a", "b", "c"]), 0)
})

Deno.test("inserts into single-element list after", () => {
  assertEquals(findInsertionIndex("c", ["a"], ["a", "b", "c"]), 1)
})

Deno.test("handles item not in initial order", () => {
  // indexOf returns -1, so targetIndex is -1, all existing items have higher index
  assertEquals(findInsertionIndex("z", ["a", "b"], ["a", "b", "c"]), 0)
})

Deno.test("handles complex reordering scenario", () => {
  const initialOrder = ["1", "2", "3", "4", "5"]
  // Container has 1, 3, 5 — insert 4 between 3 and 5
  assertEquals(findInsertionIndex("4", ["1", "3", "5"], initialOrder), 2)
  // Container has 1, 3, 5 — insert 2 between 1 and 3
  assertEquals(findInsertionIndex("2", ["1", "3", "5"], initialOrder), 1)
})

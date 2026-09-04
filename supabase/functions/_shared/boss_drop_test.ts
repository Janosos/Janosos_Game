import {
  assertEquals,
  assertGreaterOrEqual,
  assertLess,
} from "jsr:@std/assert@1";

import { deterministicBasisPointRoll } from "./boss_drop.ts";

const testKey = "janosos-test-drop-key-with-at-least-32-bytes";

Deno.test("boss drop roll is deterministic and stays in basis-point range", async () => {
  const first = await deterministicBasisPointRoll(testKey, "same-stage");
  const retry = await deterministicBasisPointRoll(testKey, "same-stage");
  assertEquals(first, retry);
  assertGreaterOrEqual(first, 0);
  assertLess(first, 10_000);
});

Deno.test("different stage material produces independent deterministic rolls", async () => {
  const values = await Promise.all(
    Array.from(
      { length: 128 },
      (_, index) => deterministicBasisPointRoll(testKey, `stage-${index}`),
    ),
  );
  assertGreaterOrEqual(new Set(values).size, 120);
});

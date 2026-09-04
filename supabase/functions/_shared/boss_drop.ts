import { requiredEnvironment } from "./game_http.ts";

const encoder = new TextEncoder();
const rollSpace = 10_000;
const hitThreshold = 100;
const unbiasedLimit = Math.floor(0x1_0000_0000 / rollSpace) * rollSpace;

export interface BossDropRoll {
  basisPoints: number;
  granted: boolean;
}

export async function rollBossDrop(input: {
  userId: string;
  campaignId: string;
  sequence: number;
  rewardId: string;
  keyVersion: number;
}): Promise<BossDropRoll> {
  const key = dropKey(input.keyVersion);
  const material = [
    input.campaignId,
    input.sequence,
    input.userId,
    input.rewardId,
  ].join("|");
  const basisPoints = await deterministicBasisPointRoll(key, material);
  return { basisPoints, granted: basisPoints < hitThreshold };
}

export async function deterministicBasisPointRoll(
  rawKey: string,
  material: string,
): Promise<number> {
  const bytes = encoder.encode(rawKey);
  if (bytes.length < 32) {
    throw new Error("Boss-drop keys must contain at least 32 bytes");
  }
  const key = await crypto.subtle.importKey(
    "raw",
    bytes.slice().buffer as ArrayBuffer,
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  for (let counter = 0; counter < 1024; counter += 1) {
    const payload = encoder.encode(`${material}|${counter}`);
    const signature = new Uint8Array(
      await crypto.subtle.sign(
        "HMAC",
        key,
        payload.slice().buffer as ArrayBuffer,
      ),
    );
    const view = new DataView(signature.buffer);
    for (let offset = 0; offset <= signature.byteLength - 4; offset += 4) {
      const value = view.getUint32(offset, false);
      if (value < unbiasedLimit) return value % rollSpace;
    }
  }
  throw new Error("Unable to derive an unbiased boss-drop roll");
}

function dropKey(version: number): string {
  const currentVersion = positiveVersion("JANOSOS_DROP_KEY_VERSION");
  if (version === currentVersion) {
    return requiredEnvironment("JANOSOS_DROP_KEY");
  }

  const previousRaw = Deno.env.get("JANOSOS_PREVIOUS_DROP_KEY_VERSION");
  const previousVersion = previousRaw == null ? null : Number(previousRaw);
  if (previousVersion === version) {
    return requiredEnvironment("JANOSOS_PREVIOUS_DROP_KEY");
  }
  throw new Error("Unknown boss-drop key version");
}

function positiveVersion(name: string): number {
  const value = Number(Deno.env.get(name) ?? "1");
  if (!Number.isInteger(value) || value < 1 || value > 32767) {
    throw new Error(`${name} must be a positive small integer`);
  }
  return value;
}

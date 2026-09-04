import { type JWTPayload, jwtVerify, SignJWT } from "npm:jose@6";

import { requiredEnvironment } from "./game_http.ts";

const encoder = new TextEncoder();
const issuer = "janosos-game";
const audience = "janosos-stage";

export interface StageTokenInput {
  userId: string;
  campaignId: string;
  sequence: number;
  characterId: string;
  mode: string;
  loadoutDigest: string;
  configurationDigest: string;
  contentVersion: string;
  protocolVersion: number;
  idempotencyKey: string;
  issuedAtSeconds: number;
  expiresAtSeconds: number;
}

export interface VerifiedStageClaims extends JWTPayload {
  campaign_id: string;
  stage_sequence: number;
  character_id: string;
  mode: string;
  loadout_digest: string;
  configuration_digest: string;
  content_version: string;
  protocol_version: number;
  nonce: string;
  signing_key_version: number;
  drop_key_version: number;
}

function currentKey(): Uint8Array {
  const key = encoder.encode(requiredEnvironment("JANOSOS_STAGE_SIGNING_KEY"));
  if (key.length < 32) {
    throw new Error("JANOSOS_STAGE_SIGNING_KEY must contain at least 32 bytes");
  }
  return key;
}

function positiveVersion(name: string): number {
  const value = Number(Deno.env.get(name) ?? "1");
  if (!Number.isInteger(value) || value < 1 || value > 32767) {
    throw new Error(`${name} must be a positive small integer`);
  }
  return value;
}

function base64Url(bytes: Uint8Array): string {
  let binary = "";
  for (const byte of bytes) binary += String.fromCharCode(byte);
  return btoa(binary).replaceAll("+", "-").replaceAll("/", "_").replace(
    /=+$/,
    "",
  );
}

async function deterministicNonce(
  key: Uint8Array,
  input: StageTokenInput,
): Promise<string> {
  const hmacKey = await crypto.subtle.importKey(
    "raw",
    key.slice().buffer as ArrayBuffer,
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const material = encoder.encode(
    `${input.userId}|${input.campaignId}|${input.sequence}|${input.idempotencyKey}`,
  );
  const signature = await crypto.subtle.sign(
    "HMAC",
    hmacKey,
    material.slice().buffer as ArrayBuffer,
  );
  return base64Url(new Uint8Array(signature).slice(0, 18));
}

export async function createStageToken(
  input: StageTokenInput,
): Promise<string> {
  const key = currentKey();
  const signingKeyVersion = positiveVersion(
    "JANOSOS_STAGE_SIGNING_KEY_VERSION",
  );
  const dropKeyVersion = positiveVersion("JANOSOS_DROP_KEY_VERSION");
  const nonce = await deterministicNonce(key, input);
  return new SignJWT({
    campaign_id: input.campaignId,
    stage_sequence: input.sequence,
    character_id: input.characterId,
    mode: input.mode,
    loadout_digest: input.loadoutDigest,
    configuration_digest: input.configurationDigest,
    content_version: input.contentVersion,
    protocol_version: input.protocolVersion,
    nonce,
    signing_key_version: signingKeyVersion,
    drop_key_version: dropKeyVersion,
  })
    .setProtectedHeader({ alg: "HS256", kid: `v${signingKeyVersion}` })
    .setIssuer(issuer)
    .setAudience(audience)
    .setSubject(input.userId)
    .setIssuedAt(input.issuedAtSeconds)
    .setNotBefore(input.issuedAtSeconds)
    .setExpirationTime(input.expiresAtSeconds)
    .sign(key);
}

export async function verifyStageToken(
  token: string,
): Promise<VerifiedStageClaims> {
  const keys = [currentKey()];
  const previous = Deno.env.get("JANOSOS_STAGE_PREVIOUS_SIGNING_KEY");
  if (previous) {
    const previousKey = encoder.encode(previous);
    if (previousKey.length < 32) {
      throw new Error(
        "JANOSOS_STAGE_PREVIOUS_SIGNING_KEY must contain at least 32 bytes",
      );
    }
    keys.push(previousKey);
  }

  let lastError: unknown;
  for (const key of keys) {
    try {
      const { payload } = await jwtVerify(token, key, {
        issuer,
        audience,
        algorithms: ["HS256"],
      });
      const claims = payload as VerifiedStageClaims;
      if (
        typeof claims.sub !== "string" ||
        typeof claims.campaign_id !== "string" ||
        !Number.isInteger(claims.stage_sequence) ||
        typeof claims.character_id !== "string" ||
        typeof claims.mode !== "string" ||
        typeof claims.loadout_digest !== "string" ||
        typeof claims.configuration_digest !== "string" ||
        typeof claims.content_version !== "string" ||
        !Number.isInteger(claims.protocol_version) ||
        typeof claims.nonce !== "string" ||
        !Number.isInteger(claims.signing_key_version) ||
        !Number.isInteger(claims.drop_key_version)
      ) {
        throw new Error("Stage token has incomplete claims");
      }
      return claims;
    } catch (error) {
      lastError = error;
    }
  }
  throw lastError ?? new Error("Stage token verification failed");
}

export function currentSigningKeyVersion(): number {
  return positiveVersion("JANOSOS_STAGE_SIGNING_KEY_VERSION");
}

export function currentDropKeyVersion(): number {
  return positiveVersion("JANOSOS_DROP_KEY_VERSION");
}

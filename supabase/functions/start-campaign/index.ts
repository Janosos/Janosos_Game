import {
  authenticate,
  commandResponse,
  databaseErrorResponse,
  isResponse,
  jsonResponse,
  optionsResponse,
  readJsonObject,
  requestDigest,
  requireDigest,
  requireIdentifier,
  requireInteger,
  requireUuid,
} from "../_shared/game_http.ts";

const characterIds = new Set([
  "jano",
  "parker",
  "chema",
  "conra",
  "shyno",
  "nakama",
  "nanic",
]);
const modes = new Set(["standard", "progression"]);
const baseLives = new Map<string, number>([["parker", 2]]);

Deno.serve(async (request: Request) => {
  const preflight = optionsResponse(request);
  if (preflight) return preflight;
  if (request.method !== "POST") {
    return jsonResponse(405, { code: "method_not_allowed" });
  }

  try {
    const clients = await authenticate(request);
    if (isResponse(clients)) return clients;
    const body = await readJsonObject(request);
    if (isResponse(body)) return body;

    const characterId = requireIdentifier(
      body.character_id,
      "character_id",
      characterIds,
    );
    if (isResponse(characterId)) return characterId;
    const mode = requireIdentifier(body.mode, "mode", modes);
    if (isResponse(mode)) return mode;
    const contentVersion = requireIdentifier(
      body.content_version,
      "content_version",
    );
    if (isResponse(contentVersion)) return contentVersion;
    const protocolVersion = requireInteger(
      body.protocol_version,
      "protocol_version",
      1,
      100000,
    );
    if (isResponse(protocolVersion)) return protocolVersion;
    const loadoutDigest = requireDigest(body.loadout_digest, "loadout_digest");
    if (isResponse(loadoutDigest)) return loadoutDigest;
    const lives = baseLives.get(characterId) ?? 1;
    const idempotencyKey = requireUuid(
      body.idempotency_key,
      "idempotency_key",
    );
    if (isResponse(idempotencyKey)) return idempotencyKey;

    const normalized = {
      character_id: characterId,
      mode,
      content_version: contentVersion,
      protocol_version: protocolVersion,
      loadout_digest: loadoutDigest,
      lives,
      idempotency_key: idempotencyKey,
    };
    const digest = await requestDigest(normalized);
    const { data, error } = await clients.userClient.rpc("start_campaign", {
      p_character_id: characterId,
      p_mode: mode,
      p_content_version: contentVersion,
      p_protocol_version: protocolVersion,
      p_loadout_digest: loadoutDigest,
      p_lives: lives,
      p_idempotency_key: idempotencyKey,
      p_request_digest: digest,
    });
    if (error) return databaseErrorResponse(error);
    return commandResponse(data);
  } catch (error) {
    console.error("Unexpected start-campaign failure", error);
    return jsonResponse(500, { code: "internal_error" });
  }
});

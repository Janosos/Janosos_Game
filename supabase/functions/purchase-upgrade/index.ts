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
const statIds = new Set(["speed", "jump", "damage", "vitality", "fortune"]);

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
    const statId = requireIdentifier(body.stat_id, "stat_id", statIds);
    if (isResponse(statId)) return statId;
    const expectedRank = requireInteger(
      body.expected_rank,
      "expected_rank",
      0,
      5,
    );
    if (isResponse(expectedRank)) return expectedRank;
    const contentVersion = requireIdentifier(
      body.content_version,
      "content_version",
    );
    if (isResponse(contentVersion)) return contentVersion;
    const catalogDigest = requireDigest(body.catalog_digest, "catalog_digest");
    if (isResponse(catalogDigest)) return catalogDigest;
    const idempotencyKey = requireUuid(body.idempotency_key, "idempotency_key");
    if (isResponse(idempotencyKey)) return idempotencyKey;

    const normalized = {
      character_id: characterId,
      stat_id: statId,
      expected_rank: expectedRank,
      content_version: contentVersion,
      catalog_digest: catalogDigest,
      idempotency_key: idempotencyKey,
    };
    const digest = await requestDigest(normalized);
    const { data, error } = await clients.adminClient.rpc(
      "apply_purchase_upgrade",
      {
        p_user_id: clients.user.id,
        p_character_id: characterId,
        p_stat_id: statId,
        p_expected_rank: expectedRank,
        p_content_version: contentVersion,
        p_catalog_digest: catalogDigest,
        p_idempotency_key: idempotencyKey,
        p_request_digest: digest,
      },
    );
    if (error) return databaseErrorResponse(error);
    return commandResponse(data);
  } catch (error) {
    console.error("Unexpected purchase-upgrade failure", error);
    return jsonResponse(500, { code: "internal_error" });
  }
});

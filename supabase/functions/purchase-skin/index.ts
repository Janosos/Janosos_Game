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
    const skinId = requireIdentifier(body.skin_id, "skin_id");
    if (isResponse(skinId)) return skinId;
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
      skin_id: skinId,
      content_version: contentVersion,
      catalog_digest: catalogDigest,
      idempotency_key: idempotencyKey,
    };
    const digest = await requestDigest(normalized);
    const { data, error } = await clients.adminClient.rpc(
      "apply_purchase_skin",
      {
        p_user_id: clients.user.id,
        p_character_id: characterId,
        p_skin_id: skinId,
        p_content_version: contentVersion,
        p_catalog_digest: catalogDigest,
        p_idempotency_key: idempotencyKey,
        p_request_digest: digest,
      },
    );
    if (error) return databaseErrorResponse(error);
    return commandResponse(data);
  } catch (error) {
    console.error("Unexpected purchase-skin failure", error);
    return jsonResponse(500, { code: "internal_error" });
  }
});

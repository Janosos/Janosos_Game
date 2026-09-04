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

function optionalIdentifier(
  value: unknown,
  field: string,
): string | null | Response {
  if (value === null || value === undefined) return null;
  return requireIdentifier(value, field);
}

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
    const activeSkillId = optionalIdentifier(
      body.active_skill_id,
      "active_skill_id",
    );
    if (isResponse(activeSkillId)) return activeSkillId;
    const skinId = optionalIdentifier(body.skin_id, "skin_id");
    if (isResponse(skinId)) return skinId;
    if (
      !Array.isArray(body.passive_skill_ids) ||
      body.passive_skill_ids.length > 2
    ) {
      return jsonResponse(400, { code: "invalid_passive_skill_ids" });
    }
    const passiveIds: string[] = [];
    for (const candidate of body.passive_skill_ids) {
      const parsed = requireIdentifier(candidate, "passive_skill_ids");
      if (isResponse(parsed)) return parsed;
      passiveIds.push(parsed);
    }
    if (new Set(passiveIds).size !== passiveIds.length) {
      return jsonResponse(400, { code: "duplicate_passive_skill" });
    }
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
      active_skill_id: activeSkillId,
      passive_skill_ids: passiveIds,
      skin_id: skinId,
      content_version: contentVersion,
      catalog_digest: catalogDigest,
      idempotency_key: idempotencyKey,
    };
    const digest = await requestDigest(normalized);
    const { data, error } = await clients.adminClient.rpc(
      "apply_equip_loadout",
      {
        p_user_id: clients.user.id,
        p_character_id: characterId,
        p_active_skill_id: activeSkillId,
        p_passive_skill_1_id: passiveIds[0] ?? null,
        p_passive_skill_2_id: passiveIds[1] ?? null,
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
    console.error("Unexpected equip-loadout failure", error);
    return jsonResponse(500, { code: "internal_error" });
  }
});

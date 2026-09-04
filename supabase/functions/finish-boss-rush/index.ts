import {
  authenticate,
  commandResponse,
  databaseErrorResponse,
  isResponse,
  jsonResponse,
  optionsResponse,
  readJsonObject,
  requestDigest,
  requireIdentifier,
  requireInteger,
  requireUuid,
  sha256Text,
} from "../_shared/game_http.ts";
import { rollBossDrop } from "../_shared/boss_drop.ts";
import { verifyStageToken } from "../_shared/stage_token.ts";

const outcomes = new Set(["victory", "defeat"]);
const rewards = [
  "headless_horseman.spectral_trail",
  "queen_of_hearts.card_aura",
  "mister_hyde.hyde_serum",
  "phantom.phantom_mask",
  "snow_queen.frost_heart",
  "dracula.crimson_cape",
  "wicked_witch.silver_shoes",
  "frankenstein_creature.galvanic_core",
  "davy_jones.abyssal_compass",
  "moriarty.strategist_crown",
];

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
    if (
      typeof body.attempt_token !== "string" ||
      body.attempt_token.length > 8192
    ) {
      return jsonResponse(400, { code: "invalid_attempt_token" });
    }
    const idempotencyKey = requireUuid(
      body.idempotency_key,
      "idempotency_key",
    );
    if (isResponse(idempotencyKey)) return idempotencyKey;
    const outcome = requireIdentifier(body.outcome, "outcome", outcomes);
    if (isResponse(outcome)) return outcome;
    const bossesDefeated = requireInteger(
      body.bosses_defeated,
      "bosses_defeated",
      0,
      10,
    );
    if (isResponse(bossesDefeated)) return bossesDefeated;
    if ((outcome === "victory") !== (bossesDefeated === 10)) {
      return jsonResponse(400, { code: "boss_rush_outcome_mismatch" });
    }
    const score = requireInteger(body.score, "score", 0, 5000000);
    if (isResponse(score)) return score;
    const durationMs = requireInteger(
      body.duration_ms,
      "duration_ms",
      1000,
      21600000,
    );
    if (isResponse(durationMs)) return durationMs;

    let claims;
    try {
      claims = await verifyStageToken(body.attempt_token);
    } catch (_error) {
      return jsonResponse(401, { code: "invalid_or_expired_attempt_token" });
    }
    if (claims.sub !== clients.user.id) {
      return jsonResponse(403, { code: "attempt_token_account_mismatch" });
    }
    if (claims.mode !== "boss_rush" || claims.stage_sequence !== 1) {
      return jsonResponse(409, { code: "invalid_boss_rush_claims" });
    }

    const dropRolls: Array<{
      level: number;
      reward_id: string;
      roll_basis_points: number;
    }> = [];
    for (let index = 0; index < bossesDefeated; index += 1) {
      const level = index + 1;
      const rewardId = rewards[index];
      const drop = await rollBossDrop({
        userId: clients.user.id,
        campaignId: claims.campaign_id,
        sequence: level,
        rewardId,
        keyVersion: claims.drop_key_version,
      });
      dropRolls.push({
        level,
        reward_id: rewardId,
        roll_basis_points: drop.basisPoints,
      });
    }

    const tokenDigest = await sha256Text(body.attempt_token);
    const normalized = {
      campaign_id: claims.campaign_id,
      token_digest: tokenDigest,
      outcome,
      bosses_defeated: bossesDefeated,
      score,
      duration_ms: durationMs,
      drop_rolls: dropRolls,
      idempotency_key: idempotencyKey,
    };
    const digest = await requestDigest(normalized);
    const { data, error } = await clients.adminClient.rpc(
      "apply_finish_boss_rush",
      {
        p_user_id: clients.user.id,
        p_campaign_id: claims.campaign_id,
        p_token_digest: tokenDigest,
        p_outcome: outcome,
        p_bosses_defeated: bossesDefeated,
        p_score: score,
        p_duration_ms: durationMs,
        p_drop_rolls: dropRolls,
        p_idempotency_key: idempotencyKey,
        p_request_digest: digest,
      },
    );
    if (error) return databaseErrorResponse(error);
    return commandResponse(data);
  } catch (error) {
    console.error("Unexpected finish-boss-rush failure", error);
    return jsonResponse(500, { code: "internal_error" });
  }
});

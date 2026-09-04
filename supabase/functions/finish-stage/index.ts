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
import { verifyStageToken } from "../_shared/stage_token.ts";
import { rollBossDrop } from "../_shared/boss_drop.ts";

const outcomes = new Set(["victory", "defeat"]);
const rewardIds = new Map<number, string>([
  [1, "headless_horseman.spectral_trail"],
  [2, "queen_of_hearts.card_aura"],
  [3, "mister_hyde.hyde_serum"],
  [4, "phantom.phantom_mask"],
  [5, "snow_queen.frost_heart"],
  [6, "dracula.crimson_cape"],
  [7, "wicked_witch.silver_shoes"],
  [8, "frankenstein_creature.galvanic_core"],
  [9, "davy_jones.abyssal_compass"],
  [10, "moriarty.strategist_crown"],
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
    if (
      typeof body.stage_token !== "string" || body.stage_token.length > 8192
    ) {
      return jsonResponse(400, { code: "invalid_stage_token" });
    }
    const idempotencyKey = requireUuid(
      body.idempotency_key,
      "idempotency_key",
    );
    if (isResponse(idempotencyKey)) return idempotencyKey;
    const outcome = requireIdentifier(body.outcome, "outcome", outcomes);
    if (isResponse(outcome)) return outcome;
    const score = requireInteger(body.score, "score", 0, 5000000);
    if (isResponse(score)) return score;
    const durationMs = requireInteger(
      body.duration_ms,
      "duration_ms",
      1000,
      21600000,
    );
    if (isResponse(durationMs)) return durationMs;
    const defeatReason = outcome === "defeat"
      ? requireIdentifier(
        body.defeat_reason ?? "lives_depleted",
        "defeat_reason",
      )
      : null;
    if (isResponse(defeatReason)) return defeatReason;

    let claims;
    try {
      claims = await verifyStageToken(body.stage_token);
    } catch (_error) {
      return jsonResponse(401, { code: "invalid_or_expired_stage_token" });
    }
    if (claims.sub !== clients.user.id) {
      return jsonResponse(403, { code: "stage_token_account_mismatch" });
    }

    const { data: authorizedBuild, error: buildError } = await clients
      .adminClient.rpc("get_authorized_run_configuration", {
        p_user_id: clients.user.id,
        p_character_id: claims.character_id,
        p_mode: claims.mode,
        p_content_version: claims.content_version,
      });
    if (buildError) return databaseErrorResponse(buildError);
    if (!authorizedBuild || typeof authorizedBuild !== "object") {
      return jsonResponse(409, { code: "authorized_build_unavailable" });
    }
    const stats = (authorizedBuild as Record<string, unknown>).stats;
    const fortuneBasisPoints = stats && typeof stats === "object"
      ? Number((stats as Record<string, unknown>).fortune_basis_points ?? 0)
      : 0;
    if (
      !Number.isSafeInteger(fortuneBasisPoints) || fortuneBasisPoints < 0 ||
      fortuneBasisPoints > 1500
    ) {
      return jsonResponse(500, { code: "invalid_authorized_build" });
    }

    const tokenDigest = await sha256Text(body.stage_token);
    const normalized = {
      campaign_id: claims.campaign_id,
      stage_sequence: claims.stage_sequence,
      token_digest: tokenDigest,
      outcome,
      score,
      duration_ms: durationMs,
      defeat_reason: defeatReason,
      idempotency_key: idempotencyKey,
    };
    const digest = await requestDigest(normalized);
    const baseMasteryXp = outcome === "victory"
      ? 100 + claims.stage_sequence * 10
      : 25 + claims.stage_sequence * 5;
    const masteryXp = claims.mode === "standard"
      ? Math.floor(baseMasteryXp * 0.4)
      : baseMasteryXp;
    const baseCurrency = Math.min(100000, Math.max(10, Math.floor(score / 10)));
    const currencyEarned =
      claims.mode === "progression" && outcome === "victory"
        ? Math.floor(baseCurrency * (10000 + fortuneBasisPoints) / 10000)
        : 0;
    const rewardId = rewardIds.get(claims.stage_sequence);
    if (!rewardId) {
      return jsonResponse(500, { code: "missing_boss_reward" });
    }
    const drop = outcome === "victory" && claims.mode === "progression"
      ? await rollBossDrop({
        userId: clients.user.id,
        campaignId: claims.campaign_id,
        sequence: claims.stage_sequence,
        rewardId,
        keyVersion: claims.drop_key_version,
      })
      : { basisPoints: 9_999, granted: false };

    const { data, error } = await clients.adminClient.rpc(
      "apply_finish_stage_with_drop",
      {
        p_user_id: clients.user.id,
        p_campaign_id: claims.campaign_id,
        p_token_digest: tokenDigest,
        p_outcome: outcome,
        p_score: score,
        p_duration_ms: durationMs,
        p_defeat_reason: defeatReason,
        p_currency_earned: currencyEarned,
        p_mastery_xp: masteryXp,
        p_unique_reward_id: rewardId,
        p_drop_roll_basis_points: drop.basisPoints,
        p_idempotency_key: idempotencyKey,
        p_request_digest: digest,
      },
    );
    if (error) return databaseErrorResponse(error);
    return commandResponse(data);
  } catch (error) {
    console.error("Unexpected finish-stage failure", error);
    return jsonResponse(500, { code: "internal_error" });
  }
});

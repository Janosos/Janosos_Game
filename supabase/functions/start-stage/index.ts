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
  requireUuid,
  sha256Text,
} from "../_shared/game_http.ts";
import {
  createStageToken,
  currentDropKeyVersion,
  currentSigningKeyVersion,
} from "../_shared/stage_token.ts";

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
    const campaignId = requireUuid(body.campaign_id, "campaign_id");
    if (isResponse(campaignId)) return campaignId;
    const configurationDigest = requireDigest(
      body.configuration_digest,
      "configuration_digest",
    );
    if (isResponse(configurationDigest)) return configurationDigest;
    const idempotencyKey = requireUuid(
      body.idempotency_key,
      "idempotency_key",
    );
    if (isResponse(idempotencyKey)) return idempotencyKey;

    const { data: campaign, error: campaignError } = await clients.userClient
      .from("campaign_runs")
      .select(
        "id, character_id, mode, state, expected_sequence, content_version, protocol_version, loadout_digest, lease_expires_at",
      )
      .eq("id", campaignId)
      .maybeSingle();
    if (campaignError) return databaseErrorResponse(campaignError);
    if (!campaign || campaign.state !== "active") {
      return jsonResponse(409, { code: "campaign_not_active" });
    }

    const expiresAt = new Date(campaign.lease_expires_at);
    const issuedAt = new Date(expiresAt.getTime() - 6 * 60 * 60 * 1000 + 1);
    const issuedAtSeconds = Math.floor(issuedAt.getTime() / 1000);
    const expiresAtSeconds = Math.floor(expiresAt.getTime() / 1000);
    if (
      !Number.isFinite(expiresAtSeconds) ||
      expiresAtSeconds <= Date.now() / 1000
    ) {
      return jsonResponse(409, { code: "campaign_expired" });
    }

    const token = await createStageToken({
      userId: clients.user.id,
      campaignId,
      sequence: campaign.expected_sequence,
      characterId: campaign.character_id,
      mode: campaign.mode,
      loadoutDigest: campaign.loadout_digest,
      configurationDigest,
      contentVersion: campaign.content_version,
      protocolVersion: campaign.protocol_version,
      idempotencyKey,
      issuedAtSeconds,
      expiresAtSeconds,
    });
    const tokenDigest = await sha256Text(token);
    const normalized = {
      campaign_id: campaignId,
      configuration_digest: configurationDigest,
      idempotency_key: idempotencyKey,
    };
    const digest = await requestDigest(normalized);
    const { data, error } = await clients.userClient.rpc("start_stage", {
      p_campaign_id: campaignId,
      p_token_digest: tokenDigest,
      p_configuration_digest: configurationDigest,
      p_issued_at: issuedAt.toISOString(),
      p_expires_at: campaign.lease_expires_at,
      p_signing_key_version: currentSigningKeyVersion(),
      p_drop_key_version: currentDropKeyVersion(),
      p_idempotency_key: idempotencyKey,
      p_request_digest: digest,
    });
    if (error) return databaseErrorResponse(error);
    const base = commandResponse(data);
    if (base.status !== 200) return base;
    const command = data as Record<string, unknown>;
    return jsonResponse(200, { ...command, stage_token: token });
  } catch (error) {
    console.error("Unexpected start-stage failure", error);
    return jsonResponse(500, { code: "internal_error" });
  }
});

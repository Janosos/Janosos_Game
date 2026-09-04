import {
  authenticate,
  commandResponse,
  databaseErrorResponse,
  isResponse,
  jsonResponse,
  optionsResponse,
  readJsonObject,
  requestDigest,
  requireUuid,
} from "../_shared/game_http.ts";

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
    const idempotencyKey = requireUuid(
      body.idempotency_key,
      "idempotency_key",
    );
    if (isResponse(idempotencyKey)) return idempotencyKey;
    const normalized = {
      campaign_id: campaignId,
      idempotency_key: idempotencyKey,
    };
    const digest = await requestDigest(normalized);
    const { data, error } = await clients.userClient.rpc("fail_campaign", {
      p_campaign_id: campaignId,
      p_idempotency_key: idempotencyKey,
      p_request_digest: digest,
    });
    if (error) return databaseErrorResponse(error);
    return commandResponse(data);
  } catch (error) {
    console.error("Unexpected fail-campaign failure", error);
    return jsonResponse(500, { code: "internal_error" });
  }
});

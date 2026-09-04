interface LocalStatus {
  API_URL: string;
  ANON_KEY: string;
  SERVICE_ROLE_KEY: string;
}

interface JsonResponse {
  status: number;
  body: Record<string, unknown>;
}

async function localStatus(): Promise<LocalStatus> {
  const command = new Deno.Command(
    Deno.build.os === "windows" ? "npx.cmd" : "npx",
    {
      args: ["supabase@latest", "status", "-o", "json"],
      cwd: Deno.cwd(),
      stdout: "piped",
      stderr: "piped",
    },
  );
  const output = await command.output();
  if (!output.success) {
    throw new Error(new TextDecoder().decode(output.stderr));
  }
  return JSON.parse(new TextDecoder().decode(output.stdout)) as LocalStatus;
}

async function jsonRequest(
  url: string,
  init: RequestInit,
): Promise<JsonResponse> {
  const response = await fetch(url, init);
  const body = await response.json().catch(() => ({})) as Record<
    string,
    unknown
  >;
  return { status: response.status, body };
}

async function sha256(value: string): Promise<string> {
  const bytes = new TextEncoder().encode(value);
  const digest = await crypto.subtle.digest("SHA-256", bytes);
  return Array.from(new Uint8Array(digest))
    .map((byte) => byte.toString(16).padStart(2, "0"))
    .join("");
}

function assert(condition: unknown, message: string): asserts condition {
  if (!condition) throw new Error(message);
}

const status = await localStatus();
const suffix = crypto.randomUUID();
const email = `phase3-${suffix}@example.com`;
const password = `Local-${suffix}-Password!`;
let userId: string | null = null;

try {
  const created = await jsonRequest(`${status.API_URL}/auth/v1/admin/users`, {
    method: "POST",
    headers: {
      apikey: status.SERVICE_ROLE_KEY,
      Authorization: `Bearer ${status.SERVICE_ROLE_KEY}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      email,
      password,
      email_confirm: true,
      user_metadata: { display_name: "HTTP Fixture" },
    }),
  });
  assert(created.status === 200, `create user failed: ${created.status}`);
  userId = String(created.body.id);

  const signedIn = await jsonRequest(
    `${status.API_URL}/auth/v1/token?grant_type=password`,
    {
      method: "POST",
      headers: {
        apikey: status.ANON_KEY,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ email, password }),
    },
  );
  assert(signedIn.status === 200, `sign in failed: ${signedIn.status}`);
  const accessToken = String(signedIn.body.access_token);
  const authenticatedHeaders = {
    apikey: status.ANON_KEY,
    Authorization: `Bearer ${accessToken}`,
    "Content-Type": "application/json",
  };

  const campaignBody = {
    character_id: "jano",
    mode: "progression",
    content_version: "v6-preview-1",
    protocol_version: 1,
    loadout_digest: await sha256("phase3-loadout"),
    lives: 3,
    idempotency_key: crypto.randomUUID(),
  };
  const startCampaign = () =>
    jsonRequest(`${status.API_URL}/functions/v1/start-campaign`, {
      method: "POST",
      headers: authenticatedHeaders,
      body: JSON.stringify(campaignBody),
    });
  const campaign = await startCampaign();
  const campaignRetry = await startCampaign();
  assert(campaign.status === 200, `start campaign failed: ${campaign.status}`);
  assert(
    JSON.stringify(campaign.body) === JSON.stringify(campaignRetry.body),
    "start campaign retry was not canonical",
  );
  const campaignId = String(campaign.body.campaign_id);

  const stageBody = {
    campaign_id: campaignId,
    configuration_digest: await sha256("phase3-configuration"),
    idempotency_key: crypto.randomUUID(),
  };
  const startStage = () =>
    jsonRequest(`${status.API_URL}/functions/v1/start-stage`, {
      method: "POST",
      headers: authenticatedHeaders,
      body: JSON.stringify(stageBody),
    });
  const stage = await startStage();
  const stageRetry = await startStage();
  assert(stage.status === 200, `start stage failed: ${stage.status}`);
  assert(
    stage.body.stage_token === stageRetry.body.stage_token,
    "stage retry returned a different signed token",
  );

  const finishBody = {
    stage_token: String(stage.body.stage_token),
    outcome: "defeat",
    score: 1234,
    duration_ms: 15000,
    defeat_reason: "lives_depleted",
    idempotency_key: crypto.randomUUID(),
  };
  const finishStage = () =>
    jsonRequest(`${status.API_URL}/functions/v1/finish-stage`, {
      method: "POST",
      headers: authenticatedHeaders,
      body: JSON.stringify(finishBody),
    });
  const finished = await finishStage();
  const finishRetry = await finishStage();
  assert(finished.status === 200, `finish stage failed: ${finished.status}`);
  assert(finished.body.ranked === true, "accepted defeat was not ranked");
  assert(
    JSON.stringify(finished.body) === JSON.stringify(finishRetry.body),
    "finish retry was not canonical",
  );

  const leaderboardResponse = await fetch(
    `${status.API_URL}/rest/v1/rpc/get_leaderboard_page`,
    {
      method: "POST",
      headers: authenticatedHeaders,
      body: JSON.stringify({
        p_character_id: "jano",
        p_mode: "progression",
        p_content_version: "v6-preview-1",
        p_limit: 25,
      }),
    },
  );
  const leaderboard = await leaderboardResponse.json() as unknown[];
  assert(
    leaderboardResponse.status === 200 && leaderboard.length === 1,
    "finish-stage did not create exactly one leaderboard row",
  );

  const historyResponse = await fetch(
    `${status.API_URL}/rest/v1/rpc/get_personal_history`,
    {
      method: "POST",
      headers: authenticatedHeaders,
      body: JSON.stringify({
        p_character_id: "jano",
        p_mode: "progression",
        p_content_version: "v6-preview-1",
        p_limit: 100,
      }),
    },
  );
  const history = await historyResponse.json() as unknown[];
  assert(
    historyResponse.status === 200 && history.length === 1,
    "finish-stage did not create exactly one personal result",
  );

  console.log(JSON.stringify({
    authenticated: true,
    deterministic_stage_retry: true,
    canonical_finish_retry: true,
    leaderboard_rows: leaderboard.length,
    personal_results: history.length,
  }));
} finally {
  if (userId) {
    await fetch(`${status.API_URL}/auth/v1/admin/users/${userId}`, {
      method: "DELETE",
      headers: {
        apikey: status.SERVICE_ROLE_KEY,
        Authorization: `Bearer ${status.SERVICE_ROLE_KEY}`,
      },
    });
  }
}

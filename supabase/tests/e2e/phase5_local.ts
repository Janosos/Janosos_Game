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
  const digest = await crypto.subtle.digest(
    "SHA-256",
    new TextEncoder().encode(value),
  );
  return Array.from(new Uint8Array(digest))
    .map((byte) => byte.toString(16).padStart(2, "0"))
    .join("");
}

function assert(condition: unknown, message: string): asserts condition {
  if (!condition) throw new Error(message);
}

const status = await localStatus();
const suffix = crypto.randomUUID();
const email = `phase5-${suffix}@example.com`;
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
      user_metadata: { display_name: "Boss Drop Fixture" },
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
  const authenticatedHeaders = {
    apikey: status.ANON_KEY,
    Authorization: `Bearer ${String(signedIn.body.access_token)}`,
    "Content-Type": "application/json",
  };

  const campaign = await jsonRequest(
    `${status.API_URL}/functions/v1/start-campaign`,
    {
      method: "POST",
      headers: authenticatedHeaders,
      body: JSON.stringify({
        character_id: "jano",
        mode: "progression",
        content_version: "v6-preview-1",
        protocol_version: 1,
        loadout_digest: await sha256("phase5-loadout"),
        idempotency_key: crypto.randomUUID(),
      }),
    },
  );
  assert(campaign.status === 200, `start campaign failed: ${campaign.status}`);

  const stage = await jsonRequest(
    `${status.API_URL}/functions/v1/start-stage`,
    {
      method: "POST",
      headers: authenticatedHeaders,
      body: JSON.stringify({
        campaign_id: campaign.body.campaign_id,
        configuration_digest: await sha256("phase5-configuration"),
        idempotency_key: crypto.randomUUID(),
      }),
    },
  );
  assert(stage.status === 200, `start stage failed: ${stage.status}`);

  const finishBody = {
    stage_token: stage.body.stage_token,
    outcome: "victory",
    score: 2400,
    duration_ms: 240000,
    idempotency_key: crypto.randomUUID(),
  };
  const finish = () =>
    jsonRequest(`${status.API_URL}/functions/v1/finish-stage`, {
      method: "POST",
      headers: authenticatedHeaders,
      body: JSON.stringify(finishBody),
    });
  const accepted = await finish();
  const retry = await finish();
  assert(accepted.status === 200, `finish stage failed: ${accepted.status}`);
  assert(
    accepted.body.unique_reward_id === "headless_horseman.spectral_trail",
    "level-one reward id was not returned",
  );
  assert(
    typeof accepted.body.unique_drop_granted === "boolean",
    "drop outcome was not explicit",
  );
  assert(
    JSON.stringify(accepted.body) === JSON.stringify(retry.body),
    "retry changed the persisted drop outcome",
  );

  const progress = await jsonRequest(
    `${status.API_URL}/rest/v1/boss_progress?select=victories,unique_reward_id,unique_reward_owned&character_id=eq.jano&boss_level=eq.1`,
    {
      method: "GET",
      headers: {
        ...authenticatedHeaders,
        Accept: "application/vnd.pgrst.object+json",
      },
    },
  );
  assert(progress.status === 200, `boss progress failed: ${progress.status}`);
  assert(progress.body.victories === 1, "retry incremented boss victories");
  assert(
    progress.body.unique_reward_owned === accepted.body.unique_drop_granted,
    "permanent ownership does not match the canonical drop outcome",
  );

  console.log(JSON.stringify({
    authenticated: true,
    level_one_reward_persisted: true,
    canonical_drop_retry: true,
    unique_drop_granted: accepted.body.unique_drop_granted,
    victories: progress.body.victories,
  }));
} finally {
  if (userId != null) {
    await fetch(`${status.API_URL}/auth/v1/admin/users/${userId}`, {
      method: "DELETE",
      headers: {
        apikey: status.SERVICE_ROLE_KEY,
        Authorization: `Bearer ${status.SERVICE_ROLE_KEY}`,
      },
    });
  }
}

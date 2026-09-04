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
  if (!output.success) throw new Error(new TextDecoder().decode(output.stderr));
  return JSON.parse(new TextDecoder().decode(output.stdout)) as LocalStatus;
}

async function requestJson(
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
const email = `phase6-${suffix}@example.com`;
const password = `Local-${suffix}-Password!`;
let userId: string | null = null;

try {
  const created = await requestJson(`${status.API_URL}/auth/v1/admin/users`, {
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
      user_metadata: { display_name: "Boss Rush Fixture" },
    }),
  });
  assert(created.status === 200, `create user failed: ${created.status}`);
  userId = String(created.body.id);

  const serviceHeaders = {
    apikey: status.SERVICE_ROLE_KEY,
    Authorization: `Bearer ${status.SERVICE_ROLE_KEY}`,
    "Content-Type": "application/json",
  };
  const entitlement = await fetch(
    `${status.API_URL}/rest/v1/character_progress`,
    {
      method: "POST",
      headers: { ...serviceHeaders, Prefer: "return=minimal" },
      body: JSON.stringify({
        user_id: userId,
        character_id: "jano",
        purchase_phase_unlocked: true,
      }),
    },
  );
  assert(
    entitlement.status === 201,
    `entitlement failed: ${entitlement.status}`,
  );

  const signedIn = await requestJson(
    `${status.API_URL}/auth/v1/token?grant_type=password`,
    {
      method: "POST",
      headers: { apikey: status.ANON_KEY, "Content-Type": "application/json" },
      body: JSON.stringify({ email, password }),
    },
  );
  assert(signedIn.status === 200, `sign in failed: ${signedIn.status}`);
  const authHeaders = {
    apikey: status.ANON_KEY,
    Authorization: `Bearer ${String(signedIn.body.access_token)}`,
    "Content-Type": "application/json",
  };

  const start = await requestJson(
    `${status.API_URL}/functions/v1/start-boss-rush`,
    {
      method: "POST",
      headers: authHeaders,
      body: JSON.stringify({
        character_id: "jano",
        content_version: "v6-preview-1",
        protocol_version: 1,
        loadout_digest: await sha256("phase6-loadout"),
        idempotency_key: crypto.randomUUID(),
      }),
    },
  );
  assert(start.status === 200, `start Boss Rush failed: ${start.status}`);

  const stage = await requestJson(
    `${status.API_URL}/functions/v1/start-stage`,
    {
      method: "POST",
      headers: authHeaders,
      body: JSON.stringify({
        campaign_id: start.body.campaign_id,
        configuration_digest: await sha256("phase6-configuration"),
        idempotency_key: crypto.randomUUID(),
      }),
    },
  );
  assert(stage.status === 200, `Boss Rush token failed: ${stage.status}`);

  const finishBody = {
    attempt_token: stage.body.stage_token,
    outcome: "defeat",
    bosses_defeated: 3,
    score: 9000,
    duration_ms: 420000,
    idempotency_key: crypto.randomUUID(),
  };
  const finish = () =>
    requestJson(`${status.API_URL}/functions/v1/finish-boss-rush`, {
      method: "POST",
      headers: authHeaders,
      body: JSON.stringify(finishBody),
    });
  const accepted = await finish();
  const retry = await finish();
  assert(
    accepted.status === 200,
    `finish Boss Rush failed: ${accepted.status}`,
  );
  assert(accepted.body.bosses_defeated === 3, "boss count was not canonical");
  assert(accepted.body.mastery_xp_granted === 60, "mastery was not reduced");
  assert(accepted.body.currency_granted === 0, "Boss Rush granted currency");
  assert(
    JSON.stringify(accepted.body) === JSON.stringify(retry.body),
    "Boss Rush retry changed its canonical response",
  );

  const progressResponse = await fetch(
    `${status.API_URL}/rest/v1/boss_progress?select=boss_level,victories&character_id=eq.jano&order=boss_level.asc`,
    { headers: authHeaders },
  );
  const progress = await progressResponse.json() as Array<
    Record<string, unknown>
  >;
  assert(progress.length === 3, "progress was not limited to defeated bosses");
  assert(
    progress.every((row) => row.victories === 1),
    "retry duplicated a victory",
  );

  const board = await requestJson(
    `${status.API_URL}/rest/v1/rpc/get_leaderboard_page`,
    {
      method: "POST",
      headers: authHeaders,
      body: JSON.stringify({
        p_character_id: "jano",
        p_mode: "boss_rush",
        p_content_version: "v6-preview-1",
        p_limit: 25,
      }),
    },
  );
  assert(board.status === 200, `Boss Rush leaderboard failed: ${board.status}`);
  const entries = board.body as unknown as Array<Record<string, unknown>>;
  assert(entries.length === 1, "Boss Rush best score was not published");
  assert(entries[0].mode === "boss_rush", "score leaked into another mode");

  console.log(JSON.stringify({
    authenticated: true,
    boss_rush_authorized: true,
    bosses_defeated: accepted.body.bosses_defeated,
    reduced_mastery: accepted.body.mastery_xp_granted,
    currency_granted: accepted.body.currency_granted,
    canonical_retry: true,
    separate_leaderboard: true,
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

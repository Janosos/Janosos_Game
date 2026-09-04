interface LocalStatus {
  API_URL: string;
  ANON_KEY: string;
  SERVICE_ROLE_KEY: string;
}

async function status(): Promise<LocalStatus> {
  const output = await new Deno.Command(
    Deno.build.os === "windows" ? "npx.cmd" : "npx",
    {
      args: ["supabase@latest", "status", "-o", "json"],
      cwd: Deno.cwd(),
      stdout: "piped",
      stderr: "piped",
    },
  ).output();
  if (!output.success) throw new Error(new TextDecoder().decode(output.stderr));
  return JSON.parse(new TextDecoder().decode(output.stdout)) as LocalStatus;
}

async function json(
  url: string,
  init: RequestInit,
): Promise<{ status: number; body: Record<string, unknown> }> {
  const response = await fetch(url, init);
  return {
    status: response.status,
    body: await response.json().catch(() => ({})) as Record<string, unknown>,
  };
}

async function digest(text: string): Promise<string> {
  const value = await crypto.subtle.digest(
    "SHA-256",
    new TextEncoder().encode(text),
  );
  return [...new Uint8Array(value)]
    .map((byte) => byte.toString(16).padStart(2, "0"))
    .join("");
}

function assert(value: unknown, message: string): asserts value {
  if (!value) throw new Error(message);
}

const local = await status();
const suffix = crypto.randomUUID();
const email = `chain-${suffix}@example.com`;
const password = `Chain-${suffix}-Password!`;
let userId: string | null = null;

try {
  const created = await json(`${local.API_URL}/auth/v1/admin/users`, {
    method: "POST",
    headers: {
      apikey: local.SERVICE_ROLE_KEY,
      Authorization: `Bearer ${local.SERVICE_ROLE_KEY}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      email,
      password,
      email_confirm: true,
      user_metadata: { display_name: "Campaign Chain Fixture" },
    }),
  });
  assert(created.status === 200, "fixture user was not created");
  userId = String(created.body.id);

  const login = await json(
    `${local.API_URL}/auth/v1/token?grant_type=password`,
    {
      method: "POST",
      headers: { apikey: local.ANON_KEY, "Content-Type": "application/json" },
      body: JSON.stringify({ email, password }),
    },
  );
  assert(login.status === 200, "fixture user could not sign in");
  const headers = {
    apikey: local.ANON_KEY,
    Authorization: `Bearer ${String(login.body.access_token)}`,
    "Content-Type": "application/json",
  };

  const campaign = await json(
    `${local.API_URL}/functions/v1/start-campaign`,
    {
      method: "POST",
      headers,
      body: JSON.stringify({
        character_id: "jano",
        mode: "progression",
        content_version: "v6-preview-1",
        protocol_version: 1,
        loadout_digest: await digest("campaign-chain-loadout"),
        idempotency_key: crypto.randomUUID(),
      }),
    },
  );
  assert(campaign.status === 200, "campaign did not start");

  let totalTemporaryCurrency = 0;
  for (let level = 1; level <= 10; level += 1) {
    const stage = await json(`${local.API_URL}/functions/v1/start-stage`, {
      method: "POST",
      headers,
      body: JSON.stringify({
        campaign_id: campaign.body.campaign_id,
        configuration_digest: await digest(`campaign-level-${level}`),
        idempotency_key: crypto.randomUUID(),
      }),
    });
    assert(stage.status === 200, `stage ${level} did not start`);
    assert(stage.body.sequence === level, `stage ${level} sequence drifted`);

    const finish = await json(`${local.API_URL}/functions/v1/finish-stage`, {
      method: "POST",
      headers,
      body: JSON.stringify({
        stage_token: stage.body.stage_token,
        outcome: "victory",
        score: 1000,
        duration_ms: 240000,
        idempotency_key: crypto.randomUUID(),
      }),
    });
    assert(finish.status === 200, `stage ${level} did not finish`);
    assert(
      finish.body.level_completed === level,
      `stage ${level} completion was not canonical`,
    );
    assert(
      finish.body.ready_to_complete === (level === 10),
      `stage ${level} completion readiness drifted`,
    );
    totalTemporaryCurrency = Number(finish.body.temporary_currency);
  }

  assert(totalTemporaryCurrency === 1000, "temporary currency total drifted");
  const completeBody = {
    campaign_id: campaign.body.campaign_id,
    idempotency_key: crypto.randomUUID(),
  };
  const complete = await json(
    `${local.API_URL}/functions/v1/complete-campaign`,
    { method: "POST", headers, body: JSON.stringify(completeBody) },
  );
  assert(complete.status === 200, "campaign could not be completed");
  assert(complete.body.banked_currency === 1000, "currency was not banked");
  assert(
    complete.body.purchase_phase_unlocked === true,
    "store and Boss Rush entitlement were not unlocked",
  );

  const progress = await json(
    `${local.API_URL}/rest/v1/character_progress?select=mastery_xp,banked_currency,purchase_phase_unlocked&character_id=eq.jano`,
    {
      method: "GET",
      headers: { ...headers, Accept: "application/vnd.pgrst.object+json" },
    },
  );
  assert(progress.status === 200, "final character progress was unavailable");
  assert(progress.body.mastery_xp === 1550, "ten-stage mastery total drifted");
  assert(progress.body.banked_currency === 1000, "banked balance drifted");
  assert(
    progress.body.purchase_phase_unlocked === true,
    "entitlement was lost",
  );

  console.log(JSON.stringify({
    authenticated: true,
    levels_completed: 10,
    mastery_xp: progress.body.mastery_xp,
    banked_currency: progress.body.banked_currency,
    boss_rush_unlocked: progress.body.purchase_phase_unlocked,
  }));
} finally {
  if (userId != null) {
    await fetch(`${local.API_URL}/auth/v1/admin/users/${userId}`, {
      method: "DELETE",
      headers: {
        apikey: local.SERVICE_ROLE_KEY,
        Authorization: `Bearer ${local.SERVICE_ROLE_KEY}`,
      },
    });
  }
}

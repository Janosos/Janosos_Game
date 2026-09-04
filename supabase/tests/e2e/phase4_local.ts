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
const email = `phase4-${suffix}@example.com`;
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
      user_metadata: { display_name: "Economy HTTP Fixture" },
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
  const serviceHeaders = {
    apikey: status.SERVICE_ROLE_KEY,
    Authorization: `Bearer ${status.SERVICE_ROLE_KEY}`,
    "Content-Type": "application/json",
  };

  const insertProgress = await fetch(
    `${status.API_URL}/rest/v1/character_progress`,
    {
      method: "POST",
      headers: { ...serviceHeaders, Prefer: "return=minimal" },
      body: JSON.stringify({
        user_id: userId,
        character_id: "jano",
        mastery_xp: 46500,
        banked_currency: 20000,
        purchase_phase_unlocked: false,
      }),
    },
  );
  assert(insertProgress.status === 201, "could not seed locked progress");

  const snapshotResponse = await jsonRequest(
    `${status.API_URL}/rest/v1/rpc/get_progression_snapshot`,
    {
      method: "POST",
      headers: authenticatedHeaders,
      body: JSON.stringify({
        p_character_id: "jano",
        p_content_version: "v6-preview-1",
      }),
    },
  );
  assert(snapshotResponse.status === 200, "initial snapshot failed");
  const catalogDigest = String(snapshotResponse.body.content_digest);
  assert(/^[0-9a-f]{64}$/.test(catalogDigest), "snapshot digest was invalid");

  const lockedUpgradeBody = {
    character_id: "jano",
    stat_id: "speed",
    expected_rank: 0,
    content_version: "v6-preview-1",
    catalog_digest: catalogDigest,
    idempotency_key: crypto.randomUUID(),
  };
  const lockedUpgrade = await jsonRequest(
    `${status.API_URL}/functions/v1/purchase-upgrade`,
    {
      method: "POST",
      headers: authenticatedHeaders,
      body: JSON.stringify(lockedUpgradeBody),
    },
  );
  assert(
    lockedUpgrade.status === 409 && lockedUpgrade.body.code === "store_locked",
    "store entitlement was not enforced over HTTP",
  );

  const unlockProgress = await fetch(
    `${status.API_URL}/rest/v1/character_progress?user_id=eq.${userId}&character_id=eq.jano`,
    {
      method: "PATCH",
      headers: { ...serviceHeaders, Prefer: "return=minimal" },
      body: JSON.stringify({ purchase_phase_unlocked: true }),
    },
  );
  assert(unlockProgress.status === 204, "could not unlock fixture store");

  const upgradeBody = {
    ...lockedUpgradeBody,
    idempotency_key: crypto.randomUUID(),
  };
  const purchaseUpgrade = () =>
    jsonRequest(`${status.API_URL}/functions/v1/purchase-upgrade`, {
      method: "POST",
      headers: authenticatedHeaders,
      body: JSON.stringify(upgradeBody),
    });
  const upgraded = await purchaseUpgrade();
  const upgradeRetry = await purchaseUpgrade();
  assert(upgraded.status === 200, `upgrade failed: ${upgraded.status}`);
  assert(
    JSON.stringify(upgraded.body) === JSON.stringify(upgradeRetry.body),
    "upgrade retry was not canonical",
  );

  const skillIds = [
    "jano_ricochet_round",
    "jano_quickdraw",
    "jano_scavenger_sight",
  ];
  for (const skillId of skillIds) {
    const purchased = await jsonRequest(
      `${status.API_URL}/functions/v1/purchase-skill`,
      {
        method: "POST",
        headers: authenticatedHeaders,
        body: JSON.stringify({
          character_id: "jano",
          skill_id: skillId,
          content_version: "v6-preview-1",
          catalog_digest: catalogDigest,
          idempotency_key: crypto.randomUUID(),
        }),
      },
    );
    assert(purchased.status === 200, `skill purchase failed: ${skillId}`);
  }

  const skinPurchase = await jsonRequest(
    `${status.API_URL}/functions/v1/purchase-skin`,
    {
      method: "POST",
      headers: authenticatedHeaders,
      body: JSON.stringify({
        character_id: "jano",
        skin_id: "jano_aurora",
        content_version: "v6-preview-1",
        catalog_digest: catalogDigest,
        idempotency_key: crypto.randomUUID(),
      }),
    },
  );
  assert(skinPurchase.status === 200, "palette purchase failed");

  const equipped = await jsonRequest(
    `${status.API_URL}/functions/v1/equip-loadout`,
    {
      method: "POST",
      headers: authenticatedHeaders,
      body: JSON.stringify({
        character_id: "jano",
        active_skill_id: "jano_ricochet_round",
        passive_skill_ids: ["jano_quickdraw", "jano_scavenger_sight"],
        skin_id: "jano_aurora",
        content_version: "v6-preview-1",
        catalog_digest: catalogDigest,
        idempotency_key: crypto.randomUUID(),
      }),
    },
  );
  assert(equipped.status === 200, "loadout equip failed");
  assert(
    /^[0-9a-f]{64}$/.test(String(equipped.body.loadout_digest)),
    "server did not return an authorized loadout digest",
  );

  const finalSnapshot = await jsonRequest(
    `${status.API_URL}/rest/v1/rpc/get_progression_snapshot`,
    {
      method: "POST",
      headers: authenticatedHeaders,
      body: JSON.stringify({
        p_character_id: "jano",
        p_content_version: "v6-preview-1",
      }),
    },
  );
  const skills = finalSnapshot.body.skills as Array<Record<string, unknown>>;
  assert(
    skills.filter((skill) => skill.owned === true).length === 3,
    "snapshot did not expose owned skills",
  );
  assert(
    !("premium_wallet" in finalSnapshot.body),
    "snapshot leaked a premium affordance",
  );

  const standardBuild = await jsonRequest(
    `${status.API_URL}/rest/v1/rpc/get_authorized_run_configuration`,
    {
      method: "POST",
      headers: serviceHeaders,
      body: JSON.stringify({
        p_user_id: userId,
        p_character_id: "jano",
        p_mode: "standard",
        p_content_version: "v6-preview-1",
      }),
    },
  );
  const standardStats = standardBuild.body.stats as Record<string, unknown>;
  const standardLoadout = standardBuild.body.loadout as Record<string, unknown>;
  assert(
    standardBuild.status === 200 && standardStats.speed_basis_points === 0,
    "Standard retained a purchased stat",
  );
  assert(
    Array.isArray(standardLoadout.passive_skill_ids) &&
      standardLoadout.passive_skill_ids.length === 0,
    "Standard retained a purchased passive",
  );

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
        loadout_digest: await sha256("untrusted-client-build"),
        idempotency_key: crypto.randomUUID(),
      }),
    },
  );
  assert(campaign.status === 200, "campaign with equipped build failed");

  const purchaseDuringCampaign = await jsonRequest(
    `${status.API_URL}/functions/v1/purchase-upgrade`,
    {
      method: "POST",
      headers: authenticatedHeaders,
      body: JSON.stringify({
        ...upgradeBody,
        expected_rank: 1,
        idempotency_key: crypto.randomUUID(),
      }),
    },
  );
  assert(
    purchaseDuringCampaign.status === 409 &&
      purchaseDuringCampaign.body.code === "campaign_active",
    "an active campaign allowed its build to mutate",
  );

  console.log(JSON.stringify({
    authenticated: true,
    store_entitlement_enforced: true,
    canonical_purchase_retry: true,
    exclusive_skills_owned: 3,
    palette_owned: true,
    loadout_equipped: true,
    standard_normalized: true,
    active_campaign_build_frozen: true,
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

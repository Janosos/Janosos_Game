interface LocalStatus {
  API_URL: string;
  ANON_KEY: string;
  SERVICE_ROLE_KEY: string;
}

interface Options {
  rps: number;
  seconds: number;
  maxP95Ms: number;
}

function optionNumber(name: string, fallback: number): number {
  const index = Deno.args.indexOf(`--${name}`);
  const raw = index < 0 ? undefined : Deno.args[index + 1];
  const value = raw === undefined ? fallback : Number(raw);
  if (!Number.isFinite(value) || value <= 0) {
    throw new Error(`--${name} must be a positive number`);
  }
  return value;
}

const options: Options = {
  rps: optionNumber("rps", 25),
  seconds: optionNumber("seconds", 10),
  maxP95Ms: optionNumber("max-p95-ms", 2000),
};

async function localStatus(): Promise<LocalStatus> {
  const command = new Deno.Command(
    Deno.build.os === "windows" ? "npx.cmd" : "npx",
    {
      args: ["supabase", "status", "-o", "json"],
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
): Promise<{ status: number; body: Record<string, unknown> }> {
  const response = await fetch(url, init);
  const body = await response.json().catch(() => ({})) as Record<
    string,
    unknown
  >;
  return { status: response.status, body };
}

function percentile(sorted: readonly number[], fraction: number): number {
  if (sorted.length === 0) return 0;
  return sorted[
    Math.min(sorted.length - 1, Math.ceil(sorted.length * fraction) - 1)
  ];
}

const status = await localStatus();
const suffix = crypto.randomUUID();
const email = `load-${suffix}@example.com`;
const password = `Load-${suffix}-Password!`;
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
      user_metadata: { display_name: "Load Fixture" },
    }),
  });
  if (created.status !== 200) throw new Error("unable to create load fixture");
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
  if (signedIn.status !== 200) {
    throw new Error("unable to sign in load fixture");
  }
  const accessToken = String(signedIn.body.access_token);
  const headers = {
    apikey: status.ANON_KEY,
    Authorization: `Bearer ${accessToken}`,
    "Content-Type": "application/json",
  };
  const body = JSON.stringify({
    p_character_id: "jano",
    p_mode: "progression",
    p_content_version: "v6-preview-1",
    p_limit: 25,
  });
  const total = Math.ceil(options.rps * options.seconds);
  const intervalMs = 1000 / options.rps;
  const startedAt = performance.now();
  const requests: Promise<{ ok: boolean; elapsedMs: number }>[] = [];

  for (let index = 0; index < total; index += 1) {
    const targetMs = startedAt + index * intervalMs;
    const waitMs = targetMs - performance.now();
    if (waitMs > 0) await new Promise((resolve) => setTimeout(resolve, waitMs));
    requests.push((async () => {
      const requestStarted = performance.now();
      const response = await fetch(
        `${status.API_URL}/rest/v1/rpc/get_leaderboard_page`,
        { method: "POST", headers, body },
      );
      await response.arrayBuffer();
      return {
        ok: response.status === 200,
        elapsedMs: performance.now() - requestStarted,
      };
    })());
  }

  const results = await Promise.all(requests);
  const latencies = results.map((result) => result.elapsedMs).sort((a, b) =>
    a - b
  );
  const failures = results.filter((result) => !result.ok).length;
  const p95Ms = percentile(latencies, 0.95);
  const summary = {
    requested_rps: options.rps,
    duration_seconds: options.seconds,
    requests: results.length,
    failures,
    p50_ms: Math.round(percentile(latencies, 0.5)),
    p95_ms: Math.round(p95Ms),
    p99_ms: Math.round(percentile(latencies, 0.99)),
  };
  console.log(JSON.stringify(summary));
  if (failures > 0 || p95Ms > options.maxP95Ms) Deno.exitCode = 1;
} finally {
  if (userId !== null) {
    await fetch(`${status.API_URL}/auth/v1/admin/users/${userId}`, {
      method: "DELETE",
      headers: {
        apikey: status.SERVICE_ROLE_KEY,
        Authorization: `Bearer ${status.SERVICE_ROLE_KEY}`,
      },
    });
  }
}

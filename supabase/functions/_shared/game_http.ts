import {
  createClient,
  type SupabaseClient,
  type User,
} from "npm:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const jsonHeaders = {
  ...corsHeaders,
  "Content-Type": "application/json; charset=utf-8",
  "Cache-Control": "no-store",
};

export interface AuthenticatedClients {
  user: User;
  userClient: SupabaseClient;
  adminClient: SupabaseClient;
}

export function jsonResponse(
  status: number,
  body: Record<string, unknown>,
): Response {
  return new Response(JSON.stringify(body), { status, headers: jsonHeaders });
}

export function optionsResponse(request: Request): Response | null {
  return request.method === "OPTIONS"
    ? new Response("ok", { headers: corsHeaders })
    : null;
}

export function requiredEnvironment(name: string): string {
  const value = Deno.env.get(name);
  if (!value) throw new Error(`Missing server environment: ${name}`);
  return value;
}

export async function authenticate(
  request: Request,
): Promise<AuthenticatedClients | Response> {
  const authorization = request.headers.get("Authorization") ?? "";
  if (!authorization.startsWith("Bearer ")) {
    return jsonResponse(401, { code: "authentication_required" });
  }
  const token = authorization.slice("Bearer ".length);
  const url = requiredEnvironment("SUPABASE_URL");
  const publishableKey = Deno.env.get("SUPABASE_PUBLISHABLE_KEY") ??
    requiredEnvironment("SUPABASE_ANON_KEY");
  const secretKey = Deno.env.get("SUPABASE_SECRET_KEY") ??
    requiredEnvironment("SUPABASE_SERVICE_ROLE_KEY");
  const userClient = createClient(url, publishableKey, {
    global: { headers: { Authorization: authorization } },
    auth: { autoRefreshToken: false, persistSession: false },
  });
  const { data, error } = await userClient.auth.getUser(token);
  if (error || !data.user) {
    return jsonResponse(401, { code: "authentication_required" });
  }
  const adminClient = createClient(url, secretKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });
  return { user: data.user, userClient, adminClient };
}

export async function readJsonObject(
  request: Request,
): Promise<Record<string, unknown> | Response> {
  const declaredLength = Number(request.headers.get("content-length") ?? "0");
  if (Number.isFinite(declaredLength) && declaredLength > 32 * 1024) {
    return jsonResponse(413, { code: "request_too_large" });
  }
  const body = await request.json().catch(() => null);
  if (!body || typeof body !== "object" || Array.isArray(body)) {
    return jsonResponse(400, { code: "invalid_json_body" });
  }
  return body as Record<string, unknown>;
}

export function isResponse(value: unknown): value is Response {
  return value instanceof Response;
}

export function requireUuid(
  value: unknown,
  field: string,
): string | Response {
  if (
    typeof value !== "string" ||
    !/^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i
      .test(value)
  ) {
    return jsonResponse(400, { code: `invalid_${field}` });
  }
  return value.toLowerCase();
}

export function requireDigest(
  value: unknown,
  field: string,
): string | Response {
  if (typeof value !== "string" || !/^[0-9a-f]{64}$/.test(value)) {
    return jsonResponse(400, { code: `invalid_${field}` });
  }
  return value;
}

export function requireInteger(
  value: unknown,
  field: string,
  minimum: number,
  maximum: number,
): number | Response {
  if (
    typeof value !== "number" || !Number.isSafeInteger(value) ||
    value < minimum || value > maximum
  ) {
    return jsonResponse(400, { code: `invalid_${field}` });
  }
  return value;
}

export function requireIdentifier(
  value: unknown,
  field: string,
  allowed?: ReadonlySet<string>,
): string | Response {
  if (
    typeof value !== "string" || !/^[a-z][a-z0-9_-]{0,47}$/.test(value) ||
    (allowed && !allowed.has(value))
  ) {
    return jsonResponse(400, { code: `invalid_${field}` });
  }
  return value;
}

export function databaseErrorResponse(
  error: { code?: string; message?: string } | null,
): Response {
  const message = error?.message ?? "";
  if (error?.code === "22023" || message.includes("idempotency key")) {
    return jsonResponse(409, { code: "idempotency_conflict" });
  }
  if (error?.code === "55000") {
    return jsonResponse(409, { code: "command_in_progress" });
  }
  console.error("Database command failed", {
    code: error?.code ?? "unknown",
  });
  return jsonResponse(500, { code: "database_command_failed" });
}

export function commandResponse(data: unknown): Response {
  if (!data || typeof data !== "object" || Array.isArray(data)) {
    return jsonResponse(500, { code: "invalid_command_response" });
  }
  const body = data as Record<string, unknown>;
  return jsonResponse(body.status === "rejected" ? 409 : 200, body);
}

function canonicalValue(value: unknown): unknown {
  if (Array.isArray(value)) return value.map(canonicalValue);
  if (value && typeof value === "object") {
    const source = value as Record<string, unknown>;
    return Object.fromEntries(
      Object.keys(source).sort().map((
        key,
      ) => [key, canonicalValue(source[key])]),
    );
  }
  return value;
}

export function requestDigest(value: unknown): Promise<string> {
  return sha256Text(JSON.stringify(canonicalValue(value)));
}

export async function sha256Text(value: string): Promise<string> {
  const bytes = new TextEncoder().encode(value);
  const digest = await crypto.subtle.digest("SHA-256", bytes);
  return Array.from(new Uint8Array(digest))
    .map((byte) => byte.toString(16).padStart(2, "0"))
    .join("");
}

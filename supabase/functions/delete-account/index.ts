import { createClient } from "npm:@supabase/supabase-js@2";
import { decodeJwt } from "npm:jose@6";

const recentAuthenticationWindowSeconds = 10 * 60;
const strongMethods = new Set(["password", "oauth", "otp", "totp", "recovery"]);

const jsonHeaders = {
  "Content-Type": "application/json; charset=utf-8",
  "Cache-Control": "no-store",
};

function response(status: number, body: Record<string, unknown>): Response {
  return new Response(JSON.stringify(body), { status, headers: jsonHeaders });
}

function requiredEnvironment(name: string): string {
  const value = Deno.env.get(name);
  if (!value) throw new Error(`Missing server environment: ${name}`);
  return value;
}

function hasRecentStrongAuthentication(
  token: string,
  nowSeconds: number,
): boolean {
  const claims = decodeJwt(token);
  const entries = Array.isArray(claims.amr) ? claims.amr : [];
  return entries.some((candidate) => {
    if (!candidate || typeof candidate !== "object") return false;
    const entry = candidate as { method?: unknown; timestamp?: unknown };
    return typeof entry.method === "string" &&
      strongMethods.has(entry.method) &&
      typeof entry.timestamp === "number" &&
      nowSeconds - entry.timestamp <= recentAuthenticationWindowSeconds &&
      entry.timestamp <= nowSeconds + 30;
  });
}

Deno.serve(async (request: Request) => {
  if (request.method !== "POST") {
    return response(405, { code: "method_not_allowed" });
  }

  const authorization = request.headers.get("Authorization") ?? "";
  if (!authorization.startsWith("Bearer ")) {
    return response(401, { code: "authentication_required" });
  }
  const token = authorization.slice("Bearer ".length);

  try {
    const url = requiredEnvironment("SUPABASE_URL");
    const publishableKey = Deno.env.get("SUPABASE_PUBLISHABLE_KEY") ??
      requiredEnvironment("SUPABASE_ANON_KEY");
    const secretKey = Deno.env.get("SUPABASE_SECRET_KEY") ??
      requiredEnvironment("SUPABASE_SERVICE_ROLE_KEY");

    const userClient = createClient(url, publishableKey, {
      global: { headers: { Authorization: authorization } },
      auth: { autoRefreshToken: false, persistSession: false },
    });
    const { data: userData, error: userError } = await userClient.auth.getUser(
      token,
    );
    if (userError || !userData.user) {
      return response(401, { code: "authentication_required" });
    }

    if (!hasRecentStrongAuthentication(token, Math.floor(Date.now() / 1000))) {
      return response(403, {
        code: "recent_authentication_required",
        message: "Vuelve a iniciar sesión antes de eliminar la cuenta.",
      });
    }

    const rawBody = await request.json().catch(() => null);
    const idempotencyKey = rawBody && typeof rawBody === "object"
      ? (rawBody as Record<string, unknown>).idempotency_key
      : null;
    if (
      typeof idempotencyKey !== "string" ||
      !/^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i
        .test(idempotencyKey)
    ) {
      return response(400, { code: "invalid_idempotency_key" });
    }

    const { data: receipts, error: receiptError } = await userClient.rpc(
      "begin_account_deletion",
      { p_idempotency_key: idempotencyKey },
    );
    if (receiptError || !Array.isArray(receipts) || receipts.length !== 1) {
      console.error("Unable to begin deletion", receiptError);
      return response(500, { code: "deletion_receipt_failed" });
    }

    const receipt = receipts[0] as { receipt_id: string; status: string };
    if (receipt.status === "completed") {
      return response(200, { deleted: true, receipt_id: receipt.receipt_id });
    }
    if (receipt.status === "failed") {
      return response(409, { code: "previous_deletion_attempt_failed" });
    }

    const adminClient = createClient(url, secretKey, {
      auth: { autoRefreshToken: false, persistSession: false },
    });
    const { error: deletionError } = await adminClient.auth.admin.deleteUser(
      userData.user.id,
    );
    if (deletionError) {
      console.error("Unable to delete auth user", deletionError);
      await adminClient.rpc("complete_account_deletion", {
        p_receipt_id: receipt.receipt_id,
        p_succeeded: false,
        p_failure_code: "auth_admin_delete_failed",
      });
      return response(500, { code: "account_deletion_failed" });
    }

    const { error: completionError } = await adminClient.rpc(
      "complete_account_deletion",
      {
        p_receipt_id: receipt.receipt_id,
        p_succeeded: true,
        p_failure_code: null,
      },
    );
    if (completionError) {
      // The account is already gone. Log this for repair without returning PII.
      console.error(
        "Account deleted but receipt completion failed",
        completionError,
      );
    }

    return response(200, { deleted: true, receipt_id: receipt.receipt_id });
  } catch (error) {
    console.error("Unexpected account deletion error", error);
    return response(500, { code: "internal_error" });
  }
});

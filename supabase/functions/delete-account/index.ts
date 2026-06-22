import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function jsonResponse(body: Record<string, unknown>, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders,
      "Content-Type": "application/json",
    },
  });
}

serve(async (request: Request) => {
  if (request.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (request.method !== "POST") {
    return jsonResponse({ error: "Method not allowed" }, 405);
  }

  const authorization = request.headers.get("Authorization");
  if (!authorization?.startsWith("Bearer ")) {
    return jsonResponse({ error: "Not authenticated" }, 401);
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

  if (!supabaseUrl || !anonKey || !serviceRoleKey) {
    return jsonResponse({ error: "Server is not configured" }, 500);
  }

  const userClient = createClient(supabaseUrl, anonKey, {
    global: {
      headers: {
        Authorization: authorization,
      },
    },
    auth: {
      persistSession: false,
    },
  });

  const {
    data: { user },
    error: userError,
  } = await userClient.auth.getUser();

  if (userError || !user) {
    return jsonResponse({ error: "Not authenticated" }, 401);
  }

  const adminClient = createClient(supabaseUrl, serviceRoleKey, {
    auth: {
      persistSession: false,
      autoRefreshToken: false,
    },
  });

  const { error: billPaymentsDeleteError } = await adminClient
    .from("bill_payments")
    .delete()
    .eq("user_id", user.id);

  if (billPaymentsDeleteError) {
    console.error("Failed to delete bill payments", billPaymentsDeleteError);
    return jsonResponse({ error: "Account deletion failed" }, 500);
  }

  const { error: billsDeleteError } = await adminClient
    .from("bills")
    .delete()
    .eq("user_id", user.id);

  if (billsDeleteError) {
    console.error("Failed to delete bills", billsDeleteError);
    return jsonResponse({ error: "Account deletion failed" }, 500);
  }

  const { error: subscriptionsDeleteError } = await adminClient
    .from("subscriptions")
    .delete()
    .eq("user_id", user.id);

  if (subscriptionsDeleteError) {
    console.error("Failed to delete subscriptions", subscriptionsDeleteError);
    return jsonResponse({ error: "Account deletion failed" }, 500);
  }

  const { error: recurringTransactionsDeleteError } = await adminClient
    .from("recurring_transactions")
    .delete()
    .eq("user_id", user.id);

  if (recurringTransactionsDeleteError) {
    console.error("Failed to delete recurring transactions", recurringTransactionsDeleteError);
    return jsonResponse({ error: "Account deletion failed" }, 500);
  }

  const { error: oneTimeTransactionsDeleteError } = await adminClient
    .from("one_time_transactions")
    .delete()
    .eq("user_id", user.id);

  if (oneTimeTransactionsDeleteError) {
    console.error("Failed to delete one-time transactions", oneTimeTransactionsDeleteError);
    return jsonResponse({ error: "Account deletion failed" }, 500);
  }

  const { error: financialCategoriesDeleteError } = await adminClient
    .from("financial_categories")
    .delete()
    .eq("user_id", user.id);

  if (financialCategoriesDeleteError) {
    console.error("Failed to delete financial categories", financialCategoriesDeleteError);
    return jsonResponse({ error: "Account deletion failed" }, 500);
  }

  const { error: seededCategoryOverridesDeleteError } = await adminClient
    .from("seeded_category_overrides")
    .delete()
    .eq("user_id", user.id);

  if (seededCategoryOverridesDeleteError) {
    console.error("Failed to delete seeded category overrides", seededCategoryOverridesDeleteError);
    return jsonResponse({ error: "Account deletion failed" }, 500);
  }

  const { error: savingsGoalsDeleteError } = await adminClient
    .from("savings_goals")
    .delete()
    .eq("user_id", user.id);

  if (savingsGoalsDeleteError) {
    console.error("Failed to delete savings goals", savingsGoalsDeleteError);
    return jsonResponse({ error: "Account deletion failed" }, 500);
  }

  const { error: notificationPrefsDeleteError } = await adminClient
    .from("notification_preferences")
    .delete()
    .eq("user_id", user.id);

  if (notificationPrefsDeleteError) {
    console.error("Failed to delete notification preferences", notificationPrefsDeleteError);
    return jsonResponse({ error: "Account deletion failed" }, 500);
  }

  const { error: userSettingsDeleteError } = await adminClient
    .from("user_settings")
    .delete()
    .eq("user_id", user.id);

  if (userSettingsDeleteError) {
    console.error("Failed to delete user settings", userSettingsDeleteError);
    return jsonResponse({ error: "Account deletion failed" }, 500);
  }

  const { error: profileDeleteError } = await adminClient
    .from("profiles")
    .delete()
    .eq("user_id", user.id);

  if (profileDeleteError) {
    console.error("Failed to delete profile", profileDeleteError);
    return jsonResponse({ error: "Account deletion failed" }, 500);
  }

  const { error: backupVersionsDeleteError } = await adminClient
    .from("user_backup_versions")
    .delete()
    .eq("user_id", user.id);

  if (backupVersionsDeleteError) {
    console.error("Failed to delete user backup versions", backupVersionsDeleteError);
    return jsonResponse({ error: "Account deletion failed" }, 500);
  }

  const { error: backupDeleteError } = await adminClient
    .from("user_backups")
    .delete()
    .eq("user_id", user.id);

  if (backupDeleteError) {
    console.error("Failed to delete user backup", backupDeleteError);
    return jsonResponse({ error: "Account deletion failed" }, 500);
  }

  const { error: userDeleteError } = await adminClient.auth.admin.deleteUser(user.id);

  if (userDeleteError) {
    console.error("Failed to delete auth user", userDeleteError);
    return jsonResponse({ error: "Account deletion failed" }, 500);
  }

  return jsonResponse({ deleted: true }, 200);
});

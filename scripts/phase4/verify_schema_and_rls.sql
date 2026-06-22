-- BudgetMeter Phase 4 post-deploy verification
-- Run in Supabase Dashboard → SQL Editor after migrations 0001-0009 are applied.
-- Read-only audit queries; safe to run on production for inspection.

-- 1) Expected user-owned tables exist
SELECT tablename
FROM pg_tables
WHERE schemaname = 'public'
  AND tablename IN (
    'profiles',
    'user_settings',
    'notification_preferences',
    'savings_goals',
    'subscriptions',
    'bills',
    'bill_payments',
    'recurring_transactions',
    'one_time_transactions',
    'financial_categories',
    'seeded_category_overrides',
    'user_backups',
    'user_backup_versions'
  )
ORDER BY tablename;

-- 2) RLS enabled on all public user tables above
SELECT c.relname AS table_name, c.relrowsecurity AS rls_enabled
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = 'public'
  AND c.relkind = 'r'
  AND c.relname IN (
    'profiles', 'user_settings', 'notification_preferences',
    'savings_goals', 'subscriptions', 'bills', 'bill_payments',
    'recurring_transactions', 'one_time_transactions',
    'financial_categories', 'seeded_category_overrides',
    'user_backups', 'user_backup_versions'
  )
ORDER BY c.relname;

-- 3) Policy inventory (expect authenticated SELECT/INSERT/UPDATE on sync tables)
SELECT schemaname, tablename, policyname, cmd, roles
FROM pg_policies
WHERE schemaname = 'public'
ORDER BY tablename, policyname;

-- 4) Financial sync tables should NOT expose broad anon policies
SELECT tablename, policyname, roles
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename IN (
    'savings_goals', 'subscriptions', 'bills', 'bill_payments',
    'recurring_transactions', 'one_time_transactions',
    'financial_categories', 'seeded_category_overrides'
  )
  AND roles::text ILIKE '%anon%';

-- 5) updated_at triggers on tables that define updated_at column
SELECT t.tgname AS trigger_name, c.relname AS table_name
FROM pg_trigger t
JOIN pg_class c ON t.tgrelid = c.oid
JOIN pg_namespace n ON c.relnamespace = n.oid
WHERE n.nspname = 'public'
  AND NOT t.tgisinternal
  AND t.tgname ILIKE '%updated_at%'
ORDER BY c.relname;

-- 6) Unique constraints for sync identity (spot check)
SELECT conrelid::regclass AS table_name, conname
FROM pg_constraint
WHERE connamespace = 'public'::regnamespace
  AND contype = 'u'
  AND conrelid::regclass::text IN (
    'savings_goals', 'subscriptions', 'bills', 'bill_payments',
    'recurring_transactions', 'one_time_transactions',
    'financial_categories', 'seeded_category_overrides'
  )
ORDER BY table_name, conname;

-- 7) set_updated_at function exists
SELECT proname, prosecdef AS security_definer
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public' AND proname = 'set_updated_at';

-- Pass criteria (manual):
-- - All 13 tables present
-- - rls_enabled = true for all 13
-- - Query 4 returns zero rows (no anon policies on financial sync tables)
-- - Financial tables have no DELETE policies (soft delete via client upsert only)
-- - Triggers present on tables with updated_at

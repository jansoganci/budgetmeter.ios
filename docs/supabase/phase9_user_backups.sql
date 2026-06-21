-- Phase 9: Supabase backup/sync schema and RLS
-- Legacy draft kept for context.
-- Prefer the ordered migration files in supabase/migrations/:
-- 0001_user_backups_base.sql
-- 0002_user_backup_versions.sql
-- 0003_backup_version_capture_trigger.sql

create table if not exists public.user_backups (
    user_id uuid primary key references auth.users(id) on delete cascade,
    schema_version integer not null,
    app_version text not null,
    payload jsonb not null,
    record_counts jsonb not null,
    updated_at timestamptz not null default now()
);

alter table public.user_backups enable row level security;

create policy "Users can read own backup"
    on public.user_backups
    for select
    using (auth.uid() = user_id);

create policy "Users can insert own backup"
    on public.user_backups
    for insert
    with check (auth.uid() = user_id);

create policy "Users can update own backup"
    on public.user_backups
    for update
    using (auth.uid() = user_id)
    with check (auth.uid() = user_id);

create policy "Users can delete own backup"
    on public.user_backups
    for delete
    using (auth.uid() = user_id);

-- Account deletion is handled by the `delete-account` Supabase Edge Function.
-- Do not expose SECURITY DEFINER account-deletion functions through PostgREST.
drop function if exists public.delete_own_account();

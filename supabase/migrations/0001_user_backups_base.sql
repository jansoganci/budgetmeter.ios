-- BudgetMeter Supabase migration 0001
-- Base latest-backup table for premium manual cloud backup/restore.
-- Safe to run after the older docs/supabase/phase9_user_backups.sql draft.

create table if not exists public.user_backups (
    user_id uuid primary key references auth.users(id) on delete cascade,
    schema_version integer not null,
    app_version text not null,
    payload jsonb not null,
    record_counts jsonb not null,
    updated_at timestamptz not null default now()
);

alter table public.user_backups
    add column if not exists created_at timestamptz not null default now(),
    add column if not exists deleted_at timestamptz,
    add column if not exists backup_count integer not null default 0,
    add column if not exists latest_backup_version_id uuid;

alter table public.user_backups
    add constraint user_backups_schema_version_positive
    check (schema_version > 0) not valid;

alter table public.user_backups
    add constraint user_backups_payload_is_object
    check (jsonb_typeof(payload) = 'object') not valid;

alter table public.user_backups
    add constraint user_backups_record_counts_is_object
    check (jsonb_typeof(record_counts) = 'object') not valid;

create index if not exists user_backups_updated_at_idx
    on public.user_backups (user_id, updated_at desc);

create index if not exists user_backups_deleted_at_idx
    on public.user_backups (user_id, deleted_at);

alter table public.user_backups enable row level security;

do $$
begin
    if not exists (
        select 1 from pg_policies
        where schemaname = 'public'
          and tablename = 'user_backups'
          and policyname = 'Users can read own backup'
    ) then
        create policy "Users can read own backup"
            on public.user_backups
            for select
            using (auth.uid() = user_id);
    end if;

    if not exists (
        select 1 from pg_policies
        where schemaname = 'public'
          and tablename = 'user_backups'
          and policyname = 'Users can insert own backup'
    ) then
        create policy "Users can insert own backup"
            on public.user_backups
            for insert
            with check (auth.uid() = user_id);
    end if;

    if not exists (
        select 1 from pg_policies
        where schemaname = 'public'
          and tablename = 'user_backups'
          and policyname = 'Users can update own backup'
    ) then
        create policy "Users can update own backup"
            on public.user_backups
            for update
            using (auth.uid() = user_id)
            with check (auth.uid() = user_id);
    end if;

    if not exists (
        select 1 from pg_policies
        where schemaname = 'public'
          and tablename = 'user_backups'
          and policyname = 'Users can delete own backup'
    ) then
        create policy "Users can delete own backup"
            on public.user_backups
            for delete
            using (auth.uid() = user_id);
    end if;
end $$;

-- Account deletion is handled by the delete-account Edge Function.
-- Do not expose SECURITY DEFINER account-deletion functions through PostgREST.
drop function if exists public.delete_own_account();

comment on table public.user_backups is
    'Latest BudgetMeter cloud backup per authenticated user. Historical versions live in public.user_backup_versions.';


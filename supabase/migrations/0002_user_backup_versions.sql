-- BudgetMeter Supabase migration 0002
-- Append-only backup snapshot history for data-loss protection.

create extension if not exists pgcrypto with schema extensions;

create table if not exists public.user_backup_versions (
    id uuid primary key default extensions.gen_random_uuid(),
    user_id uuid not null references auth.users(id) on delete cascade,
    schema_version integer not null,
    app_version text not null,
    payload jsonb not null,
    record_counts jsonb not null,
    backup_reason text not null default 'manual_backup',
    is_restorable boolean not null default true,
    created_at timestamptz not null default now(),
    deleted_at timestamptz,
    restored_at timestamptz,
    payload_sha256 text
);

alter table public.user_backup_versions
    add constraint user_backup_versions_schema_version_positive
    check (schema_version > 0) not valid;

alter table public.user_backup_versions
    add constraint user_backup_versions_payload_is_object
    check (jsonb_typeof(payload) = 'object') not valid;

alter table public.user_backup_versions
    add constraint user_backup_versions_record_counts_is_object
    check (jsonb_typeof(record_counts) = 'object') not valid;

alter table public.user_backup_versions
    add constraint user_backup_versions_backup_reason_known
    check (backup_reason in ('manual_backup', 'restore_snapshot', 'migration', 'unknown')) not valid;

create index if not exists user_backup_versions_user_created_idx
    on public.user_backup_versions (user_id, created_at desc);

create index if not exists user_backup_versions_user_restorable_idx
    on public.user_backup_versions (user_id, is_restorable, deleted_at, created_at desc);

alter table public.user_backup_versions enable row level security;

do $$
begin
    if not exists (
        select 1 from pg_policies
        where schemaname = 'public'
          and tablename = 'user_backup_versions'
          and policyname = 'Users can read own backup versions'
    ) then
        create policy "Users can read own backup versions"
            on public.user_backup_versions
            for select
            using (auth.uid() = user_id);
    end if;

    if not exists (
        select 1 from pg_policies
        where schemaname = 'public'
          and tablename = 'user_backup_versions'
          and policyname = 'Users can insert own backup versions'
    ) then
        create policy "Users can insert own backup versions"
            on public.user_backup_versions
            for insert
            with check (auth.uid() = user_id);
    end if;

    if not exists (
        select 1 from pg_policies
        where schemaname = 'public'
          and tablename = 'user_backup_versions'
          and policyname = 'Users can update own backup versions'
    ) then
        create policy "Users can update own backup versions"
            on public.user_backup_versions
            for update
            using (auth.uid() = user_id)
            with check (auth.uid() = user_id);
    end if;

    if not exists (
        select 1 from pg_policies
        where schemaname = 'public'
          and tablename = 'user_backup_versions'
          and policyname = 'Users can delete own backup versions'
    ) then
        create policy "Users can delete own backup versions"
            on public.user_backup_versions
            for delete
            using (auth.uid() = user_id);
    end if;
end $$;

comment on table public.user_backup_versions is
    'Versioned BudgetMeter cloud backup snapshots. Account deletion must hard-delete these rows.';

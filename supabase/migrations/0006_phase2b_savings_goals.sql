-- BudgetMeter Supabase migration 0006
-- Phase 2B savings_goals financial sync table.

create table if not exists public.savings_goals (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references auth.users(id) on delete cascade default auth.uid(),
    client_record_id text not null,
    name text not null,
    target_amount numeric not null,
    current_amount numeric not null default 0,
    target_date date,
    emoji text,
    color_hex text,
    priority integer,
    is_archived boolean not null default false,
    archived_date timestamptz,
    completed_date timestamptz,
    notes text,
    category_label text,
    monthly_contribution numeric,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    deleted_at timestamptz
);

do $$
begin
    if not exists (
        select 1 from pg_constraint
        where conname = 'savings_goals_user_id_client_record_id_key'
          and conrelid = 'public.savings_goals'::regclass
    ) then
        alter table public.savings_goals
            add constraint savings_goals_user_id_client_record_id_key
            unique (user_id, client_record_id);
    end if;

    if not exists (
        select 1 from pg_constraint
        where conname = 'savings_goals_name_non_empty'
          and conrelid = 'public.savings_goals'::regclass
    ) then
        alter table public.savings_goals
            add constraint savings_goals_name_non_empty
            check (btrim(name) <> '') not valid;
    end if;

    if not exists (
        select 1 from pg_constraint
        where conname = 'savings_goals_target_amount_non_negative'
          and conrelid = 'public.savings_goals'::regclass
    ) then
        alter table public.savings_goals
            add constraint savings_goals_target_amount_non_negative
            check (target_amount >= 0) not valid;
    end if;

    if not exists (
        select 1 from pg_constraint
        where conname = 'savings_goals_current_amount_non_negative'
          and conrelid = 'public.savings_goals'::regclass
    ) then
        alter table public.savings_goals
            add constraint savings_goals_current_amount_non_negative
            check (current_amount >= 0) not valid;
    end if;

    if not exists (
        select 1 from pg_constraint
        where conname = 'savings_goals_monthly_contribution_non_negative'
          and conrelid = 'public.savings_goals'::regclass
    ) then
        alter table public.savings_goals
            add constraint savings_goals_monthly_contribution_non_negative
            check (monthly_contribution is null or monthly_contribution >= 0) not valid;
    end if;

    if not exists (
        select 1 from pg_constraint
        where conname = 'savings_goals_priority_non_negative'
          and conrelid = 'public.savings_goals'::regclass
    ) then
        alter table public.savings_goals
            add constraint savings_goals_priority_non_negative
            check (priority is null or priority >= 0) not valid;
    end if;

    if not exists (
        select 1 from pg_constraint
        where conname = 'savings_goals_color_hex_format'
          and conrelid = 'public.savings_goals'::regclass
    ) then
        alter table public.savings_goals
            add constraint savings_goals_color_hex_format
            check (
                color_hex is null
                or color_hex ~ '^#[0-9A-Fa-f]{6}([0-9A-Fa-f]{2})?$'
            ) not valid;
    end if;
end $$;

create index if not exists savings_goals_user_id_updated_at_idx
    on public.savings_goals (user_id, updated_at desc);

create index if not exists savings_goals_user_id_deleted_at_idx
    on public.savings_goals (user_id, deleted_at);

create index if not exists savings_goals_user_id_is_archived_idx
    on public.savings_goals (user_id, is_archived);

create index if not exists savings_goals_user_id_target_date_idx
    on public.savings_goals (user_id, target_date);

alter table public.savings_goals enable row level security;

do $$
begin
    if not exists (
        select 1 from pg_policies
        where schemaname = 'public'
          and tablename = 'savings_goals'
          and policyname = 'SavingsGoals: users can read own rows'
    ) then
        create policy "SavingsGoals: users can read own rows"
            on public.savings_goals
            for select
            to authenticated
            using (auth.uid() = user_id);
    end if;

    if not exists (
        select 1 from pg_policies
        where schemaname = 'public'
          and tablename = 'savings_goals'
          and policyname = 'SavingsGoals: users can insert own rows'
    ) then
        create policy "SavingsGoals: users can insert own rows"
            on public.savings_goals
            for insert
            to authenticated
            with check (auth.uid() = user_id);
    end if;

    if not exists (
        select 1 from pg_policies
        where schemaname = 'public'
          and tablename = 'savings_goals'
          and policyname = 'SavingsGoals: users can update own rows'
    ) then
        create policy "SavingsGoals: users can update own rows"
            on public.savings_goals
            for update
            to authenticated
            using (auth.uid() = user_id)
            with check (auth.uid() = user_id);
    end if;
end $$;

drop trigger if exists set_savings_goals_updated_at on public.savings_goals;
create trigger set_savings_goals_updated_at
    before update on public.savings_goals
    for each row
    execute function public.set_updated_at();

comment on table public.savings_goals is
    'Phase 2B financial sync table for account-owned savings goals. Uses client_record_id for cross-device identity and deleted_at tombstones for sync-safe deletes.';

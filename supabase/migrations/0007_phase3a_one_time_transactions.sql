-- BudgetMeter Supabase migration 0007
-- Phase 3A one_time_transactions financial sync table.

create table if not exists public.one_time_transactions (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references auth.users(id) on delete cascade default auth.uid(),
    client_record_id text not null,
    type text not null,
    amount numeric not null,
    occurrence_date timestamptz not null,
    category_key text,
    category_label text not null,
    custom_icon_name text,
    custom_color_hex text,
    source_type text,
    source_client_record_id text,
    notes text,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    deleted_at timestamptz
);

do $$
begin
    if not exists (
        select 1 from pg_constraint
        where conname = 'one_time_transactions_user_id_client_record_id_key'
          and conrelid = 'public.one_time_transactions'::regclass
    ) then
        alter table public.one_time_transactions
            add constraint one_time_transactions_user_id_client_record_id_key
            unique (user_id, client_record_id);
    end if;

    if not exists (
        select 1 from pg_constraint
        where conname = 'one_time_transactions_type_allowed'
          and conrelid = 'public.one_time_transactions'::regclass
    ) then
        alter table public.one_time_transactions
            add constraint one_time_transactions_type_allowed
            check (type in ('income', 'expense')) not valid;
    end if;

    if not exists (
        select 1 from pg_constraint
        where conname = 'one_time_transactions_amount_non_negative'
          and conrelid = 'public.one_time_transactions'::regclass
    ) then
        alter table public.one_time_transactions
            add constraint one_time_transactions_amount_non_negative
            check (amount >= 0) not valid;
    end if;

    if not exists (
        select 1 from pg_constraint
        where conname = 'one_time_transactions_category_label_non_empty'
          and conrelid = 'public.one_time_transactions'::regclass
    ) then
        alter table public.one_time_transactions
            add constraint one_time_transactions_category_label_non_empty
            check (btrim(category_label) <> '') not valid;
    end if;

    if not exists (
        select 1 from pg_constraint
        where conname = 'one_time_transactions_client_record_id_non_empty'
          and conrelid = 'public.one_time_transactions'::regclass
    ) then
        alter table public.one_time_transactions
            add constraint one_time_transactions_client_record_id_non_empty
            check (btrim(client_record_id) <> '') not valid;
    end if;
end $$;

create index if not exists one_time_transactions_user_id_updated_at_idx
    on public.one_time_transactions (user_id, updated_at desc);

create index if not exists one_time_transactions_user_id_deleted_at_idx
    on public.one_time_transactions (user_id, deleted_at);

create index if not exists one_time_transactions_user_id_occurrence_date_idx
    on public.one_time_transactions (user_id, occurrence_date desc);

create index if not exists one_time_transactions_user_id_type_occurrence_date_idx
    on public.one_time_transactions (user_id, type, occurrence_date desc);

create index if not exists one_time_transactions_user_id_category_key_idx
    on public.one_time_transactions (user_id, category_key);

alter table public.one_time_transactions enable row level security;

do $$
begin
    if not exists (
        select 1 from pg_policies
        where schemaname = 'public'
          and tablename = 'one_time_transactions'
          and policyname = 'OneTimeTransactions: users can read own rows'
    ) then
        create policy "OneTimeTransactions: users can read own rows"
            on public.one_time_transactions
            for select
            to authenticated
            using (auth.uid() = user_id);
    end if;

    if not exists (
        select 1 from pg_policies
        where schemaname = 'public'
          and tablename = 'one_time_transactions'
          and policyname = 'OneTimeTransactions: users can insert own rows'
    ) then
        create policy "OneTimeTransactions: users can insert own rows"
            on public.one_time_transactions
            for insert
            to authenticated
            with check (auth.uid() = user_id);
    end if;

    if not exists (
        select 1 from pg_policies
        where schemaname = 'public'
          and tablename = 'one_time_transactions'
          and policyname = 'OneTimeTransactions: users can update own rows'
    ) then
        create policy "OneTimeTransactions: users can update own rows"
            on public.one_time_transactions
            for update
            to authenticated
            using (auth.uid() = user_id)
            with check (auth.uid() = user_id);
    end if;
end $$;

drop trigger if exists set_one_time_transactions_updated_at on public.one_time_transactions;
create trigger set_one_time_transactions_updated_at
    before update on public.one_time_transactions
    for each row
    execute function public.set_updated_at();

comment on table public.one_time_transactions is
    'Phase 3A financial sync table for one-time income and expense entries. Uses client_record_id for cross-device identity and deleted_at tombstones for sync-safe deletes.';

comment on column public.one_time_transactions.custom_color_hex is
    'Optional color snapshot. Local app may store palette keys (e.g. blue) or hex strings; no strict hex-only DB constraint in Phase 3A.';

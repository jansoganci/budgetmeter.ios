-- BudgetMeter Supabase migration 0008
-- Phase 2C remaining financial sync: subscriptions, bills, bill_payments, recurring_transactions.

-- subscriptions
create table if not exists public.subscriptions (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references auth.users(id) on delete cascade default auth.uid(),
    client_record_id text not null,
    name text not null,
    amount numeric not null,
    billing_cycle text not null default 'monthly',
    custom_cycle_days integer not null default 0,
    first_bill_date timestamptz,
    next_renewal_date timestamptz,
    category_label text,
    notes text,
    reminder_days_before integer not null default 3,
    is_active boolean not null default true,
    is_paused boolean not null default false,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    deleted_at timestamptz
);

-- bills
create table if not exists public.bills (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references auth.users(id) on delete cascade default auth.uid(),
    client_record_id text not null,
    name text not null,
    amount numeric not null,
    is_recurring boolean not null default false,
    frequency text,
    due_date timestamptz,
    original_due_date timestamptz,
    category_label text,
    icon_name text,
    color_hex text,
    notes text,
    reminder_days_before integer not null default 3,
    is_paid boolean not null default false,
    paid_date timestamptz,
    paid_amount numeric not null default 0,
    is_auto_pay boolean not null default false,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    deleted_at timestamptz
);

-- bill_payments
create table if not exists public.bill_payments (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references auth.users(id) on delete cascade default auth.uid(),
    client_record_id text not null,
    bill_client_record_id text not null,
    due_date timestamptz,
    paid_date timestamptz,
    expected_amount numeric not null default 0,
    actual_amount numeric not null default 0,
    notes text,
    was_late boolean not null default false,
    days_late integer not null default 0,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    deleted_at timestamptz
);

-- recurring_transactions
create table if not exists public.recurring_transactions (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references auth.users(id) on delete cascade default auth.uid(),
    client_record_id text not null,
    title text not null,
    amount numeric not null,
    category_name text,
    category_type text,
    frequency text,
    start_date timestamptz,
    end_date timestamptz,
    next_due_date timestamptz,
    is_active boolean not null default true,
    notes text,
    last_processed_date timestamptz,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    deleted_at timestamptz
);

do $$
begin
    -- subscriptions constraints
    if not exists (select 1 from pg_constraint where conname = 'subscriptions_user_id_client_record_id_key') then
        alter table public.subscriptions add constraint subscriptions_user_id_client_record_id_key unique (user_id, client_record_id);
    end if;
    if not exists (select 1 from pg_constraint where conname = 'subscriptions_name_non_empty') then
        alter table public.subscriptions add constraint subscriptions_name_non_empty check (btrim(name) <> '') not valid;
    end if;
    if not exists (select 1 from pg_constraint where conname = 'subscriptions_amount_non_negative') then
        alter table public.subscriptions add constraint subscriptions_amount_non_negative check (amount >= 0) not valid;
    end if;

    -- bills constraints
    if not exists (select 1 from pg_constraint where conname = 'bills_user_id_client_record_id_key') then
        alter table public.bills add constraint bills_user_id_client_record_id_key unique (user_id, client_record_id);
    end if;
    if not exists (select 1 from pg_constraint where conname = 'bills_name_non_empty') then
        alter table public.bills add constraint bills_name_non_empty check (btrim(name) <> '') not valid;
    end if;
    if not exists (select 1 from pg_constraint where conname = 'bills_amount_non_negative') then
        alter table public.bills add constraint bills_amount_non_negative check (amount >= 0) not valid;
    end if;

    -- bill_payments constraints
    if not exists (select 1 from pg_constraint where conname = 'bill_payments_user_id_client_record_id_key') then
        alter table public.bill_payments add constraint bill_payments_user_id_client_record_id_key unique (user_id, client_record_id);
    end if;
    if not exists (select 1 from pg_constraint where conname = 'bill_payments_bill_client_record_id_non_empty') then
        alter table public.bill_payments add constraint bill_payments_bill_client_record_id_non_empty check (btrim(bill_client_record_id) <> '') not valid;
    end if;

    -- recurring_transactions constraints
    if not exists (select 1 from pg_constraint where conname = 'recurring_transactions_user_id_client_record_id_key') then
        alter table public.recurring_transactions add constraint recurring_transactions_user_id_client_record_id_key unique (user_id, client_record_id);
    end if;
    if not exists (select 1 from pg_constraint where conname = 'recurring_transactions_title_non_empty') then
        alter table public.recurring_transactions add constraint recurring_transactions_title_non_empty check (btrim(title) <> '') not valid;
    end if;
    if not exists (select 1 from pg_constraint where conname = 'recurring_transactions_amount_non_negative') then
        alter table public.recurring_transactions add constraint recurring_transactions_amount_non_negative check (amount >= 0) not valid;
    end if;
end $$;

create index if not exists subscriptions_user_id_updated_at_idx on public.subscriptions (user_id, updated_at desc);
create index if not exists subscriptions_user_id_deleted_at_idx on public.subscriptions (user_id, deleted_at);
create index if not exists subscriptions_user_id_is_active_idx on public.subscriptions (user_id, is_active);
create index if not exists subscriptions_user_id_next_renewal_date_idx on public.subscriptions (user_id, next_renewal_date);

create index if not exists bills_user_id_updated_at_idx on public.bills (user_id, updated_at desc);
create index if not exists bills_user_id_deleted_at_idx on public.bills (user_id, deleted_at);
create index if not exists bills_user_id_due_date_idx on public.bills (user_id, due_date);
create index if not exists bills_user_id_is_paid_idx on public.bills (user_id, is_paid);

create index if not exists bill_payments_user_id_updated_at_idx on public.bill_payments (user_id, updated_at desc);
create index if not exists bill_payments_user_id_deleted_at_idx on public.bill_payments (user_id, deleted_at);
create index if not exists bill_payments_user_id_bill_client_record_id_idx on public.bill_payments (user_id, bill_client_record_id);
create index if not exists bill_payments_user_id_paid_date_idx on public.bill_payments (user_id, paid_date);

create index if not exists recurring_transactions_user_id_updated_at_idx on public.recurring_transactions (user_id, updated_at desc);
create index if not exists recurring_transactions_user_id_deleted_at_idx on public.recurring_transactions (user_id, deleted_at);
create index if not exists recurring_transactions_user_id_next_due_date_idx on public.recurring_transactions (user_id, next_due_date);
create index if not exists recurring_transactions_user_id_is_active_idx on public.recurring_transactions (user_id, is_active);

alter table public.subscriptions enable row level security;
alter table public.bills enable row level security;
alter table public.bill_payments enable row level security;
alter table public.recurring_transactions enable row level security;

do $$
begin
    if not exists (select 1 from pg_policies where schemaname = 'public' and tablename = 'subscriptions' and policyname = 'Subscriptions: users can read own rows') then
        create policy "Subscriptions: users can read own rows" on public.subscriptions for select to authenticated using (auth.uid() = user_id);
    end if;
    if not exists (select 1 from pg_policies where schemaname = 'public' and tablename = 'subscriptions' and policyname = 'Subscriptions: users can insert own rows') then
        create policy "Subscriptions: users can insert own rows" on public.subscriptions for insert to authenticated with check (auth.uid() = user_id);
    end if;
    if not exists (select 1 from pg_policies where schemaname = 'public' and tablename = 'subscriptions' and policyname = 'Subscriptions: users can update own rows') then
        create policy "Subscriptions: users can update own rows" on public.subscriptions for update to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);
    end if;

    if not exists (select 1 from pg_policies where schemaname = 'public' and tablename = 'bills' and policyname = 'Bills: users can read own rows') then
        create policy "Bills: users can read own rows" on public.bills for select to authenticated using (auth.uid() = user_id);
    end if;
    if not exists (select 1 from pg_policies where schemaname = 'public' and tablename = 'bills' and policyname = 'Bills: users can insert own rows') then
        create policy "Bills: users can insert own rows" on public.bills for insert to authenticated with check (auth.uid() = user_id);
    end if;
    if not exists (select 1 from pg_policies where schemaname = 'public' and tablename = 'bills' and policyname = 'Bills: users can update own rows') then
        create policy "Bills: users can update own rows" on public.bills for update to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);
    end if;

    if not exists (select 1 from pg_policies where schemaname = 'public' and tablename = 'bill_payments' and policyname = 'BillPayments: users can read own rows') then
        create policy "BillPayments: users can read own rows" on public.bill_payments for select to authenticated using (auth.uid() = user_id);
    end if;
    if not exists (select 1 from pg_policies where schemaname = 'public' and tablename = 'bill_payments' and policyname = 'BillPayments: users can insert own rows') then
        create policy "BillPayments: users can insert own rows" on public.bill_payments for insert to authenticated with check (auth.uid() = user_id);
    end if;
    if not exists (select 1 from pg_policies where schemaname = 'public' and tablename = 'bill_payments' and policyname = 'BillPayments: users can update own rows') then
        create policy "BillPayments: users can update own rows" on public.bill_payments for update to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);
    end if;

    if not exists (select 1 from pg_policies where schemaname = 'public' and tablename = 'recurring_transactions' and policyname = 'RecurringTransactions: users can read own rows') then
        create policy "RecurringTransactions: users can read own rows" on public.recurring_transactions for select to authenticated using (auth.uid() = user_id);
    end if;
    if not exists (select 1 from pg_policies where schemaname = 'public' and tablename = 'recurring_transactions' and policyname = 'RecurringTransactions: users can insert own rows') then
        create policy "RecurringTransactions: users can insert own rows" on public.recurring_transactions for insert to authenticated with check (auth.uid() = user_id);
    end if;
    if not exists (select 1 from pg_policies where schemaname = 'public' and tablename = 'recurring_transactions' and policyname = 'RecurringTransactions: users can update own rows') then
        create policy "RecurringTransactions: users can update own rows" on public.recurring_transactions for update to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);
    end if;
end $$;

drop trigger if exists set_subscriptions_updated_at on public.subscriptions;
create trigger set_subscriptions_updated_at before update on public.subscriptions for each row execute function public.set_updated_at();

drop trigger if exists set_bills_updated_at on public.bills;
create trigger set_bills_updated_at before update on public.bills for each row execute function public.set_updated_at();

drop trigger if exists set_bill_payments_updated_at on public.bill_payments;
create trigger set_bill_payments_updated_at before update on public.bill_payments for each row execute function public.set_updated_at();

drop trigger if exists set_recurring_transactions_updated_at on public.recurring_transactions;
create trigger set_recurring_transactions_updated_at before update on public.recurring_transactions for each row execute function public.set_updated_at();

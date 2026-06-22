-- BudgetMeter Supabase migration 0010
-- Row-level currency_code for money-bearing synced tables.

-- savings_goals
alter table public.savings_goals
    add column if not exists currency_code text;

update public.savings_goals sg
set currency_code = coalesce(
    (select us.preferred_currency_code
     from public.user_settings us
     where us.user_id = sg.user_id),
    'USD'
)
where sg.currency_code is null;

alter table public.savings_goals
    alter column currency_code set not null;

do $$
begin
    if not exists (
        select 1 from pg_constraint
        where conname = 'savings_goals_currency_code_format'
          and conrelid = 'public.savings_goals'::regclass
    ) then
        alter table public.savings_goals
            add constraint savings_goals_currency_code_format
            check (currency_code ~ '^[A-Z]{3}$') not valid;
        alter table public.savings_goals
            validate constraint savings_goals_currency_code_format;
    end if;
end $$;

-- subscriptions
alter table public.subscriptions
    add column if not exists currency_code text;

update public.subscriptions s
set currency_code = coalesce(
    (select us.preferred_currency_code
     from public.user_settings us
     where us.user_id = s.user_id),
    'USD'
)
where s.currency_code is null;

alter table public.subscriptions
    alter column currency_code set not null;

do $$
begin
    if not exists (
        select 1 from pg_constraint
        where conname = 'subscriptions_currency_code_format'
          and conrelid = 'public.subscriptions'::regclass
    ) then
        alter table public.subscriptions
            add constraint subscriptions_currency_code_format
            check (currency_code ~ '^[A-Z]{3}$') not valid;
        alter table public.subscriptions
            validate constraint subscriptions_currency_code_format;
    end if;
end $$;

-- bills
alter table public.bills
    add column if not exists currency_code text;

update public.bills b
set currency_code = coalesce(
    (select us.preferred_currency_code
     from public.user_settings us
     where us.user_id = b.user_id),
    'USD'
)
where b.currency_code is null;

alter table public.bills
    alter column currency_code set not null;

do $$
begin
    if not exists (
        select 1 from pg_constraint
        where conname = 'bills_currency_code_format'
          and conrelid = 'public.bills'::regclass
    ) then
        alter table public.bills
            add constraint bills_currency_code_format
            check (currency_code ~ '^[A-Z]{3}$') not valid;
        alter table public.bills
            validate constraint bills_currency_code_format;
    end if;
end $$;

-- bill_payments
alter table public.bill_payments
    add column if not exists currency_code text;

update public.bill_payments bp
set currency_code = coalesce(
    (select us.preferred_currency_code
     from public.user_settings us
     where us.user_id = bp.user_id),
    'USD'
)
where bp.currency_code is null;

alter table public.bill_payments
    alter column currency_code set not null;

do $$
begin
    if not exists (
        select 1 from pg_constraint
        where conname = 'bill_payments_currency_code_format'
          and conrelid = 'public.bill_payments'::regclass
    ) then
        alter table public.bill_payments
            add constraint bill_payments_currency_code_format
            check (currency_code ~ '^[A-Z]{3}$') not valid;
        alter table public.bill_payments
            validate constraint bill_payments_currency_code_format;
    end if;
end $$;

-- recurring_transactions
alter table public.recurring_transactions
    add column if not exists currency_code text;

update public.recurring_transactions rt
set currency_code = coalesce(
    (select us.preferred_currency_code
     from public.user_settings us
     where us.user_id = rt.user_id),
    'USD'
)
where rt.currency_code is null;

alter table public.recurring_transactions
    alter column currency_code set not null;

do $$
begin
    if not exists (
        select 1 from pg_constraint
        where conname = 'recurring_transactions_currency_code_format'
          and conrelid = 'public.recurring_transactions'::regclass
    ) then
        alter table public.recurring_transactions
            add constraint recurring_transactions_currency_code_format
            check (currency_code ~ '^[A-Z]{3}$') not valid;
        alter table public.recurring_transactions
            validate constraint recurring_transactions_currency_code_format;
    end if;
end $$;

-- one_time_transactions
alter table public.one_time_transactions
    add column if not exists currency_code text;

update public.one_time_transactions ott
set currency_code = coalesce(
    (select us.preferred_currency_code
     from public.user_settings us
     where us.user_id = ott.user_id),
    'USD'
)
where ott.currency_code is null;

alter table public.one_time_transactions
    alter column currency_code set not null;

do $$
begin
    if not exists (
        select 1 from pg_constraint
        where conname = 'one_time_transactions_currency_code_format'
          and conrelid = 'public.one_time_transactions'::regclass
    ) then
        alter table public.one_time_transactions
            add constraint one_time_transactions_currency_code_format
            check (currency_code ~ '^[A-Z]{3}$') not valid;
        alter table public.one_time_transactions
            validate constraint one_time_transactions_currency_code_format;
    end if;
end $$;

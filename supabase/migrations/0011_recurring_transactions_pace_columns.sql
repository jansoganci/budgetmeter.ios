-- BudgetMeter Supabase migration 0011
-- Discriminators for recurring_transactions: category pace vs automation schedules.

alter table public.recurring_transactions
    add column if not exists source_type text,
    add column if not exists category_key text;

create index if not exists recurring_transactions_user_id_source_type_idx
    on public.recurring_transactions (user_id, source_type);

create index if not exists recurring_transactions_user_id_category_key_idx
    on public.recurring_transactions (user_id, category_key);

comment on column public.recurring_transactions.source_type is
    'Row origin: categoryPace (Income/Expense pace amounts) or automation (RecurringTransaction schedules).';

comment on column public.recurring_transactions.category_key is
    'Seeded template key for pace rows; null for custom categories and automation schedules.';

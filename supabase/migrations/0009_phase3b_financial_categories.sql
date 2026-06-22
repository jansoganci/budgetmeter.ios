-- BudgetMeter Supabase migration 0009
-- Phase 3B financial_categories + seeded_category_overrides sync tables.

create table if not exists public.financial_categories (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references auth.users(id) on delete cascade default auth.uid(),
    client_record_id text not null,
    type text not null,
    name text not null,
    icon_name text,
    color_hex text,
    is_active boolean not null default true,
    sort_order integer,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    deleted_at timestamptz
);

create table if not exists public.seeded_category_overrides (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references auth.users(id) on delete cascade default auth.uid(),
    category_key text not null,
    type text not null,
    custom_label text,
    custom_icon_name text,
    custom_color_hex text,
    is_hidden boolean not null default false,
    sort_order integer,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    deleted_at timestamptz
);

do $$
begin
    if not exists (
        select 1 from pg_constraint
        where conname = 'financial_categories_user_id_client_record_id_key'
          and conrelid = 'public.financial_categories'::regclass
    ) then
        alter table public.financial_categories
            add constraint financial_categories_user_id_client_record_id_key
            unique (user_id, client_record_id);
    end if;

    if not exists (
        select 1 from pg_constraint
        where conname = 'financial_categories_type_allowed'
          and conrelid = 'public.financial_categories'::regclass
    ) then
        alter table public.financial_categories
            add constraint financial_categories_type_allowed
            check (type in ('income', 'expense')) not valid;
    end if;

    if not exists (
        select 1 from pg_constraint
        where conname = 'financial_categories_name_non_empty'
          and conrelid = 'public.financial_categories'::regclass
    ) then
        alter table public.financial_categories
            add constraint financial_categories_name_non_empty
            check (btrim(name) <> '') not valid;
    end if;

    if not exists (
        select 1 from pg_constraint
        where conname = 'financial_categories_client_record_id_non_empty'
          and conrelid = 'public.financial_categories'::regclass
    ) then
        alter table public.financial_categories
            add constraint financial_categories_client_record_id_non_empty
            check (btrim(client_record_id) <> '') not valid;
    end if;

    if not exists (
        select 1 from pg_constraint
        where conname = 'seeded_category_overrides_user_id_type_category_key_key'
          and conrelid = 'public.seeded_category_overrides'::regclass
    ) then
        alter table public.seeded_category_overrides
            add constraint seeded_category_overrides_user_id_type_category_key_key
            unique (user_id, type, category_key);
    end if;

    if not exists (
        select 1 from pg_constraint
        where conname = 'seeded_category_overrides_type_allowed'
          and conrelid = 'public.seeded_category_overrides'::regclass
    ) then
        alter table public.seeded_category_overrides
            add constraint seeded_category_overrides_type_allowed
            check (type in ('income', 'expense')) not valid;
    end if;

    if not exists (
        select 1 from pg_constraint
        where conname = 'seeded_category_overrides_category_key_non_empty'
          and conrelid = 'public.seeded_category_overrides'::regclass
    ) then
        alter table public.seeded_category_overrides
            add constraint seeded_category_overrides_category_key_non_empty
            check (btrim(category_key) <> '') not valid;
    end if;
end $$;

alter table public.financial_categories validate constraint financial_categories_type_allowed;
alter table public.financial_categories validate constraint financial_categories_name_non_empty;
alter table public.financial_categories validate constraint financial_categories_client_record_id_non_empty;

alter table public.seeded_category_overrides validate constraint seeded_category_overrides_type_allowed;
alter table public.seeded_category_overrides validate constraint seeded_category_overrides_category_key_non_empty;

create index if not exists financial_categories_user_id_updated_at_idx
    on public.financial_categories (user_id, updated_at desc);

create index if not exists financial_categories_user_id_deleted_at_idx
    on public.financial_categories (user_id, deleted_at);

create index if not exists financial_categories_user_id_type_idx
    on public.financial_categories (user_id, type);

create index if not exists financial_categories_user_id_client_record_id_idx
    on public.financial_categories (user_id, client_record_id);

create index if not exists seeded_category_overrides_user_id_updated_at_idx
    on public.seeded_category_overrides (user_id, updated_at desc);

create index if not exists seeded_category_overrides_user_id_deleted_at_idx
    on public.seeded_category_overrides (user_id, deleted_at);

create index if not exists seeded_category_overrides_user_id_type_idx
    on public.seeded_category_overrides (user_id, type);

create index if not exists seeded_category_overrides_user_id_type_category_key_idx
    on public.seeded_category_overrides (user_id, type, category_key);

alter table public.financial_categories enable row level security;
alter table public.seeded_category_overrides enable row level security;

do $$
begin
    if not exists (
        select 1 from pg_policies
        where schemaname = 'public'
          and tablename = 'financial_categories'
          and policyname = 'FinancialCategories: users can read own rows'
    ) then
        create policy "FinancialCategories: users can read own rows"
            on public.financial_categories
            for select
            to authenticated
            using (auth.uid() = user_id);
    end if;

    if not exists (
        select 1 from pg_policies
        where schemaname = 'public'
          and tablename = 'financial_categories'
          and policyname = 'FinancialCategories: users can insert own rows'
    ) then
        create policy "FinancialCategories: users can insert own rows"
            on public.financial_categories
            for insert
            to authenticated
            with check (auth.uid() = user_id);
    end if;

    if not exists (
        select 1 from pg_policies
        where schemaname = 'public'
          and tablename = 'financial_categories'
          and policyname = 'FinancialCategories: users can update own rows'
    ) then
        create policy "FinancialCategories: users can update own rows"
            on public.financial_categories
            for update
            to authenticated
            using (auth.uid() = user_id)
            with check (auth.uid() = user_id);
    end if;

    if not exists (
        select 1 from pg_policies
        where schemaname = 'public'
          and tablename = 'seeded_category_overrides'
          and policyname = 'SeededCategoryOverrides: users can read own rows'
    ) then
        create policy "SeededCategoryOverrides: users can read own rows"
            on public.seeded_category_overrides
            for select
            to authenticated
            using (auth.uid() = user_id);
    end if;

    if not exists (
        select 1 from pg_policies
        where schemaname = 'public'
          and tablename = 'seeded_category_overrides'
          and policyname = 'SeededCategoryOverrides: users can insert own rows'
    ) then
        create policy "SeededCategoryOverrides: users can insert own rows"
            on public.seeded_category_overrides
            for insert
            to authenticated
            with check (auth.uid() = user_id);
    end if;

    if not exists (
        select 1 from pg_policies
        where schemaname = 'public'
          and tablename = 'seeded_category_overrides'
          and policyname = 'SeededCategoryOverrides: users can update own rows'
    ) then
        create policy "SeededCategoryOverrides: users can update own rows"
            on public.seeded_category_overrides
            for update
            to authenticated
            using (auth.uid() = user_id)
            with check (auth.uid() = user_id);
    end if;
end $$;

drop trigger if exists set_financial_categories_updated_at on public.financial_categories;
create trigger set_financial_categories_updated_at
    before update on public.financial_categories
    for each row
    execute function public.set_updated_at();

drop trigger if exists set_seeded_category_overrides_updated_at on public.seeded_category_overrides;
create trigger set_seeded_category_overrides_updated_at
    before update on public.seeded_category_overrides
    for each row
    execute function public.set_updated_at();

comment on table public.financial_categories is
    'Phase 3B sync table for user-created custom reusable income/expense categories. Seeded catalog rows remain app-defined locally.';

comment on table public.seeded_category_overrides is
    'Phase 3B sync table for user-specific presentation overrides to app-defined seeded category keys.';

comment on column public.financial_categories.color_hex is
    'Optional color. Local app may store palette keys (e.g. blue) or hex strings.';

comment on column public.seeded_category_overrides.custom_color_hex is
    'Optional color override. Local app may store palette keys (e.g. blue) or hex strings.';

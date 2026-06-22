-- BudgetMeter Supabase migration 0004
-- Phase 1 account/settings tables (no financial sync tables).

create table if not exists public.profiles (
    user_id uuid primary key references auth.users(id) on delete cascade default auth.uid(),
    email text,
    display_name text,
    provider text,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create table if not exists public.user_settings (
    user_id uuid primary key references auth.users(id) on delete cascade default auth.uid(),
    onboarding_completed boolean not null default false,
    preferred_currency_code text not null default 'USD',
    selected_theme text not null default 'default',
    appearance_mode text not null default 'system',
    language_code text not null default 'en',
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create table if not exists public.notification_preferences (
    user_id uuid primary key references auth.users(id) on delete cascade default auth.uid(),
    daily_encouragement_enabled boolean not null default false,
    weekly_summary_enabled boolean not null default false,
    milestones_enabled boolean not null default true,
    spending_alerts_enabled boolean not null default true,
    daily_time time,
    weekly_summary_time time,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

do $$
begin
    if not exists (
        select 1 from pg_constraint
        where conname = 'user_settings_currency_code_format'
          and conrelid = 'public.user_settings'::regclass
    ) then
        alter table public.user_settings
            add constraint user_settings_currency_code_format
            check (preferred_currency_code ~ '^[A-Z]{3}$') not valid;
    end if;

    if not exists (
        select 1 from pg_constraint
        where conname = 'user_settings_appearance_mode_allowed'
          and conrelid = 'public.user_settings'::regclass
    ) then
        alter table public.user_settings
            add constraint user_settings_appearance_mode_allowed
            check (appearance_mode in ('light', 'dark', 'system')) not valid;
    end if;

    if not exists (
        select 1 from pg_constraint
        where conname = 'user_settings_language_code_valid'
          and conrelid = 'public.user_settings'::regclass
    ) then
        alter table public.user_settings
            add constraint user_settings_language_code_valid
            check (
                char_length(language_code) between 2 and 16
                and language_code ~ '^[A-Za-z0-9_-]+$'
            ) not valid;
    end if;

    if not exists (
        select 1 from pg_constraint
        where conname = 'user_settings_theme_non_empty'
          and conrelid = 'public.user_settings'::regclass
    ) then
        alter table public.user_settings
            add constraint user_settings_theme_non_empty
            check (btrim(selected_theme) <> '') not valid;
    end if;
end $$;

alter table public.profiles enable row level security;
alter table public.user_settings enable row level security;
alter table public.notification_preferences enable row level security;

do $$
begin
    -- profiles policies
    if not exists (
        select 1 from pg_policies
        where schemaname = 'public'
          and tablename = 'profiles'
          and policyname = 'Profiles: users can read own row'
    ) then
        create policy "Profiles: users can read own row"
            on public.profiles
            for select
            to authenticated
            using (auth.uid() = user_id);
    end if;

    if not exists (
        select 1 from pg_policies
        where schemaname = 'public'
          and tablename = 'profiles'
          and policyname = 'Profiles: users can insert own row'
    ) then
        create policy "Profiles: users can insert own row"
            on public.profiles
            for insert
            to authenticated
            with check (auth.uid() = user_id);
    end if;

    if not exists (
        select 1 from pg_policies
        where schemaname = 'public'
          and tablename = 'profiles'
          and policyname = 'Profiles: users can update own row'
    ) then
        create policy "Profiles: users can update own row"
            on public.profiles
            for update
            to authenticated
            using (auth.uid() = user_id)
            with check (auth.uid() = user_id);
    end if;

    -- user_settings policies
    if not exists (
        select 1 from pg_policies
        where schemaname = 'public'
          and tablename = 'user_settings'
          and policyname = 'UserSettings: users can read own row'
    ) then
        create policy "UserSettings: users can read own row"
            on public.user_settings
            for select
            to authenticated
            using (auth.uid() = user_id);
    end if;

    if not exists (
        select 1 from pg_policies
        where schemaname = 'public'
          and tablename = 'user_settings'
          and policyname = 'UserSettings: users can insert own row'
    ) then
        create policy "UserSettings: users can insert own row"
            on public.user_settings
            for insert
            to authenticated
            with check (auth.uid() = user_id);
    end if;

    if not exists (
        select 1 from pg_policies
        where schemaname = 'public'
          and tablename = 'user_settings'
          and policyname = 'UserSettings: users can update own row'
    ) then
        create policy "UserSettings: users can update own row"
            on public.user_settings
            for update
            to authenticated
            using (auth.uid() = user_id)
            with check (auth.uid() = user_id);
    end if;

    -- notification_preferences policies
    if not exists (
        select 1 from pg_policies
        where schemaname = 'public'
          and tablename = 'notification_preferences'
          and policyname = 'NotificationPrefs: users can read own row'
    ) then
        create policy "NotificationPrefs: users can read own row"
            on public.notification_preferences
            for select
            to authenticated
            using (auth.uid() = user_id);
    end if;

    if not exists (
        select 1 from pg_policies
        where schemaname = 'public'
          and tablename = 'notification_preferences'
          and policyname = 'NotificationPrefs: users can insert own row'
    ) then
        create policy "NotificationPrefs: users can insert own row"
            on public.notification_preferences
            for insert
            to authenticated
            with check (auth.uid() = user_id);
    end if;

    if not exists (
        select 1 from pg_policies
        where schemaname = 'public'
          and tablename = 'notification_preferences'
          and policyname = 'NotificationPrefs: users can update own row'
    ) then
        create policy "NotificationPrefs: users can update own row"
            on public.notification_preferences
            for update
            to authenticated
            using (auth.uid() = user_id)
            with check (auth.uid() = user_id);
    end if;
end $$;

comment on table public.profiles is
    'Phase 1 account profile row per authenticated user.';
comment on table public.user_settings is
    'Phase 1 account-level user settings (onboarding, theme, appearance, language, currency).';
comment on table public.notification_preferences is
    'Phase 1 account-level notification preference toggles and preferred schedule times.';


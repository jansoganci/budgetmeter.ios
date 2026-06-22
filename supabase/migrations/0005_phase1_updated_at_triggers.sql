-- BudgetMeter Supabase migration 0005
-- Shared updated_at trigger function for Phase 1 tables.

create or replace function public.set_updated_at()
returns trigger
language plpgsql
security invoker
set search_path = public
as $$
begin
    new.updated_at = now();
    return new;
end;
$$;

drop trigger if exists set_profiles_updated_at on public.profiles;
create trigger set_profiles_updated_at
    before update on public.profiles
    for each row
    execute function public.set_updated_at();

drop trigger if exists set_user_settings_updated_at on public.user_settings;
create trigger set_user_settings_updated_at
    before update on public.user_settings
    for each row
    execute function public.set_updated_at();

drop trigger if exists set_notification_preferences_updated_at on public.notification_preferences;
create trigger set_notification_preferences_updated_at
    before update on public.notification_preferences
    for each row
    execute function public.set_updated_at();

comment on function public.set_updated_at() is
    'Sets updated_at = now() before row updates.';


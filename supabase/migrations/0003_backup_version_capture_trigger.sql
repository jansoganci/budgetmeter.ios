-- BudgetMeter Supabase migration 0003
-- Automatically captures a restorable version whenever the latest backup changes.

create or replace function public.capture_user_backup_version()
returns trigger
language plpgsql
security invoker
set search_path = public
as $$
declare
    new_version_id uuid := extensions.gen_random_uuid();
    should_capture_version boolean := false;
begin
    new.updated_at = now();
    new.created_at = coalesce(new.created_at, now());

    if tg_op = 'INSERT' then
        should_capture_version := true;
    elsif old.schema_version is distinct from new.schema_version
       or old.app_version is distinct from new.app_version
       or old.payload is distinct from new.payload
       or old.record_counts is distinct from new.record_counts then
        should_capture_version := true;
    end if;

    if should_capture_version then

        insert into public.user_backup_versions (
            id,
            user_id,
            schema_version,
            app_version,
            payload,
            record_counts,
            backup_reason,
            is_restorable,
            created_at,
            deleted_at
        ) values (
            new_version_id,
            new.user_id,
            new.schema_version,
            new.app_version,
            new.payload,
            new.record_counts,
            'manual_backup',
            true,
            now(),
            null
        );

        new.latest_backup_version_id = new_version_id;
        if tg_op = 'INSERT' then
            new.backup_count = coalesce(new.backup_count, 0) + 1;
        else
            new.backup_count = coalesce(old.backup_count, 0) + 1;
        end if;
        new.deleted_at = null;
    end if;

    return new;
end;
$$;

drop trigger if exists capture_user_backup_version_before_write on public.user_backups;

create trigger capture_user_backup_version_before_write
    before insert or update of schema_version, app_version, payload, record_counts
    on public.user_backups
    for each row
    execute function public.capture_user_backup_version();

do $$
begin
    if not exists (
        select 1
        from pg_constraint
        where conname = 'user_backups_latest_backup_version_id_fkey'
          and conrelid = 'public.user_backups'::regclass
    ) then
        alter table public.user_backups
            add constraint user_backups_latest_backup_version_id_fkey
            foreign key (latest_backup_version_id)
            references public.user_backup_versions(id)
            on delete set null;
    end if;
end $$;

comment on function public.capture_user_backup_version() is
    'Captures a version-history row before user_backups latest backup insert/update. Keeps app writes backward-compatible.';

-- ============================================
-- Attend75 Database Triggers
-- Migration: 004_triggers (REFINED)
-- ============================================

-- ============================================
-- FUNCTION: handle_new_user
-- Auto-create profile and settings on signup
-- ============================================
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public, auth
as $$
begin
  -- Create profile
  insert into public.profiles (id, email, first_name, last_name)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data->>'first_name', ''),
    coalesce(new.raw_user_meta_data->>'last_name', '')
  );

  -- Create default user settings
  insert into public.user_settings (user_id)
  values (new.id);

  return new;
end;
$$;

-- Trigger on auth.users insert
drop trigger if exists on_auth_user_created on auth.users;

create trigger on_auth_user_created
after insert on auth.users
for each row
execute function public.handle_new_user();

-- ============================================
-- UPDATED_AT TRIGGERS
-- Reuse canonical function: set_updated_at
-- ============================================

drop trigger if exists set_attendance_logs_updated_at
on public.attendance_logs;

create trigger set_attendance_logs_updated_at
before update on public.attendance_logs
for each row
execute function public.set_updated_at();

drop trigger if exists set_user_settings_updated_at
on public.user_settings;

create trigger set_user_settings_updated_at
before update on public.user_settings
for each row
execute function public.set_updated_at();

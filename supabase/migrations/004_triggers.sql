-- ============================================
-- Attend75 Database Triggers
-- Migration: 004_triggers (IDEMPOTENT)
-- Safe to run multiple times
-- ============================================

-- ============================================
-- FUNCTION: handle_new_user
-- Auto-create profile and settings on signup
-- ============================================
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
BEGIN
  -- Create profile (with ON CONFLICT for safety)
  INSERT INTO public.profiles (id, email, first_name, last_name)
  VALUES (
    new.id,
    new.email,
    COALESCE(new.raw_user_meta_data->>'first_name', ''),
    COALESCE(new.raw_user_meta_data->>'last_name', '')
  )
  ON CONFLICT (id) DO NOTHING;

  -- Create default user settings (with ON CONFLICT for safety)
  INSERT INTO public.user_settings (user_id)
  VALUES (new.id)
  ON CONFLICT (user_id) DO NOTHING;

  RETURN new;
END;
$$;

-- Trigger on auth.users insert
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

CREATE TRIGGER on_auth_user_created
AFTER INSERT ON auth.users
FOR EACH ROW
EXECUTE FUNCTION public.handle_new_user();

-- ============================================
-- UPDATED_AT TRIGGERS
-- Reuse canonical function: set_updated_at
-- ============================================

DROP TRIGGER IF EXISTS set_attendance_logs_updated_at ON public.attendance_logs;

CREATE TRIGGER set_attendance_logs_updated_at
BEFORE UPDATE ON public.attendance_logs
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();

DROP TRIGGER IF EXISTS set_user_settings_updated_at ON public.user_settings;

CREATE TRIGGER set_user_settings_updated_at
BEFORE UPDATE ON public.user_settings
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();

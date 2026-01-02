-- ============================================
-- Attend75 Database Schema
-- Migration: 001_initial_schema (IDEMPOTENT)
-- Safe to run on existing databases
-- ============================================

-- Required for gen_random_uuid()
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ============================================
-- TABLE: profiles
-- ============================================
CREATE TABLE IF NOT EXISTS public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  first_name text,
  last_name text,
  email text,
  avatar_url text,
  target_attendance real not null default 75.0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ============================================
-- TABLE: subjects
-- ============================================
CREATE TABLE IF NOT EXISTS public.subjects (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  start_month text,
  end_month text,
  total_classes integer not null default 0,
  attended_classes integer not null default 0,
  required_attendance real not null default 75.0,
  days_of_week integer[] not null default '{}',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

CREATE INDEX IF NOT EXISTS idx_subjects_user_id ON public.subjects(user_id);

-- ============================================
-- TABLE: lecture_slots
-- ============================================
CREATE TABLE IF NOT EXISTS public.lecture_slots (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  subject_id uuid not null references public.subjects(id) on delete cascade,
  day_of_week smallint not null check (day_of_week >= 0 and day_of_week <= 6),
  start_time time not null,
  end_time time not null,
  duration_hours smallint not null default 1 check (duration_hours in (1, 2)),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

CREATE INDEX IF NOT EXISTS idx_lecture_slots_user_id ON public.lecture_slots(user_id);
CREATE INDEX IF NOT EXISTS idx_lecture_slots_subject_id ON public.lecture_slots(subject_id);
CREATE INDEX IF NOT EXISTS idx_lecture_slots_day ON public.lecture_slots(day_of_week);

-- ============================================
-- TABLE: attendance_logs
-- ============================================
CREATE TABLE IF NOT EXISTS public.attendance_logs (
  id uuid primary key default gen_random_uuid(),
  subject_id uuid not null references public.subjects(id) on delete cascade,
  lecture_slot_id uuid references public.lecture_slots(id),
  date date not null,
  status text not null check (status in ('present', 'absent', 'duty-leave')),
  hours_logged smallint not null default 1,
  duty_requested boolean not null default false,
  duty_approved boolean not null default false,
  duty_reason text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Add columns if they don't exist (for existing tables)
ALTER TABLE public.attendance_logs ADD COLUMN IF NOT EXISTS lecture_slot_id uuid REFERENCES public.lecture_slots(id);
ALTER TABLE public.attendance_logs ADD COLUMN IF NOT EXISTS hours_logged smallint DEFAULT 1;

CREATE INDEX IF NOT EXISTS idx_attendance_logs_subject_date ON public.attendance_logs(subject_id, date);
CREATE INDEX IF NOT EXISTS idx_attendance_logs_slot ON public.attendance_logs(lecture_slot_id);

-- ============================================
-- TABLE: user_settings
-- ============================================
CREATE TABLE IF NOT EXISTS public.user_settings (
  user_id uuid primary key references auth.users(id) on delete cascade,
  accent_color text not null default '#6366f1',
  notifications_enabled boolean not null default true,
  reminder_time text not null default '09:00',
  include_duty_leave boolean not null default true,
  default_required_attendance real not null default 75.0,
  show_warning_at real not null default 80.0,
  show_critical_at real not null default 75.0,
  auto_mark_weekends boolean not null default false,
  theme_mode text not null default 'system',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ============================================
-- UPDATED_AT TRIGGER FUNCTION
-- ============================================
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  new.updated_at = now();
  RETURN new;
END;
$$;

-- Triggers (DROP IF EXISTS, then CREATE)
DROP TRIGGER IF EXISTS set_profiles_updated_at ON public.profiles;
CREATE TRIGGER set_profiles_updated_at
BEFORE UPDATE ON public.profiles
FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

DROP TRIGGER IF EXISTS set_subjects_updated_at ON public.subjects;
CREATE TRIGGER set_subjects_updated_at
BEFORE UPDATE ON public.subjects
FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

DROP TRIGGER IF EXISTS set_lecture_slots_updated_at ON public.lecture_slots;
CREATE TRIGGER set_lecture_slots_updated_at
BEFORE UPDATE ON public.lecture_slots
FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

DROP TRIGGER IF EXISTS set_attendance_logs_updated_at ON public.attendance_logs;
CREATE TRIGGER set_attendance_logs_updated_at
BEFORE UPDATE ON public.attendance_logs
FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

DROP TRIGGER IF EXISTS set_user_settings_updated_at ON public.user_settings;
CREATE TRIGGER set_user_settings_updated_at
BEFORE UPDATE ON public.user_settings
FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

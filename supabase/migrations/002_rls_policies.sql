-- ============================================
-- Attend75 Row Level Security Policies
-- Migration: 002_rls_policies (REFINED)
-- ============================================

-- Enable RLS
alter table public.profiles enable row level security;
alter table public.subjects enable row level security;
alter table public.attendance_logs enable row level security;
alter table public.user_settings enable row level security;

-- ============================================
-- PROFILES
-- ============================================

drop policy if exists "Enable all access for users to own profile"
on public.profiles;

create policy "Enable all access for users to own profile"
on public.profiles
for all
using (
  id = (select auth.uid())
)
with check (
  id = (select auth.uid())
);

-- ============================================
-- SUBJECTS
-- ============================================

drop policy if exists "Users can view own subjects" on public.subjects;
drop policy if exists "Users can insert own subjects" on public.subjects;
drop policy if exists "Users can update own subjects" on public.subjects;
drop policy if exists "Users can delete own subjects" on public.subjects;

create policy "Users can view own subjects"
on public.subjects
for select
using (
  user_id = (select auth.uid())
);

create policy "Users can insert own subjects"
on public.subjects
for insert
with check (
  user_id = (select auth.uid())
);

create policy "Users can update own subjects"
on public.subjects
for update
using (
  user_id = (select auth.uid())
)
with check (
  user_id = (select auth.uid())
);

create policy "Users can delete own subjects"
on public.subjects
for delete
using (
  user_id = (select auth.uid())
);

-- ============================================
-- LECTURE SLOTS
-- ============================================

alter table public.lecture_slots enable row level security;

drop policy if exists "Users can view own lecture_slots" on public.lecture_slots;
drop policy if exists "Users can insert own lecture_slots" on public.lecture_slots;
drop policy if exists "Users can update own lecture_slots" on public.lecture_slots;
drop policy if exists "Users can delete own lecture_slots" on public.lecture_slots;

create policy "Users can view own lecture_slots"
on public.lecture_slots
for select
using (
  user_id = (select auth.uid())
);

create policy "Users can insert own lecture_slots"
on public.lecture_slots
for insert
with check (
  user_id = (select auth.uid())
);

create policy "Users can update own lecture_slots"
on public.lecture_slots
for update
using (
  user_id = (select auth.uid())
)
with check (
  user_id = (select auth.uid())
);

create policy "Users can delete own lecture_slots"
on public.lecture_slots
for delete
using (
  user_id = (select auth.uid())
);

-- ============================================
-- ATTENDANCE LOGS
-- ============================================

drop policy if exists "Users can view own attendance logs" on public.attendance_logs;
drop policy if exists "Users can insert own attendance logs" on public.attendance_logs;
drop policy if exists "Users can update own attendance logs" on public.attendance_logs;
drop policy if exists "Users can delete own attendance logs" on public.attendance_logs;

create policy "Users can view own attendance logs"
on public.attendance_logs
for select
using (
  subject_id in (
    select id
    from public.subjects
    where user_id = (select auth.uid())
  )
);

create policy "Users can insert own attendance logs"
on public.attendance_logs
for insert
with check (
  subject_id in (
    select id
    from public.subjects
    where user_id = (select auth.uid())
  )
);

create policy "Users can update own attendance logs"
on public.attendance_logs
for update
using (
  subject_id in (
    select id
    from public.subjects
    where user_id = (select auth.uid())
  )
)
with check (
  subject_id in (
    select id
    from public.subjects
    where user_id = (select auth.uid())
  )
);

create policy "Users can delete own attendance logs"
on public.attendance_logs
for delete
using (
  subject_id in (
    select id
    from public.subjects
    where user_id = (select auth.uid())
  )
);

-- ============================================
-- USER SETTINGS
-- ============================================

drop policy if exists "Users can view own settings" on public.user_settings;
drop policy if exists "Users can insert own settings" on public.user_settings;
drop policy if exists "Users can update own settings" on public.user_settings;

create policy "Users can view own settings"
on public.user_settings
for select
using (
  user_id = (select auth.uid())
);

create policy "Users can insert own settings"
on public.user_settings
for insert
with check (
  user_id = (select auth.uid())
);

create policy "Users can update own settings"
on public.user_settings
for update
using (
  user_id = (select auth.uid())
)
with check (
  user_id = (select auth.uid())
);

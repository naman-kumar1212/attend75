-- ============================================
-- Attend75 Database Schema - Unique Constraints
-- Migration: 005_add_unique_constraints
-- Purpose: Fix upsert operations for attendance logs
-- ============================================

-- Add unique constraint for lecture-based attendance
-- This is required for: onConflict: 'subject_id,date,lecture_slot_id'
ALTER TABLE public.attendance_logs
DROP CONSTRAINT IF EXISTS attendance_logs_subject_date_slot_unique;

ALTER TABLE public.attendance_logs
ADD CONSTRAINT attendance_logs_subject_date_slot_unique
UNIQUE (subject_id, date, lecture_slot_id);

-- Add unique constraint for legacy (non-lecture) attendance
-- This is required for: onConflict: 'subject_id,date' when lecture_slot_id is NULL
-- Note: Standard UNIQUE constraint treats NULLs as distinct, so we need a unique index with WHERE clause
DROP INDEX IF EXISTS idx_attendance_logs_subject_date_null_slot;

CREATE UNIQUE INDEX idx_attendance_logs_subject_date_null_slot
ON public.attendance_logs (subject_id, date)
WHERE lecture_slot_id IS NULL;

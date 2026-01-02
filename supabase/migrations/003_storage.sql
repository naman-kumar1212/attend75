-- ============================================
-- Attend75 Storage Configuration
-- Migration: 003_storage
-- ============================================

-- Create avatars bucket (public for easy access)
INSERT INTO storage.buckets (id, name, public)
VALUES ('avatars', 'avatars', true)
ON CONFLICT (id) DO NOTHING;

-- ============================================
-- STORAGE POLICIES
-- Users can manage their own avatars
-- ============================================

-- Policy: Users can upload their own avatar
-- Avatar path format: {user_id}/avatar_{timestamp}.{ext}
CREATE POLICY "Users can upload own avatar"
ON storage.objects
FOR INSERT
WITH CHECK (
  bucket_id = 'avatars'
  AND (select auth.uid())::text = (storage.foldername(name))[1]
);

-- Policy: Users can update their own avatar
CREATE POLICY "Users can update own avatar"
ON storage.objects
FOR UPDATE
USING (
  bucket_id = 'avatars'
  AND (select auth.uid())::text = (storage.foldername(name))[1]
)
WITH CHECK (
  bucket_id = 'avatars'
  AND (select auth.uid())::text = (storage.foldername(name))[1]
);

-- Policy: Users can delete their own avatar
CREATE POLICY "Users can delete own avatar"
ON storage.objects
FOR DELETE
USING (
  bucket_id = 'avatars'
  AND (select auth.uid())::text = (storage.foldername(name))[1]
);

-- Policy: Anyone can view avatars (public bucket)
CREATE POLICY "Public avatar access"
ON storage.objects
FOR SELECT
USING (
  bucket_id = 'avatars'
);

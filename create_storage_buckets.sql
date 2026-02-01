-- Create Storage Buckets for Draw2Toy
-- Execute this via Supabase Dashboard > SQL Editor

-- 1. Create buckets if they don't exist
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES
  ('drawings-original', 'drawings-original', false, 10485760, ARRAY['image/jpeg', 'image/jpg', 'image/png', 'image/webp']),
  ('drawings-processed', 'drawings-processed', true, 10485760, ARRAY['image/png', 'image/webp']),
  ('models-3d', 'models-3d', true, 52428800, ARRAY['model/gltf-binary', 'application/octet-stream']),
  ('models-thumbnails', 'models-thumbnails', true, 2097152, ARRAY['image/png', 'image/jpeg', 'image/webp'])
ON CONFLICT (id) DO UPDATE SET
  public = EXCLUDED.public,
  file_size_limit = EXCLUDED.file_size_limit,
  allowed_mime_types = EXCLUDED.allowed_mime_types;

-- 2. Drop existing policies to avoid conflicts
DROP POLICY IF EXISTS "Users can upload own drawings" ON storage.objects;
DROP POLICY IF EXISTS "Users can view own drawings" ON storage.objects;
DROP POLICY IF EXISTS "Users can update own drawings" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete own drawings" ON storage.objects;
DROP POLICY IF EXISTS "Public access for processed drawings" ON storage.objects;
DROP POLICY IF EXISTS "Service role can upload processed drawings" ON storage.objects;
DROP POLICY IF EXISTS "Public access for 3D models" ON storage.objects;
DROP POLICY IF EXISTS "Service role can upload 3D models" ON storage.objects;
DROP POLICY IF EXISTS "Public access for thumbnails" ON storage.objects;
DROP POLICY IF EXISTS "Service role can upload thumbnails" ON storage.objects;
DROP POLICY IF EXISTS "Service role full access drawings-original" ON storage.objects;
DROP POLICY IF EXISTS "Service role full access drawings-processed" ON storage.objects;
DROP POLICY IF EXISTS "Service role full access models-3d" ON storage.objects;
DROP POLICY IF EXISTS "Service role full access models-thumbnails" ON storage.objects;

-- 3. RLS policies for drawings-original bucket
CREATE POLICY "Users can upload own drawings" ON storage.objects FOR INSERT TO authenticated
WITH CHECK (bucket_id = 'drawings-original' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "Users can view own drawings" ON storage.objects FOR SELECT TO authenticated
USING (bucket_id = 'drawings-original' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "Users can update own drawings" ON storage.objects FOR UPDATE TO authenticated
USING (bucket_id = 'drawings-original' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "Users can delete own drawings" ON storage.objects FOR DELETE TO authenticated
USING (bucket_id = 'drawings-original' AND auth.uid()::text = (storage.foldername(name))[1]);

-- 4. Public buckets policies
CREATE POLICY "Public access for processed drawings" ON storage.objects FOR SELECT TO public
USING (bucket_id = 'drawings-processed');

CREATE POLICY "Service role can upload processed drawings" ON storage.objects FOR INSERT TO service_role
WITH CHECK (bucket_id = 'drawings-processed');

CREATE POLICY "Public access for 3D models" ON storage.objects FOR SELECT TO public
USING (bucket_id = 'models-3d');

CREATE POLICY "Service role can upload 3D models" ON storage.objects FOR INSERT TO service_role
WITH CHECK (bucket_id = 'models-3d');

CREATE POLICY "Public access for thumbnails" ON storage.objects FOR SELECT TO public
USING (bucket_id = 'models-thumbnails');

CREATE POLICY "Service role can upload thumbnails" ON storage.objects FOR INSERT TO service_role
WITH CHECK (bucket_id = 'models-thumbnails');

-- 5. Service role full access on all buckets
CREATE POLICY "Service role full access drawings-original" ON storage.objects FOR ALL TO service_role
USING (bucket_id = 'drawings-original');

CREATE POLICY "Service role full access drawings-processed" ON storage.objects FOR ALL TO service_role
USING (bucket_id = 'drawings-processed');

CREATE POLICY "Service role full access models-3d" ON storage.objects FOR ALL TO service_role
USING (bucket_id = 'models-3d');

CREATE POLICY "Service role full access models-thumbnails" ON storage.objects FOR ALL TO service_role
USING (bucket_id = 'models-thumbnails');

-- Verify
SELECT id, name, public, file_size_limit, created_at
FROM storage.buckets
WHERE id IN ('drawings-original', 'drawings-processed', 'models-3d', 'models-thumbnails')
ORDER BY created_at DESC;

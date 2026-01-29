-- =====================================================
-- SETUP COMPLETO MVP DRAW2TOY
-- Esegui questo script via Supabase Dashboard > SQL Editor
-- =====================================================

-- STEP 1: CREATE STORAGE BUCKETS
-- =====================================================
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

-- STEP 2: CREATE AI_PREDICTIONS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS public.ai_predictions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  prediction_id TEXT NOT NULL UNIQUE,
  drawing_id UUID NOT NULL REFERENCES public.drawings(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  prediction_type TEXT NOT NULL CHECK (prediction_type IN ('background_removal', '3d_generation')),
  status TEXT NOT NULL DEFAULT 'starting' CHECK (status IN ('starting', 'processing', 'succeeded', 'failed', 'canceled')),
  output TEXT,
  error TEXT,
  processing_time DECIMAL(10, 2),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  started_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_ai_predictions_drawing ON public.ai_predictions(drawing_id);
CREATE INDEX IF NOT EXISTS idx_ai_predictions_user ON public.ai_predictions(user_id);
CREATE INDEX IF NOT EXISTS idx_ai_predictions_status ON public.ai_predictions(status);
CREATE INDEX IF NOT EXISTS idx_ai_predictions_prediction_id ON public.ai_predictions(prediction_id);

-- STEP 3: RLS POLICIES FOR STORAGE
-- =====================================================

-- Drop existing policies if they exist (to avoid duplicates)
DROP POLICY IF EXISTS "Users can upload own drawings" ON storage.objects;
DROP POLICY IF EXISTS "Users can view own drawings" ON storage.objects;
DROP POLICY IF EXISTS "Service role full access drawings-original" ON storage.objects;
DROP POLICY IF EXISTS "Public access for processed drawings" ON storage.objects;
DROP POLICY IF EXISTS "Service role can upload processed drawings" ON storage.objects;
DROP POLICY IF EXISTS "Service role full access drawings-processed" ON storage.objects;
DROP POLICY IF EXISTS "Public access for 3D models" ON storage.objects;
DROP POLICY IF EXISTS "Service role can upload 3D models" ON storage.objects;
DROP POLICY IF EXISTS "Service role full access models-3d" ON storage.objects;
DROP POLICY IF EXISTS "Public access for thumbnails" ON storage.objects;
DROP POLICY IF EXISTS "Service role can upload thumbnails" ON storage.objects;
DROP POLICY IF EXISTS "Service role full access models-thumbnails" ON storage.objects;

-- drawings-original bucket
CREATE POLICY "Users can upload own drawings" ON storage.objects
  FOR INSERT TO authenticated WITH CHECK (
    bucket_id = 'drawings-original' AND auth.uid()::text = (storage.foldername(name))[1]
  );

CREATE POLICY "Users can view own drawings" ON storage.objects
  FOR SELECT TO authenticated USING (
    bucket_id = 'drawings-original' AND auth.uid()::text = (storage.foldername(name))[1]
  );

CREATE POLICY "Service role full access drawings-original" ON storage.objects
  FOR ALL TO service_role USING (bucket_id = 'drawings-original');

-- drawings-processed bucket (public read)
CREATE POLICY "Public access for processed drawings" ON storage.objects
  FOR SELECT TO public USING (bucket_id = 'drawings-processed');

CREATE POLICY "Service role can upload processed drawings" ON storage.objects
  FOR INSERT TO service_role WITH CHECK (bucket_id = 'drawings-processed');

CREATE POLICY "Service role full access drawings-processed" ON storage.objects
  FOR ALL TO service_role USING (bucket_id = 'drawings-processed');

-- models-3d bucket (public read)
CREATE POLICY "Public access for 3D models" ON storage.objects
  FOR SELECT TO public USING (bucket_id = 'models-3d');

CREATE POLICY "Service role can upload 3D models" ON storage.objects
  FOR INSERT TO service_role WITH CHECK (bucket_id = 'models-3d');

CREATE POLICY "Service role full access models-3d" ON storage.objects
  FOR ALL TO service_role USING (bucket_id = 'models-3d');

-- models-thumbnails bucket (public read)
CREATE POLICY "Public access for thumbnails" ON storage.objects
  FOR SELECT TO public USING (bucket_id = 'models-thumbnails');

CREATE POLICY "Service role can upload thumbnails" ON storage.objects
  FOR INSERT TO service_role WITH CHECK (bucket_id = 'models-thumbnails');

CREATE POLICY "Service role full access models-thumbnails" ON storage.objects
  FOR ALL TO service_role USING (bucket_id = 'models-thumbnails');

-- STEP 4: RLS POLICIES FOR AI_PREDICTIONS
-- =====================================================
ALTER TABLE public.ai_predictions ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can view own predictions" ON public.ai_predictions;
DROP POLICY IF EXISTS "Service role full access ai_predictions" ON public.ai_predictions;

CREATE POLICY "Users can view own predictions" ON public.ai_predictions
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Service role full access ai_predictions" ON public.ai_predictions
  FOR ALL USING (auth.jwt() ->> 'role' = 'service_role');

-- STEP 5: VERIFY SETUP
-- =====================================================
SELECT 'Storage buckets created:' as info;
SELECT id, name, public, file_size_limit FROM storage.buckets
WHERE id IN ('drawings-original', 'drawings-processed', 'models-3d', 'models-thumbnails')
ORDER BY created_at DESC;

SELECT 'AI Predictions table created:' as info;
SELECT EXISTS (
  SELECT FROM information_schema.tables 
  WHERE table_schema = 'public' AND table_name = 'ai_predictions'
) as table_exists;

SELECT '✅ SETUP COMPLETO - MVP READY!' as status;
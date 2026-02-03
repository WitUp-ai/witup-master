-- ============================================================================
-- FIX CAMERA LOOP & DATABASE SYNC - Emergency Production Fix
-- ============================================================================

-- This migration ensures the drawings table exists with proper RLS policies
-- and correct navigation logic in the camera flow

-- =====================================================
-- ENSURE BASIC TABLES EXIST
-- =====================================================

-- Enable extensions if not already enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create processing_status enum if not exists
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'processing_status') THEN
        CREATE TYPE processing_status AS ENUM ('pending', 'processing', 'completed', 'failed');
    END IF;
END $$;

-- =====================================================
-- ENSURE drawings TABLE EXISTS WITH CORRECT STRUCTURE
-- =====================================================
CREATE TABLE IF NOT EXISTS public.drawings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL,
    child_profile_id UUID,
    
    -- Drawing metadata
    title TEXT,
    description TEXT,
    
    -- Image storage
    original_image_url TEXT NOT NULL,
    processed_image_url TEXT,
    thumbnail_url TEXT,
    
    -- 3D Generation
    model_3d_url TEXT,
    model_status processing_status NOT NULL DEFAULT 'pending',
    processing_started_at TIMESTAMPTZ,
    processing_completed_at TIMESTAMPTZ,
    processing_error TEXT,
    
    -- Processing step (for real-time progress)
    processing_step TEXT,
    processing_progress INTEGER DEFAULT 0,
    
    -- AI metadata
    ai_prompt_used TEXT,
    ai_model_version TEXT,
    estimated_quality_score DECIMAL(3, 2),
    
    -- AR Settings
    ar_scale DECIMAL(5, 2) DEFAULT 1.0,
    ar_animation_enabled BOOLEAN DEFAULT TRUE,
    ar_sound_enabled BOOLEAN DEFAULT TRUE,
    
    -- Engagement metrics
    views_count INTEGER NOT NULL DEFAULT 0,
    ar_sessions_count INTEGER NOT NULL DEFAULT 0,
    share_count INTEGER NOT NULL DEFAULT 0,
    
    -- Privacy & Visibility
    is_public BOOLEAN DEFAULT FALSE,
    is_featured BOOLEAN DEFAULT FALSE,
    
    -- Timestamps
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT valid_quality_score CHECK (estimated_quality_score >= 0 AND estimated_quality_score <= 1)
);

-- =====================================================
-- ENSURE RLS IS ENABLED AND POLICIES EXIST
-- =====================================================

-- Enable RLS
ALTER TABLE public.drawings ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist (to avoid conflicts)
DO $$ BEGIN
    DROP POLICY IF EXISTS "Users can view own drawings" ON public.drawings;
EXCEPTION WHEN OTHERS THEN NULL;
END $$;

DO $$ BEGIN
    DROP POLICY IF EXISTS "Anyone can view public drawings" ON public.drawings;
EXCEPTION WHEN OTHERS THEN NULL;
END $$;

DO $$ BEGIN
    DROP POLICY IF EXISTS "Users can insert own drawings" ON public.drawings;
EXCEPTION WHEN OTHERS THEN NULL;
END $$;

DO $$ BEGIN
    DROP POLICY IF EXISTS "Users can update own drawings" ON public.drawings;
EXCEPTION WHEN OTHERS THEN NULL;
END $$;

DO $$ BEGIN
    DROP POLICY IF EXISTS "Users can delete own drawings" ON public.drawings;
EXCEPTION WHEN OTHERS THEN NULL;
END $$;

-- Create fresh policies
CREATE POLICY "Users can view own drawings" ON public.drawings
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Anyone can view public drawings" ON public.drawings
    FOR SELECT USING (is_public = TRUE);

CREATE POLICY "Users can insert own drawings" ON public.drawings
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own drawings" ON public.drawings
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own drawings" ON public.drawings
    FOR DELETE USING (auth.uid() = user_id);

-- =====================================================
-- ENSURE INDEXES EXIST
-- =====================================================
CREATE INDEX IF NOT EXISTS idx_drawings_user ON public.drawings(user_id);
CREATE INDEX IF NOT EXISTS idx_drawings_status ON public.drawings(model_status);
CREATE INDEX IF NOT EXISTS idx_drawings_created ON public.drawings(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_drawings_public ON public.drawings(is_public) WHERE is_public = TRUE;

-- =====================================================
-- ENSURE updated_at TRIGGER EXISTS
-- =====================================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DO $$ BEGIN
    DROP TRIGGER IF EXISTS update_drawings_updated_at ON public.drawings;
EXCEPTION WHEN OTHERS THEN NULL;
END $$;

CREATE TRIGGER update_drawings_updated_at BEFORE UPDATE ON public.drawings
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- REAL-TIME ENABLEMENT
-- =====================================================
-- Note: This may fail if realtime is not enabled, but that's OK
DO $$ BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.drawings;
EXCEPTION WHEN OTHERS THEN NULL;
END $$;

DO $$ BEGIN
    ALTER TABLE public.drawings REPLICA IDENTITY FULL;
EXCEPTION WHEN OTHERS THEN NULL;
END $$;

-- =====================================================
-- COMMENT
-- =====================================================
COMMENT ON TABLE public.drawings IS 'User-uploaded drawings and their 3D models - Emergency camera fix';
COMMENT ON COLUMN public.drawings.processing_step IS 'Current step in processing pipeline: uploading, validating, removing_background, stylizing, generating_3d, finalizing';
-- COMMENT ON COLUMN public.drawings.processing_progress IS 'Progress percentage 0-100 for current step'; -- Removed because column might not exist yet

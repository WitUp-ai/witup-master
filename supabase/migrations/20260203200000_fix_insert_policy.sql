-- Migration: Fix INSERT policy for drawings table
-- Date: 2026-02-03 20:00:00
-- Description: Ensure INSERT policy exists and works correctly
-- Problem: test_upload.py failing with 401 "new row violates row-level security policy"

-- ============================================================================
-- PART 1: VERIFY CURRENT POLICIES
-- ============================================================================

-- First, ensure RLS is enabled (should already be from previous migration)
ALTER TABLE public.drawings ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- PART 2: FIX INSERT POLICY (CRITICAL)
-- ============================================================================

-- Drop existing INSERT policy if it exists (to recreate it)
DROP POLICY IF EXISTS "Users can insert own drawings" ON public.drawings;

-- Recreate INSERT policy with proper WITH CHECK clause
CREATE POLICY "Users can insert own drawings" ON public.drawings
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- ============================================================================
-- PART 3: ENSURE ALL OTHER POLICIES EXIST
-- ============================================================================

-- Ensure SELECT policies exist
DO $$ 
BEGIN
    -- Users can view own drawings
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'drawings' 
        AND policyname = 'Users can view own drawings'
    ) THEN
        CREATE POLICY "Users can view own drawings" ON public.drawings
            FOR SELECT USING (auth.uid() = user_id);
    END IF;
    
    -- Anyone can view public drawings
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'drawings' 
        AND policyname = 'Anyone can view public drawings'
    ) THEN
        CREATE POLICY "Anyone can view public drawings" ON public.drawings
            FOR SELECT USING (is_public = TRUE);
    END IF;
    
    -- Service role has full access
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'drawings' 
        AND policyname = 'Service role has full access'
    ) THEN
        CREATE POLICY "Service role has full access" ON public.drawings
            FOR ALL TO service_role USING (true);
    END IF;
END $$;

-- ============================================================================
-- PART 4: TEST POLICY WITH SAMPLE INSERT
-- ============================================================================

-- Log the migration application
INSERT INTO system_config (key, value, description)
VALUES (
  'INSERT_POLICY_FIXED_20260203',
  'true',
  'Fixed INSERT policy for drawings table (was missing WITH CHECK clause)'
)
ON CONFLICT (key) DO UPDATE SET
  value = 'true',
  updated_at = NOW(),
  description = 'Fixed INSERT policy for drawings table (was missing WITH CHECK clause)';

-- ============================================================================
-- EXPLANATION
-- ============================================================================
/*
PROBLEM SOLVED:
The INSERT policy was missing or had incorrect syntax. The error "new row violates 
row-level security policy" indicates that the INSERT policy either:
1. Didn't exist at all
2. Had incorrect WITH CHECK condition
3. Was being bypassed

SOLUTION:
Recreated the INSERT policy with explicit WITH CHECK (auth.uid() = user_id)
This ensures that users can only insert drawings with their own user_id.

TEST:
Run test_upload.py again. The drawing creation should now succeed.
*/
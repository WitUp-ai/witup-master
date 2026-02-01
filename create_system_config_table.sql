-- =====================================================
-- SYSTEM_CONFIG TABLE FOR DRAW2TOY PIVOT
-- =====================================================
-- Created: 2026-01-29
-- Purpose: Dynamic configuration storage for API keys and AI models
-- =====================================================

-- Create system_config table
CREATE TABLE IF NOT EXISTS public.system_config (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Configuration key (unique identifier)
    key TEXT NOT NULL UNIQUE,
    
    -- Configuration value (encrypted at rest)
    value TEXT NOT NULL,
    
    -- Human-readable description
    description TEXT,
    
    -- Metadata
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_by UUID REFERENCES public.users(id) ON DELETE SET NULL,
    
    -- Constraints
    CONSTRAINT valid_key_format CHECK (key ~ '^[A-Z_][A-Z0-9_]*$')
);

-- Create index for faster lookups
CREATE INDEX IF NOT EXISTS idx_system_config_key ON public.system_config(key);
CREATE INDEX IF NOT EXISTS idx_system_config_updated ON public.system_config(updated_at DESC);

-- Enable Row Level Security
ALTER TABLE public.system_config ENABLE ROW LEVEL SECURITY;

-- RLS Policies
-- Only service_role (backend) and admin users can access system_config
CREATE POLICY "Service role full access" ON public.system_config
    FOR ALL USING (auth.jwt() ->> 'role' = 'service_role');

-- Admin users (with custom claim) can read
CREATE POLICY "Admin users can read config" ON public.system_config
    FOR SELECT USING (
        auth.uid() IN (
            SELECT id FROM public.users 
            WHERE email LIKE '%@admin.draw2toy.com' -- Example admin detection
            OR EXISTS (
                SELECT 1 FROM public.users 
                WHERE id = auth.uid() 
                AND subscription_tier = 'family' -- Or other admin flag
            )
        )
    );

-- Insert default configurations (with placeholder values)
INSERT INTO public.system_config (key, value, description) VALUES
    ('REPLICATE_API_TOKEN', 'YOUR_REPLICATE_API_TOKEN', 'API Key for Replicate AI services'),
    ('MODEL_VISION', 'moondream', 'Vision AI model for drawing validation (moondream, gpt-4o-mini, etc.)'),
    ('MODEL_3D_GENERATOR', 'triposr', '3D generation model (triposr, rodin, etc.)'),
    ('PRINTER_API_KEY', 'PLACEHOLDER_PRINTER_KEY', 'API Key for 3D printing service'),
    ('SYSTEM_STATUS', 'active', 'System status: active, maintenance, disabled')
ON CONFLICT (key) DO UPDATE SET
    value = EXCLUDED.value,
    description = EXCLUDED.description,
    updated_at = NOW();

-- Create a view for non-sensitive config (for client-side use)
CREATE OR REPLACE VIEW public.system_config_public AS
SELECT 
    key,
    description,
    updated_at
FROM public.system_config
WHERE key IN ('SYSTEM_STATUS', 'MODEL_VISION', 'MODEL_3D_GENERATOR');

-- Function to get config value (with decryption placeholder)
CREATE OR REPLACE FUNCTION public.get_config(p_key TEXT)
RETURNS TEXT AS $$
DECLARE
    config_value TEXT;
BEGIN
    SELECT value INTO config_value
    FROM public.system_config
    WHERE key = p_key;
    
    RETURN config_value;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE EXCEPTION 'Configuration key % not found', p_key;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant permissions
GRANT SELECT ON public.system_config_public TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_config TO authenticated;

-- =====================================================
-- VERIFICATION QUERIES
-- =====================================================

-- Verify table creation
SELECT 'Table created: system_config' as status;

-- Show inserted configurations (mask sensitive values)
SELECT 
    key,
    CASE 
        WHEN key LIKE '%TOKEN%' OR key LIKE '%KEY%' THEN '*****' || SUBSTRING(value, -4)
        ELSE value
    END as masked_value,
    description,
    updated_at
FROM public.system_config
ORDER BY key;

-- Test the get_config function
SELECT get_config('SYSTEM_STATUS') as test_result;

-- =====================================================
-- MIGRATION NOTES
-- =====================================================
/*
1. Run this script in Supabase SQL Editor
2. Update the REPLICATE_API_TOKEN with your actual key
3. Add admin users by updating their email or adding admin flag
4. Consider encrypting sensitive values using pgcrypto:
   - CREATE EXTENSION IF NOT EXISTS pgcrypto;
   - Store: pgp_sym_encrypt('actual_value', 'encryption_key')
   - Retrieve: pgp_sym_decrypt(value::bytea, 'encryption_key')
*/

SELECT '✅ SYSTEM_CONFIG TABLE READY FOR PIVOT' as final_status;
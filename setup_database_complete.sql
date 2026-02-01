-- ============================================================================
-- Complete Database Setup Script
-- Run this in Supabase SQL Editor to set up everything automatically
-- ============================================================================

-- Step 1: Create system_config table if not exists
CREATE TABLE IF NOT EXISTS system_config (
  key text PRIMARY KEY,
  value text NOT NULL,
  description text,
  is_secret boolean DEFAULT false,
  updated_at timestamptz DEFAULT now(),
  updated_by text
);

-- Enable RLS
ALTER TABLE system_config ENABLE ROW LEVEL SECURITY;

-- RLS Policies for system_config
CREATE POLICY IF NOT EXISTS "service_role_all_system_config" ON system_config
  FOR ALL USING (auth.role() = 'service_role');

CREATE POLICY IF NOT EXISTS "admin_read_system_config" ON system_config
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.id = auth.uid()
      AND (users.role = 'admin' OR users.email = 'giovanni.sapere@witup.ai')
    )
  );

CREATE POLICY IF NOT EXISTS "admin_write_system_config" ON system_config
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.id = auth.uid()
      AND (users.role = 'admin' OR users.email = 'giovanni.sapere@witup.ai')
    )
  );

-- Step 2: Add is_secret column if doesn't exist
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'system_config' AND column_name = 'is_secret'
  ) THEN
    ALTER TABLE system_config ADD COLUMN is_secret boolean DEFAULT false;
  END IF;
END $$;

-- Step 3: Create usage_logs table
CREATE TABLE IF NOT EXISTS usage_logs (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  drawing_id uuid REFERENCES drawings(id) ON DELETE SET NULL,
  user_id uuid,
  provider text NOT NULL,
  model text,
  operation text,
  status text NOT NULL DEFAULT 'success',
  cost_estimated numeric(10,6),
  latency_ms integer,
  error_message text,
  metadata jsonb,
  created_at timestamptz DEFAULT now()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_usage_logs_created ON usage_logs(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_usage_logs_drawing ON usage_logs(drawing_id);
CREATE INDEX IF NOT EXISTS idx_usage_logs_provider ON usage_logs(provider, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_usage_logs_status ON usage_logs(status) WHERE status != 'success';

-- Enable RLS
ALTER TABLE usage_logs ENABLE ROW LEVEL SECURITY;

-- RLS Policies for usage_logs
CREATE POLICY IF NOT EXISTS "service_role_all_usage_logs" ON usage_logs
  FOR ALL USING (auth.role() = 'service_role');

CREATE POLICY IF NOT EXISTS "admin_read_usage_logs" ON usage_logs
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.id = auth.uid()
      AND (users.role = 'admin' OR users.email = 'giovanni.sapere@witup.ai')
    )
  );

CREATE POLICY IF NOT EXISTS "user_read_own_logs" ON usage_logs
  FOR SELECT USING (auth.uid() = user_id);

-- Step 4: Insert default configurations
INSERT INTO system_config (key, value, description, is_secret) VALUES
  ('REPLICATE_API_TOKEN', 'r8_YOUR_TOKEN_HERE', 'Token API principale Replicate - INSERISCI IL TUO TOKEN QUI', true),
  ('STYLE_PROMPT_CUPPY', 'A cute 3D toy character, claymation style, made of plasticine, play-doh texture, cute, puffy, volumetric, soft studio lighting, octane render, high quality, isometric view, smooth vinyl toy, tactile feeling, clean white background', 'Prompt per stilizzazione Cuppy', false),
  ('MONTHLY_SPEND_LIMIT', '10.0', 'Limite budget mensile USD', false),
  ('COST_VISION_VALIDATION', '0.002', 'Costo stimato per validazione vision (USD)', false),
  ('COST_BACKGROUND_REMOVAL', '0.005', 'Costo stimato per rimozione sfondo (USD)', false),
  ('COST_STYLIZATION', '0.02', 'Costo stimato per stilizzazione SDXL (USD)', false),
  ('COST_3D_GENERATION', '0.05', 'Costo stimato per generazione 3D (USD)', false)
ON CONFLICT (key) DO NOTHING;

-- Mark sensitive keys
UPDATE system_config SET is_secret = true
WHERE key ILIKE '%TOKEN%' OR key ILIKE '%KEY%' OR key ILIKE '%SECRET%';

-- Step 5: Verify setup
SELECT 'system_config table' as table_name, COUNT(*) as row_count FROM system_config
UNION ALL
SELECT 'usage_logs table', COUNT(*) FROM usage_logs;

-- Show current configurations (with masked secrets)
SELECT
  key,
  CASE
    WHEN is_secret THEN '***MASKED***'
    ELSE value
  END as value,
  description,
  is_secret
FROM system_config
ORDER BY key;

-- Migration: Admin & SaaS Foundation
-- Adds is_secret to system_config, creates usage_logs, inserts defaults

-- ============================================================
-- 1. ALTER system_config: add is_secret column
-- ============================================================
ALTER TABLE system_config
  ADD COLUMN IF NOT EXISTS is_secret boolean DEFAULT false;

-- Mark existing sensitive keys
UPDATE system_config SET is_secret = true
WHERE key ILIKE '%TOKEN%' OR key ILIKE '%KEY%' OR key ILIKE '%SECRET%';

-- ============================================================
-- 2. CREATE usage_logs table (Cost Intelligence)
-- ============================================================
CREATE TABLE IF NOT EXISTS usage_logs (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  drawing_id uuid REFERENCES drawings(id) ON DELETE SET NULL,
  user_id uuid,
  provider text NOT NULL,          -- 'replicate', 'openai', 'removebg'
  model text,                      -- 'triposr', 'flux-schnell', 'moondream2', 'rembg'
  operation text,                  -- 'vision_validation', 'background_removal', 'stylization', '3d_generation'
  status text NOT NULL DEFAULT 'success', -- 'success', 'error', 'error_402', 'error_timeout'
  cost_estimated numeric(10,6),    -- estimated cost in USD
  latency_ms integer,
  error_message text,
  metadata jsonb,                  -- extra info (prediction_id, tokens, etc.)
  created_at timestamptz DEFAULT now()
);

-- Indexes for analytics queries
CREATE INDEX IF NOT EXISTS idx_usage_logs_created ON usage_logs(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_usage_logs_drawing ON usage_logs(drawing_id);
CREATE INDEX IF NOT EXISTS idx_usage_logs_provider ON usage_logs(provider, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_usage_logs_status ON usage_logs(status) WHERE status != 'success';

-- ============================================================
-- 3. RLS Policies for usage_logs
-- ============================================================
ALTER TABLE usage_logs ENABLE ROW LEVEL SECURITY;

-- Service role can do everything (Edge Functions use this)
CREATE POLICY "service_role_all" ON usage_logs
  FOR ALL USING (auth.role() = 'service_role');

-- Admin users can read all logs
CREATE POLICY "admin_read_usage_logs" ON usage_logs
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.id = auth.uid()
      AND (users.role = 'admin' OR users.email IN ('giovanni.sapere@witup.ai', 'testuser@gmail.com'))
    )
  );

-- Regular users can see their own logs
CREATE POLICY "user_read_own_logs" ON usage_logs
  FOR SELECT USING (auth.uid() = user_id);

-- ============================================================
-- 4. Insert default configurations (if not present)
-- ============================================================
INSERT INTO system_config (key, value, description, is_secret) VALUES
  ('REPLICATE_API_TOKEN', '', 'Token API principale Replicate', true),
  ('STYLE_PROMPT_CUPPY', 'A cute 3D toy character, claymation style, made of plasticine, play-doh texture, cute, puffy, volumetric, soft studio lighting, octane render, high quality, isometric view, smooth vinyl toy, tactile feeling, clean white background', 'Prompt per stilizzazione Cuppy', false),
  ('MONTHLY_SPEND_LIMIT', '10.0', 'Limite budget mensile USD', false),
  ('COST_VISION_VALIDATION', '0.002', 'Costo stimato per validazione vision (USD)', false),
  ('COST_BACKGROUND_REMOVAL', '0.005', 'Costo stimato per rimozione sfondo (USD)', false),
  ('COST_STYLIZATION', '0.02', 'Costo stimato per stilizzazione SDXL (USD)', false),
  ('COST_3D_GENERATION', '0.05', 'Costo stimato per generazione 3D (USD)', false)
ON CONFLICT (key) DO NOTHING;

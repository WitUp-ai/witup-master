-- ============================================================================
-- SETUP COMPLETO DATABASE - Esecuzione Automatica
-- ============================================================================

-- Step 1: Crea tabella system_config (se non esiste)
CREATE TABLE IF NOT EXISTS system_config (
  key text PRIMARY KEY,
  value text NOT NULL,
  description text,
  is_secret boolean DEFAULT false,
  updated_at timestamptz DEFAULT now(),
  updated_by text
);

-- Abilita RLS
ALTER TABLE system_config ENABLE ROW LEVEL SECURITY;

-- Step 2: Drop existing policies (se esistono)
DROP POLICY IF EXISTS "service_role_all_system_config" ON system_config;
DROP POLICY IF EXISTS "admin_read_system_config" ON system_config;
DROP POLICY IF EXISTS "admin_write_system_config" ON system_config;
DROP POLICY IF EXISTS "authenticated_read_public_config" ON system_config;

-- Step 3: Crea policies per system_config
CREATE POLICY "service_role_all_system_config" ON system_config
  FOR ALL USING (auth.role() = 'service_role');

CREATE POLICY "admin_read_system_config" ON system_config
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.id = auth.uid()
      AND (users.role = 'admin' OR users.email = 'giovanni.sapere@witup.ai')
    )
  );

CREATE POLICY "admin_write_system_config" ON system_config
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.id = auth.uid()
      AND (users.role = 'admin' OR users.email = 'giovanni.sapere@witup.ai')
    )
  );

CREATE POLICY "authenticated_read_public_config" ON system_config
  FOR SELECT USING (
    auth.role() = 'authenticated' AND is_secret = false
  );

-- Step 4: Crea tabella usage_logs (se non esiste)
CREATE TABLE IF NOT EXISTS usage_logs (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  drawing_id uuid,
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

-- Indici per performance
CREATE INDEX IF NOT EXISTS idx_usage_logs_created ON usage_logs(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_usage_logs_drawing ON usage_logs(drawing_id);
CREATE INDEX IF NOT EXISTS idx_usage_logs_provider ON usage_logs(provider, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_usage_logs_status ON usage_logs(status) WHERE status != 'success';

-- Abilita RLS
ALTER TABLE usage_logs ENABLE ROW LEVEL SECURITY;

-- Step 5: Drop existing policies
DROP POLICY IF EXISTS "service_role_all_usage_logs" ON usage_logs;
DROP POLICY IF EXISTS "admin_read_usage_logs" ON usage_logs;
DROP POLICY IF EXISTS "user_read_own_logs" ON usage_logs;

-- Step 6: Crea policies per usage_logs
CREATE POLICY "service_role_all_usage_logs" ON usage_logs
  FOR ALL USING (auth.role() = 'service_role');

CREATE POLICY "admin_read_usage_logs" ON usage_logs
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.id = auth.uid()
      AND (users.role = 'admin' OR users.email = 'giovanni.sapere@witup.ai')
    )
  );

CREATE POLICY "user_read_own_logs" ON usage_logs
  FOR SELECT USING (auth.uid() = user_id);

-- Step 7: Inserisci configurazioni default
INSERT INTO system_config (key, value, description, is_secret) VALUES
  ('REPLICATE_API_TOKEN', '', 'Token API principale Replicate', true),
  ('STYLE_PROMPT_CUPPY', 'A cute 3D toy character, claymation style, made of plasticine, play-doh texture, cute, puffy, volumetric, soft studio lighting, octane render, high quality, isometric view, smooth vinyl toy, tactile feeling, clean white background', 'Prompt per stilizzazione Cuppy', false),
  ('MONTHLY_SPEND_LIMIT', '10.0', 'Limite budget mensile USD', false),
  ('COST_VISION_VALIDATION', '0.002', 'Costo stimato per validazione vision (USD)', false),
  ('COST_BACKGROUND_REMOVAL', '0.005', 'Costo stimato per rimozione sfondo (USD)', false),
  ('COST_STYLIZATION', '0.02', 'Costo stimato per stilizzazione SDXL (USD)', false),
  ('COST_3D_GENERATION', '0.05', 'Costo stimato per generazione 3D (USD)', false)
ON CONFLICT (key) DO NOTHING;

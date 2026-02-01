# 🔧 Setup Manuale Database - ESEGUIRE SUBITO

## ⚠️ IMPORTANTE: Il database NON è configurato correttamente

L'app va in errore perché mancano tabelle nel database. Esegui questo setup ORA.

---

## 📍 Dove Eseguire

1. Vai su: **https://supabase.com/dashboard/project/rnfzzmfpykbavuirypfz/sql/new**
2. Copia TUTTO il codice SQL qui sotto
3. Incolla nel SQL Editor
4. Click **"RUN"** (bottone verde)
5. ✅ Done!

---

## 📋 SQL DA ESEGUIRE (Copia tutto)

```sql
-- ============================================================================
-- SETUP COMPLETO DATABASE - Draw2Toy
-- Esegui questo script UNA VOLTA nel Supabase SQL Editor
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
  ('REPLICATE_API_TOKEN', '', 'Token API principale Replicate - INSERISCI IL TUO TOKEN DOPO', true),
  ('STYLE_PROMPT_CUPPY', 'A cute 3D toy character, claymation style, made of plasticine, play-doh texture, cute, puffy, volumetric, soft studio lighting, octane render, high quality, isometric view, smooth vinyl toy, tactile feeling, clean white background', 'Prompt per stilizzazione Cuppy', false),
  ('MONTHLY_SPEND_LIMIT', '10.0', 'Limite budget mensile USD', false),
  ('COST_VISION_VALIDATION', '0.002', 'Costo stimato per validazione vision (USD)', false),
  ('COST_BACKGROUND_REMOVAL', '0.005', 'Costo stimato per rimozione sfondo (USD)', false),
  ('COST_STYLIZATION', '0.02', 'Costo stimato per stilizzazione SDXL (USD)', false),
  ('COST_3D_GENERATION', '0.05', 'Costo stimato per generazione 3D (USD)', false)
ON CONFLICT (key) DO NOTHING;

-- Step 8: Verifica setup
SELECT 'Setup completato!' as status;
SELECT 'system_config:' as table_name, COUNT(*) as rows FROM system_config;
SELECT 'usage_logs:' as table_name, COUNT(*) as rows FROM usage_logs;

-- Mostra configurazioni (secrets mascherati)
SELECT
  key,
  CASE
    WHEN is_secret THEN '***INSERISCI TOKEN***'
    ELSE value
  END as value,
  description,
  is_secret
FROM system_config
ORDER BY key;
```

---

## ✅ Dopo aver eseguito lo script

Dovresti vedere nell'output:

```
Setup completato!

system_config: 7 rows
usage_logs: 0 rows

key                      | value                  | description
-------------------------|------------------------|----------------------------------
COST_3D_GENERATION       | 0.05                   | Costo stimato per generazione 3D
COST_BACKGROUND_REMOVAL  | 0.005                  | Costo stimato per rimozione sfondo
COST_STYLIZATION         | 0.02                   | Costo stimato per stilizzazione
COST_VISION_VALIDATION   | 0.002                  | Costo stimato per validazione vision
MONTHLY_SPEND_LIMIT      | 10.0                   | Limite budget mensile USD
REPLICATE_API_TOKEN      | ***INSERISCI TOKEN***  | Token API principale Replicate
STYLE_PROMPT_CUPPY       | A cute 3D toy...       | Prompt per stilizzazione Cuppy
```

---

## 🔑 STEP CRITICO: Inserisci il Token Replicate

Dopo aver eseguito lo script, devi inserire il tuo token Replicate:

### Opzione A: Via SQL Editor

```sql
UPDATE system_config
SET value = 'r8_IL_TUO_TOKEN_QUI'
WHERE key = 'REPLICATE_API_TOKEN';
```

### Opzione B: Via Admin Panel (dopo login)

1. Login: https://web-wit-up.vercel.app/login
2. Email: `giovanni.sapere@witup.ai`
3. Password: `Gnotti2025!`
4. Naviga a: https://web-wit-up.vercel.app/admin
5. Tab "API & Config"
6. Click "Edit" su `REPLICATE_API_TOKEN`
7. Inserisci il tuo token: `r8_XXXXXXXXXXXXXXXXXXXXXXX`
8. Click "Save"

**Dove trovo il token Replicate?**
https://replicate.com/account/api-tokens

---

## 🔄 Verifica che funziona

Dopo aver configurato tutto:

1. Logout dall'app (se loggato)
2. Login con `giovanni.sapere@witup.ai` / `Gnotti2025!`
3. Vai su Home
4. **Scatta una foto / Carica un disegno**
5. ✅ Dovrebbe processare senza errori!

---

## 🐛 Se vedi ancora errori

Controlla i logs Edge Function:

```bash
# Nel terminal
cd "d:\Giovanni Sapere\Documents\Test_Project_01"
./supabase.exe functions list
./supabase.exe functions logs process-drawing --limit 100
```

O vai su:
https://supabase.com/dashboard/project/rnfzzmfpykbavuirypfz/functions/process-drawing/logs

---

## ❓ FAQ

**Q: "Permission denied for table system_config"**
A: Le RLS policies non sono state create. Riesegui lo script completo.

**Q: "relation system_config does not exist"**
A: La tabella non è stata creata. Riesegui lo script completo.

**Q: "REPLICATE_API_TOKEN is empty"**
A: Devi inserire il token Replicate (vedi step sopra).

**Q: "L'app va ancora in errore dopo setup"**
A: Controlla i logs Edge Function (link sopra) e inviami lo screenshot dell'errore.

---

**Creato**: 1 Febbraio 2026
**Urgenza**: ALTA - Esegui questo script PRIMA di testare l'app di nuovo

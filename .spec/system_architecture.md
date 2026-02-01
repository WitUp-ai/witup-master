# System Architecture: Draw2Toy SaaS Platform Complete

**Status**: ✅ Revised for SaaS Platform Evolution  
**Date**: 31 Gennaio 2026  
**Decision Makers**: CTO, Lead Architect  
**Framework**: WITUP Master Blueprint (Updated for SaaS)

---

## Context

Draw2Toy evolve da MVP a **SaaS Platform Completa** con gestione Business & Admin professionale. Il sistema deve diventare "Vendor Agnostic" (posso cambiare AI quando voglio) e "Business Ready" (so quanto spendo e incasso).

Nuovi requisiti post-MVP:
- **AI Orchestrator Layer**: Astrazione per provider AI multipli (Replicate, OpenAI, TripoSR, Meshy, etc.)
- **Cost Intelligence**: Tracking dettagliato costi AI per ogni chiamata, con dashboard consumi
- **CRM & SaaS Management**: Gestione utenti completa, credit system, integrazione Stripe nativa
- **Admin Panel Professional**: Configurazione dinamica senza toccare codice

Obiettivi tecnici:
- **Vendor Agnostic**: Switch provider AI senza deploy
- **Cost Transparency**: Margine chiaro per disegno (costo vs prezzo)
- **Subscription Ready**: Gestione abbonamenti, crediti, quota enforcement
- **Admin Control**: Configurazione UI-driven di tutto il sistema

---

## Architecture Overview: SaaS Platform Complete

```
┌─────────────────────────────────────────────────────────────────┐
│                        CLIENT LAYER                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ┌──────────────────┐              ┌──────────────────┐         │
│  │   Mobile App     │              │   Admin Panel    │         │
│  │   (Flutter PWA)  │              │   (Next.js 14)   │         │
│  │                  │              │                  │         │
│  │  • AR Viewer     │              │  • AI Provider   │         │
│  │  • Camera        │              │    Management    │         │
│  │  • Gallery       │              │  • Cost Dashboard│         │
│  │  • Profile       │              │  • User CRM      │         │
│  │  • Credits       │              │  • Billing       │         │
│  └────────┬─────────┘              └────────┬─────────┘         │
│           │                                 │                   │
└───────────┼─────────────────────────────────┼───────────────────┘
            │                                 │
            │         ┌───────────────────────┘
            │         │
            ▼         ▼
┌─────────────────────────────────────────────────────────────────┐
│                      API GATEWAY LAYER                           │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│              ┌──────────────────────────────┐                   │
│              │   Supabase Edge Functions    │                   │
│              │   (Deno Runtime)             │                   │
│              │                              │                   │
│              │  • AI Orchestrator           │                   │
│              │  • Cost Tracking             │                   │
│              │  • Quota Enforcement         │                   │
│              │  • Stripe Webhook            │                   │
│              └──────────┬───────────────────┘                   │
│                         │                                        │
└─────────────────────────┼────────────────────────────────────────┘
                          │
         ┌────────────────┼────────────────┐
         │                │                │
         ▼                ▼                ▼
┌─────────────────┐ ┌──────────────┐ ┌──────────────┐
│ AI ORCHESTRATOR │ │   SUPABASE   │ │   STRIPE     │
│   & GATEWAY     │ │   BACKEND    │ │   BILLING    │
└─────────────────┘ └──────────────┘ └──────────────┘
         │                │                │
         ▼                ▼                ▼
┌─────────────────────────────────────────────────────┐
│              DATA & STORAGE LAYER                    │
├─────────────────────────────────────────────────────┤
│                                                       │
│  ┌──────────────┐  ┌──────────────┐  ┌───────────┐ │
│  │  PostgreSQL  │  │   S3/Bucket  │  │   Redis   │ │
│  │  (Supabase)  │  │  (Supabase)  │  │  (Cache)  │ │
│  │              │  │              │  │           │ │
│  │ • New Tables │  │ • Images     │  │ • Session │ │
│  │   usage_logs │  │ • 3D Files   │  │ • Queue   │ │
│  │   ai_providers│ │ • Thumbnails │  │ • Temp    │ │
│  │   plans      │  │ • AR Assets  │  │           │ │
│  │   prompts    │  │              │  │           │ │
│  └──────────────┘  └──────────────┘  └───────────┘ │
│                                                       │
└─────────────────────────────────────────────────────┘
```

---

## Component Details: New SaaS Modules

### 0. ROBUSTEZZA INFRASTRUTTURALE (Stabilità Operativa - PRIORITÀ CRITICA)

**Problema**: Blocchi dovuti a "Spend Limits" di Replicate non gestiti e mancanza di visibilità sui consumi in tempo reale.

**Soluzione**: Sistema di error handling avanzato, health check automatico e notifiche critiche per billing issues.

#### Error Handling Avanzato:
```
Flusso di gestione errori:
1. AI Orchestrator intercetta tutte le risposte dai provider AI
2. Classifica errori in categorie:
   - "Billing Error" (402 Payment Required, 429 Rate Limit, 403 Insufficient Credits)
   - "Network Error" (Timeout, Connection Refused)
   - "Model Error" (Invalid Input, Model Unavailable)
   - "Generic Error" (Altri 4xx/5xx)

3. Per "Billing Error" (402):
   - Logga immediatamente in `system_alerts` con severity = "CRITICAL"
   - Notifica Admin via dashboard con badge rosso
   - Auto-switch a provider di fallback se configurato
   - Blocca nuove richieste fino a risoluzione (opzionale)

4. Per altri errori:
   - Logga in `usage_logs` con `success = false`
   - Implementa retry intelligente (max 2 retry con backoff)
   - Fallback automatico a provider secondario
```

#### Health Check System:
```sql
-- Tabella per health check
CREATE TABLE provider_health_checks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    ai_provider_id UUID REFERENCES ai_providers(id),
    check_type TEXT NOT NULL,              -- 'api_key_validation', 'credit_check', 'model_available'
    status TEXT NOT NULL,                  -- 'healthy', 'warning', 'critical'
    response_time_ms INTEGER,
    error_message TEXT,
    checked_at TIMESTAMPTZ DEFAULT NOW()
);

-- Funzione di health check all'avvio
CREATE OR REPLACE FUNCTION perform_provider_health_check()
RETURNS VOID AS $$
DECLARE
    provider RECORD;
BEGIN
    FOR provider IN SELECT * FROM ai_providers WHERE is_active = true
    LOOP
        -- 1. Verifica API Key (dry-run call minima)
        -- 2. Verifica crediti disponibili (se provider supporta)
        -- 3. Verifica modello disponibile
        -- 4. Inserisce risultato in provider_health_checks
    END LOOP;
END;
$$ LANGUAGE plpgsql;
```

#### Sistema di Alerting Critico:
- **Dashboard Admin**: Sezione "System Alerts" con badge per errori non risolti
- **Notifiche Push**: Integrazione con Slack/Telegram per alert critici (402 errors)
- **Escalation**: Alert non risolti in 1h → notifica via email a CTO
- **Audit Trail**: Tutti gli alert loggati con azioni di risoluzione

### 1. ADMIN & CONFIGURATION DASHBOARD (Flutter Web - Nuovo Modulo)

**Problema**: Configurazione attuale tramite variabili d'ambiente e codice hardcoded. L'admin non ha visibilità o controllo in tempo reale.

**Soluzione**: Pannello Admin integrato in Flutter Web per configurazione dinamica di tutto il sistema.

#### Tabella `system_config` (Extended):
```sql
-- Estensione della tabella system_config esistente
CREATE TABLE system_config (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    key TEXT NOT NULL UNIQUE,              -- Es: 'REPLICATE_API_TOKEN', 'OPENAI_API_KEY', 'MODEL_STYLE_PROMPT'
    value TEXT NOT NULL,                   -- Valore crittografato per API keys
    description TEXT,
    category TEXT NOT NULL,                -- 'ai_provider', 'prompt', 'billing', 'system'
    is_encrypted BOOLEAN DEFAULT true,
    is_sensitive BOOLEAN DEFAULT true,     -- Se true, value viene crittografato
    updated_by UUID REFERENCES users(id),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Configurazioni predefinite
INSERT INTO system_config (key, value, description, category, is_sensitive) VALUES
('REPLICATE_API_TOKEN', '', 'API Token per Replicate', 'ai_provider', true),
('OPENAI_API_KEY', '', 'API Key per OpenAI', 'ai_provider', true),
('MODEL_STYLE_PROMPT', 'Convert this drawing into a cute 3D character in Cuppy style', 'Prompt principale per generazione 3D', 'prompt', false),
('DEFAULT_AI_PROVIDER', 'replicate', 'Provider AI predefinito', 'system', false),
('BILLING_ALERT_THRESHOLD', '100', 'Soglia alert costo giornaliero (€)', 'billing', false);
```

#### Admin Panel Structure (Flutter Web):
```
/admin
├── /dashboard           # Overview sistema (health, alert, stats)
├── /ai-providers        # Gestione provider AI (add/edit/activate)
├── /prompts             # Editor prompt system (WYSIWYG)
├── /billing            # Monitor costi e crediti
├── /users              # CRM utenti (search, ban, quota)
└── /system             # Configurazione avanzata (API keys, webhook)
```

#### Funzionalità Admin Panel:
1. **Provider Switching**:
   - Dropdown per selezionare provider attivo per ogni tipo (image/3d/vision)
   - Configurazione fallback automatico (se provider A down → passa a B)
   - Test connessione in tempo reale (ping API)

2. **Prompt Management**:
   - Editor WYSIWYG per modificare System Prompts
   - Versioning dei prompt (salvataggio storico)
   - Preview anteprima con esempio

3. **Billing Monitor**:
   - Visualizzazione costo giornaliero/mensile
   - Breakdown per provider (Replicate vs OpenAI)
   - Alert configurabili per soglie costo
   - Stima margine per disegno (costo AI vs prezzo vendita)

4. **System Health**:
   - Status provider AI (up/down)
   - Queue depth processing
   - Error rate ultime 24h
   - Log viewer per debug

#### Security per Admin Panel:
- **Role-Based Access Control**: Solo utenti con ruolo 'admin' possono accedere
- **Audit Trail**: Tutte le modifiche di configurazione loggate
- **API Key Encryption**: Chiavi crittografate a riposo, decrittate solo al bisogno
- **Session Timeout**: Auto-logout dopo 30 minuti di inattività

### 2. AI ORCHESTRATOR & GATEWAY MODULE (Nuova Core Feature - Enhanced)

**Problema**: Attualmente chiamate hardcoded a Replicate. Il sistema deve essere vendor-agnostic e resiliente.

**Soluzione**: Layer di astrazione per provider AI multipli con configurazione dinamica e gestione errori avanzata.

#### Tabella `ai_providers`
```sql
CREATE TABLE ai_providers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,                    -- 'replicate', 'openai', 'meshy', 'triposr'
    provider_type TEXT NOT NULL,           -- 'image_generation', '3d_generation', 'vision'
    api_endpoint TEXT,                     -- URL API (se REST)
    api_key_encrypted TEXT,                -- Chiave API crittografata
    model_name TEXT,                       -- 'moondream2', 'dall-e-3', 'triposr'
    cost_per_token DECIMAL(10, 6),        -- Costo per token input
    cost_per_second DECIMAL(10, 6),       -- Costo per secondo GPU
    is_active BOOLEAN DEFAULT true,
    priority INTEGER DEFAULT 1,            -- Ordine di priorità (1 = default)
    config_json JSONB,                     -- Configurazione specifica provider
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

#### Tabella `system_prompts`
```sql
CREATE TABLE system_prompts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,                    -- 'cuppy_style', 'cartoon_style'
    prompt_type TEXT NOT NULL,             -- 'image_generation', '3d_generation'
    content TEXT NOT NULL,                 -- Il prompt system
    description TEXT,
    is_active BOOLEAN DEFAULT true,
    ai_provider_id UUID REFERENCES ai_providers(id),
    version INTEGER DEFAULT 1,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

#### Flow AI Orchestrator:
```
1. Client invoca `/ai/process` con drawing_id
2. Edge Function "orchestrator" legge:
   - Configurazione AI attiva (da ai_providers)
   - Prompt system (da system_prompts)
   - Quota utente (da users/subscriptions)
3. Seleziona provider in base a:
   - Provider attivo per tipo (image_generation → OpenAI DALL-E 3)
   - Priorità (fallback se primo non disponibile)
   - Costo (se configurato per ottimizzazione)
4. Invia richiesta al provider con:
   - Prompt system + user input
   - Tracking ID per logging costi
5. Logga costo nella tabella `usage_logs`
6. Ritorna risultato al client
```

#### Admin Configuration UI:
- **Dashboard Admin**: Menu dropdown per selezionare provider attivo
- **Prompt Editor**: WYSIWYG per modificare System Prompts
- **Cost Preview**: Anteprima costo per provider selezionato
- **A/B Testing**: Possibilità di testare provider diversi per % traffico

### 3. COST INTELLIGENCE MODULE (Unit Economics)

**Problema**: Non sappiamo quanto ci costa ogni utente/disegno.

**Soluzione**: Tracking dettagliato di ogni chiamata AI con costo stimato.

#### Tabella `usage_logs`
```sql
CREATE TABLE usage_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id),
    drawing_id UUID REFERENCES drawings(id),
    ai_provider_id UUID REFERENCES ai_providers(id),
    operation_type TEXT NOT NULL,          -- 'image_generation', '3d_generation', 'vision_validation'
    
    -- Metriche consumo
    input_tokens INTEGER,
    output_tokens INTEGER,
    processing_seconds DECIMAL(10, 2),
    gpu_seconds DECIMAL(10, 2),
    
    -- Costi
    estimated_cost DECIMAL(10, 6),        -- Costo stimato in USD/EUR
    currency TEXT DEFAULT 'USD',
    
    -- Metadata
    model_name TEXT,
    prompt_tokens INTEGER,
    completion_tokens INTEGER,
    
    -- Status
    success BOOLEAN DEFAULT true,
    error_message TEXT,
    
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indici per analisi costi
CREATE INDEX idx_usage_logs_user_date ON usage_logs(user_id, DATE(created_at));
CREATE INDEX idx_usage_logs_provider_date ON usage_logs(ai_provider_id, DATE(created_at));
CREATE INDEX idx_usage_logs_drawing_id ON usage_logs(drawing_id);
```

#### Dashboard Consumi:
```
Viste analitiche:

1. **Costo Totale Giornaliero/Mensile**
   SELECT DATE(created_at) as day, SUM(estimated_cost) as total_cost
   FROM usage_logs
   GROUP BY DATE(created_at)
   ORDER BY day DESC;

2. **Breakdown per Provider**
   SELECT p.name as provider, SUM(l.estimated_cost) as total_cost
   FROM usage_logs l
   JOIN ai_providers p ON l.ai_provider_id = p.id
   GROUP BY p.name
   ORDER BY total_cost DESC;

3. **Margine per Disegno**
   SELECT 
     d.id as drawing_id,
     l.estimated_cost as ai_cost,
     o.total_amount as revenue,
     (o.total_amount - l.estimated_cost) as margin
   FROM drawings d
   JOIN usage_logs l ON d.id = l.drawing_id
   LEFT JOIN orders o ON d.id = o.drawing_id
   WHERE o.status = 'delivered';
```

#### Alerting Costi:
- **Soglia giornaliera**: Alert se costo > €100/giorno
- **Provider inefficente**: Alert se costo/token > media del 20%
- **Anomalie**: Spike costi improvvisi (>3x media storica)

### 4. CRM & SAAS MANAGEMENT MODULE

#### Tabella `plans` (Modello Business a Crediti/Abbonamento)
```sql
CREATE TABLE plans (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,                    -- 'free', 'basic', 'pro', 'enterprise'
    tier TEXT NOT NULL,                    -- 'free', 'paid'
    
    -- Modello pricing
    pricing_model TEXT NOT NULL,           -- 'credits', 'subscription', 'pay_as_you_go'
    monthly_price DECIMAL(10, 2),          -- Prezzo mensile (se subscription)
    
    -- Limiti
    monthly_credits INTEGER,               -- Credit mensili inclusi
    credit_cost DECIMAL(10, 6),            -- Costo per credito extra
    max_drawings_per_month INTEGER,        -- Limite disegni
    max_children_profiles INTEGER,         -- Limite profili bambini
    
    -- Features
    has_priority_queue BOOLEAN DEFAULT false,
    has_custom_styles BOOLEAN DEFAULT false,
    has_bulk_export BOOLEAN DEFAULT false,
    
    stripe_price_id TEXT,                  -- ID prezzo Stripe
    is_active BOOLEAN DEFAULT true,
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

#### Tabella `user_credits` (Sistema Credit)
```sql
CREATE TABLE user_credits (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) UNIQUE,
    balance INTEGER DEFAULT 0,             -- Credit attuali
    total_earned INTEGER DEFAULT 0,        -- Credit guadagnati totali
    total_spent INTEGER DEFAULT 0,         -- Credit spesi totali
    
    -- Reset mensile
    monthly_credits_used INTEGER DEFAULT 0,
    last_reset_date DATE DEFAULT CURRENT_DATE,
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

#### Tabella `credit_transactions`
```sql
CREATE TABLE credit_transactions (
    id UUID PRIMARY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id),
    amount INTEGER NOT NULL,               -- + per acquisto, - per utilizzo
    transaction_type TEXT NOT NULL,        -- 'purchase', 'usage', 'bonus', 'refund'
    description TEXT,
    
    -- Riferimenti
    drawing_id UUID REFERENCES drawings(id),
    order_id UUID REFERENCES orders(id),
    stripe_payment_id TEXT,
    
    balance_before INTEGER,
    balance_after INTEGER,
    
    created_at TIMESTAMptz DEFAULT NOW()
);
```

#### Integrazione Stripe Completa:
```
Webhook Stripe configurati:

1. **checkout.session.completed**
   → Crea subscription in DB
   → Aggiorna user.subscription_status
   → Assegna crediti (se plan a crediti)

2. **invoice.paid**
   → Conferma pagamento
   → Estendi subscription

3. **customer.subscription.updated**
   → Aggiorna tier/plan utente
   → Modifica limiti mensili

4. **customer.subscription.deleted**
   → Downgrade a free
   → Preserva dati ma blocca nuove features

5. **payment_intent.succeeded/failed**
   → Log transazione in credit_transactions
```

#### Quota Management:
```sql
-- Funzione per validare se utente può creare disegno
CREATE OR REPLACE FUNCTION can_user_create_drawing(user_uuid UUID)
RETURNS TABLE(can_create BOOLEAN, reason TEXT) AS $$
DECLARE
    user_plan RECORD;
    user_credit RECORD;
    drawings_this_month INTEGER;
BEGIN
    -- Ottieni plan utente
    SELECT p.* INTO user_plan
    FROM users u
    JOIN plans p ON u.plan_id = p.id
    WHERE u.id = user_uuid;
    
    -- Ottieni crediti utente
    SELECT * INTO user_credit FROM user_credits WHERE user_id = user_uuid;
    
    -- Conta disegni questo mese
    SELECT COUNT(*) INTO drawings_this_month
    FROM drawings
    WHERE user_id = user_uuid
      AND DATE_TRUNC('month', created_at) = DATE_TRUNC('month', CURRENT_DATE);
    
    -- Validazione in base a modello pricing
    IF user_plan.pricing_model = 'subscription' THEN
        -- Modello abbonamento: controlla limite mensile
        IF drawings_this_month >= user_plan.max_drawings_per_month THEN
            RETURN QUERY SELECT false, 'Monthly drawing limit reached';
        ELSE
            RETURN QUERY SELECT true, 'OK';
        END IF;
        
    ELSIF user_plan.pricing_model = 'credits' THEN
        -- Modello crediti: controlla saldo
        IF user_credit.balance <= 0 THEN
            RETURN QUERY SELECT false, 'Insufficient credits';
        ELSE
            RETURN QUERY SELECT true, 'OK';
        END IF;
        
    ELSE -- free tier
        IF drawings_this_month >= user_plan.max_drawings_per_month THEN
            RETURN QUERY SELECT false, 'Free tier limit reached';
        ELSE
            RETURN QUERY SELECT true, 'OK';
        END IF;
    END IF;
END;
$$ LANGUAGE plpgsql;
```

---

## DEPLOYMENT CHECKLIST (Piano di Test Reali)

### Pre-Deployment Verification:
- [ ] **Replicate Spend Limit**: Verificare che il limite di spesa su Replicate sia > 0
- [ ] **API Key Validation**: Tutte le API Key devono essere presenti in Supabase Secrets (non solo .env)
- [ ] **Webhook Accessibility**: I webhook devono essere raggiungibili pubblicamente (ngrok/local tunnel per sviluppo)
- [ ] **Database Migrations**: Script di migrazione testato in ambiente staging
- [ ] **Health Check**: Funzione di health check deployata e funzionante

### Post-Deployment Testing:
- [ ] **Error 402 Simulation**: Testare risposta sistema a errori "Payment Required"
- [ ] **Provider Fallback**: Verificare switch automatico a provider secondario
- [ ] **Cost Tracking**: Confermare che `usage_logs` registra costi corretti
- [ ] **Admin Panel Access**: Verificare RBAC e accesso sicuro al pannello admin
- [ ] **Stripe Webhook**: Test ricezione e processing webhook Stripe

### Monitoring Setup:
- [ ] **Alert Configuration**: Configurare alert per errori 402 e soglie costo
- [ ] **Dashboard Verification**: Confermare che dashboard mostri dati corretti
- [ ] **Log Aggregation**: Setup centralizzato log per debugging
- [ ] **Performance Baseline**: Stabilire baseline performance per detection anomalie

---

## Database Schema Updates

### Modifiche a tabelle esistenti:

#### `users` table - Aggiunte colonne:
```sql
ALTER TABLE users 
ADD COLUMN plan_id UUID REFERENCES plans(id),
ADD COLUMN stripe_customer_id TEXT,
ADD COLUMN credits_balance INTEGER DEFAULT 0,
ADD COLUMN billing_email TEXT;
```

#### `drawings` table - Aggiunte colonne:
```sql
ALTER TABLE drawings
ADD COLUMN ai_provider_used UUID REFERENCES ai_providers(id),
ADD COLUMN estimated_ai_cost DECIMAL(10, 6),
ADD COLUMN credits_spent INTEGER DEFAULT 1;
```

### Nuove tabelle aggiunte:
1. **ai_providers** - Provider AI configurabili
2. **system_prompts** - Prompt system editabili
3. **usage_logs** - Log consumi AI con costi
4. **plans** - Piani tariffari
5. **user_credits** - Saldo crediti utente
6. **credit_transactions** - Transazioni crediti
7. **system_config** - Configurazioni dinamiche
8. **provider_health_checks** - Health check provider

---

## Security Architecture Updates

### API Key Management:
- **Encryption at rest**: Tutte le API key in `ai_providers.api_key_encrypted` crittografate
- **Key Rotation**: Rotazione automatica ogni 90 giorni
- **Access Control**: Solo service_role può leggere/aggiornare chiavi

### Quota Enforcement:
- **Pre-flight check**: Edge Function valida quota prima di chiamare AI
- **Real-time deduction**: Credit spesi immediatamente al consumo
- **Grace period**: 24h per completare disegni già avviati anche se crediti finiti

### Audit Trail:
- **Tutte le operazioni AI** loggate in `usage_logs`
- **Tutte le transazioni crediti** in `credit_transactions`
- **Admin actions** in `admin_logs` esistente

---

## Monitoring & Analytics Updates

### New Dashboards:

#### 1. **Cost Intelligence Dashboard**
- Costo totale per periodo
- Breakdown per provider AI
- Margine medio per disegno (costo AI vs prezzo vendita)
- Alert costi anomali

#### 2. **User & Revenue Dashboard**
- MRR (Monthly Recurring Revenue)
- Churn rate
- Conversion rate (free → paid)
- LTV (Lifetime Value) per utente

#### 3. **AI Performance Dashboard**
- Success rate per provider
- Average processing time
- Error rate e root cause analysis
- Cost optimization suggestions

### Alerting:
- **Business Critical**: MRR drop >10%, Churn rate >5%
- **Cost Alert**: Daily AI cost > €100, Provider cost increase >20%
- **System Alert**: AI provider downtime, Stripe webhook failures

---

## Migration Strategy

### Phase 1: Schema Deployment
1. Deploy nuove tabelle (`ai_providers`, `system_prompts`, `usage_logs`, `plans`, etc.)
2. Migrare dati esistenti:
   - Default provider: Replicate (configurazione attuale)
   - Default plan: 'free' per tutti gli utenti
   - Migrare subscription esistenti a nuovi piani
3. Aggiornare colonne tabelle esistenti

### Phase 2: Feature Rollout
1. **Admin Panel**: UI per configurazione AI providers
2. **Cost Tracking**: Logging costi su tutte le nuove chiamate AI
3. **Credit System**: Opzionale inizialmente, poi obbligatorio

### Phase 3: Complete Transition
1. Disattivare chiamate AI dirette
2. Forzare tutti i flussi attraverso AI Orchestrator
3. Abilitare quota enforcement per tutti gli utenti

---

## Cost Projection (Updated)

### Infrastructure Costs (Year 1 - SaaS Platform):
```
Supabase (Pro):           €350/month   = €4,200/year    (+40% per nuove tabelle)
AI Processing (Multi-provider): €750/month   = €9,000/year    (+50% per fallback)
Stripe Fees (2.9% + €0.30): Variabile (~€500/month) = €6,000/year
Monitoring (Enhanced):    €150/month   = €1,800/year
Other Services:           €250/month   = €3,000/year
────────────────────────────────────────────────────
TOTAL:                    €2,000/month = €24,000/year
```

**ROI Justification**:
- **Cost Transparency**: Sapere margine esatto per disegno
- **Vendor Flexibility**: Risparmio 20-40% switching provider più economico
- **Upsell Opportunities**: Tiered pricing aumenta ARPU del 30%

---

## Conclusion

Questa architettura trasforma Draw2Toy da MVP a **SaaS Platform Completa**:

✅ **Vendor Agnostic**: Posso cambiare provider AI senza deploy  
✅ **Cost Transparent**: So esattamente margine per ogni disegno  
✅ **Business Ready**: CRM, billing, quota management integrato  
✅ **Admin Control**: Configurazione dinamica senza toccare codice  
✅ **Scalable**: Fondamenta per crescita a 100k+ utenti

---

**Next Steps**:
1. ✅ Architecture defined (this document)
2. ⏳ Update database schema with new tables
3. ⏳ Create implementation plan with phases
4. ⏳ Develop Admin Panel for configuration
5. ⏳ Migrate existing users/data

**Approval**: ⏳ Pending Review

---

**Document Owner**: Lead Architect  
**Last Updated**: 31 Gennaio 2026  
**Version**: 2.0 (SaaS Platform Edition)
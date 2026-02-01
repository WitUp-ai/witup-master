# Implementation Plan: Draw2Toy SaaS Platform Evolution

**Status**: ✅ Updated for SaaS Platform  
**Date**: 31 Gennaio 2026  
**Framework**: WITUP Master Blueprint  
**Version**: 2.0

---

## Overview

Questo piano descrive l'implementazione dell'evoluzione da MVP a **SaaS Platform Completa** con gestione Business & Admin professionale. Il focus è rendere il sistema "Vendor Agnostic" (posso cambiare AI quando voglio) e "Business Ready" (so quanto spendo e incasso).

## Phases Overview

### ✅ **PHASE 0: MVP CURRENT** (Completata)
- AI Pipeline funzionante con Replicate
- Database schema base
- Flutter Web App (PWA)
- Supabase backend

### 🚀 **PHASE 1: SAAS INFRASTRUCTURE & ADMIN PANEL** (Nuova - Priorità)
- **AI Orchestrator Layer**: Vendor-agnostic AI provider management
- **Cost Intelligence**: Unit economics tracking
- **CRM & SaaS Management**: User management, credit system, Stripe integration
- **Professional Admin Panel**: Dynamic configuration without code changes

### 🔮 **PHASE 2: ADVANCED FEATURES** (Future)
- Multi-region deployment
- Advanced analytics & personalization
- Enterprise features

---

## PHASE 1: SaaS Infrastructure & Admin Panel

**Timeline**: 6-8 settimane  
**Priority**: Critical  
**Dependencies**: Phase 0 completata

### Module 1.1: AI Orchestrator & Gateway

**Objective**: Sostituire chiamate hardcoded a Replicate con layer di astrazione per provider multipli.

#### Task 1.1.1: Database Schema Extension
- **Effort**: 2 giorni
- **Skills**: PostgreSQL, Supabase
- **Tasks**:
  - Creare tabelle `ai_providers`, `system_prompts`
  - Aggiornare `drawings` con colonne per tracking provider
  - Implementare migrazione dati (default provider: Replicate)
- **Deliverable**: SQL migration script pronto per deploy
- **Acceptance Criteria**:
  - [ ] Tabelle create con RLS policies
  - [ ] Default provider configurato (Replicate attuale)
  - [ ] Colonna `ai_provider_used` aggiunta a `drawings`

#### Task 1.1.2: Edge Function Orchestrator (Enhanced)
- **Effort**: 5 giorni
- **Skills**: TypeScript (Deno), AI APIs, Error Handling
- **Tasks**:
  - Creare `ai-orchestrator` Edge Function con error handling avanzato
  - Implementare provider selection logic (priorità, costo, disponibilità)
  - Integrare con `system_prompts` per dynamic prompt management
  - Mantenere backward compatibility durante transition
  - Implementare health check automatico (API key validation, credit check)
  - Gestire errori 402 "Payment Required" con alerting critico
  - Loggare tutti gli errori in `usage_logs` con classificazione (billing, network, model)
- **Deliverable**: Edge Function deployata in staging con robustezza operativa
- **Acceptance Criteria**:
  - [ ] Function risponde a `/ai/process` con error handling avanzato
  - [ ] Selezione provider in base a configurazione DB con fallback automatico
  - [ ] Errori 402 loggati come "CRITICAL" in `system_alerts`
  - [ ] Health check automatico all'avvio verifica API key e crediti
  - [ ] Logging costi e errori in `usage_logs` con classificazione corretta

#### Task 1.1.3: Admin Configuration UI
- **Effort**: 4 giorni
- **Skills**: Flutter Web, Dart, Supabase Client
- **Tasks**:
  - Creare pagina `/admin/ai-providers` in Admin Panel (Flutter Web)
  - Form per aggiungere/modificare provider AI con validazione
  - Dropdown per selezionare provider attivo per tipo (image/3d/vision)
  - Editor WYSIWYG per `system_prompts` con preview
  - Integrazione con tabella `system_config` per salvataggio dinamico
- **Deliverable**: UI funzionante in Admin Panel (Flutter Web)
- **Acceptance Criteria**:
  - [ ] Admin può aggiungere nuovo provider (OpenAI, Meshy, etc.) senza toccare codice
  - [ ] Admin può attivare/disattivare provider con toggle
  - [ ] Admin può modificare prompt system e vedere anteprima
  - [ ] Preview costo per provider selezionato basato su `ai_providers.cost_per_token`

### Module 1.2: Cost Intelligence

**Objective**: Tracking dettagliato costi AI per ogni chiamata con dashboard consumi.

#### Task 1.2.1: Usage Logging System
- **Effort**: 3 giorni
- **Skills**: PostgreSQL, TypeScript
- **Tasks**:
  - Creare tabella `usage_logs` con schema completo
  - Modificare `ai-orchestrator` per loggare ogni chiamata
  - Implementare cost estimation per ogni provider
  - Aggiungere colonne costo a `drawings`
- **Deliverable**: Sistema di logging attivo su tutte le chiamate AI
- **Acceptance Criteria**:
  - [ ] Ogni chiamata AI loggata in `usage_logs`
  - [ ] Costo stimato calcolato correttamente
  - [ ] Colonne `estimated_ai_cost` e `credits_spent` popolate in `drawings`

#### Task 1.2.2: Cost Dashboard
- **Effort**: 4 giorni
- **Skills**: Next.js 14, Chart.js, Supabase
- **Tasks**:
  - Creare dashboard `/admin/cost-intelligence`
  - Grafici: Costo giornaliero/mensile totale
  - Breakdown: Costo per provider (Replicate vs OpenAI vs altri)
  - Margine: Costo medio per disegno vs Prezzo vendita
  - Alerting configurabile (soglie giornaliere)
- **Deliverable**: Dashboard operativa con dati reali
- **Acceptance Criteria**:
  - [ ] Grafico costo giornaliero ultimi 30 giorni
  - [ ] Tabella breakdown per provider
  - [ ] Calcolo margine per disegni venduti
  - [ ] Alert configurabili per soglie costo

#### Task 1.2.3: Cost Optimization Features
- **Effort**: 2 giorni
- **Skills**: TypeScript, Business Logic
- **Tasks**:
  - Implementare A/B testing per provider (x% traffico a provider economico)
  - Alert automatici per provider inefficenti (costo/token > media 20%)
  - Report settimanale costi via email per admin
- **Deliverable**: Sistema di ottimizzazione costi
- **Acceptance Criteria**:
  - [ ] A/B testing configurabile per % traffico
  - [ ] Alert in dashboard per anomalie costo
  - [ ] Report email settimanale generato automaticamente

### Module 1.3: CRM & SaaS Management

**Objective**: Gestione utenti completa, credit system, integrazione Stripe nativa.

#### Task 1.3.1: Subscription & Plans System
- **Effort**: 4 giorni
- **Skills**: PostgreSQL, Stripe API
- **Tasks**:
  - Creare tabelle `plans`, `user_credits`, `credit_transactions`
  - Aggiornare `users` con `plan_id`, `stripe_customer_id`
  - Implementare logica piani: free, basic, pro, enterprise
  - Sostenere sia modello crediti che abbonamento
- **Deliverable**: Database schema esteso per SaaS
- **Acceptance Criteria**:
  - [ ] 4 piani predefiniti creati (free, basic, pro, enterprise)
  - [ ] Utenti esistenti migrati a piano 'free'
  - [ ] Sistema crediti funzionante (balance, earn, spend)

#### Task 1.3.2: Stripe Integration Enhancement
- **Effort**: 5 giorni
- **Skills**: TypeScript, Stripe API, Webhooks
- **Tasks**:
  - Estendere webhook Stripe esistenti
  - Gestire `checkout.session.completed` → crea subscription
  - Gestire `invoice.paid` → assegna crediti/estendi subscription
  - Gestire `customer.subscription.updated/deleted`
  - Implementare customer portal per self-service
- **Deliverable**: Integrazione Stripe completa per SaaS
- **Acceptance Criteria**:
  - [ ] Checkout Stripe crea subscription in DB
  - [ ] Pagamento assegna crediti (se plan a crediti)
  - [ ] Downgrade automatico a free se subscription cancellata
  - [ ] Customer portal accessibile dall'utente

#### Task 1.3.3: Quota Management & Enforcement
- **Effort**: 3 giorni
- **Skills**: PostgreSQL, Edge Functions
- **Tasks**:
  - Creare funzione `can_user_create_drawing()`
  - Modificare `ai-orchestrator` per validare quota prima di chiamare AI
  - Implementare grace period (24h per completare disegni già avviati)
  - UI per mostrare limite/quota all'utente
- **Deliverable**: Sistema di enforcement quota funzionante
- **Acceptance Criteria**:
  - [ ] Utente free blocca dopo 1 disegno/mese
  - [ ] Utente basic blocca dopo crediti finiti
  - [ ] Grace period funziona per disegni in corso
  - [ ] Messaggio chiaro all'utente quando quota raggiunta

#### Task 1.3.4: User Management CRM
- **Effort**: 4 giorni
- **Skills**: Next.js 14, Supabase
- **Tasks**:
  - Creare pagina `/admin/users` in Admin Panel
  - Lista utenti completa con ricerca/filtri
  - Funzionalità ban/sospensione utente
  - Vista dettaglio utente: activity, crediti, disegni, pagamenti
  - Export dati utente (GDPR compliance)
- **Deliverable**: CRM operativo per admin
- **Acceptance Criteria**:
  - [ ] Ricerca utente per email/nome
  - [ ] Ban utente con motivo e durata
  - [ ] Vista dettaglio con tutti i dati utente
  - [ ] Export dati in CSV/JSON

### Module 1.4: Professional Admin Panel

**Objective**: Single pane of glass per configurazione e monitoraggio di tutto il sistema.

#### Task 1.4.1: Admin Dashboard Consolidation
- **Effort**: 3 giorni
- **Skills**: Next.js 14, React
- **Tasks**:
  - Consolidare tutte le funzionalità admin in un'unica dashboard
  - Navigation sidebar con sezioni: AI, Costi, Utenti, Sistema
  - Role-based access control (solo admin users)
  - Responsive design per mobile admin
- **Deliverable**: Admin Panel unificato e organizzato
- **Acceptance Criteria**:
  - [ ] Tutte le funzionalità admin accessibili da sidebar
  - [ ] Solo utenti con ruolo 'admin' possono accedere
  - [ ] Design responsive funziona su mobile/desktop

#### Task 1.4.2: System Health Monitoring
- **Effort**: 2 giorni
- **Skills**: TypeScript, Supabase
- **Tasks**:
  - Dashboard sistema: stato provider AI, queue depth, error rate
  - Alerting configurabile per sistema
  - Log viewer per errori recenti
- **Deliverable**: Sistema di monitoraggio salute
- **Acceptance Criteria**:
  - [ ] Status provider AI (up/down) in tempo reale
  - [ ] Queue depth visibile con alert se > soglia
  - [ ] Log errori ultime 24h visualizzabili

#### Task 1.4.3: Audit Trail
- **Effort**: 2 giorni
- **Skills**: PostgreSQL, TypeScript
- **Tasks**:
  - Estendere `admin_logs` per tracciare tutte le azioni admin
  - Loggare: modifiche provider AI, modifiche prompt, ban utenti
  - Export log per compliance
- **Deliverable**: Sistema audit trail completo
- **Acceptance Criteria**:
  - [ ] Tutte le azioni admin loggate
  - [ ] Timestamp, user_id, action, details
  - [ ] Export log in formato leggibile

---

## PHASE 2: Advanced Features (Future - Post Phase 1)

### Module 2.1: Multi-region Deployment
- **Objective**: Deploy in EU e US per latenza ottimale
- **Tasks**: Configurazione Supabase multi-region, CDN optimization

### Module 2.2: Advanced Analytics & Personalization
- **Objective**: Recommendation engine per stili, A/B testing avanzato
- **Tasks**: Machine learning per suggerimenti, analytics behavioral

### Module 2.3: Enterprise Features
- **Objective**: White-labeling, API per partner, custom model training
- **Tasks**: White-label UI, partner API, fine-tuning interface

---

## Implementation Timeline

### Week 1-2: Foundation
- Task 1.1.1: Database Schema Extension (2 giorni)
- Task 1.3.1: Subscription & Plans System (4 giorni)
- Task 1.2.1: Usage Logging System (3 giorni)
- **Deliverable**: Database esteso, migrazione dati

### Week 3-4: Core Services
- Task 1.1.2: Edge Function Orchestrator (5 giorni)
- Task 1.3.2: Stripe Integration Enhancement (5 giorni)
- Task 1.3.3: Quota Management (3 giorni)
- **Deliverable**: AI Orchestrator funzionante, Stripe integration completa

### Week 5-6: Admin UI
- Task 1.1.3: Admin Configuration UI (4 giorni)
- Task 1.2.2: Cost Dashboard (4 giorni)
- Task 1.3.4: User Management CRM (4 giorni)
- **Deliverable**: Admin Panel completo

### Week 7-8: Polish & Launch
- Task 1.2.3: Cost Optimization Features (2 giorni)
- Task 1.4.1: Admin Dashboard Consolidation (3 giorni)
- Task 1.4.2: System Health Monitoring (2 giorni)
- Task 1.4.3: Audit Trail (2 giorni)
- Testing, bug fixing, documentation
- **Deliverable**: SaaS Platform pronta per produzione

---

## Success Metrics

### Business Metrics
- **Cost Transparency**: 100% delle chiamate AI con costo stimato
- **Vendor Flexibility**: Possibilità di switch provider in <5 minuti (config UI)
- **Margin Visibility**: Margine per disegno calcolato automaticamente
- **Admin Efficiency**: 80% riduzione tempo configurazione vs codice

### Technical Metrics
- **System Uptime**: 99.9% per API core
- **Processing Time**: <30s per disegno (incluse validazioni)
- **Data Accuracy**: 100% correlazione costi stimati vs reali (entro 5%)
- **Scalability**: Supporto 10k utenti attivi/mese

### User Metrics
- **Conversion Rate**: 5% free → paid (da misurare post-implementazione)
- **Churn Rate**: <3% mensile per utenti paid
- **Support Tickets**: 50% riduzione per issue configurazione

---

## Risk Mitigation

### High Risk: Data Migration
- **Risk**: Perdita dati durante migrazione a nuovo schema
- **Mitigation**: 
  - Backup completo pre-migrazione
  - Migrazione in staging first
  - Rollback plan testato
  - Dry-run su subset dati

### Medium Risk: Stripe Integration Complexity
- **Risk**: Errori billing che causano revenue loss o utenti insoddisfatti
- **Mitigation**:
  - Sandbox Stripe per testing
  - Webhook idempotency implementata
  - Monitoraggio intensivo prime 2 settimane
  - Manual override per correzioni billing

### Low Risk: Performance Impact
- **Risk**: AI Orchestrator aggiunge latenza
- **Mitigation**:
  - Caching layer per provider config
  - Async logging per usage_logs
  - Performance testing con load simulato
  - Fallback a chiamata diretta se orchestrator down

---

## Team & Responsibilities

### Backend/Infrastructure Team (2 persone)
- Database schema & migrations
- Edge Functions (AI Orchestrator, Stripe webhooks)
- API design & implementation
- Performance optimization

### Frontend/UI Team (1-2 persone)
- Admin Panel (Next.js)
- User-facing quota UI (Flutter)
- Dashboard & analytics visualization
- Responsive design & UX

### DevOps/Security (1 persona)
- Deployment pipeline
- Security audit (API keys, RLS policies)
- Monitoring & alerting setup
- Backup & disaster recovery

### Product/Business (1 persona)
- Requirements validation
- User testing
- Go-to-market planning
- Success metrics tracking

---

## Deployment Strategy

### Staging Environment
- **Purpose**: Testing completo prima di produzione
- **Setup**: Supabase project separato, Stripe sandbox
- **Testing**: 
  - End-to-end user flows
  - Migration script dry-run
  - Load testing (1000 utenti simulati)
  - Security penetration testing

### Gradual Rollout
1. **Week 1**: Database migration only (backward compatible)
2. **Week 2-3**: AI Orchestrator per 10% traffico, monitoraggio intensivo
3. **Week 4**: Quota enforcement per nuovi utenti only
4. **Week 5-6**: Admin Panel release to internal team
5. **Week 7**: Full rollout a 100% utenti

### Rollback Plan
- **Scenario 1**: Database migration issues
  - Rollback SQL script pronto
  - Restore from backup (max 15 min downtime)
- **Scenario 2**: AI Orchestrator performance issues
  - Feature flag per tornare a chiamate dirette
  - Cache clearing procedure
- **Scenario 3**: Billing system errors
  - Manual credit assignment process
  - Communication template per utenti

---

## Deployment Checklist (Piano di Test Reali)

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

## Post-Launch Activities

### Monitoring (First 30 days)
- Daily review cost dashboard per anomalie
- Hourly check system health dashboard
- User feedback collection via in-app survey
- Support ticket analysis per pain points

### Optimization (Month 2-3)
- Cost optimization basata su dati reali
- Provider A/B testing risultati analysis
- Quota adjustment basata su usage patterns
- Performance tuning basata su metrics

### Scaling Preparation (Month 3-6)
- Multi-region deployment planning
- Enterprise features prioritization
- Partner API development
- Advanced analytics implementation

---

## Conclusion

Questo piano trasforma Draw2Toy da MVP a **SaaS Platform Completa** in 8 settimane, focalizzandosi su:

1. **Vendor Agnostic AI**: Mai più locked-in a singolo provider
2. **Cost Intelligence**: Margine chiaro per ogni disegno
3. **Business-Ready Infrastructure**: CRM, billing, quota management
4. **Professional Admin Control**: Configurazione senza codice

Il risultato è una piattaforma scalabile, profitabile, e pronta per crescita a 100k+ utenti.

---

**Approvazione**:
- [ ] Technical Lead: _______________ Date: __/__/2026
- [ ] Product Manager: _______________ Date: __/__/2026
- [ ] CTO: _______________ Date: __/__/2026

**Document Owner**: Lead Architect  
**Last Updated**: 31 Gennaio 2026  
**Version**: 2.0  
**Status**: ⏳ Ready for Review
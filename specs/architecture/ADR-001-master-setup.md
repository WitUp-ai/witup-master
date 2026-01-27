# ADR-001: Master Setup e Architettura

## Status
✅ **Accepted**

## Data
26 Gennaio 2026

## Context

Necessità di stabilire un framework di sviluppo moderno, scalabile e replicabile che:
- Garantisca qualità del codice attraverso specifiche chiare
- Sfrutti l'AI per accelerare lo sviluppo
- Mantenga un backend robusto e centralizzato
- Permetta sviluppo multi-platform (mobile + web)

## Decision

Abbiamo deciso di adottare un'architettura basata su:

### 1. Spec-Driven Development (SDD)
- **Tool**: GitHub Spec-Kit
- **Principio**: "Specification First" - nessun codice senza spec
- **Location**: `/specs` directory con sottocategorie

**Rationale**:
- Documentazione vivente e sempre aggiornata
- Riduzione ambiguità e incomprensioni
- Facilitazione onboarding nuovi sviluppatori
- Tracciabilità decisioni tecniche

### 2. AI Development Team
- **Cline**: Dashboard, coordinamento, MCP management
- **Claude Code**: Implementazione massiva, testing
- **Ralph Loop**: Quality assurance continuo

**Rationale**:
- Accelerazione sviluppo mantenendo qualità
- Monitoring automatizzato compliance
- Riduzione errori umani
- Review continuo del codice

### 3. Supabase Cloud as Backend
- **Stack**: PostgreSQL + Auth + Storage + Edge Functions
- **Integration**: MCP Server per gestione diretta

**Rationale**:
- Backend-as-a-Service completo
- Scalabilità automatica
- Costi contenuti per progetti early-stage
- Integrazione semplice con frontend

### 4. Design Bridge Multi-Platform
- **Mobile**: FlutterFlow (export Flutter)
- **Web**: v0.dev (componenti React/Next.js)

**Rationale**:
- Rapid prototyping visuale
- Codice production-ready da design
- Consistenza cross-platform
- Riduzione tempo design-to-code

## Consequences

### Positive
- ✅ Alta qualità e tracciabilità del codice
- ✅ Velocità di sviluppo aumentata
- ✅ Onboarding facilitato per nuovi membri
- ✅ Architettura replicabile per progetti futuri
- ✅ Riduzione technical debt
- ✅ Backend gestito e scalabile

### Negative
- ⚠️ Curva di apprendimento iniziale per SDD
- ⚠️ Disciplina richiesta per workflow spec-first
- ⚠️ Dipendenza da servizi cloud (Supabase)
- ⚠️ Necessità di mantenere sincronizzazione FlutterFlow/v0.dev

### Neutral
- ℹ️ Investimento iniziale in setup e tooling
- ℹ️ Necessità di formazione team su nuovi tools

## Implementation

### Phase 1: Foundation ✅
- [x] Creazione repository e struttura `/specs`
- [x] Setup Supabase account e primo progetto
- [x] Configurazione MCP Server
- [x] Documentazione MASTER_SETUP.md

### Phase 2: Integration (Next)
- [ ] Setup FlutterFlow project
- [ ] Configurazione v0.dev account
- [ ] Prima spec tecnica in `/specs/features`
- [ ] Schema database iniziale

### Phase 3: Development (Future)
- [ ] Implementazione prima feature
- [ ] Setup CI/CD con Ralph Loop
- [ ] Testing framework configuration
- [ ] Deploy pipeline

## Related Documents
- [MASTER_SETUP.md](../../MASTER_SETUP.md) - Documentazione completa architettura
- [README.md](../../README.md) - Quick start e overview

## Notes

Questo ADR rappresenta la decisione fondamentale dell'intero progetto. Tutti i futuri ADR dovranno essere coerenti con questi principi architetturali.

## Review History
- **26/01/2026**: Creazione iniziale e approvazione

---

**Author**: Cline + AI Team  
**Reviewers**: Project Team  
**Next Review**: Dopo implementazione Phase 2


> **Spec-Driven Development**: Tutte le specifiche del progetto vivono qui

## 📋 Struttura

### `/features`
Specifiche delle funzionalità utente (user stories, acceptance criteria)

**Template**: Feature specification
**Esempio**: `USER-001-authentication.md`

### `/api`
Contratti API, endpoint, request/response schemas

**Template**: API specification
**Esempio**: `API-001-user-endpoints.md`

### `/database`
Schema database, migrazioni, relazioni tra tabelle

**Template**: Database schema
**Esempio**: `DB-001-users-table.md`, `MIGRATION-001-initial-schema.sql`

### `/architecture`
Architecture Decision Records (ADR) - decisioni architetturali

**Template**: ADR template
**Esempio**: `ADR-001-master-setup.md`

### `/ui-ux`
Specifiche design, wireframes, user flows, style guide

**Template**: UI/UX specification
**Esempio**: `UX-001-onboarding-flow.md`

### `/integrations`
Specifiche integrazioni con servizi esterni

**Template**: Integration specification
**Esempio**: `INT-001-stripe-payment.md`

## ✍️ Workflow

### 1. Crea una Spec
```bash
# Naming convention: CATEGORY-NUMBER-descriptive-name.md
# Esempio:
specs/features/FEAT-001-user-registration.md
```

### 2. Template Base
```markdown
# [CATEGORY-NUMBER]: [Title]

## Status
[ ] Draft | [ ] In Review | [ ] Accepted | [ ] Deprecated

## Context
Perché questa spec esiste? Qual è il problema da risolvere?

## Specification
Dettagli specifici dell'implementazione

## Acceptance Criteria
- [ ] Criterio 1
- [ ] Criterio 2

## Technical Notes
Note tecniche per l'implementazione

## Related Specs
- Link ad altre spec correlate
```

### 3. Review & Approval
- Team review
- Discussione su ambiguità
- Approvazione finale

### 4. Implementation
- Sviluppo conforme alla spec
- Testing contro acceptance criteria
- Chiusura spec

## 📝 Best Practices

### ✅ DO
- Scrivi spec prima del codice
- Mantieni spec aggiornate
- Usa linguaggio chiaro e non ambiguo
- Includi acceptance criteria
- Referenzia altre spec quando necessario
- Versionizza le spec in git

### ❌ DON'T
- Non iniziare a codificare senza spec
- Non lasciare spec incomplete
- Non usare gergo tecnico oscuro
- Non dimenticare gli acceptance criteria
- Non creare spec ridondanti

## 🔍 Trovare Spec

```bash
# Cerca per keyword
grep -r "authentication" specs/

# Lista tutte le spec accettate
find specs/ -name "*.md" -exec grep -l "Status.*Accepted" {} \;

# Lista spec in draft
find specs/ -name "*.md" -exec grep -l "Status.*Draft" {} \;
```

## 📊 Metriche

### Spec Coverage
```
Numero di features con spec / Numero totale di features
Target: 100%
```

### Spec Compliance
```
Features implementate secondo spec / Features totali implementate
Target: 100%
```

---

**Principio fondamentale**: 

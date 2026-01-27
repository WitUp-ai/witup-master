# 🎯 WITUP MASTER BLUEPRINT

> **Framework per Sviluppo SaaS AI-Assisted**  
> **Versione**: 1.0.0  
> **Data**: 26 Gennaio 2026  
> **Status**: ✅ Production Ready

---

## 📋 Overview

Questo è il **blueprint master** per lo sviluppo di qualsiasi nuovo progetto SaaS utilizzando il framework WITUP (Workflow Integrato Team Unificato Programmazione).

**Carica questo documento all'inizio di ogni nuova sessione per continuare il lavoro.**

---

## 🎬 Workflow Principale

### Il Processo in 4 Fasi

```
┌─────────────────────────────────────────────────────────┐
│  FASE 1: UPLOAD MATERIALE                               │
│  ─────────────────────────────────────────────────      │
│  • Upload documenti in /specs/progetto/                 │
│  • Materiali: brief, requisiti, brevetti, design        │
│  • Cline riceve e organizza i file                      │
└────────────────┬────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────┐
│  FASE 2: CREAZIONE SPECIFICHE (Cline)                   │
│  ─────────────────────────────────────────────────      │
│  • Cline analizza documenti con LLM                     │
│  • Genera specifiche strutturate in /specs/             │
│  • Organizza: features, api, database, architecture     │
│  • Crea task breakdown in /specs/plan e /tasks          │
└────────────────┬────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────┐
│  FASE 3: SVILUPPO GUIDATO (Ralph + Claude Code)         │
│  ─────────────────────────────────────────────────      │
│  • Ralph Loop legge le specs create da Cline            │
│  • Ralph monitora e guida Claude Code in real-time      │
│  • Claude Code implementa seguendo le specifiche        │
│  • Feedback continuo per compliance e qualità           │
└────────────────┬────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────┐
│  FASE 4: DESIGN E INTEGRAZIONE UI                       │
│  ─────────────────────────────────────────────────      │
│  • v0.dev: Genera componenti UI Web (React/Next.js)     │
│  • FlutterFlow: Design app mobile (Flutter export)      │
│  • Integrazione componenti in /src/web e /src/mobile    │
│  • Deploy: Vercel (web) + Store (mobile)                │
└─────────────────────────────────────────────────────────┘
```

---

## 👥 Team AI e Ruoli

### 1. **Cline** - Il Coordinatore
**Punto di Partenza di Ogni Progetto**

**Responsabilità**:
- 📥 Riceve e organizza materiale progetto
- 🔍 Analizza documenti con AI/LLM
- 📝 Crea specifiche strutturate in `/specs/`
- 🎯 Definisce task e milestone in `/specs/plan` e `/specs/tasks`
- 📊 Coordina il team durante sviluppo
- 🔧 Gestisce configurazioni e MCP Servers

**Input**: Documenti in `/specs/progetto/`  
**Output**: Specifiche complete in `/specs/`

---

### 2. **Ralph Loop** - Il Supervisore
**Guida e Monitora lo Sviluppo**

**Responsabilità**:
- 📖 Legge le specifiche create da Cline
- 👁️ Monitora Claude Code in real-time (plugin integrato)
- ✅ Verifica compliance spec ↔ code
- 🚨 Alert su deviazioni dalle specifiche
- 📈 Traccia metriche qualità e coverage

**Input**: Specs da `/specs/`  
**Output**: Feedback real-time a Claude Code

---

### 3. **Claude Code** - Il Motore di Sviluppo
**Implementa il Codice**

**Responsabilità**:
- 💻 Scrive codice seguendo le specs
- 🧪 Implementa test automatici
- ⚡ Ottimizza performance
- 🔄 Refactoring guidato da Ralph

**Input**: Specifiche + Feedback Ralph  
**Output**: Codice in `/src/`

---

### 4. **v0.dev** - Design Web
**Genera Componenti UI Web**

**Responsabilità**:
- 🎨 Genera componenti React/Next.js da prompt
- 📱 Design responsive e modern
- ⚡ Codice con Tailwind CSS
- 🔄 Iterazione rapida con AI

**Input**: Prompt basati su specs UI/UX  
**Output**: Componenti in `/src/web/components/`

---

### 5. **FlutterFlow** - Design Mobile
**Design e Deploy App Mobile**

**Responsabilità**:
- 📱 Design UI/UX mobile visuale
- 🔄 Export codice Flutter
- 🚀 Deploy su App Store / Play Store
- 🔌 Integrazione Supabase backend

**Input**: Specs UI/UX mobile  
**Output**: Codice Flutter in `/src/mobile/`

---

## 📁 Struttura Directory

```
Master/
├── specs/                      # SPECIFICHE (Spec-Driven Development)
│   ├── progetto/              # 📥 UPLOAD MATERIALE QUI
│   │   ├── brief.md           # Brief del progetto
│   │   ├── requirements.md    # Requisiti funzionali
│   │   ├── patent/            # Documentazione brevetto
│   │   └── research/          # Ricerche e analisi
│   │
│   ├── plan/                  # 🎯 Cline: Pianificazione
│   │   ├── roadmap.md
│   │   └── milestones.md
│   │
│   ├── tasks/                 # ✅ Cline: Task breakdown
│   │   ├── sprint-1.md
│   │   └── backlog.md
│   │
│   ├── features/              # 📋 Cline: Feature specs
│   │   ├── modules/
│   │   ├── B2B-module.md
│   │   └── B2C-module.md
│   │
│   ├── api/                   # 🔌 Cline: API contracts
│   │   ├── endpoints.md
│   │   └── authentication.md
│   │
│   ├── database/              # 💾 Cline: Database schema
│   │   ├── schema.md
│   │   └── migrations/
│   │
│   ├── architecture/          # 🏗️ Cline: Decisioni architetturali
│   │   └── ADR-*.md
│   │
│   └── ui-ux/                 # 🎨 Cline: Design specs
│       ├── design-system.md
│       ├── web-components.md
│       └── mobile-screens.md
│
├── src/                       # CODICE SORGENTE
│   ├── web/                   # 🌐 Claude Code + v0.dev
│   │   ├── components/
│   │   ├── pages/
│   │   └── lib/
│   │
│   └── mobile/                # 📱 Claude Code + FlutterFlow
│       ├── lib/
│       ├── screens/
│       └── widgets/
│
├── tests/                     # 🧪 Claude Code + Ralph
│   ├── unit/
│   ├── integration/
│   └── e2e/
│
└── docs/                      # 📚 DOCUMENTAZIONE
    ├── WITUP_MASTER_BLUEPRINT.md  # ⭐ QUESTO FILE
    ├── MASTER_SETUP.md
    ├── RIEPILOGO_ARCHITETTURA.md
    ├── SETUP_DEPLOYMENT.md
    ├── STACK_VERIFICATION.md
    ├── V0_DEV_SETUP.md
    └── RALPH_LOOP_STATUS.md
```

---

## 🚀 Come Iniziare un Nuovo Progetto

### Step-by-Step Guide

#### 1️⃣ Upload Materiale Progetto
```bash
# Naviga nella directory progetto
cd d:/Giovanni Sapere/Documents/Master/specs/progetto/

# Upload i tuoi documenti qui:
# - Brief progetto
# - Requisiti funzionali
# - Documentazione tecnica
# - Brevetti (se applicabile)
# - Ricerche di mercato
# - Wireframes/mockup iniziali
```

**Cosa caricare**:
- 📄 Brief.md - Descrizione progetto e obiettivi
- 📋 Requirements.md - Requisiti funzionali e non funzionali
- 🔬 Technical-specs.md - Specifiche tecniche (se disponibili)
- 📜 Patent/ - Documentazione brevetto (se applicabile)
- 🎨 Design/ - Mockup, wireframe, brand guidelines

---

#### 2️⃣ Avvia Cline per Analisi
```
Prompt per Cline:
"Analizza i documenti in /specs/progetto/ e crea le specifiche 
complete del progetto seguendo il framework Spec-Driven Development.
Genera specs in /specs/features, /specs/api, /specs/database, 
e crea il piano in /specs/plan."
```

**Cline farà**:
1. Legge e analizza tutti i documenti
2. Estrae requisiti chiave e funzionalità
3. Crea specifiche dettagliate per ogni modulo
4. Definisce API contracts
5. Progetta schema database
6. Crea roadmap e task breakdown
7. Genera ADR per decisioni architetturali

**Output Atteso**:
- `/specs/features/*.md` - Specifiche feature per feature
- `/specs/api/endpoints.md` - Tutti gli endpoint API
- `/specs/database/schema.md` - Schema completo database
- `/specs/plan/roadmap.md` - Roadmap progetto
- `/specs/tasks/*.md` - Task organizzati per sprint

---

#### 3️⃣ Configura Design (v0.dev + FlutterFlow)

**v0.dev per Web**:
```
1. Apri v0.dev
2. Leggi specs da /specs/ui-ux/web-components.md
3. Genera componenti con prompts:
   "Create [component] based on spec: [paste spec]"
4. Copia codice in /src/web/components/
```

**FlutterFlow per Mobile**:
```
1. Crea progetto su FlutterFlow
2. Leggi specs da /specs/ui-ux/mobile-screens.md
3. Design schermate visualmente
4. Export codice in /src/mobile/
```

---

#### 4️⃣ Sviluppo con Claude Code + Ralph

**Prompt per Claude Code**:
```
"Implementa le features specificate in /specs/features/ seguendo
le API contracts in /specs/api/ e lo schema database in /specs/database/.
Ralph Loop monitorerà la compliance con le specs."
```

**Ralph Loop**:
- Si attiva automaticamente (plugin in Claude Code)
- Legge specs da `/specs/`
- Monitora codice in real-time
- Fornisce feedback immediato
- Alert su deviazioni

**Claude Code**:
- Implementa feature per feature
- Scrive test automatici
- Segue feedback di Ralph
- Commit codice in `/src/`

---

#### 5️⃣ Deploy e Test

**Web (Vercel)**:
```bash
# Deploy web app
npx vercel --prod
```

**Mobile (FlutterFlow/Manual)**:
```bash
# Build mobile
cd src/mobile
flutter build apk --release
flutter build ios --release

# Deploy su store tramite FlutterFlow o manualmente
```

**Backend (Supabase)**:
```
# Via MCP Server da Cline
# Apply migrations
# Configure auth
# Setup storage
```

---

## 🔄 Workflow Iterativo

### Ciclo di Sviluppo

```
┌──────────────────────────────────────────────┐
│                                              │
│  Upload Materiale → Cline Crea Specs →      │
│  Ralph Supervisiona → Claude Code Sviluppa → │
│  v0/Flutter Design → Integration → Test →    │
│  Deploy → Feedback → Iterate ────────┘      │
│                                              │
└──────────────────────────────────────────────┘
```

### Iterazioni e Modifiche

**Per aggiungere nuova feature**:
1. Update documenti in `/specs/progetto/` se necessario
2. Cline crea/aggiorna spec in `/specs/features/`
3. Ralph legge nuova spec
4. Claude Code implementa
5. Design con v0/Flutter se necessario UI
6. Test e deploy

**Per modificare esistente**:
1. Cline aggiorna spec esistente
2. Ralph notifica Claude Code della modifica
3. Claude Code refactora seguendo nuova spec
4. Test di regressione
5. Redeploy

---

## 📊 Metriche e Quality Gates

### Monitorate da Ralph Loop

**Spec Compliance**:
- ✅ 100% features hanno spec
- ✅ 100% codice mappato a spec
- ✅ 0 deviazioni non documentate

**Code Quality**:
- ✅ Coverage test >80%
- ✅ Complexity score <15
- ✅ Maintainability >70/100
- ✅ 0 vulnerabilità critiche

**Development Velocity**:
- ⚡ Spec-to-Code <2 giorni (feature media)
- 🚀 Deploy frequency: Daily
- 🐛 Bug escape rate <5%
- ⏱️ MTTR <4 ore

---

## 🎯 Best Practices

### 1. Specification First
❌ **Mai scrivere codice senza spec**  
✅ **Sempre partire da spec in /specs/**

### 2. Single Source of Truth
❌ **Non duplicare info in posti diversi**  
✅ **Specs in /specs/ sono la fonte unica**

### 3. Atomic Commits
❌ **Non fare commit enormi multi-feature**  
✅ **Un commit = una feature/fix con ref a spec**

### 4. Test-Driven
❌ **Non sviluppare senza test**  
✅ **Test scritti insieme al codice**

### 5. Documentation as Code
❌ **Non documentazione separata che va out-of-sync**  
✅ **Specs vivono nel repo e sono sempre aggiornate**

---

## 🔧 Tools e Configurazioni

### Essenziali Attivi
- ✅ **Visual Studio Code** - IDE centrale
- ✅ **Cline** - Interfaccia AI coordinamento
- ✅ **Supabase** - Backend (MCP Server attivo)
- ✅ **Vercel** - Deploy web (login fatto)
- ✅ **Claude Pro** - Subscription attiva

### Da Configurare al Bisogno
- 🔜 **v0.dev** - Account e primi componenti
- 🔜 **FlutterFlow Pro** - Subscription per export e deploy
- 🔜 **Ralph Loop** - Verifica e config (plugin in Claude Code)

### Optional ma Consigliati
- **GitHub Actions** - CI/CD automation
- **Sentry** - Error monitoring
- **Posthog** - Analytics
- **Storybook** - Component documentation

---

## 🎨 UX INTERNAL STACK

### Costituzione UX WITUP
**Versione**: 1.0  
**File di Riferimento**: `.spec/templates/ux/UX_RULES.md`  
**Agente**: `.clauderules-ux`

Ogni progetto WITUP segue uno stack UX standardizzato e vincolante per garantire:
- 🚀 **Velocità di sviluppo** - Librerie e pattern consolidati
- ✨ **Qualità UI** - Design moderno e professionale
- 🔧 **Manutenibilità** - Codice pulito e organizzato
- 📱 **Responsiveness** - Mobile-first approach

### Stack Web (SaaS / B2C)
| Categoria | Tecnologia | Scope |
|-----------|-----------|-------|
| **Framework** | Next.js 14+ (App Router) | Core applicazione |
| **Styling** | TailwindCSS | Utility-first CSS |
| **Componenti** | Shadcn/UI (Radix primitives) | Component base strutturali |
| **Animazioni** | Framer Motion | Micro-interazioni fluide |
| **High-Impact** | Magic UI / Aceternity | Hero, Onboarding, Features (NON layout) |
| **Icons** | Lucide React | Sistema iconografico |

### Stack Mobile (Native / B2B)
| Categoria | Tecnologia | Scope |
|-----------|-----------|-------|
| **Framework** | Flutter (Latest Stable) | Core applicazione |
| **Styling** | Package 'mix' | Styling atomico CSS-like |
| **Animazioni** | flutter_animate + Rive | Animazioni native |
| **Fonts** | Google Fonts | Typography system |

### Principi di Design Vincolanti
1. **Mobile-First** - Ogni componente nasce responsive
2. **Feedback Immediato** - Hover/Active/Focus visibili su ogni elemento interattivo
3. **Skeleton Loading** - Mai spazi bianchi durante caricamento
4. **Spacing System** - Grid 4px Tailwind (no magic numbers)

### Governance Design Debt
**Tag Obbligatorio**: `// UX-DEBT: [motivo workaround]`

Usa questo tag per:
- Workaround UX temporanei
- Stili hardcoded non standard
- Compromessi tecnici UI

**Policy**:
- ❌ Vietato CSS inline senza estrazione
- ❌ Vietato stili annidati complessi
- ✅ Magic UI SOLO per sezioni high-impact
- ✅ Shadcn per tutti i layout strutturali

### File di Riferimento
- **Costituzione Completa**: `.spec/templates/ux/UX_RULES.md`
- **Regole Agente UX**: `.clauderules-ux`

**Quando Generare UI**:
1. Leggi sempre `.spec/templates/ux/UX_RULES.md` prima
2. Segui lo stack vincolante (no alternative)
3. Applica principi di design
4. Tag `// UX-DEBT:` per compromessi
5. Non chiedere permesso per rendere bella l'interfaccia

---

## 📚 Documentazione di Riferimento

### Setup e Configurazione
1. **MASTER_SETUP.md** - Setup completo infrastruttura
2. **SETUP_DEPLOYMENT.md** - Guide deployment Vercel e Flutter
3. **STACK_VERIFICATION.md** - Verifica completezza stack

### Guide Specifiche
4. **V0_DEV_SETUP.md** - Setup e uso v0.dev
5. **RALPH_LOOP_STATUS.md** - Verifica Ralph Loop

### Architettura
6. **RIEPILOGO_ARCHITETTURA.md** - Analisi team e stack
7. **ADR-001** in `/specs/architecture/` - Decisioni architetturali

---

## 🎬 Template Session Start

### Per Iniziare Nuova Sessione

```markdown
## Ciao Cline! 👋

Ricarico il progetto Master con framework WITUP.

**Contesto**:
- Blueprint: WITUP_MASTER_BLUEPRINT.md
- Setup: MASTER_SETUP.md attivo
- Stack: Team AI configurato

**Stato Attuale**:
- [ ] Materiale progetto uploadato in /specs/progetto/
- [ ] Specs create da te in /specs/
- [ ] Design fase: v0.dev e FlutterFlow
- [ ] Sviluppo: Claude Code + Ralph
- [ ] Deploy: Vercel + Store

**Prossima Azione**:
[Descrivi cosa vuoi fare]

**Domande**:
1. [Qualsiasi domanda sul progetto]
```

---

## ✅ Checklist Nuovo Progetto

### Pre-Development
- [ ] Materiale progetto caricato in `/specs/progetto/`
- [ ] Brief chiaro e requisiti definiti
- [ ] Obiettivi progetto chiari

### Specification Phase (Cline)
- [ ] Features specs in `/specs/features/`
- [ ] API contracts in `/specs/api/`
- [ ] Database schema in `/specs/database/`
- [ ] Roadmap in `/specs/plan/`
- [ ] Task breakdown in `/specs/tasks/`

### Design Phase
- [ ] v0.dev account attivo
- [ ] FlutterFlow progetto creato
- [ ] Design system definito in `/specs/ui-ux/`
- [ ] Primi componenti generati

### Development Phase
- [ ] Ralph Loop verificato attivo
- [ ] Claude Code implementa prima feature
- [ ] Test suite configurata
- [ ] CI/CD pipeline attivo

### Deployment Phase
- [ ] Vercel deploy web fatto
- [ ] Mobile build testato
- [ ] Backend Supabase configurato
- [ ] Monitoring attivo

---

## 💡 Tips per Successo

### 1. Comunicazione Chiara
Quando comunichi con Cline:
- Sii specifico su cosa vuoi
- Riferisci sempre a specs esistenti
- Chiedi chiarimenti se necessario

### 2. Iterazione Rapida
- Non aspettare perfezione prima di testare
- Deploy early, deploy often
- Feedback loop corto

### 3. Documentazione Continua
- Aggiorna specs quando cambiano requisiti
- Mantieni ADR per decisioni importanti
- Commenta codice complesso

### 4. Quality Focus
- Non bypassare Ralph warnings
- Mantieni test coverage alto
- Fix technical debt progressivamente

---

## 🎯 Obiettivo Framework WITUP

**Mission**: Rendere lo sviluppo SaaS:
- 🚀 **Veloce** - AI accelera tutto
- ✅ **Qualità Alta** - Spec-driven + Ralph monitoring
- 📈 **Scalabile** - Architettura solida
- 🔄 **Replicabile** - Stesso workflow ogni progetto
- 💰 **Cost-Effective** - Tools giusti per il job

---

## 📞 Need Help?

**Riferimenti**:
- Questo file: `WITUP_MASTER_BLUEPRINT.md`
- Setup completo: `MASTER_SETUP.md`
- Documentazione: `/docs/`

**Workflow**:
1. Upload materiale → `/specs/progetto/`
2. Chiedi a Cline di creare specs
3. Segui il flusso: Cline → Ralph → Claude → Design → Deploy

---

**Blueprint Versione**: 1.0.0  
**Ultimo Aggiornamento**: 26 Gennaio 2026  
**Manutentore**: Cline + AI Team  
**Status**: ✅ Production Ready

---

## 🔄 Quick Commands

```bash
# Start new project analysis
"Cline, analizza /specs/progetto/ e crea le specs complete"

# Update existing specs
"Cline, aggiorna spec per feature X in /specs/features/"

# Develop with Claude Code
"Claude Code, implementa spec Y con Ralph monitoring"

# Generate UI components
"v0.dev, genera componente Z basato su spec"

# Deploy
npx vercel --prod  # Web
flutter build apk  # Mobile
```

---

**🎯 Remember**: Questo blueprint è il punto di partenza. Caricalo all'inizio di ogni sessione per continuità e contesto completo del progetto Master.

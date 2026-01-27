# 🎯 MASTER SETUP - Architettura e Workflow del Progetto

> **Versione:** 1.0.0  
> **Data Creazione:** 26 Gennaio 2026  
> **Paradigma:** Spec-Driven Development  
> **Status:** Production Ready

---

## 📋 Indice

1. [Core Architecture](#-core-architecture)
2. [AI Development Team](#-ai-development-team)
3. [Data & Backend Infrastructure](#-data--backend-infrastructure)
4. [Design Bridge](#-design-bridge)
5. [Quality Assurance](#-quality-assurance)
6. [Workflow Operativo](#-workflow-operativo)
7. [Guida alla Replicabilità](#-guida-alla-replicabilità)
8. [Configurazione Ambiente](#-configurazione-ambiente)

---

## 🏗️ Core Architecture

### Paradigma: Spec-Driven Development

Il progetto segue rigorosamente il **Spec-Driven Development** tramite **GitHub Spec-Kit**.

#### Principi Fondamentali:
- ✅ **Specification First**: Tutta la logica deve essere definita in `/specs` prima dell'implementazione
- ✅ **Documentation as Code**: Le specifiche sono documentazione vivente
- ✅ **Single Source of Truth**: Le specs guidano lo sviluppo, i test e la validazione
- ✅ **Traceable Changes**: Ogni modifica al codice deve riferirsi a una spec

#### Struttura Directory Specs:
```
/specs
├── /features          # Specifiche funzionalità utente
├── /api              # Specifiche endpoint e contratti API
├── /database         # Schema database e migrazioni
├── /architecture     # Decisioni architetturali (ADR)
├── /ui-ux            # Specifiche design e interazioni
└── /integrations     # Specifiche integrazioni esterne
```

#### Workflow Spec-Driven:
1. **Define** → Scrivi la spec in `/specs`
2. **Review** → Valida la spec con il team
3. **Implement** → Scrivi il codice seguendo la spec
4. **Test** → Verifica conformità con la spec
5. **Deploy** → Rilascia solo se conforme alla spec

---

## 🤖 AI Development Team

### Team Structure

#### 1. **Cline** (Dashboard & Coordination)
- **Ruolo**: Project Manager & Visual Interface
- **Responsabilità**:
  - Gestione visiva del progetto
  - Coordinamento task tra AI agents
  - Configurazione MCP servers
  - Monitoraggio progress
  - Interazione con utente
- **Tools**:
  - Visual Studio Code Integration
  - MCP Server Management
  - File System Operations
  - Git Operations

#### 2. **Claude Code** (Coding Engine)
- **Ruolo**: Development Powerhouse
- **Responsabilità**:
  - Scrittura codice massiva
  - Implementazione features
  - Refactoring e ottimizzazioni
  - Esecuzione test nel terminale
  - Debug e troubleshooting
- **Focus**:
  - Alto volume di codice
  - Performance optimization
  - Best practices enforcement

#### 3. **Ralph Loop** (Quality Guardian)
- **Ruolo**: Continuous Quality Assurance
- **Responsabilità**:
  - Monitoraggio costante allineamento spec-code
  - Code review automatizzato
  - Test coverage analysis
  - Compliance validation
  - Alert su deviazioni dal Master Plan

---

## 💾 Data & Backend Infrastructure

### Supabase Cloud

**Stack Completo**: Database PostgreSQL + Authentication + Storage + Edge Functions

#### Configurazione:
- **Provider**: Supabase Cloud (https://supabase.com)
- **Region**: [Da configurare in base al progetto]
- **Database**: PostgreSQL 15+
- **Authentication**: Supabase Auth
- **Storage**: Supabase Storage Buckets
- **Edge Functions**: Deno Runtime

#### Struttura Credenziali:
```env
# Management API Token
SUPABASE_ACCESS_TOKEN=<your-access-token>

# Project-specific
SUPABASE_URL=https://<project-ref>.supabase.co
SUPABASE_ANON_KEY=<anon-public-key>
SUPABASE_SERVICE_ROLE_KEY=<service-role-secret>
```

### MCP Server (Model Context Protocol)

**Connessione diretta Cline ↔ Supabase**

#### Funzionalità:
- ✅ **Schema Management**: Creazione e modifica tabelle via CLI
- ✅ **Data Operations**: CRUD diretto dal dashboard
- ✅ **Query Execution**: SQL queries in tempo reale
- ✅ **Migration Management**: Apply e rollback migrazioni
- ✅ **Project Management**: Lista progetti, creazione, configurazione

#### Setup MCP Server:
```bash
# Location
c:\Users\Giovanni Sapere\Documents\Cline\MCP\supabase-server

# Install
npm install

# Build
npm run build

# Configure in Cline MCP Settings
{
  "mcpServers": {
    "supabase": {
      "command": "node",
      "args": ["path/to/supabase-server/build/index.js"],
      "env": {
        "SUPABASE_ACCESS_TOKEN": "<token>"
      }
    }
  }
}
```

#### Available MCP Tools:
- `list_projects` - Elenca tutti i progetti Supabase
- `get_project` - Dettagli progetto specifico
- `create_project` - Crea nuovo progetto
- `execute_sql` - Esegui query SQL
- `list_tables` - Lista tabelle nel database
- `get_table_schema` - Schema di una tabella
- `select_data` / `insert_data` / `update_data` / `delete_data` - CRUD operations
- `list_storage_buckets` / `create_storage_bucket` - Storage management
- `apply_migration` - Applica SQL migrations
- `connect_project` - Connetti a un progetto specifico

---

## 🎨 Design Bridge

### Architettura Multi-Platform

#### 1. **FlutterFlow** (Mobile-First)
- **Purpose**: Design e prototipazione mobile
- **Export**: Flutter code via CLI
- **Target**: iOS, Android, Web (Mobile view)

**Workflow**:
```bash
# Export da FlutterFlow
flutterflow export --project <project-id> --output ./mobile

# Integrate nel progetto
# Il codice esportato va in /mobile o /app
```

**Best Practices**:
- Design mobile-first in FlutterFlow
- Export periodico per sincronizzazione
- Custom code integrato tramite widget personalizzati
- State management: Provider/Riverpod

#### 2. **v0.dev** (Web Components)
- **Purpose**: Generazione componenti UI per Web
- **Output**: React/Next.js components
- **Target**: Web Desktop & Responsive

**Workflow**:
```bash
# Genera componenti da v0.dev
# Copia il codice generato in /components

# Esempio struttura:
/web
├── /components
│   ├── /ui           # v0.dev generated
│   ├── /layout       # Layout components
│   └── /features     # Feature-specific
```

**Best Practices**:
- Utilizza v0.dev per layout complessi
- Mantieni consistenza con design system
- Customizza styling per branding
- Integra con Tailwind CSS

---

## ✅ Quality Assurance

### Ralph Loop - Continuous Monitoring

**Ruolo**: Guardian dell'allineamento Spec ↔ Code ↔ Master Plan

#### Responsabilità:

1. **Spec Compliance**
   - Verifica che ogni feature implementata abbia una spec
   - Controlla che il codice rispetti la spec
   - Alert su implementazioni non documentate

2. **Code Quality**
   - Static analysis continuo
   - Test coverage monitoring (target: >80%)
   - Code smell detection
   - Security vulnerability scanning

3. **Master Plan Alignment**
   - Verifica milestone completate
   - Progress tracking vs. piano
   - Dependency validation
   - Architecture compliance

4. **Automated Testing**
   - Unit tests execution
   - Integration tests
   - E2E tests (quando applicabile)
   - Performance benchmarks

#### Metriche Monitorate:
- 📊 Spec Coverage: % features con spec
- 📊 Code Coverage: % codice testato
- 📊 Tech Debt: Tempo stimato per risolvere debt
- 📊 Bug Density: Bug per 1000 LOC
- 📊 Deployment Success Rate: % deploy senza rollback

---

## 🔄 Workflow Operativo

### 1. Fase di Pianificazione (Cline + User)
```
User richiesta → Cline analisi → Creazione spec in /specs → Review
```

### 2. Fase di Sviluppo (Claude Code)
```
Spec approvata → Claude Code implementa → Test locali → Commit
```

### 3. Fase di Qualità (Ralph Loop)
```
Code committed → Ralph analisi → Report compliance → Fix issues
```

### 4. Fase di Deploy
```
QA passed → Build production → Deploy → Monitor
```

### Ciclo Iterativo:
```
┌─────────────────────────────────────────────┐
│                                             │
│  User Request → Spec → Code → QA → Deploy  │
│       ↑                              ↓      │
│       └──────── Feedback Loop ───────┘      │
│                                             │
└─────────────────────────────────────────────┘
```

---

## 🚀 Guida alla Replicabilità

### Setup Nuovo Progetto

#### Step 1: Inizializzazione Repository
```bash
# Crea nuovo repository
mkdir my-new-project
cd my-new-project
git init

# Crea struttura base
mkdir -p specs/{features,api,database,architecture,ui-ux,integrations}
mkdir -p src/{mobile,web,shared}
mkdir -p tests/{unit,integration,e2e}

# Inizializza package.json
npm init -y
```

#### Step 2: Setup Supabase
```bash
# 1. Crea progetto su Supabase Cloud
# 2. Copia credenziali in .env
# 3. Configura MCP Server

# .env template
cat > .env << 'EOF'
# Supabase Cloud Configuration
SUPABASE_ACCESS_TOKEN=<your-token>
SUPABASE_URL=
SUPABASE_ANON_KEY=
SUPABASE_SERVICE_ROLE_KEY=
EOF
```

#### Step 3: Configura MCP Server Supabase
```bash
# Naviga nella directory MCP
cd c:\Users\Giovanni Sapere\Documents\Cline\MCP\supabase-server

# Install dependencies
npm install

# Build
npm run build

# Configura in Cline MCP Settings
# File: %APPDATA%\Code\User\globalStorage\saoudrizwan.claude-dev\settings\cline_mcp_settings.json
```

#### Step 4: Setup AI Team

**Cline**:
- Installa estensione Cline in VS Code
- Connetti MCP Server Supabase
- Apri progetto in VS Code

**Claude Code**:
- Configura accesso via API o CLI
- Setup environment variables
- Configura git credentials

**Ralph Loop**:
- Setup CI/CD pipeline
- Configura webhooks per monitoring
- Setup notification channels

#### Step 5: Design Tools

**FlutterFlow**:
1. Crea progetto su FlutterFlow
2. Setup FlutterFlow CLI
3. Configura export path

**v0.dev**:
1. Account su v0.dev
2. Genera componenti UI
3. Copia in `/web/components`

#### Step 6: Prima Spec
```bash
# Crea prima spec
cat > specs/architecture/ADR-001-master-setup.md << 'EOF'
# ADR-001: Master Setup e Architettura

## Status
Accepted

## Context
Setup iniziale progetto con Spec-Driven Development

## Decision
Seguire il paradigma Spec-Driven con AI Team integrato

## Consequences
- Tutti i dev devono seguire workflow spec-first
- Necessaria disciplina nella documentazione
- Maggiore tracciabilità e qualità
EOF
```

---

## ⚙️ Configurazione Ambiente

### File Essenziali

#### `.env`
```env
# Supabase Cloud Configuration
SUPABASE_ACCESS_TOKEN=<your-access-token>

# Project-specific keys
SUPABASE_URL=
SUPABASE_ANON_KEY=
SUPABASE_SERVICE_ROLE_KEY=

# Development
NODE_ENV=development

# FlutterFlow (optional)
FLUTTERFLOW_API_KEY=
FLUTTERFLOW_PROJECT_ID=
```

#### `package.json`
```json
{
  "name": "master",
  "version": "1.0.0",
  "description": "Master Project - Spec-Driven Development",
  "main": "index.js",
  "scripts": {
    "dev": "npm run dev:web",
    "dev:web": "next dev",
    "dev:mobile": "flutter run",
    "build": "npm run build:web && npm run build:mobile",
    "test": "jest",
    "test:coverage": "jest --coverage",
    "lint": "eslint . && dart analyze",
    "spec:validate": "node scripts/validate-specs.js"
  },
  "keywords": ["spec-driven", "ai-assisted", "supabase"],
  "author": "",
  "license": "ISC"
}
```

#### `.gitignore`
```
# Environment
.env
.env.local
.env.production

# Dependencies
node_modules/
.pub-cache/

# Build outputs
dist/
build/
.next/
.flutter-plugins
.flutter-plugins-dependencies

# IDE
.vscode/
.idea/
*.swp

# OS
.DS_Store
Thumbs.db

# Credentials
*.pem
*.key
```

### MCP Server Configuration

**Location**: `cline_mcp_settings.json`
```json
{
  "mcpServers": {
    "supabase": {
      "command": "node",
      "args": [
        "c:\\Users\\Giovanni Sapere\\Documents\\Cline\\MCP\\supabase-server\\build\\index.js"
      ],
      "env": {
        "SUPABASE_ACCESS_TOKEN": "${SUPABASE_ACCESS_TOKEN}"
      }
    }
  }
}
```

---

## 📚 Risorse e Riferimenti

### Documentazione
- [GitHub Spec-Kit](https://github.com/github/spec-kit)
- [Supabase Documentation](https://supabase.com/docs)
- [FlutterFlow Docs](https://docs.flutterflow.io)
- [v0.dev Guide](https://v0.dev/docs)
- [MCP Protocol](https://modelcontextprotocol.io)

### Tools
- **IDE**: Visual Studio Code
- **Version Control**: Git + GitHub
- **CI/CD**: GitHub Actions (recommended)
- **Monitoring**: Sentry / LogRocket (optional)

---

## 🎯 Checklist Setup Completo

### Inizializzazione
- [ ] Repository Git creato
- [ ] Struttura directory `/specs` creata
- [ ] `.env` configurato
- [ ] `.gitignore` impostato
- [ ] `package.json` inizializzato

### Backend
- [ ] Progetto Supabase Cloud creato
- [ ] Credenziali Supabase in `.env`
- [ ] MCP Server Supabase installato e configurato
- [ ] Connessione MCP testata in Cline
- [ ] Prima migrazione database eseguita

### Design
- [ ] Progetto FlutterFlow creato (se mobile)
- [ ] FlutterFlow CLI configurato
- [ ] Account v0.dev attivo (se web)
- [ ] Design system definito

### AI Team
- [ ] Cline configurato in VS Code
- [ ] Claude Code setup completato
- [ ] Ralph Loop CI/CD configurato

### Quality
- [ ] Test framework installato
- [ ] Linting configurato
- [ ] Pre-commit hooks impostati
- [ ] CI/CD pipeline attiva

### Documentazione
- [ ] README.md principale creato
- [ ] Prima spec architetturale scritta
- [ ] Contributing guidelines definite
- [ ] Code of conduct impostato

---

## 🔮 Prossimi Passi

1. **Definire Prima Feature**: Crea spec in `/specs/features/`
2. **Setup Database Schema**: Definisci tabelle in `/specs/database/`
3. **Implementare Authentication**: Configura Supabase Auth
4. **Creare UI Base**: Design system e componenti fondamentali
5. **Setup Testing**: Framework e primi test
6. **Deploy Pipeline**: Automazione deployment

---

## 📝 Note Finali

Questo Master Setup rappresenta la base per un workflow di sviluppo moderno, spec-driven e AI-assisted. 

**Principi chiave da ricordare**:
- 📋 **Specification First** - Always
- 🤖 **AI Collaboration** - Leverage AI team effectively
- ✅ **Quality Gates** - No compromises
- 🔄 **Iterative Improvement** - Continuous refinement
- 📊 **Data-Driven Decisions** - Metrics matter

---

**Versione Documento**: 1.0.0  
**Ultimo Aggiornamento**: 26 Gennaio 2026  
**Manutentore**: Cline + AI Team  
**Status**: ✅ Production Ready

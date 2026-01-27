# Master Project

> **Spec-Driven Development** con **AI-Assisted Workflow**

## 📖 Overview

Questo è il progetto Master che implementa un workflow di sviluppo moderno basato su:
- **Spec-Driven Development** (GitHub Spec-Kit)
- **AI Development Team** (Cline, Claude Code, Ralph Loop)
- **Supabase Cloud** (Backend & Database)
- **Design Bridge** (FlutterFlow + v0.dev)

## 🚀 Quick Start

```bash
# Clone repository
git clone <repository-url>
cd Master

# Install dependencies
npm install

# Configure environment
cp .env.example .env
# Edit .env with your credentials

# Start development
npm run dev
```

## 📚 Documentazione

Per la documentazione completa del setup e architettura, consulta:
- **[MASTER_SETUP.md](./MASTER_SETUP.md)** - Architettura completa e guida alla replicabilità

## 🏗️ Struttura Progetto

```
Master/
├── specs/              # Specifiche (Spec-Driven Development)
│   ├── features/       # Feature specifications
│   ├── api/           # API contracts
│   ├── database/      # Database schema & migrations
│   ├── architecture/  # Architecture Decision Records
│   ├── ui-ux/         # UI/UX specifications
│   └── integrations/  # External integrations specs
├── src/               # Source code
│   ├── mobile/        # FlutterFlow exports
│   ├── web/           # Web components (v0.dev)
│   └── shared/        # Shared utilities
├── tests/             # Test suites
│   ├── unit/
│   ├── integration/
│   └── e2e/
├── .env              # Environment variables
└── package.json      # Project configuration
```

## 🤖 AI Development Team

### Cline (Dashboard)
- Coordinamento progetto
- Gestione configurazioni
- MCP Server management

### Claude Code (Engine)
- Implementazione features
- Scrittura codice massiva
- Testing & debugging

### Ralph Loop (QA)
- Code quality monitoring
- Spec compliance validation
- Continuous testing

## 💾 Tech Stack

- **Backend**: Supabase Cloud (PostgreSQL, Auth, Storage)
- **Mobile**: Flutter (FlutterFlow export)
- **Web**: React/Next.js (v0.dev components)
- **Tools**: MCP Server, GitHub Spec-Kit

## 📋 Workflow

1. **Spec First** → Definisci in `/specs`
2. **Review** → Valida specifiche
3. **Implement** → Codice conforme a spec
4. **Test** → Verifica compliance
5. **Deploy** → Rilascio production

## 🔧 Commands

```bash
# Development
npm run dev              # Start development server
npm run dev:web          # Web development
npm run dev:mobile       # Mobile development

# Testing
npm test                 # Run all tests
npm run test:coverage    # Coverage report

# Build
npm run build            # Build for production

# Quality
npm run lint             # Lint code
npm run spec:validate    # Validate specs
```

## 📦 Requirements

- Node.js >= 18
- npm >= 9
- Flutter SDK (for mobile)
- Supabase CLI (optional)
- Git

## 🔑 Environment Variables

Crea un file `.env` con:

```env
# Supabase
SUPABASE_ACCESS_TOKEN=your_access_token
SUPABASE_URL=your_project_url
SUPABASE_ANON_KEY=your_anon_key
SUPABASE_SERVICE_ROLE_KEY=your_service_role_key

# Optional
NODE_ENV=development
```

## 🤝 Contributing

1. Crea una spec in `/specs`
2. Aspetta review e approvazione
3. Implementa seguendo la spec
4. Scrivi test
5. Submit PR

## 📄 License

ISC

## 📞 Support

Per domande o supporto, consulta la documentazione in `MASTER_SETUP.md`.

---

**Status**: ✅ Production Ready  
**Version**: 1.0.0  
**Last Updated**: 26 Gennaio 2026

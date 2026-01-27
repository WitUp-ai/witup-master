# 🚀 Setup Deployment & Integration Guide

> **Data**: 26 Gennaio 2026  
> **Status**: ✅ Configurato  
> **Versione**: 1.0.0

---

## 📋 Overview

Documentazione delle configurazioni di deployment e integrazione per il progetto Master.

---

## 🌐 Vercel - Web Deployment

### Status: ✅ CONFIGURATO

**Login completato con successo** tramite:
```bash
npx vercel login
```

### Autenticazione
- ✅ Account Vercel autenticato
- ✅ CLI Vercel disponibile
- ✅ Pronto per deploy

### Deploy Web Application

```bash
# Deploy di produzione
npx vercel --prod

# Deploy di preview
npx vercel

# Deploy specifico da branch
npx vercel --prod --yes
```

### Configurazione Automatica

Per abilitare deploy automatico da Git:
1. Connetti repository su [vercel.com](https://vercel.com)
2. Vai su Project Settings → Git
3. Configura branch per auto-deploy:
   - `main` → Production
   - `develop` → Preview

### Environment Variables

Configura su Vercel Dashboard le variabili:
```env
SUPABASE_URL=your_project_url
SUPABASE_ANON_KEY=your_anon_key
NODE_ENV=production
```

### Vercel Configuration

Crea `vercel.json` nel root del progetto:
```json
{
  "version": 2,
  "builds": [
    {
      "src": "package.json",
      "use": "@vercel/next"
    }
  ],
  "routes": [
    {
      "src": "/(.*)",
      "dest": "/$1"
    }
  ],
  "env": {
    "SUPABASE_URL": "@supabase-url",
    "SUPABASE_ANON_KEY": "@supabase-anon-key"
  }
}
```

---

## 📱 FlutterFlow - Mobile Integration

### Status: ⚠️ CONFIGURAZIONE MANUALE RICHIESTA

**Nota**: FlutterFlow CLI non è disponibile come pacchetto npm pubblico.

### Approccio Alternativo: FlutterFlow API

FlutterFlow offre due metodi di integrazione:

#### Metodo 1: Export Manuale (Consigliato per Setup Iniziale)

1. **Design in FlutterFlow**:
   - Accedi a [flutterflow.io](https://flutterflow.io)
   - Crea/apri il tuo progetto
   - Design UI e logica

2. **Export Code**:
   - Menu → Export Code
   - Download ZIP file
   - Estrai in `/src/mobile` o `/mobile`

3. **Integrazione Locale**:
   ```bash
   # Naviga nella directory mobile
   cd src/mobile
   
   # Installa dipendenze Flutter
   flutter pub get
   
   # Run app
   flutter run
   ```

#### Metodo 2: FlutterFlow API (Avanzato)

FlutterFlow fornisce API per automazione:

**Setup**:
1. Ottieni API Key da FlutterFlow Dashboard
2. Usa API per export automatico

**Esempio Script Export** (`scripts/flutterflow-export.js`):
```javascript
const axios = require('axios');
const fs = require('fs');

async function exportFlutterFlow() {
  const FLUTTERFLOW_API_KEY = process.env.FLUTTERFLOW_API_KEY;
  const PROJECT_ID = process.env.FLUTTERFLOW_PROJECT_ID;
  
  try {
    const response = await axios.post(
      `https://api.flutterflow.io/v1/projects/${PROJECT_ID}/export`,
      {},
      {
        headers: {
          'Authorization': `Bearer ${FLUTTERFLOW_API_KEY}`,
          'Content-Type': 'application/json'
        }
      }
    );
    
    // Download and extract code
    console.log('Export successful:', response.data);
  } catch (error) {
    console.error('Export failed:', error.message);
  }
}

exportFlutterFlow();
```

#### Metodo 3: GitHub Integration (Consigliato per CI/CD)

FlutterFlow può fare push diretto al repository:

1. **Configura in FlutterFlow**:
   - Settings → Integrations → GitHub
   - Autorizza accesso repository
   - Configura branch target (es. `mobile-updates`)

2. **Workflow**:
   - Design update in FlutterFlow
   - Push to GitHub automaticamente
   - Pull changes localmente o via CI/CD

### Struttura Directory Mobile

```
/src/mobile/  (o /mobile/)
├── lib/
│   ├── main.dart
│   ├── screens/
│   ├── components/
│   ├── models/
│   └── services/
├── pubspec.yaml
├── android/
├── ios/
└── README.md
```

### Environment Setup Mobile

```bash
# Verifica Flutter installato
flutter --version

# Se non installato, scarica da: https://flutter.dev

# Setup per iOS (macOS only)
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -runFirstLaunch

# Setup per Android
# Installa Android Studio
# Configura Android SDK

# Verifica setup
flutter doctor
```

### Comandi Utili Mobile

```bash
# Run su device/emulator
flutter run

# Build per Android
flutter build apk --release

# Build per iOS (macOS only)
flutter build ios --release

# Test
flutter test

# Analyze code
flutter analyze
```

---

## 🔄 Workflow Completo

### 1. Sviluppo Web

```
v0.dev → Copy componenti → /src/web/components
       ↓
   Implementazione logica
       ↓
   Test localmente (npm run dev)
       ↓
   Commit to Git
       ↓
   Vercel auto-deploy ✅
```

### 2. Sviluppo Mobile

```
FlutterFlow → Design UI/UX
       ↓
   Export code (manuale o API)
       ↓
   /src/mobile/ directory
       ↓
   Customizzazioni & Business Logic
       ↓
   Test (flutter run)
       ↓
   Build & Deploy (App Store / Play Store)
```

### 3. Backend (Supabase)

```
Spec in /specs/database
       ↓
   MCP Server execute SQL
       ↓
   Test API
       ↓
   Deploy via Supabase Dashboard
```

---

## 🔧 Troubleshooting

### Vercel

**Problema**: Deploy fallito
```bash
# Check logs
npx vercel logs <deployment-url>

# Redeploy
npx vercel --force
```

**Problema**: Environment variables non caricate
- Verifica su Vercel Dashboard → Settings → Environment Variables
- Redeploy dopo modifica env vars

### FlutterFlow

**Problema**: Export code non aggiornato
- Forza re-export da FlutterFlow dashboard
- Pulisci cache: `flutter clean && flutter pub get`

**Problema**: Build errors
```bash
# Clean build
flutter clean
flutter pub get
flutter pub upgrade

# Rebuild
flutter run
```

---

## 📊 CI/CD Pipeline (Future)

### GitHub Actions Workflow

Crea `.github/workflows/deploy.yml`:

```yaml
name: Deploy

on:
  push:
    branches: [main, develop]

jobs:
  deploy-web:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Deploy to Vercel
        run: npx vercel --token ${{ secrets.VERCEL_TOKEN }} --prod
        
  deploy-mobile:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: subosito/flutter-action@v2
      - name: Build APK
        run: flutter build apk --release
      - name: Upload to Play Store
        # Configura upload automatico
```

---

## 📝 Environment Variables Complete

### `.env` file structure:

```env
# Supabase
SUPABASE_ACCESS_TOKEN=your_access_token
SUPABASE_URL=https://xxxxx.supabase.co
SUPABASE_ANON_KEY=your_anon_key
SUPABASE_SERVICE_ROLE_KEY=your_service_key

# FlutterFlow (optional)
FLUTTERFLOW_API_KEY=your_ff_api_key
FLUTTERFLOW_PROJECT_ID=your_project_id

# Development
NODE_ENV=development

# Vercel (set in Vercel Dashboard)
# VERCEL_TOKEN=your_vercel_token
```

---

## ✅ Setup Checklist

### Web Deployment
- [x] Vercel CLI installato
- [x] Vercel login completato
- [ ] Primo deploy eseguito
- [ ] Repository connesso per auto-deploy
- [ ] Environment variables configurate
- [ ] Custom domain configurato (optional)

### Mobile Integration
- [ ] FlutterFlow project creato
- [ ] Flutter SDK installato localmente
- [ ] Export code da FlutterFlow completato
- [ ] Codice integrato in `/src/mobile`
- [ ] Build Android testata
- [ ] Build iOS testata (se applicabile)
- [ ] App pubblicata su store (future)

### Backend
- [x] Supabase project creato
- [x] MCP Server configurato
- [ ] Database schema definito in specs
- [ ] Prima migrazione eseguita
- [ ] API keys configurate in environments

---

## 🎯 Next Steps

1. **Immediate**:
   - Creare primo progetto FlutterFlow
   - Definire schema database in `/specs/database`
   - Eseguire primo deploy Vercel

2. **Short Term**:
   - Setup CI/CD pipeline
   - Configurare monitoring (Sentry/LogRocket)
   - Implementare prima feature

3. **Long Term**:
   - Pubblicazione app store
   - Scaling infrastructure
   - Performance optimization

---

**Documento Versione**: 1.0.0  
**Ultimo Aggiornamento**: 26 Gennaio 2026  
**Manutentore**: Cline + AI Team  
**Status**: ✅ Ready for Development

---

## 📚 Riferimenti

- [Vercel Documentation](https://vercel.com/docs)
- [FlutterFlow Docs](https://docs.flutterflow.io)
- [Flutter Documentation](https://flutter.dev/docs)
- [Supabase Docs](https://supabase.com/docs)
- [MASTER_SETUP.md](../MASTER_SETUP.md)

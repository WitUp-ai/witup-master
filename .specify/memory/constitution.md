# Draw2Toy Constitution

## Core Principles

### I. Mobile-First PWA
L'applicazione è una Progressive Web App Flutter. Ogni feature DEVE funzionare su mobile browser (Chrome/Safari). Il design è mobile-first, responsive secondario. L'entry point è `src/mobile/lib/main.dart`.

### II. Supabase as Backend
Supabase è l'unico backend: Auth, PostgreSQL, Storage, Edge Functions, Realtime. NON si usano backend custom. Le Edge Functions (Deno/TypeScript) gestiscono la logica server-side. Le API keys sono in `system_config` table con fallback su env vars.

### III. AI Pipeline Asincrona
Il processing AI è a 2 fasi: Fase 1 sincrona (validazione + bg removal, ~5-10s) ritorna concept 2D immediato. Fase 2 asincrona (3D generation via webhook, ~1-3min). L'utente NON deve restare bloccato in attesa. Il sistema DEVE notificare via Realtime quando il 3D è pronto.

### IV. Realtime-First UX
Ogni stato di processing DEVE essere visibile all'utente in tempo reale via Supabase Realtime `.stream()`. La tabella `drawings` DEVE avere Realtime abilitato (`supabase_realtime` publication). I campi `model_status` e `processing_step` guidano la UI.

### V. Italian UI
Tutta la UI utente è in italiano. Le label, i messaggi, le notifiche sono in italiano. I log di debug e i commenti nel codice possono essere in inglese.

### VI. Security by Default
Le Edge Functions usano dual client: anon key + user JWT per RLS, service role per operazioni admin. Le API keys NON sono mai esposte al client. Le credenziali sensibili sono in env vars o `system_config` table con RLS.

### VII. Test Before Deploy
`flutter test` DEVE passare prima di ogni deploy. `flutter build web --release` DEVE completare senza errori. Deploy su Vercel per il frontend, Supabase Cloud per le Edge Functions.

## Technology Stack

| Layer | Technology |
|-------|-----------|
| Frontend | Flutter Web (Dart), Riverpod, GoRouter, flutter_animate |
| Backend | Supabase Edge Functions (Deno/TypeScript) |
| Database | Supabase PostgreSQL con RLS |
| Storage | Supabase Storage (drawings-original, drawings-processed, models-3d, models-thumbnails) |
| AI | Replicate API (Moondream2, rembg, TripoSR) |
| Realtime | Supabase Realtime (PostgreSQL CDC) |
| 3D Viewer | model_viewer_plus (WebXR/AR) |
| Deploy | Vercel (frontend), Supabase Cloud (backend) |
| CI/CD | GitHub Actions |

## Development Workflow

1. SpecKit: `/speckit.specify` → `/speckit.plan` → `/speckit.tasks` → `/speckit.analyze`
2. Implementazione su feature branch `###-feature-name`
3. `flutter test` → `flutter build web --release`
4. Deploy Edge Functions: `./supabase.exe functions deploy <name> --project-ref rnfzzmfpykbavuirypfz`
5. Deploy frontend: `npx vercel --prod --public --yes` da `src/mobile/build/web`
6. Merge su main

## Governance

La Constitution è il documento autoritativo. Ogni decisione architetturale DEVE essere coerente con questi principi. Modifiche alla Constitution richiedono documentazione esplicita del cambio e della motivazione.

**Version**: 1.0.0 | **Ratified**: 2026-01-30 | **Last Amended**: 2026-01-30

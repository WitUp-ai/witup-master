# Implementation Plan: AI Processing Pipeline

**Branch**: `001-ai-pipeline` | **Date**: 2026-01-30 | **Spec**: [spec.md](spec.md)

## Summary

Pipeline AI a 2 fasi per trasformare disegni di bambini in modelli 3D. Fase 1 sincrona (validazione Moondream2 + bg removal rembg, ~5-10s) ritorna concept 2D immediato. Fase 2 asincrona (TripoSR 3D via webhook Replicate, ~1-3min) con notifica in-app Realtime.

## Technical Context

**Language/Version**: Dart 3.x (Flutter), TypeScript (Deno Edge Functions)
**Primary Dependencies**: Flutter, Riverpod, GoRouter, flutter_animate, model_viewer_plus, supabase_flutter, http
**Storage**: Supabase PostgreSQL + Supabase Storage (4 bucket)
**Testing**: flutter_test (unit), widget test
**Target Platform**: Mobile Web (Chrome, Safari iOS), PWA
**Project Type**: mobile (Flutter Web PWA + Supabase Edge Functions)
**Performance Goals**: Concept 2D < 15s, 3D notification < 5s dal webhook, progress bar update < 2s
**Constraints**: Edge Function timeout 60s (Supabase Free), client HTTP timeout 90s, Replicate API rate limits
**Scale/Scope**: Single user, ~50 disegni/giorno, 1 modello 3D alla volta

## Constitution Check

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Mobile-First PWA | ✅ | Flutter Web, mobile-first design |
| II. Supabase as Backend | ✅ | Edge Functions, Storage, Realtime, Auth |
| III. AI Pipeline Asincrona | ✅ | 2 fasi: sincrona + webhook asincrono |
| IV. Realtime-First UX | ✅ | `.stream()` su drawings, `processing_step` tracking |
| V. Italian UI | ✅ | Tutte le label in italiano |
| VI. Security by Default | ✅ | Dual client, API keys in env/system_config |
| VII. Test Before Deploy | ✅ | 14 test, build check pre-deploy |

## Architecture

### System Flow

```
┌──────────────┐     ┌─────────────────────┐     ┌──────────────────┐
│ Flutter App   │────▶│ process-drawing     │────▶│ Replicate API    │
│ (Dart)        │     │ (Edge Function)     │     │ (AI Models)      │
│               │◀────│                     │     │                  │
│               │ concept_url + est_time   │     │ Moondream2       │
│               │     │                     │     │ rembg            │
│               │     └─────────────────────┘     │ TripoSR          │
│               │                                  └────────┬─────────┘
│               │     ┌─────────────────────┐              │ webhook
│               │     │ process-webhook     │◀─────────────┘
│               │     │ (Edge Function)     │
│               │     │ saves .glb          │
│               │     │ updates DB          │
│               │     └─────────────────────┘
│               │                │
│               │◀───────────────┘ Supabase Realtime
│ DrawingNotifier│  (model_status: completed)
│ shows SnackBar │
└──────────────┘
```

### AI Models

| Step | Model | Version ID | Mode | Timeout |
|------|-------|-----------|------|---------|
| Validazione | Moondream2 | `cdda81e2...` | Sync poll (10s max) | 10s |
| BG Removal | rembg | `fb8af171...` | Sync poll (15s max) | 15s |
| BG Removal (fallback) | Remove.bg | REST API | Sync | 10s |
| 3D Generation | TripoSR | `ecd9d615...` | Async webhook | ~1-3min |

### Edge Functions

| Function | Purpose | Auth |
|----------|---------|------|
| `process-drawing` | Orchestrator Fase 1: validate + bg remove + kick 3D | User JWT + Service Role |
| `process-webhook` | Callback Replicate: salva .glb, aggiorna DB, notifica | Service Role only |

### Storage Buckets

| Bucket | Content | Access |
|--------|---------|--------|
| `drawings-original` | Foto originale upload | RLS (user_id) |
| `drawings-processed` | Concept 2D (bg removed) | Public URL |
| `models-3d` | File .glb 3D | Public URL |
| `models-thumbnails` | Thumbnail per gallery | Public URL |

### Database Schema (drawings table)

| Column | Type | Purpose |
|--------|------|---------|
| `model_status` | text | pending → processing → processing_3d → completed / failed |
| `processing_step` | text | uploading → validating → removing_background → generating_3d → finalizing → waiting_3d → done |
| `processed_image_url` | text | URL concept 2D |
| `model_3d_url` | text | URL modello .glb |
| `validation_status` | text | valid / invalid |
| `processing_error` | text | Messaggio errore |

## Project Structure

### Source Code

```text
src/mobile/lib/
├── main.dart                                    # Entry point
├── src/app.dart                                 # Draw2ToyApp + DrawingNotifier init
├── core/
│   ├── router/app_router.dart                   # GoRouter + rootNavigatorKey
│   ├── providers/auth_provider.dart             # Auth state
│   ├── theme/app_theme.dart                     # Theme
│   └── services/
│       ├── debug_log_service.dart               # Debug logging
│       └── drawing_notifier_service.dart         # Global Realtime listener
├── features/
│   ├── ai/
│   │   ├── services/ai_processing_service.dart  # HTTP call + models
│   │   └── providers/ai_processing_provider.dart # Riverpod state
│   ├── camera/presentation/camera_screen.dart   # Upload UI
│   ├── processing/presentation/processing_screen.dart # Progress + Concept 2D
│   ├── viewer/presentation/viewer_screen.dart   # 3D viewer + AR
│   ├── home/presentation/home_screen.dart       # Home + Gallery
│   └── auth/presentation/login_screen.dart      # Login + demo
└── test/features/ai/models/drawing_status_test.dart # 14 unit tests

supabase/functions/
├── process-drawing/index.ts                      # Orchestrator Edge Function
└── process-webhook/index.ts                      # Webhook handler
```

## Complexity Tracking

No violations. Single project, direct architecture, minimal abstractions.

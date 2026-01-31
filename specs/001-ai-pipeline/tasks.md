# Tasks: AI Processing Pipeline

**Input**: Design documents from `/specs/001-ai-pipeline/`
**Prerequisites**: plan.md (required), spec.md (required)

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel
- **[Story]**: Which user story (US1-US6)
- ✅ = Completed, 🔧 = In Progress / Needs Fix, ⬜ = Pending

---

## Phase 1: Setup (Shared Infrastructure)

- [x] T001 Setup Supabase project (Auth, Storage buckets, Edge Functions)
- [x] T002 Initialize Flutter project with dependencies (Riverpod, GoRouter, supabase_flutter, model_viewer_plus, flutter_animate)
- [x] T003 [P] Configure GoRouter with auth-protected routes in `core/router/app_router.dart`
- [x] T004 [P] Setup AppTheme with colors, gradients, shadows in `core/theme/app_theme.dart`
- [x] T005 [P] Setup DebugLogService in `core/services/debug_log_service.dart`
- [x] T006 Setup Auth provider with login/signup/demo in `core/providers/auth_provider.dart`

**Checkpoint**: ✅ Infrastruttura base pronta

---

## Phase 2: Foundational (Database + Edge Functions)

- [x] T007 Create `drawings` table with RLS policies (model_status, processing_step, image URLs, validation fields)
- [x] T008 Create `ai_predictions` table for prediction_id → drawing_id mapping
- [x] T009 Create `notifications` table
- [x] T010 Create `system_config` table per API keys con RLS
- [x] T011 [P] Add `processing_step` column to drawings via migration `20260130120000_add_processing_step.sql`
- [x] T012 [P] Enable Realtime on drawings table via migration `20260130150000_enable_realtime_drawings.sql`
- [x] T013 Implement `process-drawing` Edge Function in `supabase/functions/process-drawing/index.ts`
- [x] T014 Implement `process-webhook` Edge Function in `supabase/functions/process-webhook/index.ts`
- [x] T015 Deploy both Edge Functions to Supabase Cloud

**Checkpoint**: ✅ Backend completo e deployato

---

## Phase 3: User Story 1 - Upload e Validazione (Priority: P1) 🎯 MVP

**Goal**: L'utente può scattare foto / caricare immagine e il sistema valida se è un disegno

### Implementation

- [x] T016 [US1] Implement CameraScreen with dual buttons (Scatta Foto + Carica da Galleria) in `features/camera/presentation/camera_screen.dart`
- [x] T017 [US1] Implement image upload to Supabase Storage `drawings-original` bucket
- [x] T018 [US1] Implement Moondream2 vision validation in Edge Function (sync poll, 10s timeout)
- [x] T019 [US1] Handle `not_a_drawing` response in client with Italian error message
- [x] T020 [US1] Create `DrawingValidationException` class in `ai_processing_service.dart`

**Checkpoint**: ✅ Upload e validazione funzionanti

---

## Phase 4: User Story 2 - Concept 2D "Magic Mirror" (Priority: P1)

**Goal**: Il concept 2D (bg removed) viene mostrato entro ~10s come gratificazione immediata

### Implementation

- [x] T021 [US2] Implement rembg background removal in Edge Function (sync poll, 15s timeout)
- [x] T022 [P] [US2] Implement Remove.bg fallback in Edge Function
- [x] T023 [US2] Upload processed image to `drawings-processed` bucket and save public URL
- [x] T024 [US2] Add `concept_url` and `est_time_seconds` to Edge Function response
- [x] T025 [US2] Add `conceptUrl` and `estTimeSeconds` fields to `ProcessingResult` Dart model
- [x] T026 [US2] Implement `_buildConceptReadyView` in ProcessingScreen with concept image, countdown timer, "Puoi continuare a navigare" message
- [x] T027 [US2] Implement countdown timer with `_startCountdown`, `_remainingSeconds`, `_countdownText`
- [x] T028 [US2] Handle overtime state (indeterminate progress bar + "Ancora pochi istanti...")

**Checkpoint**: ✅ Concept 2D visibile con countdown — l'utente può navigare via

---

## Phase 5: User Story 3 - Generazione 3D Asincrona (Priority: P1)

**Goal**: Il modello 3D viene generato in background e l'utente viene notificato ovunque nell'app

### Implementation

- [x] T029 [US3] Implement TripoSR async prediction with webhook in Edge Function (`start3DGenerationAsync`)
- [x] T030 [US3] Store prediction mapping in `ai_predictions` table
- [x] T031 [US3] Implement webhook handler: download .glb, upload to `models-3d`, update `model_3d_url` and `model_status: completed`
- [x] T032 [US3] Create `DrawingNotifierService` in `core/services/drawing_notifier_service.dart` — global Realtime listener
- [x] T033 [US3] Wire DrawingNotifier into `Draw2ToyApp` (start on auth, stop on logout)
- [x] T034 [US3] Show SnackBar "Modello 3D Pronto!" with "VEDI" action navigating to ViewerScreen
- [x] T035 [US3] Add `rootNavigatorKey` to GoRouter for DrawingNotifier context access

**Checkpoint**: ✅ 3D generation asincrona con notifica in-app

---

## Phase 6: User Story 4 - Progress Bar Realtime (Priority: P2)

**Goal**: Progress bar dettagliata con step e percentuale, aggiornata in tempo reale

### Implementation

- [x] T036 [US4] Add `processing_step` updates at each stage in Edge Function (uploading, validating, removing_background, generating_3d, finalizing, waiting_3d)
- [x] T037 [US4] Implement `progressPercent` getter in `DrawingStatus` (0.10 → 0.25 → 0.45 → 0.65 → 0.85 → 0.90 → 1.0)
- [x] T038 [US4] Implement `stepLabel` getter with Italian labels
- [x] T039 [US4] Implement `_buildProcessingView` with animated icon, step list, percentage, determinate progress bar
- [x] T040 [US4] Create `_PipelineStep` class and `_StepState` enum (done/active/pending)
- [x] T041 [US4] Implement `_getStepState` logic for step rendering
- [x] T042 [US4] Implement stall detection (120s timeout, 5s polling, warning + retry/home buttons)
- [x] T043 [US4] Use `drawingStatusProvider` (StreamProvider with Realtime `.stream()`) for live updates
- [x] T044 [US4] Add `processing_step` to `checkStatus` SELECT query
- [x] T045 [US4] Verify Realtime updates end-to-end — fixed: Realtime publication enabled, REPLICA IDENTITY FULL, processing_step in checkStatus SELECT

**Checkpoint**: ✅ Progress bar con Realtime verificata

---

## Phase 7: User Story 5 - Viewer 3D + AR (Priority: P2)

**Goal**: ViewerScreen con modello 3D interattivo e AR

### Implementation

- [x] T046 [US5] Implement ViewerScreen with `model_viewer_plus` widget, auto-rotate, camera controls
- [x] T047 [US5] Convert `drawingDataProvider` from FutureProvider to StreamProvider (Realtime auto-update)
- [x] T048 [US5] Show 2D fallback image when `model_3d_url` is null
- [x] T049 [US5] Show status badge (Completato/In corso/Errore)
- [x] T050 [US5] AR button with Italian label

**Checkpoint**: ✅ Viewer 3D con Realtime auto-refresh e AR

---

## Phase 8: User Story 6 - Gallery 3D (Priority: P3)

**Goal**: Gallery con griglia di disegni, status badge, delete

### Implementation

- [x] T051 [US6] Implement gallery grid in HomeScreen Tab 2
- [x] T052 [US6] Show thumbnail, title, status badge per ogni disegno
- [x] T053 [US6] Implement delete with confirmation dialog
- [x] T054 [US6] Navigate to ViewerScreen on card tap

**Checkpoint**: ✅ Gallery funzionante

---

## Phase 9: Testing

- [x] T055 [P] Unit tests for `DrawingStatus.fromJson` (all states, getters) in `test/features/ai/models/drawing_status_test.dart`
- [x] T056 [P] Unit tests for `ProcessingResult.fromJson` (success, failure, defaults)
- [x] T057 [P] Unit test for `DrawingValidationException`
- [x] T058 Logic tests for ProcessingScreen (progressPercent, stepLabel, concept fields) in `test/features/processing/processing_logic_test.dart`
- [x] T059 Logic tests for ViewerScreen (3D available, 2D fallback, status transitions) in `test/features/viewer/viewer_logic_test.dart`
- [x] T060 Pipeline flow test (full state transitions, failure, timeout) in `test/features/ai/models/pipeline_flow_test.dart`

**Checkpoint**: ✅ 56/56 tests passing

---

## Phase 10: Polish & Deploy

- [x] T061 Remove stale `widget_test.dart` placeholder
- [x] T062 `flutter test` — all passing
- [x] T063 `flutter build web --release` — success
- [x] T064 Deploy Edge Functions to Supabase Cloud
- [x] T065 Deploy frontend to Vercel
- [x] T066 Implement `cleanup-stale` Edge Function: marks drawings stuck in processing_3d >10min as failed, notifies user
- [x] T067 Add `fetchWithRetry` (3 attempts, exponential backoff) to process-webhook for download operations
- [x] T068 Latency tests + processing_time_ms tracking in `test/features/ai/models/processing_result_test.dart`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)**: No dependencies
- **Phase 2 (Foundation)**: Depends on Phase 1
- **Phase 3-5 (P1 Stories)**: Depend on Phase 2, sequential (US1 → US2 → US3)
- **Phase 6-8 (P2-P3 Stories)**: Depend on Phase 2, can parallel with P1 stories
- **Phase 9 (Testing)**: Can start after Phase 3
- **Phase 10 (Deploy)**: After all implementation phases

### Status Summary

| Phase | Status | Completion |
|-------|--------|-----------|
| 1. Setup | ✅ | 6/6 |
| 2. Foundation | ✅ | 9/9 |
| 3. US1 Upload/Validate | ✅ | 5/5 |
| 4. US2 Concept 2D | ✅ | 8/8 |
| 5. US3 3D Async | ✅ | 7/7 |
| 6. US4 Progress Bar | ✅ | 10/10 |
| 7. US5 Viewer 3D | ✅ | 5/5 |
| 8. US6 Gallery | ✅ | 4/4 |
| 9. Testing | ✅ | 6/6 |
| 10. Polish | ✅ | 8/8 |

**Overall**: 68/68 tasks complete (100%) ✅

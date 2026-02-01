# Feature Specification: AI Processing Pipeline

**Feature Branch**: `001-ai-pipeline`
**Created**: 2026-01-30
**Status**: In Progress
**Input**: Pipeline AI a 2 fasi per trasformare disegni di bambini in modelli 3D

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Upload e Validazione Disegno (Priority: P1)

Il bambino (o genitore) scatta una foto del disegno su carta o la carica dalla galleria. Il sistema valida che l'immagine sia effettivamente un disegno e non una foto generica.

**Why this priority**: Senza upload e validazione non esiste il prodotto. È il punto di ingresso obbligatorio.

**Independent Test**: Caricare un'immagine dalla camera/galleria, verificare che venga salvata su Supabase Storage e che la validazione AI accetti/rifiuti correttamente.

**Acceptance Scenarios**:

1. **Given** l'utente è autenticato e nella CameraScreen, **When** scatta una foto di un disegno su carta, **Then** l'immagine viene caricata su `drawings-original` e un record viene creato in `drawings` con `model_status: pending`
2. **Given** l'utente carica una foto di un oggetto (non un disegno), **When** la validazione AI analizza l'immagine, **Then** il sistema mostra "Non è un Disegno" con messaggio esplicativo e suggerimento di riprovare
3. **Given** l'utente carica un disegno valido, **When** la validazione passa, **Then** il processing prosegue alla fase successiva

---

### User Story 2 - Concept 2D "Magic Mirror" (Priority: P1)

Dopo la validazione, il sistema rimuove lo sfondo dal disegno e mostra il "Concept 2D" (disegno isolato su sfondo trasparente) come premio immediato entro ~5-10 secondi.

**Why this priority**: Il concept 2D è la gratificazione immediata. Senza di esso l'utente aspetta 2+ minuti senza feedback.

**Independent Test**: Caricare un disegno valido, verificare che entro 15s appaia il concept 2D nella ProcessingScreen con l'immagine processata visibile.

**Acceptance Scenarios**:

1. **Given** il disegno è stato validato, **When** il bg removal completa, **Then** l'immagine processata viene salvata su `drawings-processed` e mostrata nella ProcessingScreen con titolo "Ecco il tuo Concept 2D!"
2. **Given** il concept 2D è visibile, **When** l'utente guarda la schermata, **Then** vede un countdown timer "Tempo stimato: M:SS" per il modello 3D e il messaggio "Puoi continuare a navigare!"
3. **Given** il concept 2D è mostrato, **When** l'utente preme "Torna alla Home", **Then** viene reindirizzato alla home e il processing 3D continua in background

---

### User Story 3 - Generazione 3D Asincrona (Priority: P1)

Il modello 3D viene generato in background (~1-3 minuti) tramite TripoSR. L'utente può navigare liberamente nell'app. Quando il 3D è pronto, riceve una notifica in-app.

**Why this priority**: È il deliverable finale del prodotto — il giocattolo 3D.

**Independent Test**: Dopo l'upload di un disegno, attendere la notifica SnackBar "Modello 3D Pronto!" e verificare che il viewer 3D mostri il modello .glb.

**Acceptance Scenarios**:

1. **Given** il concept 2D è stato generato, **When** l'Edge Function lancia TripoSR via webhook, **Then** il `model_status` diventa `processing_3d` e `processing_step` diventa `waiting_3d`
2. **Given** l'utente è nella Home o in qualsiasi schermata, **When** il webhook Replicate notifica il completamento 3D, **Then** un SnackBar verde appare con "Modello 3D Pronto!" e pulsante "VEDI"
3. **Given** l'utente preme "VEDI" sulla notifica, **Then** viene navigato al ViewerScreen con il modello 3D interattivo e opzione AR

---

### User Story 4 - Progress Bar in Tempo Reale (Priority: P2)

Durante la Fase 1 (sincrona), la ProcessingScreen mostra una progress bar con percentuale e lista step dettagliata aggiornata in tempo reale via Supabase Realtime.

**Why this priority**: Migliora la UX ma non è bloccante per il funzionamento base.

**Independent Test**: Avviare il processing e verificare che la progress bar si muova attraverso gli step: Caricamento → Validazione AI → Rimozione sfondo → Generazione 3D → Finalizzazione.

**Acceptance Scenarios**:

1. **Given** il processing è in corso, **When** l'Edge Function aggiorna `processing_step` nel DB, **Then** la ProcessingScreen mostra lo step corrente con icona spinner, gli step completati con check verde, e quelli futuri in grigio
2. **Given** il processing non avanza per 120 secondi, **When** lo stall detector rileva il blocco, **Then** appare un warning arancione con opzioni "Riprova" e "Home"

---

### User Story 5 - Visualizzazione 3D e AR (Priority: P2)

Il ViewerScreen mostra il modello 3D interattivo con possibilità di rotazione, zoom, e visualizzazione in AR (WebXR).

**Why this priority**: Dipende dalla generazione 3D (US3) ma è essenziale per il valore del prodotto.

**Independent Test**: Navigare al ViewerScreen con un drawingId valido che ha `model_3d_url`, verificare che il modello 3D sia renderizzato e interattivo.

**Acceptance Scenarios**:

1. **Given** un disegno con `model_3d_url` valorizzato, **When** l'utente apre il ViewerScreen, **Then** vede il modello 3D con `model_viewer_plus`, con rotazione e zoom touch
2. **Given** il disegno è in `processing_3d` (3D non ancora pronto), **When** il webhook completa e aggiorna `model_3d_url`, **Then** il ViewerScreen si aggiorna automaticamente via Realtime mostrando il modello 3D
3. **Given** il modello 3D è caricato, **When** l'utente preme il pulsante AR, **Then** il modello viene mostrato in Realtà Aumentata (su dispositivi compatibili)

---

### User Story 6 - Gallery 3D con Gestione (Priority: P3)

La Gallery mostra tutti i disegni dell'utente con stato, preview, e opzione delete.

**Why this priority**: Feature di gestione, non critica per il flusso principale.

**Independent Test**: Verificare che la gallery mostri i disegni con status badge corretto e che il delete funzioni.

**Acceptance Scenarios**:

1. **Given** l'utente ha disegni processati, **When** apre la Gallery 3D, **Then** vede una griglia di card con thumbnail, titolo, e status badge (Completato/In corso/Errore)
2. **Given** l'utente vuole eliminare un disegno, **When** preme l'icona cestino e conferma, **Then** il disegno viene rimosso dal DB e dallo storage

---

### Edge Cases

- Cosa succede se l'Edge Function va in timeout (>60s)? → Il client ha timeout a 90s, stall detection a 120s, l'utente può riprovare
- Cosa succede se Replicate è down? → Il bg removal fallisce, il sistema marca il disegno come `failed` con errore specifico
- Cosa succede se il webhook 3D non arriva mai? → Il disegno resta in `processing_3d`; la gallery mostra "In corso" indefinitamente (TODO: aggiungere timeout server-side)
- Cosa succede se l'utente non è autenticato? → Il router redirige a login, la ProcessingScreen mostra "Utente non autenticato"
- Cosa succede se lo storage è pieno o il file è troppo grande? → L'upload fallisce con errore gestito nella CameraScreen

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Il sistema DEVE validare ogni immagine caricata con un modello vision AI (Moondream2) per verificare che sia un disegno su carta
- **FR-002**: Il sistema DEVE rimuovere lo sfondo dal disegno usando rembg (fallback: Remove.bg) e salvare il concept 2D
- **FR-003**: Il sistema DEVE generare un modello 3D (.glb) dal concept 2D usando TripoSR via webhook asincrono
- **FR-004**: Il sistema DEVE aggiornare `processing_step` nel DB ad ogni fase per abilitare il tracking in tempo reale via Realtime
- **FR-005**: Il sistema DEVE ritornare `concept_url` e `est_time_seconds` nella risposta HTTP della Edge Function
- **FR-006**: Il sistema DEVE notificare l'utente in-app (SnackBar) quando il modello 3D è pronto, indipendentemente dalla schermata corrente
- **FR-007**: Il sistema DEVE salvare il modello 3D su Supabase Storage e aggiornare `model_3d_url` nel record drawing
- **FR-008**: Il sistema DEVE mostrare il modello 3D nel ViewerScreen con `model_viewer_plus` e supporto AR
- **FR-009**: Il sistema DEVE permettere la cancellazione di un disegno dalla gallery con conferma
- **FR-010**: Il sistema DEVE gestire il fallback da Edge Function a MVP mode (processing diretto senza AI) quando le API non sono configurate

### Non-Functional Requirements

- **NFR-001**: La Fase 1 (concept 2D) DEVE completare entro 15 secondi nel 90% dei casi
- **NFR-002**: La notifica 3D DEVE apparire entro 5 secondi dal completamento del webhook
- **NFR-003**: La progress bar DEVE aggiornarsi entro 2 secondi da ogni cambio di `processing_step`
- **NFR-004**: Il sistema DEVE funzionare su Chrome mobile e Safari iOS
- **NFR-005**: Le API keys NON devono mai essere esposte al client

### Key Entities

- **Drawing**: Record principale — `id`, `user_id`, `title`, `original_image_url`, `processed_image_url`, `model_3d_url`, `thumbnail_url`, `model_status`, `processing_step`, `processing_error`, `validation_status`, `validation_reason`
- **AIProcession**: Mapping prediction → drawing — `prediction_id`, `drawing_id`, `user_id`, `prediction_type`, `status`, `output`, `error`
- **Notification**: Notifiche in-app — `user_id`, `type`, `title`, `message`, `action_url`, `metadata`

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: L'utente vede il Concept 2D entro 15 secondi dall'upload
- **SC-002**: Il modello 3D viene generato e notificato entro 3 minuti dall'upload
- **SC-003**: La progress bar mostra almeno 5 step distinti durante il processing
- **SC-004**: La notifica SnackBar appare in qualsiasi schermata quando il 3D è pronto
- **SC-005**: Il ViewerScreen si aggiorna automaticamente via Realtime quando il 3D arriva
- **SC-006**: Tutti i test (`flutter test`) passano prima di ogni deploy
- **SC-007**: Immagini non-disegno vengono rifiutate con messaggio chiaro nel 95% dei casi

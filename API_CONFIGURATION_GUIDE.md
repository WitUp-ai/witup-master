# 🔑 Guida alla Configurazione delle API

## 📋 Problema Risolto

L'applicazione mostrava il messaggio:
> "3D model generation requires API configuration. The image has been processed and saved."

Questo indicava che le API per la generazione 3D non erano configurate correttamente.

---

## ✅ Soluzioni Implementate

### 1. **Configurazione Mobile App** (`src/mobile/.env`)

Aggiunto il token API di Replicate nel file di ambiente dell'app Flutter:

```env
# AI Services Configuration
REPLICATE_API_TOKEN=YOUR_REPLICATE_API_TOKEN
```

### 2. **Configurazione Edge Functions** (Supabase)

Configurato il secret `REPLICATE_API_TOKEN` per le Edge Functions:

```bash
supabase secrets set REPLICATE_API_TOKEN=YOUR_REPLICATE_API_TOKEN --project-ref rnfzzmfpykbavuirypfz
```

✅ **Status**: Configurato con successo

> **Nota**: Le variabili `SUPABASE_URL` e `SUPABASE_SERVICE_ROLE_KEY` sono automaticamente iniettate da Supabase nelle Edge Functions e non possono essere configurate manualmente come secrets.

---

## 🔧 Come Funziona la Generazione 3D

### Flusso Completo

1. **Upload Immagine** → L'utente carica un disegno
2. **Process Drawing Function** → Elabora l'immagine e rimuove lo sfondo
3. **Replicate API** → Genera il modello 3D usando TripoSR
4. **Webhook** → Notifica l'applicazione quando il modello è pronto
5. **Storage** → Salva il modello 3D in Supabase Storage
6. **Notifica** → L'utente viene notificato che il modello è pronto

### Servizi AI Utilizzati

#### **Replicate API** (Principale)
- **Background Removal**: Modello `rembg` (fb8af171...)
- **3D Generation**: Modello `TripoSR` (ecd9d615...)
- **Token**: `YOUR_REPLICATE_API_TOKEN`

#### **Fallback Services** (Opzionali - Non configurati)
- Remove.bg API (per rimozione sfondo)
- Rodin API (per generazione 3D alternativa)

---

## 📂 File Modificati

### 1. `src/mobile/.env`
```diff
+ # AI Services Configuration
+ REPLICATE_API_TOKEN=YOUR_REPLICATE_API_TOKEN
```

### 2. Script Creato: `configure-supabase-secrets.bat`
Script per configurare automaticamente i secrets nelle Edge Functions di Supabase.

---

## 🧪 Come Testare

### 1. **Verifica Configurazione Supabase**
```bash
supabase secrets list --project-ref rnfzzmfpykbavuirypfz
```

Dovresti vedere:
- `REPLICATE_API_TOKEN` configurato

### 2. **Test della Generazione 3D**

1. Avvia l'app mobile
2. Carica un disegno
3. L'app dovrebbe ora:
   - ✅ Processare l'immagine
   - ✅ Rimuovere lo sfondo
   - ✅ Avviare la generazione 3D
   - ✅ Notificarti quando il modello è pronto

### 3. **Monitoraggio Edge Function**

Verifica i log della Edge Function `process-drawing`:
```bash
supabase functions logs process-drawing --project-ref rnfzzmfpykbavuirypfz
```

Dovresti vedere:
```
✅ Processing drawing: [drawing_id]
✅ Replicate background removal succeeded
✅ 3D generation started async, prediction ID: [id]
```

---

## 🔍 Troubleshooting

### Problema: "API configuration missing"
**Soluzione**: Verifica che `REPLICATE_API_TOKEN` sia configurato:
```bash
supabase secrets list --project-ref rnfzzmfpykbavuirypfz
```

### Problema: "Background removal failed"
**Cause possibili**:
- Token Replicate non valido
- Quota API esaurita
- Formato immagine non supportato

**Verifica**:
```bash
curl https://api.replicate.com/v1/predictions \
  -H "Authorization: Token YOUR_REPLICATE_API_TOKEN"
```

### Problema: "3D generation timeout"
**Soluzione**: La generazione 3D avviene in modo asincrono con webhook. Il processo può richiedere 2-5 minuti.

---

## 📊 Stato della Configurazione

| Componente | Status | Note |
|------------|--------|------|
| Mobile App `.env` | ✅ Configurato | REPLICATE_API_TOKEN aggiunto |
| Supabase Secrets | ✅ Configurato | REPLICATE_API_TOKEN impostato |
| Edge Functions | ✅ Pronte | process-drawing e process-webhook |
| Database Tables | ✅ Esistenti | drawings, ai_predictions |
| Storage Buckets | ✅ Esistenti | drawings-original, drawings-processed, models-3d |

---

## 🔐 Sicurezza

### API Keys Configurate

- ✅ **REPLICATE_API_TOKEN**: Configurato (sia mobile che Edge Functions)
- ⏳ **REMOVE_BG_API_KEY**: Non configurato (opzionale, fallback)
- ⏳ **RODIN_API_KEY**: Non configurato (opzionale, alternativa)
- ⏳ **OPENAI_API_KEY**: Non configurato (per future features)

### Raccomandazioni

1. **Non committare** il file `.env` nel repository
2. **Rotazione chiavi**: Cambia periodicamente le API keys
3. **Monitoraggio quota**: Controlla l'uso delle API su Replicate
4. **Backup**: Salva le configurazioni in un posto sicuro

---

## 🚀 Prossimi Passi

1. ✅ Testare la generazione 3D con un disegno reale
2. ⏳ Monitorare i log per eventuali errori
3. ⏳ Configurare servizi di fallback (Remove.bg, Rodin) se necessario
4. ⏳ Ottimizzare i parametri del modello TripoSR per migliori risultati

---

## 📞 Supporto

Per problemi o domande:
- Verifica i log delle Edge Functions: `supabase functions logs process-drawing`
- Controlla lo stato di Replicate: https://replicate.com/account/api-tokens
- Consulta la documentazione: https://replicate.com/docs

---

**Data ultima modifica**: 29 Gennaio 2026  
**Progetto Supabase**: `rnfzzmfpykbavuirypfz`  
**Status**: ✅ OPERATIVO

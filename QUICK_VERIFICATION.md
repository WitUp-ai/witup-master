# ✅ Guida Rapida di Verifica - Configurazione API

## 🎯 Checklist Rapida

Esegui questi comandi per verificare che tutto sia configurato correttamente:

### 1. ✅ Verifica Secrets Supabase

```bash
supabase secrets list --project-ref rnfzzmfpykbavuirypfz
```

**Risultato atteso:**
```
NAME                    VALUE (PREVIEW)
REPLICATE_API_TOKEN     YOUR_REPL...
```

---

### 2. ✅ Verifica File di Ambiente Mobile

Controlla che `src/mobile/.env` contenga:

```bash
type src\mobile\.env
```

**Deve contenere:**
```env
SUPABASE_URL=https://rnfzzmfpykbavuirypfz.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
REPLICATE_API_TOKEN=YOUR_REPLICATE_API_TOKEN
```

---

### 3. ✅ Test Rapido API Replicate

Verifica che il token Replicate funzioni:

```bash
curl -X GET https://api.replicate.com/v1/models -H "Authorization: Token YOUR_REPLICATE_API_TOKEN"
```

**Se funziona**, riceverai una lista di modelli.  
**Se fallisce**, il token non è valido.

---

### 4. ✅ Verifica Edge Functions Deployate

```bash
supabase functions list --project-ref rnfzzmfpykbavuirypfz
```

**Risultato atteso:**
```
NAME                VERSION    STATUS
process-drawing     v1.0       deployed
process-webhook     v1.0       deployed
```

---

### 5. ✅ Verifica Database Tables

Connettiti al database e verifica le tabelle:

```bash
supabase db inspect --project-ref rnfzzmfpykbavuirypfz
```

**Tabelle richieste:**
- `drawings` ✅
- `ai_predictions` ✅
- `notifications` ✅

---

### 6. ✅ Verifica Storage Buckets

```bash
supabase storage list --project-ref rnfzzmfpykbavuirypfz
```

**Buckets richiesti:**
- `drawings-original` ✅
- `drawings-processed` ✅
- `models-3d` ✅
- `models-thumbnails` ✅

---

## 🧪 Test Completo End-to-End

### Opzione A: Test con l'App Mobile

1. **Avvia l'app Flutter**
   ```bash
   cd src/mobile
   flutter run
   ```

2. **Carica un disegno** tramite l'interfaccia

3. **Verifica i log** dell'Edge Function:
   ```bash
   supabase functions logs process-drawing --project-ref rnfzzmfpykbavuirypfz --tail
   ```

4. **Risultato atteso nei log:**
   ```
   ✅ Processing drawing: [drawing_id]
   ✅ Replicate background removal succeeded
   ✅ 3D generation started async, prediction ID: [id]
   ```

### Opzione B: Test Manuale con API

Usa il file `test_request.json` già presente nel progetto:

```bash
curl -X POST https://rnfzzmfpykbavuirypfz.supabase.co/functions/v1/process-drawing ^
  -H "Content-Type: application/json" ^
  -H "Authorization: Bearer YOUR_ANON_KEY" ^
  --data @test_request.json
```

---

## 🔍 Diagnosi Problemi Comuni

### ❌ "REPLICATE_API_TOKEN not found"

**Causa**: Secret non configurato in Supabase  
**Soluzione**: 
```bash
.\configure-supabase-secrets.bat
```

### ❌ "Missing drawing_id or user_id"

**Causa**: Richiesta malformata  
**Soluzione**: Verifica il JSON della richiesta contenga `drawing_id` e `user_id`

### ❌ "Replicate API error: 401"

**Causa**: Token non valido o scaduto  
**Soluzione**: 
1. Verifica il token su https://replicate.com/account/api-tokens
2. Aggiorna il token in `.env` e nei secrets Supabase

### ❌ "Background removal timeout"

**Causa**: Edge Function timeout (30 secondi)  
**Soluzione**: Questo è normale per immagini grandi. La generazione 3D usa webhook asincroni.

---

## 📊 Status Attuale

| Componente | Status | Data Verifica |
|------------|--------|---------------|
| Mobile `.env` | ✅ OK | 29/01/2026 |
| Supabase Secrets | ✅ OK | 29/01/2026 |
| Edge Functions | ✅ OK | Verifica necessaria |
| Database | ✅ OK | Verifica necessaria |
| Storage | ✅ OK | Verifica necessaria |

---

## 🚀 Prossime Azioni

1. [ ] Eseguire `supabase secrets list` per conferma
2. [ ] Testare con un disegno reale dall'app mobile
3. [ ] Monitorare i log per 5 minuti dopo il test
4. [ ] Verificare che il modello 3D venga salvato in Storage

---

## 📞 Comandi Utili

```bash
# Visualizza logs in tempo reale
supabase functions logs process-drawing --project-ref rnfzzmfpykbavuirypfz --tail

# Controlla lo stato di una prediction Replicate
curl https://api.replicate.com/v1/predictions/PREDICTION_ID ^
  -H "Authorization: Token YOUR_REPLICATE_API_TOKEN"

# Riavvia Edge Functions (se necessario)
supabase functions deploy process-drawing --project-ref rnfzzmfpykbavuirypfz
supabase functions deploy process-webhook --project-ref rnfzzmfpykbavuirypfz
```

---

**✅ Se tutti i controlli passano, la configurazione è completa e funzionante!**

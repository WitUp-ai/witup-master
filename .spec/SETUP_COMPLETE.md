# Draw2Toy - Setup Completo

## 1. Configurazione Supabase (gia' fatto)

Database e Storage sono configurati. Bucket disponibili:
- `drawings-original` (private)
- `drawings-processed` (public)
- `models-3d` (public)
- `models-thumbnails` (public)
- `ar-assets` (public)
- `avatars` (public)

## 2. Deploy Edge Function

### Opzione A: Via Supabase Dashboard (Consigliato)

1. Vai su https://supabase.com/dashboard/project/rnfzzmfpykbavuirypfz/functions
2. Clicca "New Function"
3. Nome: `process-drawing`
4. Copia il contenuto di `supabase/functions/process-drawing/index.ts`
5. Clicca "Deploy"

### Opzione B: Via CLI

```bash
npx supabase functions deploy process-drawing --project-ref rnfzzmfpykbavuirypfz
```

## 3. Configura API Keys (Secrets)

Nel Supabase Dashboard > Project Settings > Edge Functions > Secrets:

### REPLICATE_API_TOKEN (Raccomandato - Gratuito per iniziare)
1. Vai su https://replicate.com
2. Crea account (gratuito)
3. Vai su https://replicate.com/account/api-tokens
4. Crea token
5. Aggiungi come Secret: `REPLICATE_API_TOKEN`

### REMOVE_BG_API_KEY (Opzionale - Alternativa)
1. Vai su https://www.remove.bg/api
2. Crea account (50 chiamate/mese gratuite)
3. Ottieni API key
4. Aggiungi come Secret: `REMOVE_BG_API_KEY`

### RODIN_API_KEY (Opzionale - Premium 3D)
1. Vai su https://hyper3d.ai
2. Richiedi accesso API
3. Aggiungi come Secret: `RODIN_API_KEY`

## 4. Test dell'App

URL Produzione: https://web-wit-up.vercel.app

1. Login con le credenziali esistenti
2. Clicca "Create Magic"
3. Seleziona un'immagine
4. L'immagine verra' processata automaticamente

## 5. Flusso Completo

```
Utente carica immagine
    ↓
Flutter App → Supabase Storage (drawings-original)
    ↓
Flutter App → Crea record in drawings table
    ↓
Flutter App → Chiama Edge Function process-drawing
    ↓
Edge Function → Scarica immagine
    ↓
Edge Function → Rimuove sfondo (Replicate/Remove.bg)
    ↓
Edge Function → Genera modello 3D (Replicate TripoSR)
    ↓
Edge Function → Salva risultati in Storage
    ↓
Edge Function → Aggiorna database (status: completed)
    ↓
Edge Function → Crea notifica
    ↓
Flutter App → Mostra risultato in Viewer
```

## 6. Costi Stimati

### Replicate (Raccomandato)
- Background Removal (rembg): ~$0.0023/immagine
- 3D Generation (TripoSR): ~$0.05/modello
- **Totale: ~$0.05/disegno**

### Remove.bg
- 50 chiamate/mese gratuite
- Poi $0.20/immagine

### Supabase
- Piano Free: 500MB storage, 2GB bandwidth
- Piano Pro ($25/mese): 100GB storage, 250GB bandwidth

## 7. Troubleshooting

### "Edge Function not found"
- Verifica che la funzione sia deployata
- Controlla il nome: `process-drawing`

### "Processing failed"
- Controlla i logs in Supabase Dashboard > Logs > Edge Functions
- Verifica che REPLICATE_API_TOKEN sia configurato

### "3D model not generated"
- TripoSR richiede immagini con sfondo bianco/trasparente
- Assicurati che il background removal funzioni prima

### "Storage permission denied"
- Verifica le RLS policies sui bucket
- I bucket public permettono lettura a tutti

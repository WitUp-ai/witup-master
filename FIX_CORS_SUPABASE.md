# 🔧 FIX CORS ERROR - Supabase Configuration

## 🚨 Problema Identificato
L'app Flutter Web non può connettersi a Supabase a causa di restrizioni CORS:
```
Access to fetch at 'https://rnfzzmfpykbavuirypfz.supabase.co/rest/v1/drawings'
from origin 'https://web-wit-up.vercel.app' has been blocked by CORS policy
```

## ✅ Soluzione: Configurare CORS su Supabase

### Step 1: Accedi a Supabase Dashboard
1. Vai su: https://supabase.com/dashboard/project/rnfzzmfpykbavuirypfz
2. Login con le tue credenziali

### Step 2: Configura Site URLs
1. Nel menu laterale sinistro, clicca su **Authentication**
2. Clicca su **URL Configuration**
3. Aggiungi questi URL nel campo **Site URL**:
   ```
   http://localhost:*
   https://web-wit-up.vercel.app
   https://*.vercel.app
   ```

### Step 3: Configura Redirect URLs (Optional)
Nel campo **Redirect URLs**, aggiungi:
```
http://localhost:*
https://web-wit-up.vercel.app/**
https://*.vercel.app/**
```

### Step 4: Salva e Attendi
1. Clicca **Save** in basso
2. Attendi 1-2 minuti per la propagazione delle modifiche

## 🧪 Test Rapido
Dopo la configurazione, esegui questo test:

```bash
# Test dalla CLI
curl -H "apikey: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJuZnp6bWZweWtiYXZ1aXJ5cGZ6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njk1MjI4MDUsImV4cCI6MjA4NTA5ODgwNX0.H4sV8bYrXz0YVbdC25TSg22iYnMaFbnyRejyEwG2O74" \
     -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJuZnp6bWZweWtiYXZ1aXJ5cGZ6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njk1MjI4MDUsImV4cCI6MjA4NTA5ODgwNX0.H4sV8bYrXz0YVbdC25TSg22iYnMaFbnyRejyEwG2O74" \
     https://rnfzzmfpykbavuirypfz.supabase.co/rest/v1/drawings?limit=1
```

Se vedi un JSON con i disegni → **CORS Risolto!** ✅

## 🔍 Alternative: Se il problema persiste

### Opzione A: Verifica Environment Variables su Vercel
Assicurati che queste variabili siano configurate:
```env
NEXT_PUBLIC_SUPABASE_URL=https://rnfzzmfpykbavuirypfz.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

### Opzione B: Controlla il codice Flutter
Il file `src/mobile/lib/core/config/app_config.dart` deve avere:
```dart
static const String supabaseUrl = 'https://rnfzzmfpykbavuirypfz.supabase.co';
static const String supabaseAnonKey = 'eyJhbGc...';
```

### Opzione C: Aggiungi Headers personalizzati (ultima risorsa)
Se Supabase ancora blocca, potrebbe essere necessario un proxy middleware.

## 📝 Note Importanti

1. **Wildcard URLs**: L'uso di `*` permette tutti i sottodomini Vercel (comodo per preview)
2. **Localhost**: Importante per testing locale dell'app Flutter Web
3. **Cache Browser**: Dopo il fix, svuota la cache del browser (Ctrl+Shift+Delete)
4. **Propagazione**: Le modifiche CORS possono richiedere 1-2 minuti

## ✅ Verifica Finale
Dopo aver configurato CORS:
1. Riapri l'app Flutter Web su Vercel
2. Prova a caricare un disegno
3. Controlla la console del browser (F12) → Non dovrebbero più esserci errori CORS

---

**Se il problema persiste dopo queste configurazioni, fammi sapere e investigheremo ulteriormente!**
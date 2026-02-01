# 🔐 Accesso Pannello Admin - Draw2Toy

## 📍 URL Pannello Admin

### Produzione (Vercel)
```
https://web-wit-up.vercel.app/admin
```

### Locale (Development)
```
http://localhost:8080/admin
```

---

## 👤 Credenziali Admin

### Account Autorizzato
**SOLO** il seguente account ha accesso al pannello admin:

```
Email: giovanni.sapere@witup.ai
Password: [La tua password Supabase Auth]
```

### 🚫 Altri Account
Tutti gli altri account (inclusi utenti registrati normali) vedranno:
- Messaggio: **"Non hai i permessi per accedere a questa sezione"**
- Icona lucchetto

---

## 🔄 Flusso di Accesso

### Step-by-Step

1. **Vai all'URL**
   ```
   https://web-wit-up.vercel.app/admin
   ```

2. **Redirect Automatico**
   - Se NON sei loggato → redirect a `/login`
   - Se sei loggato ma NON admin → vedi "Accesso Negato"
   - Se sei loggato come `giovanni.sapere@witup.ai` → vedi Admin Panel

3. **Login con Account Admin**
   - Email: `giovanni.sapere@witup.ai`
   - Password: [inserisci la password]
   - Click "Accedi"

4. **Visualizza Admin Panel**
   - 5 tab disponibili:
     - 📊 **Overview**: Stats sistema
     - 👥 **Utenti**: Gestione utenti
     - 🎨 **Drawings**: Tutti i disegni
     - ⚙️ **API & Config**: Configurazione chiavi API
     - 💰 **Costi**: Dashboard costi AI

---

## 🛠️ Configurazione Admin

### Aggiungere Altri Admin

Se vuoi aggiungere altri account admin, modifica il file:

```dart
// File: src/mobile/lib/features/admin/providers/admin_provider.dart
const _adminEmails = [
  'giovanni.sapere@witup.ai',
  'altro.admin@example.com', // Aggiungi qui
];
```

Poi ricompila e rideploya l'app:
```bash
cd src/mobile
flutter build web --release
# Deploy su Vercel
```

### Controllo Accesso via Database (Alternativa)

Per gestire admin dinamicamente senza ricompilare:

1. Aggiungi colonna `role` alla tabella `users`:
```sql
ALTER TABLE users ADD COLUMN role TEXT DEFAULT 'user';
UPDATE users SET role = 'admin' WHERE email = 'giovanni.sapere@witup.ai';
```

2. L'app già controlla automaticamente la colonna `role` nel database (vedi `isAdminProvider`)

---

## 🔍 Troubleshooting

### Problema: "Redirect a /home invece di /admin"

**Causa**: Sei già loggato, quindi il router ti porta a `/home`

**Soluzione**:
1. Una volta loggato, naviga manualmente a:
   ```
   https://web-wit-up.vercel.app/admin
   ```
2. Oppure aggiungi un link admin nella HomeScreen (vedi sotto)

### Problema: "Accesso Negato"

**Causa**: Account non autorizzato

**Verifica**:
1. Controlla l'email usata per login
2. Deve essere **esattamente** `giovanni.sapere@witup.ai`
3. Verifica nel codice che l'email sia in `_adminEmails`

### Problema: "Infinite redirect loop"

**Causa**: Problema di autenticazione Supabase

**Soluzione**:
1. Logout completo
2. Clear cache browser
3. Login di nuovo con `giovanni.sapere@witup.ai`

---

## 🎨 UI: Aggiungere Link Admin nella Home

Per facilitare l'accesso, puoi aggiungere un pulsante nella HomeScreen:

```dart
// File: src/mobile/lib/features/home/presentation/home_screen.dart

// Aggiungi nel build() method:
if (isAdmin) // Solo se admin
  FloatingActionButton(
    onPressed: () => context.go('/admin'),
    child: const Icon(Icons.admin_panel_settings),
    tooltip: 'Admin Panel',
  )
```

---

## 📊 Funzionalità Admin Panel

### Tab 1: Overview
- Total Users
- Total Drawings
- Success Rate
- Recent Errors

### Tab 2: Utenti
- Lista completa utenti
- Search/Filter
- Ban/Suspend
- View subscription status

### Tab 3: Drawings
- Tutti i disegni con status
- Failed processing logs
- Retry failed drawings
- Download models

### Tab 4: API & Config
- **🔑 REPLICATE_API_TOKEN** (masked con ***)
- **Prompt Cuppy** (editabile)
- **Monthly Spend Limit** (budget)
- **Cost Estimates** per operazione

### Tab 5: Costi (NUOVO)
- **Budget Progress Bar** (verde/giallo/rosso)
- **Costo Oggi** / **Costo Mese**
- **Breakdown per Provider** (Replicate, Remove.bg)
- **Breakdown per Operazione** (vision, bg removal, stylization, 3D)
- **Log Recenti** (ultimi 20) con:
  - Provider/Model
  - Status (✓ success / ✗ error)
  - Latenza (ms)
  - Costo stimato (USD)

---

## 🚀 Quick Start

### 1. Primo Accesso (Produzione)

```bash
# 1. Vai all'URL admin
https://web-wit-up.vercel.app/admin

# 2. Ti redirect a /login automaticamente

# 3. Login con:
Email: giovanni.sapere@witup.ai
Password: [la tua password]

# 4. Dopo login, naviga nuovamente a:
https://web-wit-up.vercel.app/admin

# 5. Vedi l'Admin Panel
```

### 2. Configurazione API Keys (Priorità Alta)

Una volta dentro l'Admin Panel:

1. Vai al tab **"API & Config"**
2. Trova la riga `REPLICATE_API_TOKEN`
3. Click **Edit**
4. Inserisci il tuo token Replicate: `r8_XXXXXXXXXXXXXXXXX`
5. Click **Save**

**IMPORTANTE**: Senza questo token, la pipeline AI non funziona!

### 3. Verifica Costi

1. Vai al tab **"Costi"**
2. Verifica il budget mensile (default: $10.00)
3. Monitora i costi giornalieri
4. Se vedi errori 402, ricarica credito su Replicate

---

## 🔒 Security Best Practices

### ✅ DO
- Usa sempre HTTPS in produzione
- Cambia password admin regolarmente
- Monitora i log di accesso in `admin_logs`
- Configura 2FA su Supabase Dashboard

### ❌ DON'T
- Non condividere le credenziali admin
- Non hardcodare API keys nel codice (usa `system_config`)
- Non disabilitare RLS policies sul database

---

## 📞 Support

Per problemi di accesso admin:
- Email: giovanni.sapere@witup.ai
- GitHub Issues: [link al repo]

---

**Ultimo Aggiornamento**: 1 Febbraio 2026
**Versione App**: 0.3.2 (Build 5)

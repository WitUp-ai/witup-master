# 🧠 AI MASTER PROTOCOL (System Override)

## 1. 🗺️ VISION & ARCHITECTURE
- **Role:** Senior Full-Stack Engineer (Flutter/Supabase) autonomo.
- **Stack:** Flutter (Frontend) + Supabase (Backend/Auth/DB) + Vercel (Web Deploy).
- **Architecture File:** Leggi SEMPRE `.spec/system_architecture.md` prima di iniziare qualsiasi task.
- **Protocollo Ralph:** Applica sempre la logica "Ralph" (Plan -> Check -> Act). Non scrivere codice se non hai validato il piano.

## 2. ⚡ SUPABASE CLI PROTOCOL (Mandatory)
Hai accesso alla `supabase` CLI installata nell'host.
- **NON** chiedere all'utente di usare la Dashboard.
- **DB Changes:** Usa `supabase db push` per applicare migrazioni.
- **Edge Functions:** Usa `supabase functions deploy [name] --no-verify-jwt`.
- **New Buckets/Tables:** Crea sempre una migrazione SQL in `supabase/migrations/` e applicala via CLI.
- **Fixing Issues:** Se c'è un errore (es. CORS, 404), risolvilo via CODICE (SQL policies o TypeScript headers), mai manuale.

## 3. 🚫 ZERO FRICTION & AUTONOMY
- **Solve, Don't Ask:** Se puoi farlo via terminale, fallo. Chiedi permesso solo per:
  1. Cancellare dati di produzione.
  2. Spese economiche (nuovi servizi).
  3. Scelte di design puramente estetico.
- **Self-Correction:** Se un comando fallisce, leggi l'errore, formula un'ipotesi, correggi e riprova. Non fermarti al primo errore.

## 4. 🚀 DEPLOYMENT STRATEGY
- **Web:** Vercel (Produzione: `main` branch).
- **Mobile:** Flutter Build (APK/IPA).
- **Environment:** Gestisci i segreti tramite `.env` locale e Vercel Environment Variables.

## 5. 🧪 QUALITY GATES
Prima di dire "Task Completato":
- [ ] Il codice compila?
- [ ] Ho testato (anche con curl/script) che il backend risponda?
- [ ] Ho gestito i casi di errore (es. rete assente, auth fallita)?

# Database Schema Deployment

## Quick Deploy (1 minuto)

1. **Apri SQL Editor:** https://supabase.com/dashboard/project/rnfzzmfpykbavuirypfz/sql/new

2. **Copia tutto** da `.spec/DEPLOY_ALL.sql` (430 righe)

3. **Incolla** nel SQL Editor

4. **Clicca Run**

---

## Cosa viene installato:

| Componente | Dettagli |
|------------|----------|
| **Tabelle** | users, drawings, orders, payments, galleries, notifications, etc. (13 tabelle) |
| **ENUMs** | subscription_tier, processing_status, order_status, etc. (6 tipi) |
| **Triggers** | Auto-update timestamps, auto-create profile, auto-confirm users |
| **RLS Policies** | Sicurezza row-level per tutte le tabelle |
| **Storage Policies** | Policies per tutti i bucket |

---

## Stato Deploy

| Componente | Stato |
|------------|-------|
| Storage Buckets | ✅ drawings-original, drawings-processed, models-3d, avatars |
| Database Schema | ⏳ **Esegui DEPLOY_ALL.sql** |
| Auto-Confirm Users | ✅ Incluso in DEPLOY_ALL.sql |
| RLS Policies | ✅ Incluso in DEPLOY_ALL.sql |
| Storage Policies | ✅ Incluso in DEPLOY_ALL.sql |

---

## Verifica Post-Deploy

```sql
SELECT table_name FROM information_schema.tables
WHERE table_schema = 'public' ORDER BY table_name;
```

Risultato atteso: 13 tabelle

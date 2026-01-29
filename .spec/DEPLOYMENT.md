# 🚀 Draw2Toy - Database Deployment Guide

**Target:** Supabase PostgreSQL  
**Schema Version:** 1.0.0  
**Last Updated:** 2026-01-27

---

## 📋 Pre-requisites

Before deploying the database schema, ensure you have:

- ✅ Active Supabase project created
- ✅ Project URL and Keys configured in `.env`
- ✅ Supabase CLI installed (optional, for migrations)
- ✅ Admin access to Supabase Dashboard

---

## 🎯 Quick Start (3 Steps)

### Step 1: Update Environment Variables

Open `.env` file in root directory and replace placeholder values:

```bash
NEXT_PUBLIC_SUPABASE_URL=https://YOUR_PROJECT_ID.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJhbGci...YOUR_REAL_KEY
```

**Where to find these:**
1. Go to [Supabase Dashboard](https://app.supabase.com)
2. Select your project
3. Navigate to **Settings** → **API**
4. Copy `Project URL` and `anon/public` key

---

### Step 2: Deploy Database Schema

**Option A: Using Supabase Dashboard (Recommended for first-time)**

1. Open Supabase Dashboard
2. Go to **SQL Editor**
3. Click **New Query**
4. Copy entire content of `.spec/database-schema.sql`
5. Paste into SQL Editor
6. Click **Run** button
7. Wait for execution (should take ~5-10 seconds)

**Option B: Using Supabase CLI**

```bash
# Install Supabase CLI (if not already)
npm install -g supabase

# Login to Supabase
supabase login

# Link to your project
supabase link --project-ref YOUR_PROJECT_ID

# Run migration
supabase db push --db-url YOUR_DATABASE_URL
```

---

### Step 3: Create Storage Buckets

In Supabase Dashboard, navigate to **Storage** and create these buckets:

| Bucket Name          | Public | Max File Size | Allowed MIME Types |
|---------------------|--------|---------------|-------------------|
| `drawings-original`  | No     | 10 MB         | image/jpeg, image/png |
| `drawings-processed` | Yes    | 10 MB         | image/png |
| `models-3d`          | Yes    | 50 MB         | model/gltf-binary (.glb) |
| `avatars`            | Yes    | 2 MB          | image/jpeg, image/png |

**Bucket Policies:**

For each bucket, configure appropriate policies:

```sql
-- drawings-original (Private)
CREATE POLICY "Users can upload own drawings"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'drawings-original' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "Users can read own drawings"
ON storage.objects FOR SELECT
TO authenticated
USING (bucket_id = 'drawings-original' AND auth.uid()::text = (storage.foldername(name))[1]);

-- drawings-processed (Public read, authenticated write)
CREATE POLICY "Anyone can view processed drawings"
ON storage.objects FOR SELECT
USING (bucket_id = 'drawings-processed');

CREATE POLICY "Service can upload processed drawings"
ON storage.objects FOR INSERT
TO service_role
WITH CHECK (bucket_id = 'drawings-processed');

-- models-3d (Public read, service write)
CREATE POLICY "Anyone can view 3D models"
ON storage.objects FOR SELECT
USING (bucket_id = 'models-3d');

CREATE POLICY "Service can upload 3D models"
ON storage.objects FOR INSERT
TO service_role
WITH CHECK (bucket_id = 'models-3d');

-- avatars (Public)
CREATE POLICY "Anyone can view avatars"
ON storage.objects FOR SELECT
USING (bucket_id = 'avatars');

CREATE POLICY "Users can upload own avatar"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1]);
```

---

## ✅ Verification Checklist

After deployment, verify everything is working:

### Database Tables
```sql
-- Check all tables exist
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public'
ORDER BY table_name;

-- Expected: 13 tables
-- users, subscriptions, child_profiles, drawings, orders, 
-- payments, galleries, gallery_items, shares, notifications,
-- analytics_events, admin_logs
```

### ENUMs
```sql
-- Check custom types
SELECT typname 
FROM pg_type 
WHERE typtype = 'e'
ORDER BY typname;

-- Expected: 6 enums
-- subscription_tier, subscription_status, processing_status,
-- order_status, toy_size, payment_status
```

### Functions
```sql
-- Check functions exist
SELECT proname 
FROM pg_proc 
WHERE pronamespace = 'public'::regnamespace
ORDER BY proname;

-- Expected: 
-- update_updated_at_column
-- generate_order_number
-- set_order_number
-- reset_monthly_drawing_limits
```

### RLS Policies
```sql
-- Check RLS is enabled
SELECT tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public'
ORDER BY tablename;

-- All tables should have rowsecurity = true
```

### Storage Buckets
```sql
-- Check buckets exist
SELECT * FROM storage.buckets;

-- Expected: 4 buckets
```

---

## 🔧 Post-Deployment Configuration

### 1. Configure Authentication

In Supabase Dashboard → **Authentication** → **Settings**:

- ✅ Enable Email/Password auth
- ✅ Configure Email templates (Welcome, Reset Password)
- ✅ Set Site URL (for email redirects)
- ✅ Add Redirect URLs (for OAuth, if needed)

**Recommended Auth Settings:**
- Minimum password length: 8 characters
- Email confirmations: Enabled
- JWT expiry: 1 hour (default)

---

### 2. Set Up Stripe Integration

1. Create Stripe account at [stripe.com](https://stripe.com)
2. Get API keys from Stripe Dashboard
3. Add to `.env`:
   ```bash
   STRIPE_SECRET_KEY=sk_test_...
   STRIPE_PUBLISHABLE_KEY=pk_test_...
   ```
4. Configure Stripe webhook:
   - URL: `https://YOUR_PROJECT.supabase.co/functions/v1/stripe-webhook`
   - Events: `customer.subscription.*`, `payment_intent.*`

---

### 3. Schedule Cron Jobs

Create Supabase Edge Function for monthly limit reset:

```bash
supabase functions new monthly-reset
```

**File: `supabase/functions/monthly-reset/index.ts`**
```typescript
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

serve(async (req) => {
  const supabase = createClient(
    Deno.env.get('SUPABASE_URL') ?? '',
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
  )

  const { error } = await supabase.rpc('reset_monthly_drawing_limits')

  if (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' }
    })
  }

  return new Response(JSON.stringify({ success: true }), {
    headers: { 'Content-Type': 'application/json' }
  })
})
```

**Schedule with GitHub Actions or external cron service:**
- Frequency: 1st day of each month at 00:00 UTC
- Method: POST to Edge Function URL with secret token

---

## 🧪 Test Data (Optional)

Insert sample data for testing:

```sql
-- Test User
INSERT INTO auth.users (id, email)
VALUES (
  '00000000-0000-0000-0000-000000000001',
  'test@draw2toy.com'
)
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.users (id, email, full_name, subscription_tier)
VALUES (
  '00000000-0000-0000-0000-000000000001',
  'test@draw2toy.com',
  'Test User',
  'magic'
);

-- Test Child Profile
INSERT INTO public.child_profiles (user_id, name, age)
VALUES (
  '00000000-0000-0000-0000-000000000001',
  'Little Artist',
  7
);

-- Test Drawing
INSERT INTO public.drawings (
  user_id,
  title,
  original_image_url,
  model_status
)
VALUES (
  '00000000-0000-0000-0000-000000000001',
  'My First Dragon',
  'drawings-original/test/dragon.jpg',
  'completed'
);
```

---

## 🔒 Security Best Practices

1. **Never commit `.env` file**
   - Already in `.gitignore`
   - Use environment variables in production

2. **Use Service Role Key carefully**
   - Only in backend/Edge Functions
   - Never expose in frontend code

3. **Enable MFA for Supabase account**
   - Dashboard → Account Settings → MFA

4. **Monitor RLS policies**
   - Regularly audit policy effectiveness
   - Test with different user roles

5. **Backup database regularly**
   - Supabase Pro: Automatic daily backups
   - Free tier: Manual SQL dumps

---

## 📊 Monitoring & Analytics

### Set Up Logging

In Supabase Dashboard → **Logs**:
- Monitor API requests
- Track slow queries
- Review auth attempts

### Key Metrics to Track

```sql
-- Active users (last 30 days)
SELECT COUNT(DISTINCT user_id) 
FROM analytics_events 
WHERE created_at > NOW() - INTERVAL '30 days';

-- Drawings processed today
SELECT COUNT(*) 
FROM drawings 
WHERE DATE(created_at) = CURRENT_DATE;

-- Revenue (current month)
SELECT SUM(amount) 
FROM payments 
WHERE status = 'succeeded'
  AND DATE_TRUNC('month', created_at) = DATE_TRUNC('month', CURRENT_DATE);
```

---

## 🆘 Troubleshooting

### Issue: "relation does not exist"
**Solution:** Schema not deployed. Re-run `database-schema.sql`

### Issue: "permission denied for table"
**Solution:** RLS policies too restrictive. Check auth.uid() matches user_id

### Issue: "violates foreign key constraint"
**Solution:** Insert parent records first (e.g., user before drawings)

### Issue: Storage upload fails
**Solution:** Check bucket policies and MIME type restrictions

---

## 🔄 Migration Strategy (Future Updates)

When schema changes:

1. Create new migration file: `.spec/migrations/YYYYMMDD_description.sql`
2. Test on staging environment first
3. Apply to production with `ALTER TABLE` (never `DROP TABLE`)
4. Update schema version in comments
5. Document breaking changes in `CHANGELOG.md`

---

## 📞 Support

**Issues with deployment?**
- Check [Supabase Documentation](https://supabase.com/docs)
- Review logs in Supabase Dashboard
- Contact: Giovanni Sapere (Project Architect)

---

**Status:** ✅ Ready for Deployment  
**Estimated Deployment Time:** 15-20 minutes  
**Difficulty:** Intermediate

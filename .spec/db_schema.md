# 🗄️ Draw2Toy - Database Schema (Visual)

**Project:** Draw2Toy SaaS Platform  
**Database:** Supabase PostgreSQL 15+  
**Version:** 1.0.0  
**Created:** 2026-01-27  
**Status:** ✅ Ready for Deployment

---

## 🎯 Schema Overview

This document provides a visual and quick-reference guide to the Draw2Toy database schema.

**Connected Database:**
- 🌐 URL: `https://rnfzzmfpykbavuirypfz.supabase.co`
- 📊 Project ID: `rnfzzmfpykbavuirypfz`
- ✅ Status: Configured & Ready

---

## 📊 Entity Relationship Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                      SUPABASE AUTH                              │
│                      (auth.users)                               │
└───────────────────────────┬─────────────────────────────────────┘
                            │
                            │ 1:1 extends
                            ▼
┌───────────────────────────────────────────────────────────────┐
│                         USERS                                 │
│  • id (uuid, PK)                                             │
│  • email, full_name, avatar_url                              │
│  • subscription_tier (free|magic|family)                      │
│  • subscription_status                                        │
│  • drawings_used_this_month                                   │
│  • stripe_customer_id                                         │
└───┬───────────────┬───────────────┬──────────────────────────┘
    │               │               │
    │ 1:N           │ 1:N           │ 1:N
    ▼               ▼               ▼
┌────────────┐  ┌──────────┐  ┌────────────────┐
│CHILD_      │  │DRAWINGS  │  │SUBSCRIPTIONS   │
│PROFILES    │  │          │  │                │
│            │  │• model_  │  │• stripe_sub_id │
│• name      │──│  status  │  │• tier, status  │
│• age       │  │• 3d_url  │  │• billing dates │
│• stats     │  │• AR      │  └────────────────┘
└────────────┘  │  settings│
                │• public? │
                └────┬─────┘
                     │ 1:N
                     ▼
      ┌──────────────┴──────────────┐
      │                             │
      ▼                             ▼
┌──────────┐                  ┌──────────┐
│ORDERS    │                  │GALLERIES │
│          │                  │          │
│• toy_size│                  │• title   │
│• pricing │                  │• slug    │
│• shipping│                  │• public? │
│• tracking│                  └────┬─────┘
└────┬─────┘                       │
     │ 1:N                         │ M:N via
     ▼                             │ gallery_items
┌──────────┐                       │
│PAYMENTS  │◄──────────────────────┘
│          │
│• stripe_ │
│  payment │
│  _intent │
│• amount  │
└──────────┘

Additional Tables:
• SHARES (social tracking)
• NOTIFICATIONS (user alerts)
• ANALYTICS_EVENTS (behavior tracking)
• ADMIN_LOGS (audit trail)
```

---

## 📋 Tables Quick Reference

### Core Business Tables (9)

| # | Table | Records | Purpose | Key Relationships |
|---|-------|---------|---------|-------------------|
| 1 | **users** | ~10K | User profiles + subscription | → auth.users (1:1) |
| 2 | **child_profiles** | ~15K | Multiple children per family | users (N:1) |
| 3 | **drawings** | ~100K | Core: photos → 3D models | users (N:1), child_profiles (N:1) |
| 4 | **subscriptions** | ~3.5K | Stripe billing records | users (N:1) |
| 5 | **orders** | ~5K | Physical toy purchases | users (N:1), drawings (N:1) |
| 6 | **payments** | ~8K | All financial transactions | users (N:1), orders/subs (N:1) |
| 7 | **galleries** | ~5K | User-curated collections | users (N:1) |
| 8 | **gallery_items** | ~30K | Junction: drawings ↔ galleries | galleries (N:1), drawings (N:1) |
| 9 | **shares** | ~20K | Social sharing tracking | users (N:1), drawings/galleries (N:1) |

### Support Tables (4)

| # | Table | Records | Purpose |
|---|-------|---------|---------|
| 10 | **notifications** | ~50K | In-app user notifications |
| 11 | **analytics_events** | ~1M+ | User behavior tracking |
| 12 | **admin_logs** | ~1K | Admin action audit trail |

---

## 🔑 Primary Keys & Indexes

### UUID Strategy
All tables use UUID v4 for primary keys:
```sql
id UUID PRIMARY KEY DEFAULT uuid_generate_v4()
```

**Benefits:**
- ✅ Globally unique
- ✅ No sequential enumeration attacks
- ✅ Distributed-safe
- ✅ Supabase native support

### Critical Indexes (Performance)

```sql
-- Users
idx_users_email                    -- Login lookups
idx_users_stripe_customer          -- Payment queries
idx_users_subscription_tier        -- Tier-based filtering

-- Drawings
idx_drawings_user                  -- User gallery (most frequent)
idx_drawings_status                -- AI pipeline queue
idx_drawings_created DESC          -- Timeline feed
idx_drawings_public (partial)      -- Community gallery

-- Orders
idx_orders_user                    -- User's order history
idx_orders_status                  -- Admin dashboard
idx_orders_number                  -- Customer lookup
idx_orders_stripe_payment          -- Payment reconciliation

-- Payments
idx_payments_stripe_intent         -- Webhook processing
idx_payments_user                  -- User transaction history
```

---

## 🔐 Security Model (RLS)

### Row Level Security Policies

**Every table has RLS enabled.** Key principles:

```sql
-- Users own their data
auth.uid() = user_id

-- Public content visible to all
is_public = TRUE

-- Service role bypasses all
(for backend operations)
```

### Policy Examples

#### Users Table
```sql
✅ "Users can view own profile"
   FOR SELECT USING (auth.uid() = id)

✅ "Users can update own profile"
   FOR UPDATE USING (auth.uid() = id)
```

#### Drawings Table
```sql
✅ "Users can view own drawings"
   FOR SELECT USING (auth.uid() = user_id)

✅ "Anyone can view public drawings"
   FOR SELECT USING (is_public = TRUE)

✅ "Users can insert own drawings"
   FOR INSERT WITH CHECK (auth.uid() = user_id)
```

#### Orders Table
```sql
✅ "Users can view own orders"
   FOR SELECT USING (auth.uid() = user_id)

❌ Admin access via service_role only
```

---

## 📐 ENUMs (Custom Types)

### `subscription_tier`
```sql
'free'    → 1 drawing/month
'magic'   → 10 drawings/month, 1 child profile
'family'  → Unlimited drawings, 3 child profiles, 20% discount
```

### `subscription_status`
```sql
'active'    → Normal billing
'trialing'  → Trial period
'past_due'  → Payment failed, grace period
'canceled'  → User canceled
'paused'    → Temporary suspension
```

### `processing_status` (Drawings)
```sql
'pending'    → Uploaded, queued
'processing' → AI generating 3D model
'completed'  → Ready for AR viewing
'failed'     → Error occurred
```

### `order_status`
```sql
'pending'    → Cart/unpaid
'paid'       → Payment confirmed
'processing' → Preparing file for print
'printing'   → 3D printer active
'painting'   → Manual coloring (if opted)
'shipped'    → In transit
'delivered'  → Completed
'canceled'   → User/admin canceled
'refunded'   → Money returned
```

### `toy_size`
```sql
'small'   → 5-8cm   (€29.99)
'medium'  → 10-15cm (€49.99)
'large'   → 20-25cm (€89.99)
```

### `payment_status`
```sql
'pending'   → Processing
'succeeded' → Completed
'failed'    → Declined
'refunded'  → Reversed
```

---

## ⚡ Triggers & Functions

### Auto-Update Timestamps
```sql
Function: update_updated_at_column()
Applied to: users, subscriptions, child_profiles, drawings, orders, galleries

Behavior: Sets updated_at = NOW() on every UPDATE
```

### Order Number Generation
```sql
Function: generate_order_number()
Trigger: set_order_number_trigger (BEFORE INSERT on orders)

Format: DT-YYYY-NNNNNN
Example: DT-2026-000001, DT-2026-000002, ...

Auto-increments per year.
```

### Monthly Quota Reset
```sql
Function: reset_monthly_drawing_limits()

Resets:
- drawings_used_this_month = 0
- last_reset_date = CURRENT_DATE

Schedule: 1st of each month via Edge Function
```

---

## 📊 Analytics Views

### `user_dashboard_stats`
Pre-aggregated user metrics:
```sql
SELECT * FROM user_dashboard_stats WHERE user_id = auth.uid();

Returns:
- subscription_tier
- drawings_used_this_month
- total_drawings (all time)
- total_orders
- total_children
```

### `popular_public_drawings`
Community feed with popularity algorithm:
```sql
popularity_score = views + (ar_sessions × 2) + (shares × 3)

SELECT * FROM popular_public_drawings
ORDER BY popularity_score DESC
LIMIT 20;
```

---

## 💾 Storage Buckets

Required Supabase Storage buckets:

| Bucket | Public | Max Size | MIME Types | RLS |
|--------|--------|----------|------------|-----|
| `drawings-original` | ❌ No | 10 MB | image/jpeg, image/png | User-owned |
| `drawings-processed` | ✅ Yes | 10 MB | image/png | Service writes |
| `models-3d` | ✅ Yes | 50 MB | model/gltf-binary | Service writes |
| `avatars` | ✅ Yes | 2 MB | image/jpeg, image/png | User-owned |

**Storage Structure:**
```
drawings-original/
  └── {user_id}/
      └── {drawing_id}.jpg

drawings-processed/
  └── {drawing_id}_processed.png

models-3d/
  └── {drawing_id}.glb

avatars/
  └── {user_id}/
      └── avatar.jpg
```

---

## 🔄 Data Flow Examples

### Drawing Upload → 3D Generation
```
1. User uploads photo
   ↓ INSERT INTO drawings (original_image_url, model_status='pending')
   
2. AI Pipeline triggered
   ↓ UPDATE drawings SET model_status='processing'
   
3. Background removal
   ↓ UPDATE drawings SET processed_image_url='...'
   
4. 3D model generation
   ↓ UPDATE drawings SET model_3d_url='...', model_status='completed'
   
5. Notification sent
   ↓ INSERT INTO notifications (type='drawing_ready')
   
6. User views in AR
   ↓ UPDATE drawings SET ar_sessions_count = ar_sessions_count + 1
```

### Order Creation → Fulfillment
```
1. User selects drawing + size
   ↓ Validate: drawing.model_status = 'completed'
   
2. Create order
   ↓ INSERT INTO orders (status='pending', total_amount calculated)
   ↓ order_number auto-generated: DT-2026-000123
   
3. Payment via Stripe
   ↓ INSERT INTO payments (stripe_payment_intent_id)
   ↓ UPDATE orders SET status='paid', paid_at=NOW()
   
4. Production starts
   ↓ UPDATE orders SET status='printing'
   ↓ UPDATE orders SET status='painting' (if is_painted=true)
   
5. Shipping
   ↓ UPDATE orders SET status='shipped', tracking_number='...'
   ↓ INSERT INTO notifications (type='order_shipped')
   
6. Delivery
   ↓ UPDATE orders SET status='delivered', delivered_at=NOW()
```

---

## 🎯 Subscription Limits Enforcement

### Tier Quotas
```sql
-- Check if user can create drawing
SELECT 
  CASE 
    WHEN subscription_tier = 'free' AND drawings_used_this_month >= 1 THEN FALSE
    WHEN subscription_tier = 'magic' AND drawings_used_this_month >= 10 THEN FALSE
    WHEN subscription_tier = 'family' THEN TRUE
    ELSE TRUE
  END as can_create_drawing
FROM users
WHERE id = auth.uid();
```

### Child Profile Limits
```sql
-- Check if user can add child
SELECT 
  COUNT(*) as current_children,
  CASE 
    WHEN subscription_tier = 'free' THEN 0
    WHEN subscription_tier = 'magic' THEN 1
    WHEN subscription_tier = 'family' THEN 3
  END as max_allowed
FROM child_profiles
WHERE user_id = auth.uid();
```

---

## 🔧 Maintenance Queries

### Monthly Reset (Scheduled)
```sql
SELECT reset_monthly_drawing_limits();
```

### Analytics: Active Users
```sql
SELECT COUNT(DISTINCT user_id) as active_users
FROM analytics_events
WHERE created_at > NOW() - INTERVAL '30 days';
```

### Revenue: Current Month
```sql
SELECT 
  SUM(amount) as total_revenue,
  COUNT(*) as transaction_count,
  AVG(amount) as avg_transaction
FROM payments
WHERE status = 'succeeded'
  AND DATE_TRUNC('month', created_at) = DATE_TRUNC('month', CURRENT_DATE);
```

### Conversion Rate: Free → Paid
```sql
SELECT 
  COUNT(*) FILTER (WHERE subscription_tier = 'free') as free_users,
  COUNT(*) FILTER (WHERE subscription_tier IN ('magic', 'family')) as paid_users,
  ROUND(
    COUNT(*) FILTER (WHERE subscription_tier IN ('magic', 'family'))::numeric / 
    NULLIF(COUNT(*)::numeric, 0) * 100, 
    2
  ) as conversion_rate_percent
FROM users;
```

---

## 📝 Migration Checklist

Before deploying to production:

- [ ] Backup existing data (if any)
- [ ] Run `database-schema.sql` in SQL Editor
- [ ] Verify all 13 tables created
- [ ] Check RLS policies enabled
- [ ] Create 4 storage buckets
- [ ] Configure bucket policies
- [ ] Test auth flow
- [ ] Insert test data
- [ ] Verify queries work
- [ ] Set up Edge Function for monthly reset
- [ ] Configure Stripe webhooks
- [ ] Enable monitoring/logging

---

## 🔗 Related Files

- **SQL Schema:** `database-schema.sql` (deploy this)
- **Full Documentation:** `database-schema-README.md` (detailed guide)
- **Deployment Guide:** `DEPLOYMENT.md` (step-by-step)
- **Spec Index:** `README.md` (overview)

---

## 📞 Database Connection Info

**Environment Variables (.env):**
```bash
NEXT_PUBLIC_SUPABASE_URL=https://rnfzzmfpykbavuirypfz.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJhbGc...[configured]
```

**Project ID:** `rnfzzmfpykbavuirypfz`  
**Region:** EU (Europe)  
**Status:** ✅ Connected & Ready

---

**Last Updated:** 2026-01-27  
**Schema Version:** 1.0.0  
**Status:** ✅ Production Ready

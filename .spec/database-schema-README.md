# 🗄️ Draw2Toy - Database Schema Documentation

**Version:** 1.0.0  
**Last Updated:** 2026-01-27  
**Framework:** Supabase (PostgreSQL 15+)  
**Status:** ✅ Ready for Implementation

---

## 📋 Overview

This document provides a comprehensive guide to the Draw2Toy database schema. The database is designed to support a SaaS platform that transforms children's drawings into 3D models and physical toys.

### Key Features
- ✅ Multi-tenant architecture with Row Level Security (RLS)
- ✅ Subscription management (Free, Magic, Family tiers)
- ✅ AI pipeline integration for 3D generation
- ✅ Marketplace for physical toy orders
- ✅ Social features (galleries, sharing)
- ✅ Payment processing with Stripe
- ✅ Analytics and notifications

---

## 🏗️ Architecture

### Database Structure

```
┌─────────────────────────────────────────────────────┐
│                  AUTHENTICATION                      │
│                 (Supabase Auth)                      │
└──────────────────┬──────────────────────────────────┘
                   │
┌──────────────────▼──────────────────────────────────┐
│                     USERS                            │
│  (profiles, subscriptions, limits)                   │
└──┬───────────────┬────────────────┬─────────────────┘
   │               │                │
   ▼               ▼                ▼
┌──────┐    ┌────────────┐   ┌──────────────┐
│CHILD │    │ DRAWINGS   │   │SUBSCRIPTIONS │
│PROFILE│───▶│ (3D Models)│   │  (Stripe)    │
└──────┘    └─────┬──────┘   └──────────────┘
                  │
           ┌──────┴──────┐
           ▼             ▼
      ┌────────┐   ┌──────────┐
      │ORDERS  │   │GALLERIES │
      │(Physical│   │(Social)  │
      │ Toys)  │   └──────────┘
      └────┬───┘
           │
           ▼
      ┌────────┐
      │PAYMENTS│
      └────────┘
```

---

## 📊 Core Tables

### 1. **users** (Extends `auth.users`)
Main user profile table with subscription and usage tracking.

**Key Fields:**
- `id` → References Supabase auth
- `subscription_tier` → free | magic | family
- `drawings_used_this_month` → Monthly quota tracking
- `stripe_customer_id` → Payment integration

**Business Rules:**
- Monthly drawing limits reset automatically
- Tier upgrades take effect immediately
- Downgrades at period end

---

### 2. **child_profiles**
Multiple children per family account (Family tier feature).

**Key Fields:**
- `user_id` → Parent/guardian
- `name`, `age`, `avatar_url`
- `total_drawings`, `total_toys_ordered` → Stats

**Limits:**
- Free: Not available
- Magic: 1 child profile
- Family: Up to 3 child profiles

---

### 3. **drawings**
Core entity: user uploads → AI processing → 3D model.

**Workflow States (`model_status`):**
```
pending → processing → completed
                    ↓
                  failed
```

**Key Fields:**
- `original_image_url` → Raw photo from user
- `processed_image_url` → Background removed
- `model_3d_url` → Generated .glb file
- `model_status` → Tracking AI pipeline
- `is_public` → Community gallery visibility

**AI Metadata:**
- `ai_prompt_used` → Input to 3D generation
- `ai_model_version` → For reproducibility
- `estimated_quality_score` → 0.00 to 1.00

---

### 4. **subscriptions**
Stripe-integrated subscription management.

**States (`status`):**
- `active` → Normal operation
- `trialing` → Trial period
- `past_due` → Payment failed, grace period
- `canceled` → User canceled
- `paused` → Temporary suspension

**Key Fields:**
- `stripe_subscription_id` → Stripe integration
- `current_period_end` → Renewal date
- `cancel_at_period_end` → Pending cancellation

---

### 5. **orders**
Physical toy marketplace orders.

**Order Lifecycle:**
```
pending → paid → processing → printing → painting → shipped → delivered
                                                   ↓
                                              canceled/refunded
```

**Pricing Structure:**
- `base_price` → Size-based (small/medium/large)
- `painting_price` → +€30 for manual coloring
- `express_price` → +€15 for fast shipping
- `discount_amount` → Coupons, Family tier discount
- `total_amount` → Final price

**Auto-generation:**
- `order_number` → Human-readable (DT-2026-001234)

---

### 6. **galleries**
User-curated collections of drawings.

**Features:**
- Private or public sharing
- Unique `slug` for URLs (draw2toy.com/gallery/my-awesome-toys)
- View tracking

---

### 7. **payments**
Financial transactions history.

**Links to:**
- `order_id` → Physical toy purchase
- `subscription_id` → Recurring billing
- `stripe_payment_intent_id` → Stripe integration

**States:**
- `pending` → Processing
- `succeeded` → Completed
- `failed` → Declined
- `refunded` → Reversed

---

## 🔒 Security (Row Level Security)

All tables have RLS enabled. Key policies:

### Users
- ✅ Can view/edit **own** profile
- ❌ Cannot view other users

### Drawings
- ✅ Can manage **own** drawings
- ✅ Anyone can view **public** drawings
- ❌ Cannot edit others' drawings

### Orders
- ✅ Can view/create **own** orders
- ❌ Cannot view others' orders
- ℹ️ Admin access via service role

### Galleries
- ✅ Can manage **own** galleries
- ✅ Anyone can view **public** galleries

---

## 📐 Data Types (ENUMs)

### `subscription_tier`
```sql
'free' | 'magic' | 'family'
```

### `processing_status`
```sql
'pending' | 'processing' | 'completed' | 'failed'
```

### `order_status`
```sql
'pending' | 'paid' | 'processing' | 'printing' | 
'painting' | 'shipped' | 'delivered' | 'canceled' | 'refunded'
```

### `toy_size`
```sql
'small' | 'medium' | 'large'
```

---

## 🚀 Functions & Triggers

### Auto-Update Timestamp
All main tables have `updated_at` auto-updated on changes.

```sql
CREATE TRIGGER update_[table]_updated_at 
BEFORE UPDATE ON public.[table]
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
```

### Order Number Generation
Automatic format: `DT-YYYY-NNNNNN`

```sql
-- Example: DT-2026-000001, DT-2026-000002, ...
```

### Monthly Limit Reset
Function to reset drawing quotas:

```sql
SELECT reset_monthly_drawing_limits();
```

**Recommended:** Schedule via Supabase Edge Function (cron job).

---

## 📊 Performance Optimization

### Indexes Created

**Users:**
- `email` (unique lookups)
- `stripe_customer_id` (payment queries)
- `subscription_tier` (filtering by tier)

**Drawings:**
- `user_id` (user's gallery)
- `child_profile_id` (child attribution)
- `model_status` (processing queue)
- `created_at DESC` (timeline)
- Partial index on `is_public` (community feed)

**Orders:**
- `user_id` (user's order history)
- `status` (admin dashboard)
- `order_number` (lookup)
- `created_at DESC` (recent orders)

---

## 📈 Views (Analytics)

### `user_dashboard_stats`
Aggregated user statistics for dashboard:
- Total drawings
- Total orders
- Number of children
- Current tier & usage

### `popular_public_drawings`
Community feed with popularity score:
```
score = views + (ar_sessions × 2) + (shares × 3)
```

---

## 🔗 Relationships

### One-to-Many
- `users` → `child_profiles` (1 parent, many children)
- `users` → `drawings` (1 user, many drawings)
- `users` → `orders` (1 user, many orders)
- `galleries` → `gallery_items` (1 gallery, many items)

### Many-to-Many
- `drawings` ↔ `galleries` (via `gallery_items`)

### Optional Relationships
- `drawings.child_profile_id` → Can be NULL (drawing not attributed)
- `payments.order_id` → Can be NULL (subscription payment)

---

## 📦 Storage Integration

Supabase Storage buckets needed:

### `drawings-original`
- User uploads (raw photos)
- Public: No (authenticated users only)
- Max size: 10MB

### `drawings-processed`
- Background-removed images
- Public: Yes (with signed URLs)

### `models-3d`
- Generated .glb files
- Public: Yes (CDN delivery)
- Max size: 50MB

### `avatars`
- User & child profile pictures
- Public: Yes

---

## 🎯 Business Logic Examples

### Check Drawing Quota
```sql
SELECT 
    u.subscription_tier,
    u.drawings_used_this_month,
    CASE 
        WHEN u.subscription_tier = 'free' THEN 1
        WHEN u.subscription_tier = 'magic' THEN 10
        WHEN u.subscription_tier = 'family' THEN 999999
    END as monthly_limit
FROM users u
WHERE u.id = auth.uid();
```

### Get User's Pending Drawings
```sql
SELECT * FROM drawings
WHERE user_id = auth.uid()
  AND model_status IN ('pending', 'processing')
ORDER BY created_at DESC;
```

### Calculate Order Total
```sql
-- Example: Medium toy + painting + express
base_price = 49.99
painting_price = 30.00 (if is_painted = true)
express_price = 15.00 (if is_express_delivery = true)
discount_amount = 10.00 (if Family tier: 20% discount)
---
total_amount = 49.99 + 30.00 + 15.00 - 10.00 = 84.99
```

---

## 🚨 Migration Notes

### Initial Setup
1. Run `database-schema.sql` on fresh Supabase project
2. Create Storage buckets (see above)
3. Configure Stripe webhook endpoint
4. Set up cron job for monthly limit reset

### Seed Data (Optional)
```sql
-- Example: Create test user
INSERT INTO public.users (id, email, full_name, subscription_tier)
VALUES (
    '[auth_user_id]',
    'test@draw2toy.com',
    'Test User',
    'free'
);
```

---

## 🔄 Future Enhancements (V2)

Potential schema additions:
- [ ] `teams` table (B2B schools/organizations)
- [ ] `vouchers` table (promo codes)
- [ ] `reviews` table (product reviews)
- [ ] `ar_sessions` table (detailed AR analytics)
- [ ] `webhooks` table (API partner integrations)
- [ ] `print_queue` table (3D printing management)

---

## 📞 Support

For schema questions or modifications, contact:
- **Architect:** Giovanni Sapere
- **Framework:** WITUP Master Blueprint
- **Documentation:** This file + inline SQL comments

---

## ✅ Checklist for Developers

Before starting development:
- [ ] Schema deployed to Supabase
- [ ] RLS policies tested
- [ ] Storage buckets created
- [ ] Stripe integration configured
- [ ] `.env` file updated with real credentials
- [ ] Test data seeded (optional)
- [ ] Edge Functions for cron jobs deployed

---

**Last Updated:** 2026-01-27  
**Schema Version:** 1.0.0  
**Status:** ✅ Production Ready

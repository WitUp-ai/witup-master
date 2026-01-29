# Supabase Setup Instructions for Draw2Toy

## Quick Setup Guide

### Step 1: Create Database Tables

1. Open your Supabase Dashboard: https://supabase.com/dashboard
2. Select your project: `rnfzzmfpykbavuirypfz`
3. Go to **SQL Editor** (left sidebar)
4. Click **New Query**
5. Copy and paste the contents of `001_create_drawings_table.sql`
6. Click **Run** (or press Ctrl+Enter)
7. You should see "Success. No rows returned"

### Step 2: Create Storage Bucket

1. Go to **Storage** (left sidebar)
2. Click **New Bucket**
3. Enter bucket name: `drawings`
4. Toggle **Public bucket** to ON
5. Click **Create bucket**

### Step 3: Configure Storage Policies

1. Stay in **Storage** section
2. Click on the `drawings` bucket
3. Go to **Policies** tab
4. Click **New Policy**
5. For each policy, use the SQL Editor method:
   - Go back to **SQL Editor**
   - Copy and paste contents of `002_storage_policies.sql`
   - Click **Run**

### Step 4: Verify Setup

Run this query in SQL Editor to verify tables were created:

```sql
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public';
```

You should see:
- drawings
- creations
- orders
- profiles

### Step 5: Test Storage

In Storage > drawings bucket:
1. Click **Upload files**
2. Upload any test image
3. Click on the file
4. Copy the public URL
5. Open URL in browser - image should display

---

## Tables Overview

### drawings
Stores uploaded drawing images from the app.

| Column | Type | Description |
|--------|------|-------------|
| id | UUID | Primary key |
| user_id | UUID | Reference to auth.users |
| file_name | TEXT | Original filename |
| storage_path | TEXT | Path in Storage bucket |
| public_url | TEXT | Public URL for the image |
| status | TEXT | uploaded, processing, completed, failed |
| created_at | TIMESTAMP | Creation timestamp |

### creations
Stores 3D models generated from drawings.

| Column | Type | Description |
|--------|------|-------------|
| id | UUID | Primary key |
| user_id | UUID | Reference to auth.users |
| drawing_id | UUID | Reference to drawings table |
| model_url | TEXT | URL to 3D model file |
| status | TEXT | pending, processing, completed, failed |

### orders
Stores physical toy orders.

| Column | Type | Description |
|--------|------|-------------|
| id | UUID | Primary key |
| user_id | UUID | Reference to auth.users |
| creation_id | UUID | Reference to creations table |
| status | TEXT | pending, paid, shipped, delivered |
| total_cents | INTEGER | Total price in cents |

### profiles
Extended user profile data with subscription info.

| Column | Type | Description |
|--------|------|-------------|
| id | UUID | Same as auth.users.id |
| subscription_tier | TEXT | free, magic, family |
| monthly_drawings_used | INTEGER | Drawings used this month |
| monthly_drawings_limit | INTEGER | Max drawings per month |

---

## Security (RLS)

All tables have Row Level Security enabled:
- Users can only see/edit their own data
- Profiles are auto-created on signup
- Storage files are organized by user_id folder

---

## Troubleshooting

### "permission denied" error
- Make sure RLS policies are created
- Check that user is authenticated

### "bucket not found" error
- Create the `drawings` bucket in Storage
- Make sure bucket name is exactly `drawings`

### Images not loading
- Check bucket is set to Public
- Verify storage policies are applied

---

## Next Steps

After setup is complete:
1. Test signup/login in the app
2. Upload a test drawing
3. Check that record appears in `drawings` table
4. Check that file appears in Storage bucket

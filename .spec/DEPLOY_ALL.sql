-- =====================================================
-- DRAW2TOY - COMPLETE DATABASE DEPLOYMENT
-- =====================================================
-- Run this ENTIRE file in Supabase SQL Editor
-- URL: https://supabase.com/dashboard/project/rnfzzmfpykbavuirypfz/sql/new
-- =====================================================

-- =====================================================
-- PART 1: AUTO-CONFIRM USERS (Development Only)
-- =====================================================

CREATE OR REPLACE FUNCTION public.auto_confirm_user()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE auth.users
    SET
        email_confirmed_at = NOW(),
        confirmed_at = NOW(),
        updated_at = NOW()
    WHERE id = NEW.id
      AND email_confirmed_at IS NULL;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS auto_confirm_user_trigger ON auth.users;
CREATE TRIGGER auto_confirm_user_trigger
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.auto_confirm_user();

-- =====================================================
-- PART 2: EXTENSIONS
-- =====================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- =====================================================
-- PART 3: ENUMS & TYPES
-- =====================================================

DO $$ BEGIN
    CREATE TYPE subscription_tier AS ENUM ('free', 'magic', 'family');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
    CREATE TYPE subscription_status AS ENUM ('active', 'canceled', 'past_due', 'trialing', 'paused');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
    CREATE TYPE processing_status AS ENUM ('pending', 'processing', 'completed', 'failed');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
    CREATE TYPE order_status AS ENUM ('pending', 'paid', 'processing', 'printing', 'painting', 'shipped', 'delivered', 'canceled', 'refunded');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
    CREATE TYPE toy_size AS ENUM ('small', 'medium', 'large');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
    CREATE TYPE payment_status AS ENUM ('pending', 'succeeded', 'failed', 'refunded');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- =====================================================
-- PART 4: TABLES
-- =====================================================

-- Users table
CREATE TABLE IF NOT EXISTS public.users (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT NOT NULL UNIQUE,
    full_name TEXT,
    avatar_url TEXT,
    subscription_tier subscription_tier NOT NULL DEFAULT 'free',
    subscription_status subscription_status DEFAULT 'active',
    stripe_customer_id TEXT UNIQUE,
    drawings_used_this_month INTEGER NOT NULL DEFAULT 0,
    last_reset_date DATE NOT NULL DEFAULT CURRENT_DATE,
    onboarding_completed BOOLEAN NOT NULL DEFAULT FALSE,
    preferred_language TEXT DEFAULT 'it',
    marketing_consent BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Subscriptions table
CREATE TABLE IF NOT EXISTS public.subscriptions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    tier subscription_tier NOT NULL,
    status subscription_status NOT NULL DEFAULT 'active',
    stripe_subscription_id TEXT UNIQUE,
    stripe_price_id TEXT,
    current_period_start TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    current_period_end TIMESTAMPTZ NOT NULL DEFAULT NOW() + INTERVAL '1 month',
    cancel_at_period_end BOOLEAN DEFAULT FALSE,
    canceled_at TIMESTAMPTZ,
    amount_per_month DECIMAL(10, 2),
    currency TEXT DEFAULT 'EUR',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Child profiles table
CREATE TABLE IF NOT EXISTS public.child_profiles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    age INTEGER,
    avatar_url TEXT,
    favorite_color TEXT,
    bio TEXT,
    total_drawings INTEGER NOT NULL DEFAULT 0,
    total_toys_ordered INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Drawings table
CREATE TABLE IF NOT EXISTS public.drawings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    child_profile_id UUID REFERENCES public.child_profiles(id) ON DELETE SET NULL,
    title TEXT,
    description TEXT,
    original_image_url TEXT NOT NULL,
    processed_image_url TEXT,
    thumbnail_url TEXT,
    model_3d_url TEXT,
    model_status processing_status NOT NULL DEFAULT 'pending',
    processing_started_at TIMESTAMPTZ,
    processing_completed_at TIMESTAMPTZ,
    processing_error TEXT,
    ai_prompt_used TEXT,
    ai_model_version TEXT,
    estimated_quality_score DECIMAL(3, 2),
    ar_scale DECIMAL(5, 2) DEFAULT 1.0,
    ar_animation_enabled BOOLEAN DEFAULT TRUE,
    ar_sound_enabled BOOLEAN DEFAULT TRUE,
    views_count INTEGER NOT NULL DEFAULT 0,
    ar_sessions_count INTEGER NOT NULL DEFAULT 0,
    share_count INTEGER NOT NULL DEFAULT 0,
    is_public BOOLEAN DEFAULT FALSE,
    is_featured BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Orders table
CREATE TABLE IF NOT EXISTS public.orders (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    drawing_id UUID NOT NULL REFERENCES public.drawings(id) ON DELETE RESTRICT,
    order_number TEXT UNIQUE,
    status order_status NOT NULL DEFAULT 'pending',
    toy_size toy_size NOT NULL DEFAULT 'medium',
    is_painted BOOLEAN DEFAULT FALSE,
    is_express_delivery BOOLEAN DEFAULT FALSE,
    quantity INTEGER NOT NULL DEFAULT 1,
    base_price DECIMAL(10, 2) NOT NULL DEFAULT 0,
    painting_price DECIMAL(10, 2) DEFAULT 0,
    express_price DECIMAL(10, 2) DEFAULT 0,
    discount_amount DECIMAL(10, 2) DEFAULT 0,
    total_amount DECIMAL(10, 2) NOT NULL DEFAULT 0,
    currency TEXT DEFAULT 'EUR',
    stripe_payment_intent_id TEXT,
    payment_status payment_status NOT NULL DEFAULT 'pending',
    paid_at TIMESTAMPTZ,
    shipping_name TEXT,
    shipping_address_line1 TEXT,
    shipping_address_line2 TEXT,
    shipping_city TEXT,
    shipping_postal_code TEXT,
    shipping_country TEXT,
    shipping_phone TEXT,
    tracking_number TEXT,
    shipped_at TIMESTAMPTZ,
    delivered_at TIMESTAMPTZ,
    estimated_delivery_date DATE,
    customer_notes TEXT,
    internal_notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Payments table
CREATE TABLE IF NOT EXISTS public.payments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    order_id UUID REFERENCES public.orders(id) ON DELETE SET NULL,
    subscription_id UUID REFERENCES public.subscriptions(id) ON DELETE SET NULL,
    stripe_payment_intent_id TEXT UNIQUE,
    stripe_charge_id TEXT,
    amount DECIMAL(10, 2) NOT NULL,
    currency TEXT DEFAULT 'EUR',
    status payment_status NOT NULL,
    payment_method_type TEXT,
    payment_method_last4 TEXT,
    refunded_amount DECIMAL(10, 2) DEFAULT 0,
    refunded_at TIMESTAMPTZ,
    refund_reason TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Galleries table
CREATE TABLE IF NOT EXISTS public.galleries (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    cover_image_url TEXT,
    is_public BOOLEAN DEFAULT FALSE,
    slug TEXT UNIQUE,
    views_count INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Gallery items table
CREATE TABLE IF NOT EXISTS public.gallery_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    gallery_id UUID NOT NULL REFERENCES public.galleries(id) ON DELETE CASCADE,
    drawing_id UUID NOT NULL REFERENCES public.drawings(id) ON DELETE CASCADE,
    position INTEGER NOT NULL DEFAULT 0,
    added_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(gallery_id, drawing_id)
);

-- Shares table
CREATE TABLE IF NOT EXISTS public.shares (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    drawing_id UUID REFERENCES public.drawings(id) ON DELETE CASCADE,
    gallery_id UUID REFERENCES public.galleries(id) ON DELETE CASCADE,
    platform TEXT NOT NULL,
    share_url TEXT,
    clicks_count INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Notifications table
CREATE TABLE IF NOT EXISTS public.notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    type TEXT NOT NULL,
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    action_url TEXT,
    is_read BOOLEAN DEFAULT FALSE,
    read_at TIMESTAMPTZ,
    metadata JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Analytics events table
CREATE TABLE IF NOT EXISTS public.analytics_events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES public.users(id) ON DELETE SET NULL,
    event_type TEXT NOT NULL,
    event_category TEXT,
    drawing_id UUID REFERENCES public.drawings(id) ON DELETE SET NULL,
    order_id UUID REFERENCES public.orders(id) ON DELETE SET NULL,
    device_type TEXT,
    app_version TEXT,
    session_id TEXT,
    properties JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Admin logs table
CREATE TABLE IF NOT EXISTS public.admin_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    admin_user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    action TEXT NOT NULL,
    target_table TEXT,
    target_id UUID,
    old_values JSONB,
    new_values JSONB,
    reason TEXT,
    ip_address INET,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- System config table (Dynamic Configuration Management)
CREATE TABLE IF NOT EXISTS public.system_config (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    key TEXT NOT NULL UNIQUE,
    value TEXT NOT NULL,
    description TEXT,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_by UUID REFERENCES public.users(id) ON DELETE SET NULL,
    CONSTRAINT valid_key_format CHECK (key ~ '^[A-Z_][A-Z0-9_]*$')
);

-- System config indexes
CREATE INDEX IF NOT EXISTS idx_system_config_key ON public.system_config(key);
CREATE INDEX IF NOT EXISTS idx_system_config_updated ON public.system_config(updated_at DESC);

-- =====================================================
-- PART 5: INDEXES
-- =====================================================

CREATE INDEX IF NOT EXISTS idx_users_email ON public.users(email);
CREATE INDEX IF NOT EXISTS idx_users_stripe_customer ON public.users(stripe_customer_id);
CREATE INDEX IF NOT EXISTS idx_drawings_user ON public.drawings(user_id);
CREATE INDEX IF NOT EXISTS idx_drawings_status ON public.drawings(model_status);
CREATE INDEX IF NOT EXISTS idx_drawings_created ON public.drawings(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_orders_user ON public.orders(user_id);
CREATE INDEX IF NOT EXISTS idx_orders_status ON public.orders(status);
CREATE INDEX IF NOT EXISTS idx_notifications_user ON public.notifications(user_id);

-- =====================================================
-- PART 6: FUNCTIONS & TRIGGERS
-- =====================================================

-- Updated_at trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply to all tables with updated_at
DO $$
DECLARE
    t text;
BEGIN
    FOR t IN SELECT unnest(ARRAY['users', 'subscriptions', 'child_profiles', 'drawings', 'orders', 'payments', 'galleries'])
    LOOP
        EXECUTE format('DROP TRIGGER IF EXISTS update_%s_updated_at ON public.%s', t, t);
        EXECUTE format('CREATE TRIGGER update_%s_updated_at BEFORE UPDATE ON public.%s FOR EACH ROW EXECUTE FUNCTION update_updated_at_column()', t, t);
    END LOOP;
END $$;

-- Auto-create user profile on signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.users (id, email, full_name)
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'name', NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1))
    )
    ON CONFLICT (id) DO NOTHING;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user();

-- =====================================================
-- PART 7: ROW LEVEL SECURITY (RLS)
-- =====================================================

-- Enable RLS on all tables
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.child_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.drawings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.galleries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.gallery_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.shares ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.analytics_events ENABLE ROW LEVEL SECURITY;

-- Users policies
DROP POLICY IF EXISTS "Users can view own profile" ON public.users;
CREATE POLICY "Users can view own profile" ON public.users
    FOR SELECT USING (auth.uid() = id);

DROP POLICY IF EXISTS "Users can update own profile" ON public.users;
CREATE POLICY "Users can update own profile" ON public.users
    FOR UPDATE USING (auth.uid() = id);

-- Drawings policies
DROP POLICY IF EXISTS "Users can view own drawings" ON public.drawings;
CREATE POLICY "Users can view own drawings" ON public.drawings
    FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own drawings" ON public.drawings;
CREATE POLICY "Users can insert own drawings" ON public.drawings
    FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own drawings" ON public.drawings;
CREATE POLICY "Users can update own drawings" ON public.drawings
    FOR UPDATE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete own drawings" ON public.drawings;
CREATE POLICY "Users can delete own drawings" ON public.drawings
    FOR DELETE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Anyone can view public drawings" ON public.drawings;
CREATE POLICY "Anyone can view public drawings" ON public.drawings
    FOR SELECT USING (is_public = TRUE);

-- Child profiles policies
DROP POLICY IF EXISTS "Users can manage own child profiles" ON public.child_profiles;
CREATE POLICY "Users can manage own child profiles" ON public.child_profiles
    FOR ALL USING (auth.uid() = user_id);

-- Notifications policies
DROP POLICY IF EXISTS "Users can view own notifications" ON public.notifications;
CREATE POLICY "Users can view own notifications" ON public.notifications
    FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own notifications" ON public.notifications;
CREATE POLICY "Users can update own notifications" ON public.notifications
    FOR UPDATE USING (auth.uid() = user_id);

-- Orders policies
DROP POLICY IF EXISTS "Users can view own orders" ON public.orders;
CREATE POLICY "Users can view own orders" ON public.orders
    FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own orders" ON public.orders;
CREATE POLICY "Users can insert own orders" ON public.orders
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Galleries policies
DROP POLICY IF EXISTS "Users can manage own galleries" ON public.galleries;
CREATE POLICY "Users can manage own galleries" ON public.galleries
    FOR ALL USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Anyone can view public galleries" ON public.galleries;
CREATE POLICY "Anyone can view public galleries" ON public.galleries
    FOR SELECT USING (is_public = TRUE);

-- =====================================================
-- PART 8: STORAGE POLICIES
-- =====================================================

-- drawings-original (Private - user upload)
DROP POLICY IF EXISTS "Users can upload to drawings-original" ON storage.objects;
CREATE POLICY "Users can upload to drawings-original" ON storage.objects
    FOR INSERT TO authenticated
    WITH CHECK (bucket_id = 'drawings-original' AND (storage.foldername(name))[1] = auth.uid()::text);

DROP POLICY IF EXISTS "Users can view own drawings-original" ON storage.objects;
CREATE POLICY "Users can view own drawings-original" ON storage.objects
    FOR SELECT TO authenticated
    USING (bucket_id = 'drawings-original' AND (storage.foldername(name))[1] = auth.uid()::text);

DROP POLICY IF EXISTS "Users can delete own drawings-original" ON storage.objects;
CREATE POLICY "Users can delete own drawings-original" ON storage.objects
    FOR DELETE TO authenticated
    USING (bucket_id = 'drawings-original' AND (storage.foldername(name))[1] = auth.uid()::text);

-- drawings-processed (Public read)
DROP POLICY IF EXISTS "Anyone can view drawings-processed" ON storage.objects;
CREATE POLICY "Anyone can view drawings-processed" ON storage.objects
    FOR SELECT USING (bucket_id = 'drawings-processed');

-- models-3d (Public read)
DROP POLICY IF EXISTS "Anyone can view models-3d" ON storage.objects;
CREATE POLICY "Anyone can view models-3d" ON storage.objects
    FOR SELECT USING (bucket_id = 'models-3d');

-- avatars (Public read, authenticated upload)
DROP POLICY IF EXISTS "Anyone can view avatars" ON storage.objects;
CREATE POLICY "Anyone can view avatars" ON storage.objects
    FOR SELECT USING (bucket_id = 'avatars');

DROP POLICY IF EXISTS "Users can upload own avatar" ON storage.objects;
CREATE POLICY "Users can upload own avatar" ON storage.objects
    FOR INSERT TO authenticated
    WITH CHECK (bucket_id = 'avatars' AND (storage.foldername(name))[1] = auth.uid()::text);

-- =====================================================
-- DEPLOYMENT COMPLETE!
-- =====================================================
-- Storage buckets created via API: ✅
-- Database schema: ✅
-- RLS policies: ✅
-- Auto-confirm users: ✅
-- =====================================================

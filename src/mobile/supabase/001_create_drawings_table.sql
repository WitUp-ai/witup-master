-- =====================================================
-- Draw2Toy Database Schema
-- Run this script in Supabase SQL Editor
-- =====================================================

-- Enable UUID extension if not already enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =====================================================
-- 1. DRAWINGS TABLE
-- Stores uploaded drawing images
-- =====================================================
CREATE TABLE IF NOT EXISTS public.drawings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,

    -- File info
    file_name TEXT NOT NULL,
    storage_path TEXT NOT NULL,
    public_url TEXT,

    -- Metadata
    title TEXT,
    description TEXT,

    -- Processing status: uploaded, processing, completed, failed
    status TEXT NOT NULL DEFAULT 'uploaded',

    -- Timestamps
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Index for faster queries
CREATE INDEX IF NOT EXISTS idx_drawings_user_id ON public.drawings(user_id);
CREATE INDEX IF NOT EXISTS idx_drawings_status ON public.drawings(status);
CREATE INDEX IF NOT EXISTS idx_drawings_created_at ON public.drawings(created_at DESC);

-- =====================================================
-- 2. CREATIONS TABLE
-- Stores 3D models generated from drawings
-- =====================================================
CREATE TABLE IF NOT EXISTS public.creations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    drawing_id UUID REFERENCES public.drawings(id) ON DELETE SET NULL,

    -- 3D Model info
    model_url TEXT,
    thumbnail_url TEXT,
    model_type TEXT DEFAULT 'glb', -- glb, obj, fbx

    -- Metadata
    title TEXT,
    description TEXT,

    -- Processing info
    status TEXT NOT NULL DEFAULT 'pending', -- pending, processing, completed, failed
    processing_started_at TIMESTAMPTZ,
    processing_completed_at TIMESTAMPTZ,
    error_message TEXT,

    -- AR/Interaction data
    ar_scale FLOAT DEFAULT 1.0,
    ar_position JSONB DEFAULT '{"x": 0, "y": 0, "z": 0}'::jsonb,

    -- Timestamps
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_creations_user_id ON public.creations(user_id);
CREATE INDEX IF NOT EXISTS idx_creations_drawing_id ON public.creations(drawing_id);
CREATE INDEX IF NOT EXISTS idx_creations_status ON public.creations(status);

-- =====================================================
-- 3. ORDERS TABLE (for physical toy orders)
-- =====================================================
CREATE TABLE IF NOT EXISTS public.orders (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    creation_id UUID REFERENCES public.creations(id) ON DELETE SET NULL,

    -- Order details
    order_number TEXT UNIQUE,
    status TEXT NOT NULL DEFAULT 'pending', -- pending, paid, processing, shipped, delivered, cancelled

    -- Product config
    size TEXT DEFAULT 'medium', -- small, medium, large
    color_option TEXT,
    quantity INTEGER DEFAULT 1,

    -- Pricing (in cents)
    subtotal_cents INTEGER NOT NULL DEFAULT 0,
    shipping_cents INTEGER NOT NULL DEFAULT 0,
    tax_cents INTEGER NOT NULL DEFAULT 0,
    total_cents INTEGER NOT NULL DEFAULT 0,
    currency TEXT DEFAULT 'EUR',

    -- Shipping
    shipping_address JSONB,
    tracking_number TEXT,
    estimated_delivery TIMESTAMPTZ,

    -- Payment
    stripe_payment_intent_id TEXT,
    paid_at TIMESTAMPTZ,

    -- Timestamps
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_orders_user_id ON public.orders(user_id);
CREATE INDEX IF NOT EXISTS idx_orders_status ON public.orders(status);

-- =====================================================
-- 4. USER PROFILES TABLE (extended user data)
-- =====================================================
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,

    -- User info
    display_name TEXT,
    avatar_url TEXT,

    -- Subscription
    subscription_tier TEXT DEFAULT 'free', -- free, magic, family
    subscription_status TEXT DEFAULT 'active',
    stripe_customer_id TEXT,

    -- Usage quotas
    monthly_drawings_used INTEGER DEFAULT 0,
    monthly_drawings_limit INTEGER DEFAULT 1,
    quota_reset_date TIMESTAMPTZ,

    -- Preferences
    preferences JSONB DEFAULT '{}'::jsonb,

    -- Timestamps
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =====================================================
-- 5. ROW LEVEL SECURITY (RLS) POLICIES
-- =====================================================

-- Enable RLS on all tables
ALTER TABLE public.drawings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.creations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- DRAWINGS policies
CREATE POLICY "Users can view own drawings" ON public.drawings
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own drawings" ON public.drawings
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own drawings" ON public.drawings
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own drawings" ON public.drawings
    FOR DELETE USING (auth.uid() = user_id);

-- CREATIONS policies
CREATE POLICY "Users can view own creations" ON public.creations
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own creations" ON public.creations
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own creations" ON public.creations
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own creations" ON public.creations
    FOR DELETE USING (auth.uid() = user_id);

-- ORDERS policies
CREATE POLICY "Users can view own orders" ON public.orders
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own orders" ON public.orders
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own orders" ON public.orders
    FOR UPDATE USING (auth.uid() = user_id);

-- PROFILES policies
CREATE POLICY "Users can view own profile" ON public.profiles
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON public.profiles
    FOR UPDATE USING (auth.uid() = id);

-- =====================================================
-- 6. TRIGGERS FOR UPDATED_AT
-- =====================================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply trigger to all tables
CREATE TRIGGER update_drawings_updated_at
    BEFORE UPDATE ON public.drawings
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_creations_updated_at
    BEFORE UPDATE ON public.creations
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_orders_updated_at
    BEFORE UPDATE ON public.orders
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_profiles_updated_at
    BEFORE UPDATE ON public.profiles
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- 7. AUTO-CREATE PROFILE ON USER SIGNUP
-- =====================================================

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, display_name, quota_reset_date)
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'name', NEW.email),
        DATE_TRUNC('month', NOW()) + INTERVAL '1 month'
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger for new user signup
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user();

-- =====================================================
-- DONE! Now create the Storage bucket manually:
-- 1. Go to Storage in Supabase Dashboard
-- 2. Create a new bucket called "drawings"
-- 3. Make it PUBLIC (for easy image access)
-- 4. Add these policies in Storage > Policies:
--    - Allow authenticated users to upload to their folder
--    - Allow public read access
-- =====================================================

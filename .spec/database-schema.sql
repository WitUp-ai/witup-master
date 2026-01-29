-- =====================================================
-- DRAW2TOY - DATABASE SCHEMA
-- =====================================================
-- Framework: Supabase (PostgreSQL 15+)
-- Created: 2026-01-27
-- Version: 1.0.0
-- Description: Complete database schema for Draw2Toy SaaS platform
-- =====================================================

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- =====================================================
-- ENUMS & TYPES
-- =====================================================

-- Subscription tier levels
CREATE TYPE subscription_tier AS ENUM ('free', 'magic', 'family');

-- Subscription status
CREATE TYPE subscription_status AS ENUM ('active', 'canceled', 'past_due', 'trialing', 'paused');

-- Drawing processing status
CREATE TYPE processing_status AS ENUM ('pending', 'processing', 'completed', 'failed');

-- Order status for physical toys
CREATE TYPE order_status AS ENUM ('pending', 'paid', 'processing', 'printing', 'painting', 'shipped', 'delivered', 'canceled', 'refunded');

-- Toy size options
CREATE TYPE toy_size AS ENUM ('small', 'medium', 'large');

-- Payment status
CREATE TYPE payment_status AS ENUM ('pending', 'succeeded', 'failed', 'refunded');

-- =====================================================
-- TABLE: users (extends Supabase auth.users)
-- =====================================================
CREATE TABLE public.users (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT NOT NULL UNIQUE,
    full_name TEXT,
    avatar_url TEXT,
    
    -- Subscription info
    subscription_tier subscription_tier NOT NULL DEFAULT 'free',
    subscription_status subscription_status DEFAULT 'active',
    stripe_customer_id TEXT UNIQUE,
    
    -- Limits tracking (monthly reset)
    drawings_used_this_month INTEGER NOT NULL DEFAULT 0,
    last_reset_date DATE NOT NULL DEFAULT CURRENT_DATE,
    
    -- Metadata
    onboarding_completed BOOLEAN NOT NULL DEFAULT FALSE,
    preferred_language TEXT DEFAULT 'it',
    marketing_consent BOOLEAN DEFAULT FALSE,
    
    -- Timestamps
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT valid_email CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$')
);

-- Indexes for users
CREATE INDEX idx_users_email ON public.users(email);
CREATE INDEX idx_users_stripe_customer ON public.users(stripe_customer_id);
CREATE INDEX idx_users_subscription_tier ON public.users(subscription_tier);

-- =====================================================
-- TABLE: subscriptions
-- =====================================================
CREATE TABLE public.subscriptions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    
    -- Subscription details
    tier subscription_tier NOT NULL,
    status subscription_status NOT NULL DEFAULT 'active',
    
    -- Stripe integration
    stripe_subscription_id TEXT UNIQUE,
    stripe_price_id TEXT,
    
    -- Billing
    current_period_start TIMESTAMPTZ NOT NULL,
    current_period_end TIMESTAMPTZ NOT NULL,
    cancel_at_period_end BOOLEAN DEFAULT FALSE,
    canceled_at TIMESTAMPTZ,
    
    -- Pricing
    amount_per_month DECIMAL(10, 2),
    currency TEXT DEFAULT 'EUR',
    
    -- Timestamps
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT valid_period CHECK (current_period_end > current_period_start)
);

-- Indexes for subscriptions
CREATE INDEX idx_subscriptions_user ON public.subscriptions(user_id);
CREATE INDEX idx_subscriptions_stripe ON public.subscriptions(stripe_subscription_id);
CREATE INDEX idx_subscriptions_status ON public.subscriptions(status);

-- =====================================================
-- TABLE: child_profiles
-- =====================================================
CREATE TABLE public.child_profiles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    
    -- Child info
    name TEXT NOT NULL,
    age INTEGER,
    avatar_url TEXT,
    
    -- Preferences
    favorite_color TEXT,
    bio TEXT,
    
    -- Stats
    total_drawings INTEGER NOT NULL DEFAULT 0,
    total_toys_ordered INTEGER NOT NULL DEFAULT 0,
    
    -- Timestamps
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT valid_age CHECK (age > 0 AND age <= 18)
);

-- Indexes for child_profiles
CREATE INDEX idx_child_profiles_user ON public.child_profiles(user_id);

-- =====================================================
-- TABLE: drawings
-- =====================================================
CREATE TABLE public.drawings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    child_profile_id UUID REFERENCES public.child_profiles(id) ON DELETE SET NULL,
    
    -- Drawing metadata
    title TEXT,
    description TEXT,
    
    -- Image storage
    original_image_url TEXT NOT NULL, -- Supabase Storage path
    processed_image_url TEXT, -- Background removed
    thumbnail_url TEXT,
    
    -- 3D Generation
    model_3d_url TEXT, -- .glb file path
    model_status processing_status NOT NULL DEFAULT 'pending',
    processing_started_at TIMESTAMPTZ,
    processing_completed_at TIMESTAMPTZ,
    processing_error TEXT,
    
    -- AI metadata
    ai_prompt_used TEXT,
    ai_model_version TEXT,
    estimated_quality_score DECIMAL(3, 2), -- 0.00 to 1.00
    
    -- AR Settings
    ar_scale DECIMAL(5, 2) DEFAULT 1.0,
    ar_animation_enabled BOOLEAN DEFAULT TRUE,
    ar_sound_enabled BOOLEAN DEFAULT TRUE,
    
    -- Engagement metrics
    views_count INTEGER NOT NULL DEFAULT 0,
    ar_sessions_count INTEGER NOT NULL DEFAULT 0,
    share_count INTEGER NOT NULL DEFAULT 0,
    
    -- Privacy & Visibility
    is_public BOOLEAN DEFAULT FALSE,
    is_featured BOOLEAN DEFAULT FALSE,
    
    -- Timestamps
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT valid_quality_score CHECK (estimated_quality_score >= 0 AND estimated_quality_score <= 1)
);

-- Indexes for drawings
CREATE INDEX idx_drawings_user ON public.drawings(user_id);
CREATE INDEX idx_drawings_child ON public.drawings(child_profile_id);
CREATE INDEX idx_drawings_status ON public.drawings(model_status);
CREATE INDEX idx_drawings_created ON public.drawings(created_at DESC);
CREATE INDEX idx_drawings_public ON public.drawings(is_public) WHERE is_public = TRUE;
CREATE INDEX idx_drawings_featured ON public.drawings(is_featured) WHERE is_featured = TRUE;

-- =====================================================
-- TABLE: orders
-- =====================================================
CREATE TABLE public.orders (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    drawing_id UUID NOT NULL REFERENCES public.drawings(id) ON DELETE RESTRICT,
    
    -- Order details
    order_number TEXT UNIQUE NOT NULL, -- Human-readable (DT-2026-001234)
    status order_status NOT NULL DEFAULT 'pending',
    
    -- Product configuration
    toy_size toy_size NOT NULL,
    is_painted BOOLEAN DEFAULT FALSE,
    is_express_delivery BOOLEAN DEFAULT FALSE,
    quantity INTEGER NOT NULL DEFAULT 1,
    
    -- Pricing
    base_price DECIMAL(10, 2) NOT NULL,
    painting_price DECIMAL(10, 2) DEFAULT 0,
    express_price DECIMAL(10, 2) DEFAULT 0,
    discount_amount DECIMAL(10, 2) DEFAULT 0,
    total_amount DECIMAL(10, 2) NOT NULL,
    currency TEXT DEFAULT 'EUR',
    
    -- Payment
    stripe_payment_intent_id TEXT,
    payment_status payment_status NOT NULL DEFAULT 'pending',
    paid_at TIMESTAMPTZ,
    
    -- Shipping
    shipping_name TEXT NOT NULL,
    shipping_address_line1 TEXT NOT NULL,
    shipping_address_line2 TEXT,
    shipping_city TEXT NOT NULL,
    shipping_postal_code TEXT NOT NULL,
    shipping_country TEXT NOT NULL,
    shipping_phone TEXT,
    
    tracking_number TEXT,
    shipped_at TIMESTAMPTZ,
    delivered_at TIMESTAMPTZ,
    estimated_delivery_date DATE,
    
    -- Notes
    customer_notes TEXT,
    internal_notes TEXT,
    
    -- Timestamps
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT valid_quantity CHECK (quantity > 0),
    CONSTRAINT valid_total CHECK (total_amount >= 0)
);

-- Indexes for orders
CREATE INDEX idx_orders_user ON public.orders(user_id);
CREATE INDEX idx_orders_drawing ON public.orders(drawing_id);
CREATE INDEX idx_orders_status ON public.orders(status);
CREATE INDEX idx_orders_number ON public.orders(order_number);
CREATE INDEX idx_orders_created ON public.orders(created_at DESC);
CREATE INDEX idx_orders_stripe_payment ON public.orders(stripe_payment_intent_id);

-- =====================================================
-- TABLE: payments
-- =====================================================
CREATE TABLE public.payments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    order_id UUID REFERENCES public.orders(id) ON DELETE SET NULL,
    subscription_id UUID REFERENCES public.subscriptions(id) ON DELETE SET NULL,
    
    -- Payment details
    stripe_payment_intent_id TEXT UNIQUE,
    stripe_charge_id TEXT,
    
    amount DECIMAL(10, 2) NOT NULL,
    currency TEXT DEFAULT 'EUR',
    status payment_status NOT NULL,
    
    -- Metadata
    payment_method_type TEXT, -- card, paypal, etc
    payment_method_last4 TEXT,
    
    -- Refund info
    refunded_amount DECIMAL(10, 2) DEFAULT 0,
    refunded_at TIMESTAMPTZ,
    refund_reason TEXT,
    
    -- Timestamps
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes for payments
CREATE INDEX idx_payments_user ON public.payments(user_id);
CREATE INDEX idx_payments_order ON public.payments(order_id);
CREATE INDEX idx_payments_subscription ON public.payments(subscription_id);
CREATE INDEX idx_payments_stripe_intent ON public.payments(stripe_payment_intent_id);

-- =====================================================
-- TABLE: galleries
-- =====================================================
CREATE TABLE public.galleries (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    
    -- Gallery metadata
    title TEXT NOT NULL,
    description TEXT,
    cover_image_url TEXT,
    
    -- Settings
    is_public BOOLEAN DEFAULT FALSE,
    slug TEXT UNIQUE, -- For public URL sharing
    
    -- Stats
    views_count INTEGER NOT NULL DEFAULT 0,
    
    -- Timestamps
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes for galleries
CREATE INDEX idx_galleries_user ON public.galleries(user_id);
CREATE INDEX idx_galleries_slug ON public.galleries(slug) WHERE slug IS NOT NULL;
CREATE INDEX idx_galleries_public ON public.galleries(is_public) WHERE is_public = TRUE;

-- =====================================================
-- TABLE: gallery_items (junction table)
-- =====================================================
CREATE TABLE public.gallery_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    gallery_id UUID NOT NULL REFERENCES public.galleries(id) ON DELETE CASCADE,
    drawing_id UUID NOT NULL REFERENCES public.drawings(id) ON DELETE CASCADE,
    
    -- Ordering
    position INTEGER NOT NULL DEFAULT 0,
    
    -- Timestamps
    added_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    -- Constraints
    UNIQUE(gallery_id, drawing_id)
);

-- Indexes for gallery_items
CREATE INDEX idx_gallery_items_gallery ON public.gallery_items(gallery_id, position);
CREATE INDEX idx_gallery_items_drawing ON public.gallery_items(drawing_id);

-- =====================================================
-- TABLE: shares
-- =====================================================
CREATE TABLE public.shares (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    drawing_id UUID REFERENCES public.drawings(id) ON DELETE CASCADE,
    gallery_id UUID REFERENCES public.galleries(id) ON DELETE CASCADE,
    
    -- Share details
    platform TEXT NOT NULL, -- instagram, facebook, tiktok, etc
    share_url TEXT,
    
    -- Stats
    clicks_count INTEGER NOT NULL DEFAULT 0,
    
    -- Timestamps
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    -- Constraints
    CHECK (drawing_id IS NOT NULL OR gallery_id IS NOT NULL)
);

-- Indexes for shares
CREATE INDEX idx_shares_user ON public.shares(user_id);
CREATE INDEX idx_shares_drawing ON public.shares(drawing_id);
CREATE INDEX idx_shares_gallery ON public.shares(gallery_id);
CREATE INDEX idx_shares_created ON public.shares(created_at DESC);

-- =====================================================
-- TABLE: notifications
-- =====================================================
CREATE TABLE public.notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    
    -- Notification content
    type TEXT NOT NULL, -- drawing_ready, order_shipped, subscription_expiring, etc
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    action_url TEXT,
    
    -- Status
    is_read BOOLEAN DEFAULT FALSE,
    read_at TIMESTAMPTZ,
    
    -- Metadata
    metadata JSONB,
    
    -- Timestamps
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes for notifications
CREATE INDEX idx_notifications_user ON public.notifications(user_id);
CREATE INDEX idx_notifications_unread ON public.notifications(user_id, is_read) WHERE is_read = FALSE;
CREATE INDEX idx_notifications_created ON public.notifications(created_at DESC);

-- =====================================================
-- TABLE: analytics_events
-- =====================================================
CREATE TABLE public.analytics_events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES public.users(id) ON DELETE SET NULL,
    
    -- Event details
    event_type TEXT NOT NULL, -- drawing_uploaded, ar_opened, toy_ordered, etc
    event_category TEXT, -- engagement, conversion, etc
    
    -- Context
    drawing_id UUID REFERENCES public.drawings(id) ON DELETE SET NULL,
    order_id UUID REFERENCES public.orders(id) ON DELETE SET NULL,
    
    -- Device/Session info
    device_type TEXT, -- ios, android, web
    app_version TEXT,
    session_id TEXT,
    
    -- Metadata
    properties JSONB,
    
    -- Timestamp
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes for analytics_events
CREATE INDEX idx_analytics_user ON public.analytics_events(user_id);
CREATE INDEX idx_analytics_type ON public.analytics_events(event_type);
CREATE INDEX idx_analytics_created ON public.analytics_events(created_at DESC);

-- =====================================================
-- TABLE: admin_logs
-- =====================================================
CREATE TABLE public.admin_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    admin_user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    
    -- Action details
    action TEXT NOT NULL, -- user_banned, order_refunded, etc
    target_table TEXT,
    target_id UUID,
    
    -- Changes
    old_values JSONB,
    new_values JSONB,
    
    -- Context
    reason TEXT,
    ip_address INET,
    
    -- Timestamp
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes for admin_logs
CREATE INDEX idx_admin_logs_admin ON public.admin_logs(admin_user_id);
CREATE INDEX idx_admin_logs_created ON public.admin_logs(created_at DESC);

-- =====================================================
-- FUNCTIONS & TRIGGERS
-- =====================================================

-- Function: Update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply updated_at trigger to relevant tables
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON public.users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_subscriptions_updated_at BEFORE UPDATE ON public.subscriptions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_child_profiles_updated_at BEFORE UPDATE ON public.child_profiles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_drawings_updated_at BEFORE UPDATE ON public.drawings
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_orders_updated_at BEFORE UPDATE ON public.orders
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_galleries_updated_at BEFORE UPDATE ON public.galleries
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Function: Generate unique order number
CREATE OR REPLACE FUNCTION generate_order_number()
RETURNS TEXT AS $$
DECLARE
    new_number TEXT;
    year_code TEXT;
    sequence_num INTEGER;
BEGIN
    year_code := TO_CHAR(NOW(), 'YYYY');
    
    -- Get next sequence number for this year
    SELECT COALESCE(MAX(CAST(SUBSTRING(order_number FROM 9) AS INTEGER)), 0) + 1
    INTO sequence_num
    FROM public.orders
    WHERE order_number LIKE 'DT-' || year_code || '-%';
    
    new_number := 'DT-' || year_code || '-' || LPAD(sequence_num::TEXT, 6, '0');
    
    RETURN new_number;
END;
$$ LANGUAGE plpgsql;

-- Trigger: Auto-generate order number
CREATE OR REPLACE FUNCTION set_order_number()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.order_number IS NULL THEN
        NEW.order_number := generate_order_number();
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_order_number_trigger BEFORE INSERT ON public.orders
    FOR EACH ROW EXECUTE FUNCTION set_order_number();

-- Function: Reset monthly drawing limits
CREATE OR REPLACE FUNCTION reset_monthly_drawing_limits()
RETURNS void AS $$
BEGIN
    UPDATE public.users
    SET 
        drawings_used_this_month = 0,
        last_reset_date = CURRENT_DATE
    WHERE last_reset_date < DATE_TRUNC('month', CURRENT_DATE);
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
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

-- Users: Can only view/edit their own profile
CREATE POLICY "Users can view own profile" ON public.users
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON public.users
    FOR UPDATE USING (auth.uid() = id);

-- Subscriptions: Users can view their own subscriptions
CREATE POLICY "Users can view own subscriptions" ON public.subscriptions
    FOR SELECT USING (auth.uid() = user_id);

-- Child Profiles: Users can manage their own child profiles
CREATE POLICY "Users can view own child profiles" ON public.child_profiles
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own child profiles" ON public.child_profiles
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own child profiles" ON public.child_profiles
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own child profiles" ON public.child_profiles
    FOR DELETE USING (auth.uid() = user_id);

-- Drawings: Users can manage their own drawings, others can view public ones
CREATE POLICY "Users can view own drawings" ON public.drawings
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Anyone can view public drawings" ON public.drawings
    FOR SELECT USING (is_public = TRUE);

CREATE POLICY "Users can insert own drawings" ON public.drawings
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own drawings" ON public.drawings
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own drawings" ON public.drawings
    FOR DELETE USING (auth.uid() = user_id);

-- Orders: Users can view/create their own orders
CREATE POLICY "Users can view own orders" ON public.orders
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own orders" ON public.orders
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Galleries: Users manage own galleries, others can view public ones
CREATE POLICY "Users can view own galleries" ON public.galleries
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Anyone can view public galleries" ON public.galleries
    FOR SELECT USING (is_public = TRUE);

CREATE POLICY "Users can manage own galleries" ON public.galleries
    FOR ALL USING (auth.uid() = user_id);

-- Notifications: Users can only view their own notifications
CREATE POLICY "Users can view own notifications" ON public.notifications
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can update own notifications" ON public.notifications
    FOR UPDATE USING (auth.uid() = user_id);

-- =====================================================
-- INITIAL DATA / SEEDS (Optional)
-- =====================================================

-- Insert default gallery for each new user (handled by application)

-- =====================================================
-- PERFORMANCE VIEWS (Optional)
-- =====================================================

-- View: User dashboard stats
CREATE OR REPLACE VIEW user_dashboard_stats AS
SELECT 
    u.id as user_id,
    u.subscription_tier,
    u.drawings_used_this_month,
    COUNT(DISTINCT d.id) as total_drawings,
    COUNT(DISTINCT o.id) as total_orders,
    COUNT(DISTINCT cp.id) as total_children
FROM public.users u
LEFT JOIN public.drawings d ON d.user_id = u.id
LEFT JOIN public.orders o ON o.user_id = u.id
LEFT JOIN public.child_profiles cp ON cp.user_id = u.id
GROUP BY u.id, u.subscription_tier, u.drawings_used_this_month;

-- View: Popular public drawings
CREATE OR REPLACE VIEW popular_public_drawings AS
SELECT 
    d.*,
    u.full_name as creator_name,
    u.avatar_url as creator_avatar,
    (d.views_count + d.ar_sessions_count * 2 + d.share_count * 3) as popularity_score
FROM public.drawings d
JOIN public.users u ON u.id = d.user_id
WHERE d.is_public = TRUE
  AND d.model_status = 'completed'
ORDER BY popularity_score DESC;

-- =====================================================
-- COMMENTS & DOCUMENTATION
-- =====================================================

COMMENT ON TABLE public.users IS 'Main user accounts table extending Supabase auth.users';
COMMENT ON TABLE public.subscriptions IS 'Subscription management with Stripe integration';
COMMENT ON TABLE public.child_profiles IS 'Multiple children profiles per family account';
COMMENT ON TABLE public.drawings IS 'User-uploaded drawings and their 3D models';
COMMENT ON TABLE public.orders IS 'Physical toy orders through marketplace';
COMMENT ON TABLE public.payments IS 'Payment transactions history';
COMMENT ON TABLE public.galleries IS 'User-created galleries for organizing drawings';
COMMENT ON TABLE public.notifications IS 'In-app notification system';
COMMENT ON TABLE public.analytics_events IS 'Event tracking for analytics';

-- =====================================================
-- TABLE: system_config (Dynamic Configuration Management)
-- =====================================================
CREATE TABLE public.system_config (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Configuration key (unique identifier)
    key TEXT NOT NULL UNIQUE,
    
    -- Configuration value (encrypted at rest)
    value TEXT NOT NULL,
    
    -- Human-readable description
    description TEXT,
    
    -- Metadata
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_by UUID REFERENCES public.users(id) ON DELETE SET NULL,
    
    -- Constraints
    CONSTRAINT valid_key_format CHECK (key ~ '^[A-Z_][A-Z0-9_]*$')
);

-- Indexes for system_config
CREATE INDEX idx_system_config_key ON public.system_config(key);
CREATE INDEX idx_system_config_updated ON public.system_config(updated_at DESC);

-- Enable RLS for system_config
ALTER TABLE public.system_config ENABLE ROW LEVEL SECURITY;

-- RLS Policies for system_config
-- Only service_role (backend) and admin users can access system_config
CREATE POLICY "Service role full access" ON public.system_config
    FOR ALL USING (auth.jwt() ->> 'role' = 'service_role');

-- Admin users (with role = 'admin') can read
CREATE POLICY "Admin users can read config" ON public.system_config
    FOR SELECT USING (
        auth.uid() IN (SELECT id FROM public.users WHERE role = 'admin')
    );

-- Admin users can modify config
CREATE POLICY "Admin users can modify config" ON public.system_config
    FOR ALL USING (
        auth.uid() IN (SELECT id FROM public.users WHERE role = 'admin')
    );

-- Function to get config value
CREATE OR REPLACE FUNCTION public.get_config(p_key TEXT)
RETURNS TEXT AS $$
DECLARE
    config_value TEXT;
BEGIN
    SELECT value INTO config_value
    FROM public.system_config
    WHERE key = p_key;
    
    RETURN config_value;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE EXCEPTION 'Configuration key % not found', p_key;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- View for non-sensitive config (for client-side use)
CREATE OR REPLACE VIEW public.system_config_public AS
SELECT 
    key,
    description,
    updated_at
FROM public.system_config
WHERE key IN ('SYSTEM_STATUS', 'MODEL_VISION', 'MODEL_3D_GENERATOR');

-- Grant permissions
GRANT SELECT ON public.system_config_public TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_config TO authenticated;

-- =====================================================
-- END OF SCHEMA
-- =====================================================

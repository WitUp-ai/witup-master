-- =====================================================
-- AUTO-CONFIRM USERS (Development Only)
-- =====================================================
-- This trigger automatically confirms user emails on signup.
-- REMOVE THIS IN PRODUCTION!
-- =====================================================

-- Function to auto-confirm users
CREATE OR REPLACE FUNCTION public.auto_confirm_user()
RETURNS TRIGGER AS $$
BEGIN
    -- Auto-confirm the user's email
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

-- Trigger: Auto-confirm on user creation
DROP TRIGGER IF EXISTS auto_confirm_user_trigger ON auth.users;
CREATE TRIGGER auto_confirm_user_trigger
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.auto_confirm_user();

-- Grant necessary permissions
GRANT USAGE ON SCHEMA auth TO postgres;
GRANT ALL ON auth.users TO postgres;

-- =====================================================
-- IMPORTANT: Remove this in production by running:
-- DROP TRIGGER auto_confirm_user_trigger ON auth.users;
-- DROP FUNCTION public.auto_confirm_user();
-- =====================================================

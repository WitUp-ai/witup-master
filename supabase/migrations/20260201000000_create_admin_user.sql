-- ============================================================================
-- Migration: Create Admin User
-- Date: 2026-02-01
-- Description: Automatically creates admin user if it doesn't exist
-- ============================================================================

-- Enable pgcrypto extension for password hashing
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Create admin user function (idempotent - safe to run multiple times)
CREATE OR REPLACE FUNCTION create_admin_user_if_not_exists()
RETURNS void AS $$
DECLARE
  admin_email TEXT := 'giovanni.sapere@witup.ai';
  admin_password TEXT := 'Gnotti2025!';
  user_exists BOOLEAN;
  new_user_id UUID;
BEGIN
  -- Check if user already exists
  SELECT EXISTS (
    SELECT 1 FROM auth.users WHERE email = admin_email
  ) INTO user_exists;

  -- Only create if doesn't exist
  IF NOT user_exists THEN
    -- Generate new user ID
    new_user_id := gen_random_uuid();

    -- Insert user into auth.users
    INSERT INTO auth.users (
      instance_id,
      id,
      aud,
      role,
      email,
      encrypted_password,
      email_confirmed_at,
      confirmation_token,
      recovery_token,
      email_change_token_new,
      email_change,
      created_at,
      updated_at,
      raw_app_meta_data,
      raw_user_meta_data,
      is_super_admin,
      confirmation_sent_at
    )
    VALUES (
      '00000000-0000-0000-0000-000000000000',
      new_user_id,
      'authenticated',
      'authenticated',
      admin_email,
      crypt(admin_password, gen_salt('bf')),
      NOW(),
      '',
      '',
      '',
      '',
      NOW(),
      NOW(),
      '{"provider":"email","providers":["email"]}'::jsonb,
      '{"name":"Giovanni Sapere"}'::jsonb,
      FALSE,
      NOW()
    );

    RAISE NOTICE 'Admin user created: % with ID: %', admin_email, new_user_id;
  ELSE
    RAISE NOTICE 'Admin user already exists: %', admin_email;
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Execute the function to create admin user
SELECT create_admin_user_if_not_exists();

-- Add user to users table if it doesn't exist
-- (this will be populated by auth trigger, but we ensure it here)
INSERT INTO users (id, email, created_at)
SELECT
  u.id,
  u.email,
  u.created_at
FROM auth.users u
WHERE u.email = 'giovanni.sapere@witup.ai'
  AND NOT EXISTS (
    SELECT 1 FROM users WHERE email = 'giovanni.sapere@witup.ai'
  );

-- Set admin role if users table has role column
DO $$
BEGIN
  -- Check if role column exists
  IF EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_name = 'users'
      AND column_name = 'role'
  ) THEN
    -- Update role to admin
    UPDATE users
    SET role = 'admin'
    WHERE email = 'giovanni.sapere@witup.ai'
      AND (role IS NULL OR role != 'admin');

    RAISE NOTICE 'Admin role set for user';
  ELSE
    RAISE NOTICE 'Users table does not have role column - skipping role assignment';
  END IF;
END $$;

-- Cleanup: Drop the function after use (optional, can keep for future re-runs)
-- DROP FUNCTION IF EXISTS create_admin_user_if_not_exists();

-- ============================================================================
-- Verification Query (for manual check after migration)
-- ============================================================================
-- SELECT email, email_confirmed_at, created_at
-- FROM auth.users
-- WHERE email = 'giovanni.sapere@witup.ai';

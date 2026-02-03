-- Fix RLS policies for system_config table
-- Edge Functions need to read API keys from this table

-- Drop existing restrictive policy
DROP POLICY IF EXISTS "service_role_all_system_config" ON public.system_config;

-- Temporarily disable RLS to allow Edge Functions to read config
-- Edge Functions run with service_role but auth.role() doesn't work correctly
ALTER TABLE public.system_config DISABLE ROW LEVEL SECURITY;

-- Alternative: If we want to keep RLS enabled, use this permissive policy instead:
-- CREATE POLICY "allow_all_read_system_config" ON public.system_config
--   FOR SELECT USING (true);
--
-- CREATE POLICY "service_role_write_system_config" ON public.system_config
--   FOR ALL USING (auth.role() = 'service_role');

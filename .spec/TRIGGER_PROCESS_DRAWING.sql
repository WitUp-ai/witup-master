-- =====================================================
-- DRAW2TOY - Auto-Process Drawing Trigger
-- =====================================================
-- Questo trigger viene eseguito quando un nuovo disegno
-- viene inserito, e chiama l'Edge Function per processarlo.
-- =====================================================

-- Function to call Edge Function for processing
CREATE OR REPLACE FUNCTION public.trigger_drawing_processing()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    edge_function_url TEXT;
    service_role_key TEXT;
BEGIN
    -- Get Supabase URL from environment (set in dashboard)
    edge_function_url := current_setting('app.supabase_url', true) || '/functions/v1/process-drawing';
    service_role_key := current_setting('app.service_role_key', true);

    -- Only trigger for new drawings with pending status
    IF NEW.model_status = 'pending' THEN
        -- Queue the processing (async via pg_net extension if available)
        -- For now, we'll handle this from the client side

        -- Log the event for debugging
        RAISE NOTICE 'Drawing % queued for processing', NEW.id;
    END IF;

    RETURN NEW;
END;
$$;

-- Create trigger on drawings table (disabled by default - enable when Edge Function is deployed)
-- DROP TRIGGER IF EXISTS auto_process_drawing ON public.drawings;
-- CREATE TRIGGER auto_process_drawing
--     AFTER INSERT ON public.drawings
--     FOR EACH ROW
--     EXECUTE FUNCTION public.trigger_drawing_processing();

-- =====================================================
-- Alternative: Use pg_cron for batch processing
-- =====================================================
-- This runs every minute to process pending drawings

-- CREATE EXTENSION IF NOT EXISTS pg_cron;
--
-- SELECT cron.schedule(
--     'process-pending-drawings',
--     '* * * * *',  -- Every minute
--     $$
--     SELECT net.http_post(
--         url := current_setting('app.supabase_url') || '/functions/v1/process-batch',
--         headers := jsonb_build_object(
--             'Content-Type', 'application/json',
--             'Authorization', 'Bearer ' || current_setting('app.service_role_key')
--         ),
--         body := jsonb_build_object('limit', 5)
--     ) FROM public.drawings
--     WHERE model_status = 'pending'
--     LIMIT 1;
--     $$
-- );

-- =====================================================
-- For MVP: Processing will be triggered from client
-- =====================================================
-- The mobile app will call the Edge Function directly
-- after uploading a drawing.

COMMENT ON FUNCTION public.trigger_drawing_processing() IS
'Triggers AI processing for new drawings. Called automatically on insert or manually from client.';

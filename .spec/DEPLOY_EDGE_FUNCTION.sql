-- =====================================================
-- DRAW2TOY - Database Trigger per Processing
-- =====================================================
-- Questo trigger notifica automaticamente quando un
-- drawing e' pronto per essere processato.
-- =====================================================

-- Funzione per notificare il processing
CREATE OR REPLACE FUNCTION public.notify_drawing_ready()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Notifica via Supabase Realtime
    PERFORM pg_notify(
        'drawing_ready',
        json_build_object(
            'drawing_id', NEW.id,
            'user_id', NEW.user_id,
            'status', NEW.model_status
        )::text
    );

    RETURN NEW;
END;
$$;

-- Trigger quando un drawing viene inserito
DROP TRIGGER IF EXISTS on_drawing_inserted ON public.drawings;
CREATE TRIGGER on_drawing_inserted
    AFTER INSERT ON public.drawings
    FOR EACH ROW
    WHEN (NEW.model_status = 'pending')
    EXECUTE FUNCTION public.notify_drawing_ready();

-- Trigger quando lo status cambia
DROP TRIGGER IF EXISTS on_drawing_status_changed ON public.drawings;
CREATE TRIGGER on_drawing_status_changed
    AFTER UPDATE OF model_status ON public.drawings
    FOR EACH ROW
    WHEN (OLD.model_status IS DISTINCT FROM NEW.model_status)
    EXECUTE FUNCTION public.notify_drawing_ready();

-- =====================================================
-- Aggiungi colonna thumbnail_url se non esiste
-- =====================================================
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'drawings' AND column_name = 'thumbnail_url'
    ) THEN
        ALTER TABLE public.drawings ADD COLUMN thumbnail_url TEXT;
    END IF;
END
$$;

-- =====================================================
-- Indici per performance
-- =====================================================
CREATE INDEX IF NOT EXISTS idx_drawings_status_user
ON public.drawings(user_id, model_status);

CREATE INDEX IF NOT EXISTS idx_drawings_pending
ON public.drawings(model_status)
WHERE model_status = 'pending';

-- =====================================================
-- DONE
-- =====================================================

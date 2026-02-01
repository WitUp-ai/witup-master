-- =====================================================
-- DRAW2TOY - Admin Role Setup
-- =====================================================
-- Aggiunge supporto ruolo admin agli utenti
-- =====================================================

-- Aggiungi colonna role se non esiste
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'users' AND column_name = 'role'
    ) THEN
        ALTER TABLE public.users ADD COLUMN role TEXT DEFAULT 'user';
    END IF;
END
$$;

-- Crea indice per lookup rapido admin
CREATE INDEX IF NOT EXISTS idx_users_role ON public.users(role);

-- Imposta Giovanni come admin (owner del progetto)
-- Usa l'email del proprietario del progetto
UPDATE public.users SET role = 'admin' WHERE email = 'giovanni@witup.ai';

-- View per admin: statistiche generali
CREATE OR REPLACE VIEW public.admin_stats AS
SELECT
    (SELECT COUNT(*) FROM public.users) AS total_users,
    (SELECT COUNT(*) FROM public.users WHERE created_at > NOW() - INTERVAL '7 days') AS new_users_7d,
    (SELECT COUNT(*) FROM public.users WHERE created_at > NOW() - INTERVAL '30 days') AS new_users_30d,
    (SELECT COUNT(*) FROM public.drawings) AS total_drawings,
    (SELECT COUNT(*) FROM public.drawings WHERE created_at > NOW() - INTERVAL '7 days') AS new_drawings_7d,
    (SELECT COUNT(*) FROM public.drawings WHERE model_status = 'completed') AS completed_drawings,
    (SELECT COUNT(*) FROM public.drawings WHERE model_status = 'failed') AS failed_drawings,
    (SELECT COUNT(*) FROM public.drawings WHERE model_status = 'pending') AS pending_drawings;

-- View per admin: attività recenti
CREATE OR REPLACE VIEW public.admin_recent_activity AS
SELECT
    d.id,
    d.created_at,
    d.model_status,
    d.original_url,
    u.email AS user_email
FROM public.drawings d
LEFT JOIN public.users u ON d.user_id = u.id
ORDER BY d.created_at DESC
LIMIT 50;

-- RLS: solo admin possono vedere le view admin
CREATE POLICY "Admin view stats" ON public.users
    FOR SELECT USING (
        auth.uid() IN (SELECT id FROM public.users WHERE role = 'admin')
        OR auth.uid() = id
    );

-- =====================================================
-- DONE - Esegui nel SQL Editor di Supabase
-- =====================================================

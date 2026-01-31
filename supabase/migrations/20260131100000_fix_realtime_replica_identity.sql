-- Ensure drawings table has FULL replica identity for Realtime updates
-- Without this, UPDATE events may not include all columns
ALTER TABLE public.drawings REPLICA IDENTITY FULL;

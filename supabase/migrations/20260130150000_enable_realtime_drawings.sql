-- Enable Realtime on drawings table so that .stream() receives live updates
-- This is required for processing_step progress to be visible in the client
ALTER PUBLICATION supabase_realtime ADD TABLE public.drawings;

-- Add processing_step column for granular progress tracking
ALTER TABLE public.drawings
ADD COLUMN IF NOT EXISTS processing_step TEXT DEFAULT NULL;

COMMENT ON COLUMN public.drawings.processing_step IS 'Current processing step: uploading, validating, removing_background, generating_3d, finalizing';

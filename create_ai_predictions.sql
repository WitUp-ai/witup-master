-- Create AI Predictions table for tracking async processing
CREATE TABLE IF NOT EXISTS public.ai_predictions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  prediction_id TEXT NOT NULL UNIQUE, -- Replicate prediction ID
  drawing_id UUID NOT NULL REFERENCES public.drawings(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  prediction_type TEXT NOT NULL CHECK (prediction_type IN ('background_removal', '3d_generation')),
  status TEXT NOT NULL DEFAULT 'starting' CHECK (status IN ('starting', 'processing', 'succeeded', 'failed', 'canceled')),
  output TEXT,
  error TEXT,
  processing_time DECIMAL(10, 2), -- seconds
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  started_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_ai_predictions_drawing ON public.ai_predictions(drawing_id);
CREATE INDEX IF NOT EXISTS idx_ai_predictions_user ON public.ai_predictions(user_id);
CREATE INDEX IF NOT EXISTS idx_ai_predictions_status ON public.ai_predictions(status);
CREATE INDEX IF NOT EXISTS idx_ai_predictions_prediction_id ON public.ai_predictions(prediction_id);

-- Add RLS policies
ALTER TABLE public.ai_predictions ENABLE ROW LEVEL SECURITY;

-- Policy: Users can view their own predictions
CREATE POLICY "Users can view own predictions" ON public.ai_predictions
  FOR SELECT USING (auth.uid() = user_id);

-- Policy: Service role can do everything (for Edge Functions)
CREATE POLICY "Service role full access" ON public.ai_predictions
  FOR ALL USING (auth.jwt() ->> 'role' = 'service_role');

-- Add comment for documentation
COMMENT ON TABLE public.ai_predictions IS 'Tracks async AI predictions from Replicate API';
COMMENT ON COLUMN public.ai_predictions.prediction_id IS 'Replicate prediction ID (from their API)';
COMMENT ON COLUMN public.ai_predictions.prediction_type IS 'Type of prediction: background_removal or 3d_generation';
COMMENT ON COLUMN public.ai_predictions.processing_time IS 'Processing time in seconds from Replicate metrics';
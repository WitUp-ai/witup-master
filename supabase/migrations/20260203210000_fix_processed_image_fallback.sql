-- Fix per il problema dell'immagine processata mancante
-- 1. Assicura che le colonne necessarie esistano
-- 2. Aggiunge una colonna per tracciare quale versione dell'immagine mostrare
-- 3. Aggiunge una funzione trigger per gestire il fallback automatico

-- Assicurati che le colonne esistano (idempotente)
ALTER TABLE drawings ADD COLUMN IF NOT EXISTS processed_image_url text;
ALTER TABLE drawings ADD COLUMN IF NOT EXISTS stylized_image_url text;
ALTER TABLE drawings ADD COLUMN IF NOT EXISTS thumbnail_url text;
ALTER TABLE drawings ADD COLUMN IF NOT EXISTS original_image_url text;
ALTER TABLE drawings ADD COLUMN IF NOT EXISTS model_3d_url text;

-- Aggiungi colonna per tracciare la versione dell'immagine da mostrare
ALTER TABLE drawings ADD COLUMN IF NOT EXISTS display_image_version text 
  CHECK (display_image_version IN ('processed', 'stylized', 'original', 'thumbnail'));

-- Funzione per gestire il fallback automatico dell'immagine
CREATE OR REPLACE FUNCTION handle_image_fallback()
RETURNS TRIGGER AS $$
BEGIN
  -- Se abbiamo un'immagine stylized, usa quella
  IF NEW.stylized_image_url IS NOT NULL THEN
    NEW.display_image_version := 'stylized';
    -- Se processed_image_url è vuoto, usa stylized
    IF NEW.processed_image_url IS NULL THEN
        NEW.processed_image_url := NEW.stylized_image_url;
    END IF;
  
  -- Altrimenti se abbiamo un'immagine processed, usa quella
  ELSIF NEW.processed_image_url IS NOT NULL THEN
    NEW.display_image_version := 'processed';
  
  -- Se abbiamo solo il thumbnail, usalo come fallback
  ELSIF NEW.thumbnail_url IS NOT NULL THEN
    NEW.display_image_version := 'thumbnail';
    IF NEW.processed_image_url IS NULL THEN
        NEW.processed_image_url := NEW.thumbnail_url;
    END IF;
  
  -- Ultimo fallback: usa l'immagine originale
  ELSE
    NEW.display_image_version := 'original';
    IF NEW.processed_image_url IS NULL THEN
        NEW.processed_image_url := NEW.original_image_url;
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger per applicare il fallback automaticamente
DROP TRIGGER IF EXISTS trg_handle_image_fallback ON drawings;
CREATE TRIGGER trg_handle_image_fallback
  BEFORE UPDATE ON drawings
  FOR EACH ROW
  WHEN (NEW.model_status = 'completed')
  EXECUTE FUNCTION handle_image_fallback();

-- Applica il fallback a tutti i record esistenti completati
UPDATE drawings 
SET model_status = model_status
WHERE model_status = 'completed';

-- Aggiungi indice per performance
CREATE INDEX IF NOT EXISTS idx_drawings_display_version 
  ON drawings(display_image_version) 
  WHERE model_status = 'completed';

-- Log della migrazione
INSERT INTO migrations (name, executed_at) 
VALUES ('20260203210000_fix_processed_image_fallback', NOW())
ON CONFLICT (name) DO NOTHING;

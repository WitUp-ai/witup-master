@echo off
REM Script per configurare i secrets delle Edge Functions Supabase
REM Progetto: rnfzzmfpykbavuirypfz

echo ========================================
echo CONFIGURAZIONE SECRETS SUPABASE
echo ========================================
echo.
echo Progetto: rnfzzmfpykbavuirypfz
echo.

REM Controlla se supabase.exe esiste
if not exist "supabase.exe" (
    echo ERRORE: supabase.exe non trovato nella cartella corrente!
    echo Scarica Supabase CLI da: https://github.com/supabase/cli/releases
    pause
    exit /b 1
)

echo Configurazione dei secrets per le Edge Functions...
echo.

REM Configura REPLICATE_API_TOKEN
echo [1/3] Configurando REPLICATE_API_TOKEN...
supabase.exe secrets set REPLICATE_API_TOKEN=YOUR_REPLICATE_API_TOKEN --project-ref rnfzzmfpykbavuirypfz
if errorlevel 1 (
    echo ERRORE nella configurazione di REPLICATE_API_TOKEN
) else (
    echo ✓ REPLICATE_API_TOKEN configurato
)
echo.

REM Configura SUPABASE_URL
echo [2/3] Configurando SUPABASE_URL...
supabase.exe secrets set SUPABASE_URL=https://rnfzzmfpykbavuirypfz.supabase.co --project-ref rnfzzmfpykbavuirypfz
if errorlevel 1 (
    echo ERRORE nella configurazione di SUPABASE_URL
) else (
    echo ✓ SUPABASE_URL configurato
)
echo.

REM Configura SUPABASE_SERVICE_ROLE_KEY
echo [3/3] Configurando SUPABASE_SERVICE_ROLE_KEY...
supabase.exe secrets set SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJuZnp6bWZweWtiYXZ1aXJ5cGZ6Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2OTUyMjgwNSwiZXhwIjoyMDg1MDk4ODA1fQ.fT4BvxOGWwY8RjL1HAhNxNryjJO37rw1YUjmFndKCII --project-ref rnfzzmfpykbavuirypfz
if errorlevel 1 (
    echo ERRORE nella configurazione di SUPABASE_SERVICE_ROLE_KEY
) else (
    echo ✓ SUPABASE_SERVICE_ROLE_KEY configurato
)
echo.

echo ========================================
echo CONFIGURAZIONE COMPLETATA!
echo ========================================
echo.
echo NOTA: Le Edge Functions sono ora configurate con:
echo   ✓ REPLICATE_API_TOKEN (per generazione 3D)
echo   ✓ SUPABASE_URL
echo   ✓ SUPABASE_SERVICE_ROLE_KEY
echo.
echo Le Edge Functions si riavvieranno automaticamente con i nuovi secrets.
echo.
pause

@echo off
echo ========================================
echo DRAW2TOY - Setup Automatico Completo
echo ========================================
echo.
echo Questo script configura tutto il necessario.
echo.

REM Step 1: Deploy Edge Function
echo [1/3] Deploy Edge Function su Supabase...
echo.
echo NOTA: Si aprira' il browser per il login Supabase.
echo Effettua il login e torna qui.
echo.
cd /d "%~dp0"
call npx supabase login
if %ERRORLEVEL% NEQ 0 (
    echo ERRORE: Login fallito. Riprova.
    pause
    exit /b 1
)

echo.
echo Deploying process-drawing function...
call npx supabase functions deploy process-drawing --project-ref rnfzzmfpykbavuirypfz
if %ERRORLEVEL% NEQ 0 (
    echo ERRORE: Deploy fallito.
    pause
    exit /b 1
)
echo Edge Function deployata con successo!

REM Step 2: SQL Trigger
echo.
echo [2/3] Configurazione SQL triggers...
echo.
echo IMPORTANTE: Esegui il file .spec/DEPLOY_EDGE_FUNCTION.sql
echo nel SQL Editor di Supabase Dashboard:
echo https://supabase.com/dashboard/project/rnfzzmfpykbavuirypfz/sql
echo.
echo Premi un tasto dopo aver eseguito lo SQL...
pause >nul

REM Step 3: API Token
echo.
echo [3/3] Configurazione API Token per AI...
echo.
echo 1. Vai su https://replicate.com/account/api-tokens
echo 2. Crea un nuovo token
echo 3. Vai su https://supabase.com/dashboard/project/rnfzzmfpykbavuirypfz/settings/functions
echo 4. Aggiungi il Secret: REPLICATE_API_TOKEN
echo.
echo Premi un tasto dopo aver configurato il token...
pause >nul

echo.
echo ========================================
echo SETUP COMPLETATO!
echo ========================================
echo.
echo URL App: https://web-wit-up.vercel.app
echo.
echo Per ri-deployare l'app Flutter:
echo   cd src\mobile ^&^& flutter build web --release
echo   cd build\web ^&^& vercel --prod --yes
echo.
echo ========================================
pause

@echo off
echo ========================================
echo Draw2Toy - Deploy Edge Function
echo ========================================
echo.

REM Check if supabase CLI is available
where supabase >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo Installing Supabase CLI...
    npm install -g supabase
)

echo.
echo Step 1: Login to Supabase
echo Please login with your browser...
echo.
call npx supabase login

echo.
echo Step 2: Deploying Edge Function...
echo.
cd /d "%~dp0"
call npx supabase functions deploy process-drawing --project-ref rnfzzmfpykbavuirypfz

echo.
echo ========================================
echo Deploy completato!
echo.
echo Prossimi passi:
echo 1. Vai su https://supabase.com/dashboard/project/rnfzzmfpykbavuirypfz/settings/functions
echo 2. Aggiungi il Secret: REPLICATE_API_TOKEN
echo    - Ottieni token da https://replicate.com/account/api-tokens
echo.
echo App URL: https://web-wit-up.vercel.app
echo ========================================
pause

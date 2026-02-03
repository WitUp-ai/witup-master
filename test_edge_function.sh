#!/bin/bash

# Test autonomo dell'Edge Function dopo deploy
# Simula l'intero flusso: upload → DB insert → Edge Function call

set -e

SUPABASE_URL="https://rnfzzmfpykbavuirypfz.supabase.co"
ANON_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJuZnp6bWZweWtiYXZ1aXJ5cGZ6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njk1MjI4MDUsImV4cCI6MjA4NTA5ODgwNX0.H4sV8bYrXz0YVbdC25TSg22iYnMaFbnyRejyEwG2O74"
SERVICE_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJuZnp6bWZweWtiYXZ1aXJ5cGZ6Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2OTUyMjgwNSwiZXhwIjoyMDg1MDk4ODA1fQ.fT4BvxOGWwY8RjL1HAhNxNryjJO37rw1YUjmFndKCII"

echo "=== Edge Function Test Post-Deploy ==="
echo ""

# Get user ID from auth (use service key)
USER_ID="d4fd4c71-b11c-4222-a989-ec6f95791175"  # User from previous tests

# Create a test drawing record
echo "1. Creating test drawing record..."
DRAWING_ID=$(curl -s -X POST "$SUPABASE_URL/rest/v1/drawings" \
  -H "apikey: $ANON_KEY" \
  -H "Authorization: Bearer $SERVICE_KEY" \
  -H "Content-Type: application/json" \
  -H "Prefer: return=representation" \
  -d "{
    \"user_id\": \"$USER_ID\",
    \"original_image_url\": \"$USER_ID/test_drawing.jpg\",
    \"title\": \"Test Drawing for Edge Function\",
    \"model_status\": \"pending\"
  }" | grep -o '"id":"[^"]*"' | cut -d'"' -f4)

if [ -z "$DRAWING_ID" ]; then
  echo "❌ Failed to create drawing record"
  exit 1
fi

echo "✅ Drawing created: $DRAWING_ID"
echo ""

# Call Edge Function
echo "2. Calling Edge Function..."
echo "   URL: $SUPABASE_URL/functions/v1/process-drawing"
echo "   Drawing ID: $DRAWING_ID"
echo ""

RESPONSE=$(curl -s -X POST "$SUPABASE_URL/functions/v1/process-drawing" \
  -H "Authorization: Bearer $ANON_KEY" \
  -H "Content-Type: application/json" \
  -d "{
    \"drawing_id\": \"$DRAWING_ID\",
    \"user_id\": \"$USER_ID\"
  }")

echo "3. Response:"
echo "$RESPONSE" | head -c 500
echo ""
echo ""

# Check for success
if echo "$RESPONSE" | grep -q '"success":true'; then
  echo "✅ Edge Function SUCCESS"

  # Check for processed_image_url
  if echo "$RESPONSE" | grep -q '"processed_image_url"'; then
    echo "✅ processed_image_url present"
  else
    echo "⚠️  processed_image_url MISSING (API might have failed)"
  fi

  # Check for concept_url
  if echo "$RESPONSE" | grep -q '"concept_url"'; then
    echo "✅ concept_url present"
  else
    echo "⚠️  concept_url MISSING"
  fi
else
  echo "❌ Edge Function FAILED"
  echo "$RESPONSE"
  exit 1
fi

echo ""
echo "=== Test Complete ==="

import requests
import base64
import os
from dotenv import load_dotenv

# Load env vars
load_dotenv()

# Configuration
SUPABASE_URL = "https://rnfzzmfpykbavuirypfz.supabase.co"
ANON_KEY = os.getenv("NEXT_PUBLIC_SUPABASE_ANON_KEY")
FUNCTION_URL = f"{SUPABASE_URL}/functions/v1/upload-drawing"

# Login to get JWT
def login():
    url = f"{SUPABASE_URL}/auth/v1/token?grant_type=password"
    headers = {"apikey": ANON_KEY, "Content-Type": "application/json"}
    data = {"email": "test@witup.ai", "password": "password123"}
    
    response = requests.post(url, json=data, headers=headers)
    if response.status_code != 200:
        print(f"Login failed: {response.text}")
        return None
    return response.json()["access_token"]

# Upload test
def test_upload(token):
    # Create dummy image
    image_data = b"fake_image_data"
    image_base64 = base64.b64encode(image_data).decode("utf-8")
    
    payload = {
        "image_base64": image_base64,
        "file_name": "test_upload_edge.jpg",
        "content_type": "image/jpeg"
    }
    
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json"
    }
    
    print(f"Testing upload to {FUNCTION_URL}...")
    response = requests.post(FUNCTION_URL, json=payload, headers=headers)
    
    print(f"Status: {response.status_code}")
    print(f"Response: {response.text}")

if __name__ == "__main__":
    if not ANON_KEY:
        # Fallback if env not loaded
        ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJuZnp6bWZweWtiYXZ1aXJ5cGZ6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njk1MjI4MDUsImV4cCI6MjA4NTA5ODgwNX0.H4sV8bYrXz0YVbdC25TSg22iYnMaFbnyRejyEwG2O74"
        
    token = login()
    if token:
        test_upload(token)

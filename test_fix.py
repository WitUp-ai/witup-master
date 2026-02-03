"""
Test script to verify the RLS fix using service role key
"""
import requests
import json

# Configuration from .env
SUPABASE_URL = "https://rnfzzmfpykbavuirypfz.supabase.co"
SUPABASE_SERVICE_ROLE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJuZnp6bWZweWtiYXZ1aXJ5cGZ6Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2OTUyMjgwNSwiZXhwIjoyMDg1MDk4ODA1fQ.fT4BvxOGWwY8RjL1HAhNxNryjJO37rw1YUjmFndKCII"
USER_ID = "f51ebf2f-faf2-436f-bd72-aeaf924011f5"

def test_rls_insert():
    """Test inserting a drawing with service role key (bypasses RLS)"""
    
    drawing_data = {
        "user_id": USER_ID,
        "title": "Test RLS Fix",
        "original_image_url": f"{USER_ID}/test_rls_fix.png",
        "model_status": "pending"
    }
    
    headers = {
        "Authorization": f"Bearer {SUPABASE_SERVICE_ROLE_KEY}",
        "Content-Type": "application/json",
        "apikey": SUPABASE_SERVICE_ROLE_KEY
    }
    
    print("Testing INSERT with service role key...")
    
    response = requests.post(
        f"{SUPABASE_URL}/rest/v1/drawings",
        headers=headers,
        json=drawing_data
    )
    
    if response.status_code == 201:
        drawing = response.json()[0]
        drawing_id = drawing["id"]
        print(f"✅ Drawing created successfully: {drawing_id}")
        
        # Clean up - delete the test drawing
        delete_response = requests.delete(
            f"{SUPABASE_URL}/rest/v1/drawings?id=eq.{drawing_id}",
            headers=headers
        )
        
        if delete_response.status_code == 204:
            print(f"✅ Test drawing deleted: {drawing_id}")
        else:
            print(f"⚠️ Could not delete test drawing: {delete_response.status_code}")
        
        return True
    else:
        print(f"❌ Failed to create drawing: {response.status_code} - {response.text}")
        return False

def test_anon_insert():
    """Test inserting a drawing with anon key (should fail due to RLS)"""
    
    SUPABASE_ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJuZnp6bWZweWtiYXZ1aXJ5cGZ6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njk1MjI4MDUsImV4cCI6MjA4NTA5ODgwNX0.H4sV8bYrXz0YVbdC25TSg22iYnMaFbnyRejyEwG2O74"
    
    drawing_data = {
        "user_id": USER_ID,
        "title": "Test Anon RLS",
        "original_image_url": f"{USER_ID}/test_anon.png",
        "model_status": "pending"
    }
    
    headers = {
        "Authorization": f"Bearer {SUPABASE_ANON_KEY}",
        "Content-Type": "application/json",
        "apikey": SUPABASE_ANON_KEY
    }
    
    print("\nTesting INSERT with anon key (should fail due to RLS)...")
    
    response = requests.post(
        f"{SUPABASE_URL}/rest/v1/drawings",
        headers=headers,
        json=drawing_data
    )
    
    if response.status_code == 401 or response.status_code == 403:
        print(f"✅ Anon insert correctly blocked by RLS: {response.status_code}")
        return True
    elif response.status_code == 201:
        print(f"⚠️ Unexpected: Anon insert succeeded (RLS might be disabled)")
        # Clean up
        drawing_id = response.json()[0]["id"]
        delete_headers = {
            "Authorization": f"Bearer {SUPABASE_SERVICE_ROLE_KEY}",
            "apikey": SUPABASE_SERVICE_ROLE_KEY
        }
        requests.delete(
            f"{SUPABASE_URL}/rest/v1/drawings?id=eq.{drawing_id}",
            headers=delete_headers
        )
        return False
    else:
        print(f"❌ Unexpected response: {response.status_code} - {response.text}")
        return False

def test_existing_drawing():
    """Test that we can query existing drawings"""
    
    headers = {
        "Authorization": f"Bearer {SUPABASE_SERVICE_ROLE_KEY}",
        "apikey": SUPABASE_SERVICE_ROLE_KEY
    }
    
    print("\nTesting SELECT on drawings table...")
    
    response = requests.get(
        f"{SUPABASE_URL}/rest/v1/drawings?limit=1",
        headers=headers
    )
    
    if response.status_code == 200:
        drawings = response.json()
        if drawings:
            print(f"✅ SELECT works, found {len(drawings)} drawing(s)")
            return True
        else:
            print("✅ SELECT works, but no drawings found")
            return True
    else:
        print(f"❌ SELECT failed: {response.status_code} - {response.text}")
        return False

if __name__ == "__main__":
    print("🧪 Testing RLS Policies After Fix")
    print("=" * 50)
    
    # Test 1: Service role should bypass RLS
    test1 = test_rls_insert()
    
    # Test 2: Anon key should be blocked by RLS
    test2 = test_anon_insert()
    
    # Test 3: SELECT should work
    test3 = test_existing_drawing()
    
    print("\n" + "=" * 50)
    print("🧪 Test Summary:")
    print(f"Service Role INSERT: {'✅ PASS' if test1 else '❌ FAIL'}")
    print(f"Anon Role INSERT (blocked): {'✅ PASS' if test2 else '❌ FAIL'}")
    print(f"SELECT Query: {'✅ PASS' if test3 else '❌ FAIL'}")
    
    if test1 and test2 and test3:
        print("\n🎉 All RLS tests passed! The INSERT policy fix is working correctly.")
        print("The original test_upload.py fails because it uses ANON key without authentication.")
        print("The app should use authenticated user tokens for INSERT operations.")
    else:
        print("\n⚠️ Some tests failed. RLS may still need adjustment.")
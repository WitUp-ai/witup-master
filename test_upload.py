"""
Test script for uploading an image to Supabase Storage
and processing it through the AI pipeline
"""

import requests
import json
import base64
from pathlib import Path

# Configuration
SUPABASE_URL = "https://rnfzzmfpykbavuirypfz.supabase.co"
SUPABASE_ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJuZnp6bWZweWtiYXZ1aXJ5cGZ6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njk1MjI4MDUsImV4cCI6MjA4NTA5ODgwNX0.H4sV8bYrXz0YVbdC25TSg22iYnMaFbnyRejyEwG2O74"
USER_ID = "f51ebf2f-faf2-436f-bd72-aeaf924011f5"

def test_image_upload():
    """Test uploading an image to Supabase Storage"""
    
    # Create a simple test image (1x1 pixel PNG)
    test_image_data = base64.b64decode("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==")
    
    # First, create a drawing record
    drawing_data = {
        "user_id": USER_ID,
        "title": "Test Upload Image",
        "original_image_url": f"{USER_ID}/test_upload.png",
        "model_status": "pending"
    }
    
    # Insert drawing record
    headers = {
        "Authorization": f"Bearer {SUPABASE_ANON_KEY}",
        "Content-Type": "application/json",
        "apikey": SUPABASE_ANON_KEY
    }
    
    response = requests.post(
        f"{SUPABASE_URL}/rest/v1/drawings",
        headers=headers,
        json=drawing_data
    )
    
    if response.status_code == 201:
        drawing = response.json()[0]
        drawing_id = drawing["id"]
        print(f"✅ Drawing created: {drawing_id}")
        
        # Now upload the image to storage
        upload_url = f"{SUPABASE_URL}/storage/v1/object/drawings-original/{USER_ID}/test_upload.png"
        
        upload_headers = {
            "Authorization": f"Bearer {SUPABASE_ANON_KEY}",
            "Content-Type": "image/png"
        }
        
        upload_response = requests.post(
            upload_url,
            headers=upload_headers,
            data=test_image_data
        )
        
        if upload_response.status_code == 200:
            print("✅ Image uploaded to storage")
            
            # Update drawing with correct URL
            update_data = {
                "original_image_url": f"{USER_ID}/test_upload.png"
            }
            
            update_response = requests.patch(
                f"{SUPABASE_URL}/rest/v1/drawings?id=eq.{drawing_id}",
                headers=headers,
                json=update_data
            )
            
            if update_response.status_code == 204:
                print("✅ Drawing updated with image URL")
                
                # Now trigger AI processing
                process_data = {
                    "drawing_id": drawing_id,
                    "user_id": USER_ID
                }
                
                process_response = requests.post(
                    f"{SUPABASE_URL}/functions/v1/process-drawing",
                    headers=headers,
                    json=process_data
                )
                
                if process_response.status_code == 200:
                    result = process_response.json()
                    print(f"✅ AI Processing triggered: {result}")
                    
                    # Check processing status
                    check_response = requests.get(
                        f"{SUPABASE_URL}/rest/v1/drawings?id=eq.{drawing_id}",
                        headers=headers
                    )
                    
                    if check_response.status_code == 200:
                        updated_drawing = check_response.json()[0]
                        print(f"📊 Final drawing status: {updated_drawing['model_status']}")
                        print(f"📊 Thumbnail URL: {updated_drawing.get('thumbnail_url')}")
                        print(f"📊 3D Model URL: {updated_drawing.get('model_3d_url')}")
                        print(f"📊 Processed Image URL: {updated_drawing.get('processed_image_url')}")
                        
                        return {
                            "success": True,
                            "drawing_id": drawing_id,
                            "processing_result": result,
                            "final_status": updated_drawing
                        }
                    else:
                        print(f"❌ Failed to check status: {check_response.status_code}")
                else:
                    print(f"❌ Failed to trigger processing: {process_response.status_code} - {process_response.text}")
            else:
                print(f"❌ Failed to update drawing: {update_response.status_code}")
        else:
            print(f"❌ Failed to upload image: {upload_response.status_code} - {upload_response.text}")
    else:
        print(f"❌ Failed to create drawing: {response.status_code} - {response.text}")
    
    return {"success": False}

def test_direct_processing():
    """Test direct processing of existing drawing"""
    
    # Use the drawing we already processed earlier
    drawing_id = "49ea9197-2692-4576-b93a-95306700326d"
    
    headers = {
        "Authorization": f"Bearer {SUPABASE_ANON_KEY}",
        "Content-Type": "application/json"
    }
    
    process_data = {
        "drawing_id": drawing_id,
        "user_id": USER_ID
    }
    
    print(f"🔄 Testing direct processing for drawing: {drawing_id}")
    
    response = requests.post(
        f"{SUPABASE_URL}/functions/v1/process-drawing",
        headers=headers,
        json=process_data
    )
    
    if response.status_code == 200:
        result = response.json()
        print(f"✅ Processing result: {json.dumps(result, indent=2)}")
        return result
    else:
        print(f"❌ Processing failed: {response.status_code} - {response.text}")
        return None

if __name__ == "__main__":
    print("🧪 Starting Draw2Toy Integration Tests")
    print("=" * 50)
    
    # Test 1: Direct processing of existing drawing
    print("\n1. Testing direct processing...")
    result1 = test_direct_processing()
    
    # Test 2: Full upload + processing pipeline
    print("\n2. Testing full upload pipeline...")
    result2 = test_image_upload()
    
    print("\n" + "=" * 50)
    print("🧪 Test Summary:")
    print(f"Direct Processing: {'✅ Success' if result1 else '❌ Failed'}")
    print(f"Full Pipeline: {'✅ Success' if result2 and result2['success'] else '❌ Failed'}")
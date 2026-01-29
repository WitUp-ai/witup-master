"""
Draw2Toy AI Pipeline Microservice
Transforms children's drawings into 3D models

Architecture: FastAPI + Replicate API + Supabase Storage
"""

import os
import asyncio
import httpx
import replicate
import structlog
from datetime import datetime
from typing import Optional
from io import BytesIO
from PIL import Image

from fastapi import FastAPI, HTTPException, BackgroundTasks, Header
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
from pydantic_settings import BaseSettings
from supabase import create_client, Client

# Configure logging
structlog.configure(
    processors=[
        structlog.processors.TimeStamper(fmt="iso"),
        structlog.processors.JSONRenderer()
    ]
)
log = structlog.get_logger()

# Settings
class Settings(BaseSettings):
    # Supabase
    supabase_url: str = ""
    supabase_service_role_key: str = ""

    # Replicate AI
    replicate_api_token: str = "YOUR_REPLICATE_API_TOKEN"

    # Processing options
    max_image_size: int = 1920
    processing_timeout: int = 120

    class Config:
        env_file = ".env"

settings = Settings()

# Initialize clients
supabase: Optional[Client] = None
if settings.supabase_url and settings.supabase_service_role_key:
    supabase = create_client(settings.supabase_url, settings.supabase_service_role_key)

# FastAPI app
app = FastAPI(
    title="Draw2Toy AI Pipeline",
    description="Transforms drawings into 3D models",
    version="1.0.0"
)

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Request/Response Models
class ProcessRequest(BaseModel):
    drawing_id: str = Field(..., description="UUID of the drawing to process")
    user_id: str = Field(..., description="UUID of the user")
    style: str = Field(default="cartoon", description="Style: cartoon, realistic, clay")
    quality: str = Field(default="standard", description="Quality: fast, standard, high")

class ProcessResponse(BaseModel):
    success: bool
    drawing_id: str
    status: str
    processed_image_url: Optional[str] = None
    model_3d_url: Optional[str] = None
    thumbnail_url: Optional[str] = None
    processing_time_ms: Optional[int] = None
    error: Optional[str] = None

class HealthResponse(BaseModel):
    status: str
    timestamp: str
    services: dict

# Routes
@app.get("/health", response_model=HealthResponse)
async def health_check():
    """Health check endpoint"""
    services = {
        "supabase": supabase is not None,
        "replicate": bool(settings.replicate_api_token),
    }
    return HealthResponse(
        status="healthy" if all(services.values()) else "degraded",
        timestamp=datetime.utcnow().isoformat(),
        services=services
    )

@app.post("/ai/process", response_model=ProcessResponse)
async def process_drawing(
    request: ProcessRequest,
    background_tasks: BackgroundTasks,
    authorization: str = Header(None)
):
    """
    Process a drawing through the AI pipeline:
    1. Download original image
    2. Remove background (Segment Anything)
    3. Generate 3D model (TripoSR)
    4. Upload results to storage
    5. Update database
    """
    start_time = datetime.utcnow()

    log.info("process_request", drawing_id=request.drawing_id, user_id=request.user_id)

    if not supabase:
        raise HTTPException(status_code=503, detail="Supabase not configured")

    try:
        # Update status to processing
        await update_drawing_status(request.drawing_id, "processing")

        # Get drawing info
        drawing = supabase.table("drawings").select("*").eq("id", request.drawing_id).single().execute()
        if not drawing.data:
            raise HTTPException(status_code=404, detail="Drawing not found")

        original_path = drawing.data.get("original_image_url")
        if not original_path:
            raise HTTPException(status_code=400, detail="No original image found")

        # Download original image
        log.info("downloading_image", path=original_path)
        image_bytes = await download_from_storage("drawings-original", original_path)

        # Process image
        processed_url = None
        model_3d_url = None
        thumbnail_url = None

        # Step 1: Background Removal
        if settings.replicate_api_token:
            log.info("removing_background", drawing_id=request.drawing_id)
            processed_bytes = await remove_background(image_bytes)
            if processed_bytes:
                processed_path = f"{request.user_id}/processed_{request.drawing_id}.png"
                processed_url = await upload_to_storage(
                    "drawings-processed",
                    processed_path,
                    processed_bytes,
                    "image/png"
                )
                log.info("background_removed", url=processed_url)

        # Step 2: Generate 3D Model
        if settings.replicate_api_token and processed_bytes:
            log.info("generating_3d", drawing_id=request.drawing_id)
            model_bytes = await generate_3d_model(processed_bytes or image_bytes, request.style)
            if model_bytes:
                model_path = f"{request.drawing_id}/model.glb"
                model_3d_url = await upload_to_storage(
                    "models-3d",
                    model_path,
                    model_bytes,
                    "model/gltf-binary"
                )
                log.info("3d_generated", url=model_3d_url)

                # Generate thumbnail
                thumbnail_bytes = await generate_thumbnail(processed_bytes or image_bytes)
                if thumbnail_bytes:
                    thumb_path = f"{request.drawing_id}/thumbnail.png"
                    thumbnail_url = await upload_to_storage(
                        "models-thumbnails",
                        thumb_path,
                        thumbnail_bytes,
                        "image/png"
                    )

        # Calculate processing time
        end_time = datetime.utcnow()
        processing_time_ms = int((end_time - start_time).total_seconds() * 1000)

        # Update database with results
        update_data = {
            "model_status": "completed",
            "processing_completed_at": datetime.utcnow().isoformat(),
        }
        if processed_url:
            update_data["processed_image_url"] = processed_url
        if model_3d_url:
            update_data["model_3d_url"] = model_3d_url
        if thumbnail_url:
            update_data["thumbnail_url"] = thumbnail_url

        supabase.table("drawings").update(update_data).eq("id", request.drawing_id).execute()

        # Create notification
        try:
            supabase.table("notifications").insert({
                "user_id": request.user_id,
                "type": "drawing_processed",
                "title": "Your drawing is ready!",
                "message": "Your drawing has been transformed into 3D!",
                "action_url": f"/viewer/{request.drawing_id}",
                "metadata": {"drawing_id": request.drawing_id}
            }).execute()
        except Exception as e:
            log.warning("notification_failed", error=str(e))

        log.info("processing_complete",
                 drawing_id=request.drawing_id,
                 processing_time_ms=processing_time_ms)

        return ProcessResponse(
            success=True,
            drawing_id=request.drawing_id,
            status="completed",
            processed_image_url=processed_url,
            model_3d_url=model_3d_url,
            thumbnail_url=thumbnail_url,
            processing_time_ms=processing_time_ms
        )

    except Exception as e:
        log.error("processing_failed", drawing_id=request.drawing_id, error=str(e))

        # Update status to failed
        await update_drawing_status(request.drawing_id, "failed", str(e))

        return ProcessResponse(
            success=False,
            drawing_id=request.drawing_id,
            status="failed",
            error=str(e)
        )

async def update_drawing_status(drawing_id: str, status: str, error: str = None):
    """Update drawing processing status in database"""
    if not supabase:
        return

    update_data = {"model_status": status}
    if status == "processing":
        update_data["processing_started_at"] = datetime.utcnow().isoformat()
    if error:
        update_data["processing_error"] = error

    supabase.table("drawings").update(update_data).eq("id", drawing_id).execute()

async def download_from_storage(bucket: str, path: str) -> bytes:
    """Download file from Supabase storage"""
    if not supabase:
        raise Exception("Supabase not configured")

    response = supabase.storage.from_(bucket).download(path)
    return response

async def upload_to_storage(bucket: str, path: str, data: bytes, content_type: str) -> str:
    """Upload file to Supabase storage and return public URL"""
    if not supabase:
        raise Exception("Supabase not configured")

    # Upload file
    supabase.storage.from_(bucket).upload(
        path,
        data,
        {"content-type": content_type, "upsert": "true"}
    )

    # Get public URL
    url = supabase.storage.from_(bucket).get_public_url(path)
    return url

async def remove_background(image_bytes: bytes) -> Optional[bytes]:
    """Remove background using Replicate's SAM model"""
    if not settings.replicate_api_token:
        return None

    try:
        # Use rembg model on Replicate
        output = replicate.run(
            "cjwbw/rembg:fb8af171cfa1616ddcf1242c093f9c46bcada5ad4cf6f2fbe8b81b330ec5c003",
            input={"image": f"data:image/png;base64,{image_bytes.hex()}"}
        )

        # Download result
        async with httpx.AsyncClient() as client:
            response = await client.get(output)
            return response.content

    except Exception as e:
        log.warning("background_removal_failed", error=str(e))
        # Return original if background removal fails
        return image_bytes

async def generate_3d_model(image_bytes: bytes, style: str = "cartoon") -> Optional[bytes]:
    """Generate 3D model using Replicate's TripoSR or similar"""
    if not settings.replicate_api_token:
        return None

    try:
        # Use TripoSR for image-to-3D
        # This model generates 3D from single image
        import base64
        image_b64 = base64.b64encode(image_bytes).decode()

        output = replicate.run(
            "camenduru/triposr:ecd9d615e9efb7fd2a5e26bb51fc53e652b61ff7f5aac6bca7e16c2e4edba5f5",
            input={
                "image": f"data:image/png;base64,{image_b64}",
                "mc_resolution": 256,
                "foreground_ratio": 0.9
            }
        )

        # Output is a URL to the GLB file
        if output:
            async with httpx.AsyncClient() as client:
                response = await client.get(str(output))
                return response.content

    except Exception as e:
        log.warning("3d_generation_failed", error=str(e))

    return None

async def generate_thumbnail(image_bytes: bytes) -> Optional[bytes]:
    """Generate thumbnail from image"""
    try:
        img = Image.open(BytesIO(image_bytes))
        img.thumbnail((256, 256), Image.Resampling.LANCZOS)

        output = BytesIO()
        img.save(output, format="PNG", optimize=True)
        return output.getvalue()

    except Exception as e:
        log.warning("thumbnail_generation_failed", error=str(e))
        return None

# Run with: uvicorn main:app --host 0.0.0.0 --port 8080
if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8080)

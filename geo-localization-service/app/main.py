from fastapi import FastAPI
from .routes import geo
from .middleware import setup_middleware
from .db import init as init_db
from dotenv import load_dotenv
import os
import asyncio
import logging
import uuid

load_dotenv()

app = FastAPI(title="Geo-Localization Service API")

setup_middleware(app)
app.include_router(geo.router)
logger = logging.getLogger("uvicorn")

@app.on_event("startup")
async def on_startup():
    await init_db()
    print("Database connected")
    asyncio.create_task(poll_localize_queue())

async def poll_localize_queue():
    from .utils.queue_client import poll_sqs_queue, publish_to_queue
    import json
    from .utils.google_client import geocode_address
    
    localize_queue_url = os.getenv("LOCALIZE_QUEUE_URL")
    lookup_queue_url = os.getenv("LOOKUP_QUEUE_URL")
    
    if not localize_queue_url or not lookup_queue_url:
        print("Queue URLs not configured. Polling disabled.")
        return
    
    while True:
        try:
            messages = await poll_sqs_queue(localize_queue_url)

            logger.info("Messages found: %s", messages)
            for message in messages:
                try:
                    logger.info("Message is: $s", message)
                    body = json.loads(message["Body"])
                    address = body.get("address")
                    user_id = body.get("user_id")
                    request_id = str(uuid.uuid4())
                    
                    if not address:
                        print("Address not found in message, skipping")
                        continue
                    logger.info("Address found")
                    result = await geocode_address(address)
                    
                    await publish_to_queue(
                        lookup_queue_url,
                        {
                            "user_id": user_id,
                            "request_id": request_id,
                            "address": address,
                            "coordinates": result["coordinates"],
                            "formatted_address": result["formatted_address"],
                            "cuisine": body.get("cuisine")
                        }
                    )
                    
                    print(f"Processed geocoding request for '{address}'")
                except Exception as e:
                    print(f"Error processing message: {str(e)}")
            
            await asyncio.sleep(10)
        except Exception as e:
            print(f"Error polling queue: {str(e)}")
            await asyncio.sleep(10)

@app.get("/")
def read_root():
    return {"message": "Geo-Localization Service API Triggered"}
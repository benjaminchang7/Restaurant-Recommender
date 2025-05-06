from fastapi import FastAPI
from .routes import restaurants
from .middleware import setup_middleware
from .db import init as init_db
from dotenv import load_dotenv
import os
import asyncio
import logging

load_dotenv()

app = FastAPI(title="Restaurant Lookup Service API")

setup_middleware(app)
app.include_router(restaurants.router)
logger = logging.getLogger("uvicorn")

@app.on_event("startup")
async def on_startup():
    await init_db()
    print("Database connected")
    asyncio.create_task(poll_lookup_queue())

async def poll_lookup_queue():
    from .utils.queue_client import poll_sqs_queue, publish_to_queue
    import json
    from .utils.google_client import find_restaurants
    
    lookup_queue_url = os.getenv("LOOKUP_QUEUE_URL")
    recommend_queue_url = os.getenv("RECOMMEND_QUEUE_URL")
    
    if not lookup_queue_url or not recommend_queue_url:
        print("Queue URLs not configured. Polling disabled.")
        return
    
    while True:
        try:
            messages = await poll_sqs_queue(lookup_queue_url)
            logger.info("Messages found: %s", messages)
            for message in messages:
                try:
                    logger.info("Message is: $s", message)
                    body = json.loads(message["Body"])
                    request_id = body.get("request_id")
                    coordinates = body.get("coordinates")
                    address = body.get("address")
                    formatted_address = body.get("formatted_address")
                    cuisine = body.get("cuisine")
                    user_id = body.get("user_id")
                    
                    if not coordinates or not ("lat" in coordinates and "lng" in coordinates):
                        print("Coordinates not found in message - skipping")
                        continue
                    logger.info("Coordinates found")
                    result = await find_restaurants(
                        lat=coordinates["lat"],
                        lng=coordinates["lng"],
                        cuisine=cuisine
                    )
                    logger.info("Publishing to queue")
                    await publish_to_queue(
                        recommend_queue_url,
                        {
                            "user_id": user_id,
                            "request_id": request_id,
                            "address": address,
                            "formatted_address": formatted_address,
                            "coordinates": coordinates,
                            "restaurants": result["restaurants"],
                            "total_results": result["total_results"]
                        }
                    )
                    logger.info("published to queue")
                    print(f"Processed restaurant lookup for coordinates: {coordinates}")
                except Exception as e:
                    print(f"Error processing message: {str(e)}")
            
            await asyncio.sleep(10)
        except Exception as e:
            print(f"Error polling queue: {str(e)}")
            await asyncio.sleep(10)

@app.get("/")
def read_root():
    return {"message": "Restaurant Lookup Service API Triggered"}

import os, json
import httpx
from fastapi import HTTPException
from dotenv import load_dotenv
from ..models import CachedLocation
from ..db import AsyncSessionLocal

load_dotenv()
GOOGLE_API_KEY = os.getenv("GOOGLE_API_KEY")
if not GOOGLE_API_KEY:
    raise RuntimeError("GOOGLE_API_KEY environment variable is not set")

GEOCODING_BASE_URL = "https://maps.googleapis.com/maps/api/geocode/json"

async def geocode_address(address: str) -> dict:
    async with AsyncSessionLocal() as session:
        cached = await session.get(CachedLocation, address)
    if cached:
        return {
            "address": cached.address,
            "formatted_address": cached.formatted_address,
            "coordinates": {"lat": cached.lat, "lng": cached.lng}
        }

    params = {"address": address, "key": GOOGLE_API_KEY}
    async with httpx.AsyncClient() as client:
        resp = await client.get(GEOCODING_BASE_URL, params=params)
        data = resp.json()

    if data["status"] != "OK":
        raise HTTPException(400, f"Geocoding API error: {data.get('error_message', data['status'])}")
    if not data["results"]:
        raise HTTPException(404, "Address not found")

    result = data["results"][0]
    loc = result["geometry"]["location"]
    formatted = result["formatted_address"]

    new = CachedLocation(
        address=address,
        formatted_address=formatted,
        lat=loc["lat"],
        lng=loc["lng"]
    )
    async with AsyncSessionLocal() as session:
        session.add(new)
        await session.commit()

    return {
        "address": address,
        "formatted_address": formatted,
        "coordinates": {"lat": loc["lat"], "lng": loc["lng"]}
    }
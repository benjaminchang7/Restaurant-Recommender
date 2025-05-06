import os
import json
from dotenv import load_dotenv
import httpx
from fastapi import HTTPException
from datetime import datetime, timedelta
from ..models import CachedRestaurantSearch, Restaurant, Coordinates
from ..db import AsyncSessionLocal
from sqlalchemy.dialects.postgresql import insert
from sqlalchemy import select

load_dotenv()
GOOGLE_API_KEY = os.getenv("GOOGLE_API_KEY")
if not GOOGLE_API_KEY:
    raise RuntimeError("GOOGLE_API_KEY environment variable is not set")

PLACES_BASE_URL = "https://maps.googleapis.com/maps/api/place/nearbysearch/json"

async def find_restaurants(
    lat: float,
    lng: float,
    radius: int = 1500,
    type: str = "restaurant",
    cuisine: str = None
) -> dict:
    coordinates = {"lat": lat, "lng": lng}
    coordinates_key = json.dumps(coordinates, sort_keys=True)

    async with AsyncSessionLocal() as session:
        stmt = await session.execute(
            select(CachedRestaurantSearch).where(
                CachedRestaurantSearch.coordinates_key == coordinates_key,
                CachedRestaurantSearch.radius == radius,
                CachedRestaurantSearch.expires_at > datetime.utcnow(),
                CachedRestaurantSearch.cuisine == cuisine
            )
        )
    cached = stmt.scalar_one_or_none()

    if cached:
        return {"restaurants": cached.restaurants, "total_results": len(cached.restaurants)}

    params = {
        "location": f"{lat},{lng}",
        "radius": radius,
        "type": type,
        "key": GOOGLE_API_KEY
    }
    if cuisine:
        params["keyword"] = cuisine

    async with httpx.AsyncClient() as client:
        response = await client.get(PLACES_BASE_URL, params=params)
        data = response.json()

    if data["status"] not in ("OK", "ZERO_RESULTS"):
        raise HTTPException(
            status_code=400,
            detail=f"Places API error: {data.get('error_message', data['status'])}"
        )

    restaurants = []
    restaurant_models = []
    for place in data.get("results", []):
        r = {
            "place_id": place["place_id"],
            "name": place["name"],
            "vicinity": place["vicinity"],
            "coordinates": {
                "lat": place["geometry"]["location"]["lat"],
                "lng": place["geometry"]["location"]["lng"]
            },
            "types": place.get("types", [])
        }
        if "rating" in place:
            r["rating"] = place["rating"]
        if "user_ratings_total" in place:
            r["user_ratings_total"] = place["user_ratings_total"]
        if "price_level" in place:
            r["price_level"] = place["price_level"]
        if "photos" in place:
            r["photos"] = [p["photo_reference"] for p in place["photos"]]
        restaurants.append(r)

        # Create a RestaurantModel instance for individual storage
        restaurant_model = Restaurant(
            place_id=place["place_id"],
            name=place["name"],
            vicinity=place["vicinity"],
            types=place.get("types", []),
            rating=place.get("rating"),
            user_ratings_total=place.get("user_ratings_total"),
            price_level=place.get("price_level"),
            photos=[p["photo_reference"] for p in place.get("photos", [])] if "photos" in place else None
        )

        # Create Coordinates object and link it to the restaurant
        coordinates_model = Coordinates(
            lat=place["geometry"]["location"]["lat"],
            lng=place["geometry"]["location"]["lng"],
            restaurant=restaurant_model
        )
        restaurant_models.append(restaurant_model)

    new_cache = CachedRestaurantSearch(
        coordinates_key=coordinates_key,
        coordinates=coordinates,
        radius=radius,
        cuisine=cuisine,
        restaurants=restaurants,
        expires_at=datetime.utcnow() + timedelta(hours=24)
    )
    async with AsyncSessionLocal() as session:
        session.add(new_cache)
        for restaurant in restaurant_models:
            # Add the restaurant (and coordinates will be added via cascade)
            session.add(restaurant)
        await session.commit()

    return {"restaurants": restaurants, "total_results": len(restaurants)}

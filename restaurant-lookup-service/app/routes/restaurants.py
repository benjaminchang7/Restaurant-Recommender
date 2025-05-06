from fastapi import APIRouter, HTTPException, Query
from fastapi.responses import JSONResponse
from ..models import RestaurantLookupRequest, RestaurantLookupResponse
from ..utils.google_client import find_restaurants

router = APIRouter(prefix="/restaurants", tags=["Restaurant Lookup"])

@router.post("/search", response_model=RestaurantLookupResponse)
async def search_restaurants(request: RestaurantLookupRequest):
    try:
        result = await find_restaurants(
            lat=request.lat,
            lng=request.lng,
            radius=request.radius,
            type=request.type,
            cuisine=request.cuisine
        )
        return JSONResponse(content=result, status_code=200)
    except HTTPException as e:
        raise e
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Restaurant lookup error: {str(e)}")

@router.get("/search", response_model=RestaurantLookupResponse)
async def search_restaurants_get(
    lat: float = Query(..., description="Latitude of the search center"),
    lng: float = Query(..., description="Longitude of the search center"),
    radius: int = Query(1500, description="Search radius in meters"),
    cuisine: str = Query(None, description="Optional cuisine type to filter by")
):
    try:
        result = await find_restaurants(
            lat=lat,
            lng=lng,
            radius=radius,
            cuisine=cuisine
        )
        return JSONResponse(content=result, status_code=200)
    except HTTPException as e:
        raise e
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Restaurant lookup error: {str(e)}")
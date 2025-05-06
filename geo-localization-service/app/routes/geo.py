from fastapi import APIRouter, HTTPException
from fastapi.responses import JSONResponse
from ..models import GeocodingRequest, GeocodingResponse
from ..utils.google_client import geocode_address

router = APIRouter(prefix="/geo", tags=["Geo-Localization"])

@router.post("/geocode", response_model=GeocodingResponse)
async def geocode(request: GeocodingRequest):
    try:
        result = await geocode_address(request.address)
        return JSONResponse(content=result, status_code=200)
    except HTTPException as e:
        raise e
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Geocoding error: {str(e)}")
from fastapi import APIRouter, Depends, HTTPException
from fastapi.security import OAuth2PasswordBearer
from app import auth
import httpx
import os


router = APIRouter()
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="users/login")

RECOMMENDATION_SERVICE_URL = "http://recommendation"

def get_current_token(token: str = Depends(oauth2_scheme)):
    # Optionally validate token here if needed
    if not auth.decode_access_token(token):
        raise HTTPException(status_code=401, detail="Invalid or expired token")
    return token

@router.get("/all")
async def get_my_recommendations(token: str = Depends(get_current_token)):
    try:
        async with httpx.AsyncClient() as client:
            response = await client.get(
                f"{RECOMMENDATION_SERVICE_URL}/recommendation/user-recommendations",
                headers={"Authorization": f"Bearer {token}"},
                timeout=5.0
            )
        if response.status_code != 200:
            raise HTTPException(status_code=response.status_code, detail=response.text)
        return response.json()
    except Exception as e:
        raise HTTPException(status_code=502, detail=f"Failed to fetch recommendations: {str(e)}")
    
from pydantic import BaseModel, Field
from typing import Dict
from datetime import datetime
from sqlalchemy import Column, String, Float, DateTime, func
from .db import Base

class Coordinates(BaseModel):
    lat: float
    lng: float

class GeocodingRequest(BaseModel):
    address: str

class GeocodingResponse(BaseModel):
    address: str
    coordinates: Coordinates
    formatted_address: str

class CachedLocation(Base):
    __tablename__ = "cached_locations"
    address = Column(String, primary_key=True, index=True)
    formatted_address = Column(String, nullable=False)
    lat = Column(Float, nullable=False)
    lng = Column(Float, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
from pydantic import BaseModel
from typing import Dict, List, Optional
from datetime import datetime
from sqlalchemy import Column, String, Integer, Float, JSON, ARRAY, DateTime, func, PrimaryKeyConstraint, ForeignKey
from .db import Base
from sqlalchemy.orm import relationship

class Coordinates(Base):
    __tablename__ = "coordinates"
    
    id = Column(Integer, primary_key=True, index=True)
    lat = Column(Float, nullable=False)
    lng = Column(Float, nullable=False)
    
    # Relationship (one-to-one) with Restaurant
    restaurant_id = Column(Integer, ForeignKey("restaurants.id", ondelete="CASCADE"), unique=True)
    restaurant = relationship("Restaurant", back_populates="coordinates")

class Restaurant(Base):
    __tablename__ = "restaurants"
    
    id = Column(Integer, primary_key=True, index=True)
    place_id = Column(String, unique=True, index=True)
    name = Column(String, nullable=False)
    vicinity = Column(String, nullable=False)
    rating = Column(Float, nullable=True)
    user_ratings_total = Column(Integer, nullable=True)
    price_level = Column(Integer, nullable=True)
    types = Column(ARRAY(String), nullable=False)
    photos = Column(ARRAY(String), nullable=True)

    coordinates = relationship("Coordinates", uselist=False, back_populates="restaurant", cascade="all, delete-orphan")
    created_at = Column(DateTime, default=datetime.now())
    updated_at = Column(DateTime, default=datetime.now(), onupdate=datetime.now())

class CoordinatesMDB(BaseModel):
    lat: float
    lng: float

class RestaurantMDB(BaseModel):
    place_id: str
    name: str
    vicinity: str
    rating: Optional[float] = None
    user_ratings_total: Optional[int] = None
    price_level: Optional[int] = None
    types: List[str]
    coordinates: CoordinatesMDB
    photos: Optional[List[str]] = None

class RestaurantLookupRequest(BaseModel):
    lat: float
    lng: float
    radius: int = 1500
    type: str = "restaurant"
    cuisine: Optional[str] = None

class RestaurantLookupResponse(BaseModel):
    restaurants: List[RestaurantMDB]
    total_results: int

class CachedRestaurantSearch(Base):
    __tablename__ = "cached_restaurant_searches"

    coordinates_key = Column(String, nullable=False)
    coordinates = Column(JSON, nullable=False)

    radius = Column(Integer, nullable=False)
    cuisine = Column(String, nullable=True)

    restaurants = Column(JSON, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    expires_at = Column(DateTime(timezone=True), nullable=False)

    __table_args__ = (
        PrimaryKeyConstraint("coordinates_key", "radius", "cuisine"),
    )

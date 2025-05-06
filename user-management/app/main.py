import os
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.routers import users, preferences, ratings, recommendation
from app.database import Base, engine
import logging
from sqlalchemy import text

logger = logging.getLogger("uvicorn")

Base.metadata.create_all(bind=engine)

app = FastAPI(title="User Management Service")

@app.get("/")
def health_check():
    return {"status": "ok"}

frontend_origin = os.environ.get("FRONTEND_ORIGIN", "http://localhost:3000")
origins = [frontend_origin]

logger.info(f"[DEBUG] FRONTEND_ORIGIN from env: {frontend_origin}")
logger.info(f"[DEBUG] CORS allow_origins: {origins}")

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(users.router, prefix="/users", tags=["Users"])
app.include_router(preferences.router, prefix="/preferences", tags=["Preferences"])
app.include_router(ratings.router, prefix="/ratings", tags=["Ratings"])
app.include_router(recommendation.router, prefix="/recommendations", tags=["Recommendations"])
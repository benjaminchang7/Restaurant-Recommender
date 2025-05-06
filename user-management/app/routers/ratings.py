from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app import schemas, crud, auth, database
from fastapi.security import OAuth2PasswordBearer

router = APIRouter()
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="users/login")


def get_current_user_email(token: str = Depends(oauth2_scheme)):
    payload = auth.decode_access_token(token)
    if payload is None:
        raise HTTPException(status_code=401, detail="Invalid or expired token")
    return payload["sub"]


@router.post("/", response_model=schemas.RatingOut)
def create_rating(
    rating: schemas.RatingCreate,
    db: Session = Depends(database.get_db),
    email: str = Depends(get_current_user_email),
):
    user = crud.get_user_by_email(db, email)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return crud.create_rating(db, user_id=user.id, rating=rating)
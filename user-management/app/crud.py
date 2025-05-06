from sqlalchemy.orm import Session
from app import models, schemas
from app.auth import get_password_hash, verify_password, create_access_token


def create_user(db: Session, user: schemas.UserCreate):
    hashed_pw = get_password_hash(user.password)
    db_user = models.User(email=user.email, hashed_password=hashed_pw)
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    return db_user


def authenticate_user(db: Session, email: str, password: str):
    user = db.query(models.User).filter(models.User.email == email).first()
    if not user or not verify_password(password, user.hashed_password):
        return None
    return user


def get_user_by_email(db: Session, email: str):
    return db.query(models.User).filter(models.User.email == email).first()


def create_preference(db: Session, user_id: int, pref: schemas.PreferenceCreate):
    db_pref = models.Preference(
        cuisine=pref.cuisine,
        location=pref.address,
        user_id=user_id
    )
    db.add(db_pref)
    db.commit()
    db.refresh(db_pref)
    return db_pref



def get_preferences(db: Session, user_id: int):
    return db.query(models.Preference).filter(models.Preference.user_id == user_id).all()


def create_rating(db: Session, user_id: int, rating: schemas.RatingCreate):
    db_rating = models.Rating(**rating.dict(), user_id=user_id)
    db.add(db_rating)
    db.commit()
    db.refresh(db_rating)
    return db_rating


def get_user_ratings(db: Session, user_id: int):
    return db.query(models.Rating).filter(models.Rating.user_id == user_id).all()

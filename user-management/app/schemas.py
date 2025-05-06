from pydantic import BaseModel, EmailStr
from typing import Optional


class UserCreate(BaseModel):
    email: EmailStr
    password: str


class UserLogin(BaseModel):
    email: EmailStr
    password: str


class UserOut(BaseModel):
    id: int
    email: EmailStr

    class Config:
        orm_mode = True


class PreferenceCreate(BaseModel):
    cuisine: str
    address: str

class PreferenceOut(BaseModel):
    id: int
    cuisine: str
    address: str
    user_id: int

    class Config:
        orm_mode = True

    @staticmethod
    def from_orm_with_address(pref):
        return PreferenceOut(
            id=pref.id,
            cuisine=pref.cuisine,
            address=pref.location,
            user_id=pref.user_id
        )

class RatingCreate(BaseModel):
    restaurant_id: str
    approved: bool


class RatingOut(RatingCreate):
    user_id: int

    class Config:
        orm_mode = True
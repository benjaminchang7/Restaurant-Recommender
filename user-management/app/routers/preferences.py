import os
import boto3
import json
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app import schemas, crud, auth, database
from fastapi.security import OAuth2PasswordBearer
import logging

logger = logging.getLogger("uvicorn")
router = APIRouter()
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="users/login")
sqs_client = boto3.client("sqs", region_name=os.environ["AWS_REGION"])
LOCALIZE_QUEUE_URL = os.environ["LOCALIZE_QUEUE_URL"]


def get_current_user_email(token: str = Depends(oauth2_scheme)):
    payload = auth.decode_access_token(token)
    if payload is None:
        raise HTTPException(status_code=401, detail="Invalid or expired token")
    return payload["sub"]


@router.post("/", response_model=schemas.PreferenceOut)
def create_preference(
    pref: schemas.PreferenceCreate,
    db: Session = Depends(database.get_db),
    email: str = Depends(get_current_user_email),
):
    logger.info("Creating preference for user: %s", email)
    user = crud.get_user_by_email(db, email)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    preference = crud.create_preference(db, user_id=user.id, pref=pref)
    logger.info("Created preference: %s", preference)

    preference_out = schemas.PreferenceOut.from_orm_with_address(preference)

    message = {
        "user_id": user.id,
        "preference_id": preference.id,
        "cuisine": preference.cuisine,
        "address": preference_out.address
    }

    try:
        response = sqs_client.send_message(
            QueueUrl=LOCALIZE_QUEUE_URL,
            MessageBody=json.dumps(message)
        )
        message_id = response.get("MessageId")
        logger.info("Message sent to SQS. MessageId: %s", message_id)
    except Exception as e:
        logger.error("Failed to send SQS message: %s", str(e))
        raise HTTPException(status_code=500, detail="Failed to send preference to processing queue")

    return {
        **preference_out.dict(),
        "message_id": message_id
    }


@router.get("/", response_model=list[schemas.PreferenceOut])
def get_all_preferences(
    db: Session = Depends(database.get_db),
    email: str = Depends(get_current_user_email),
):
    user = crud.get_user_by_email(db, email)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    preferences = crud.get_preferences(db, user_id=user.id)
    
    return [schemas.PreferenceOut.from_orm_with_address(p) for p in preferences]

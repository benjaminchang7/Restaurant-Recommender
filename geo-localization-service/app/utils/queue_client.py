import boto3
import os
import json
from dotenv import load_dotenv
from typing import List, Dict, Any

load_dotenv()

AWS_ACCESS_KEY_ID = os.getenv("AWS_ACCESS_KEY_ID")
AWS_SECRET_ACCESS_KEY = os.getenv("AWS_SECRET_ACCESS_KEY")
AWS_REGION = os.getenv("AWS_REGION", "us-east-1")

sqs_client = boto3.client(
    'sqs',
    aws_access_key_id=AWS_ACCESS_KEY_ID,
    aws_secret_access_key=AWS_SECRET_ACCESS_KEY,
    region_name=AWS_REGION
)

async def poll_sqs_queue(queue_url: str) -> List[Dict[str, Any]]:
    response = sqs_client.receive_message(
        QueueUrl=queue_url,
        MaxNumberOfMessages=10, 
        WaitTimeSeconds=1,  
        VisibilityTimeout=30
    )
    
    messages = response.get('Messages', [])
    
    for message in messages:
        sqs_client.delete_message(
            QueueUrl=queue_url,
            ReceiptHandle=message['ReceiptHandle']
        )
    
    return messages

async def publish_to_queue(queue_url: str, message_body: Dict[str, Any]) -> Dict[str, Any]:
    response = sqs_client.send_message(
        QueueUrl=queue_url,
        MessageBody=json.dumps(message_body)
    )
    
    return response
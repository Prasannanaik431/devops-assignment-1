import os
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import datetime
from dotenv import load_dotenv
load_dotenv()

app = FastAPI()

origins = ["*"]

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/")
async def read_root():
    timezone_offset = os.getenv("TIMEZONE_OFFSET", "+05:30")
    greeting = os.getenv("GREETING", "Hello World")
    secret_message = os.getenv("SECRET_MESSAGE", "N/A")

    hours, minutes = map(int, timezone_offset.split(":"))
    india_timezone = datetime.timezone(datetime.timedelta(hours=hours, minutes=minutes))
    current_time = datetime.datetime.now(india_timezone).strftime("%Y-%m-%d %H:%M:%S")

    return {
        "status": "ok",
        "message": greeting,
        "timestamp": current_time,
        "secret": secret_message
    }

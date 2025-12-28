from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
import datetime

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
    india_timezone = datetime.timezone(datetime.timedelta(hours=5, minutes=30))
    current_time = datetime.datetime.now(india_timezone).strftime("%Y-%m-%d %H:%M:%S")
    return {"status": "ok", "message": "Hello World", "timestamp": current_time}


@app.get("/health")
def health():
    """Health check endpoint for Kubernetes liveness probe."""
    return {"status": "ok"}

from dotenv import load_dotenv

# Carga las variables del archivo .env (base de datos y JWT)
load_dotenv()

from fastapi import Depends, FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware

from infrastructure.repositories.BacklogRepository import (
    BacklogRepository,
    BacklogRepositoryError,
)
from presentation.controlers.dependences.backlog_controller import router as backlog_router
from presentation.controlers.dependences.users_controller import router as users_router
from presentation.security import get_current_user


app = FastAPI(
    title="Scrum Planning API",
    version="1.0.0"
)

origins = [
    "http://localhost:5173",
    "http://127.0.0.1:5173",
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(users_router)
app.include_router(backlog_router)

# Sprint definitions and assignments remain temporary until a sprint table exists.
sprints_db = [
    {
        "id": 1,
        "name": "Sprint 1",
        "startDate": "2026-01-05",
        "endDate": "2026-01-19",
        "workItemIds": [],
    }
]


@app.get("/sprints")
def get_sprints(_current_user: dict = Depends(get_current_user)):
    try:
        work_items = BacklogRepository().list_items()
    except BacklogRepositoryError as error:
        raise HTTPException(status_code=error.status_code, detail=str(error)) from error
    valid_ids = {item["id"] for item in work_items}
    for sprint in sprints_db:
        sprint["workItemIds"] = [
            item_id
            for item_id in sprint["workItemIds"]
            if item_id in valid_ids
        ]
    return sprints_db


@app.post("/sprints/{sprint_id}/work-items/{work_item_id}/toggle")
def toggle_work_item_in_sprint(
    sprint_id: int,
    work_item_id: str,
    _current_user: dict = Depends(get_current_user),
):
    sprint = next((s for s in sprints_db if s["id"] == sprint_id), None)
    if sprint is None:
        raise HTTPException(status_code=404, detail="Sprint not found")
    try:
        work_items = BacklogRepository().list_items()
    except BacklogRepositoryError as error:
        raise HTTPException(status_code=error.status_code, detail=str(error)) from error
    if not any(item["id"] == work_item_id for item in work_items):
        raise HTTPException(status_code=404, detail="Work item not found")

    if work_item_id in sprint["workItemIds"]:
        sprint["workItemIds"].remove(work_item_id)
    else:
        sprint["workItemIds"].append(work_item_id)
    return sprints_db

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from presentation.controlers.dependences.users_controller import router as users_router


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

from fastapi import Body, HTTPException

work_items_db = [
    {
        "id": 1,
        "order": 1,
        "type": "Story",
        "title": "Configurar API de Scrum",
        "state": "Active",
        "level": 1,
        "progress": 50,
        "hasChildren": False,
    }
]


@app.get("/work-items")
def get_work_items():
    return work_items_db


@app.post("/work-items")
def create_work_item(payload: dict = Body(...)):
    next_id = max([item["id"] for item in work_items_db], default=0) + 1
    new_item = {
        "id": next_id,
        "order": len(work_items_db) + 1,
        "type": payload.get("type", "Story"),
        "title": payload.get("title", "Nuevo Work Item"),
        "state": payload.get("state", "New"),
        "level": payload.get("level", 1),
        "progress": payload.get("progress", 0),
        "hasChildren": payload.get("hasChildren", False),
    }
    work_items_db.append(new_item)
    return new_item


@app.delete("/work-items/{item_id}")
def delete_work_item(item_id: int):
    for index, item in enumerate(work_items_db):
        if item["id"] == item_id:
            work_items_db.pop(index)
            return {"deleted": True, "id": item_id}
    raise HTTPException(status_code=404, detail="Work item not found")
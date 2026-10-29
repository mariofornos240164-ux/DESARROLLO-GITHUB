from pydantic import BaseModel
from datetime import datetime
from typing import Optional, List

class StatusBase(BaseModel):
    statusId: int
    statusName: str
    statusCreationDate: datetime
    statusCreatorId: int
    statusModificationDate: Optional[datetime] = None
    statusModificatorId: Optional[int] = None
    statusEnable: bool

class StatusCreate(BaseModel):
    statusName: str
    statusCreatorId: int

class StatusUpdate(BaseModel):
    statusId: int
    statusName: Optional[str] = None
    statusModificatorId: int
    statusEnable: Optional[bool] = None

class LtsStatus(BaseModel):
    statuses: List[StatusBase]
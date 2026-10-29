from pydantic import BaseModel
from datetime import datetime
from typing import Optional, List

class RolBase(BaseModel):
    rolId: int
    rolName: str
    rolCreationDate: datetime
    rolCreatorId: int
    rolModificationDate: Optional[datetime] = None
    rolModificatorId: Optional[int] = None
    rolEnable: bool

class RolCreate(BaseModel):
    rolName: str
    rolCreatorId: int

class RolUpdate(BaseModel):
    rolId: int
    rolName: Optional[str] = None
    rolModificatorId: int
    rolEnable: Optional[bool] = None

class LtsRoles(BaseModel):
    roles: List[RolBase]
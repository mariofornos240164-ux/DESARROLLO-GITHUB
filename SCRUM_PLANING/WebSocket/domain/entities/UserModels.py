from pydantic import BaseModel, Field
from datetime import datetime
from typing import Optional, List

class UserBase(BaseModel):
    userId: int
    userFullName: str
    userName: str
    userEmail: str
    userRolId: int
    userCreationDate: datetime
    userCreatorId: Optional[int] = None
    userModificationDate: Optional[datetime] = None
    userModificatorId: Optional[int] = None
    userEnable: bool


class UserCreate(BaseModel):
    userFullName: str = Field(min_length=1, max_length=80)
    userName: str = Field(min_length=1, max_length=80)
    userEmail: str = Field(min_length=1, max_length=80)
    userPassword: str = Field(min_length=1, max_length=256)
    userRolId: int = Field(gt=0)

class UserUpdate(BaseModel):
    userId: int
    userFullName: Optional[str] = None
    userName: Optional[str] = None
    userEmail: Optional[str] = None
    userPassword: Optional[str] = None
    userRolId: Optional[int] = None
    userEnable: Optional[bool] = None


class LtsUsers(BaseModel):
    users: List[UserBase]

class UserLogin(BaseModel):
    userName: str
    userPassword: str

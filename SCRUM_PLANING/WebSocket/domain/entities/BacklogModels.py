from typing import Literal

from pydantic import BaseModel, Field


class BacklogItemCreate(BaseModel):
    type: Literal["Epic", "Feature", "Story", "Task"]
    title: str = Field(min_length=1, max_length=500)
    description: str = Field(min_length=1, max_length=2000)
    acceptanceCriteria: str | None = Field(default=None, max_length=4000)
    state: Literal["New", "Active", "Closed"]
    parentId: str = Field(min_length=1)

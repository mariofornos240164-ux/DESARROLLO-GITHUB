from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, status

from domain.entities.BacklogModels import BacklogItemCreate
from domain.shared.operationResult import OperationResult
from infrastructure.repositories.BacklogRepository import (
    BacklogRepository,
    BacklogRepositoryError,
)
from presentation.generic_states import OperationResponse
from presentation.security import get_current_user


router = APIRouter(tags=["Backlog"])


def get_backlog_repository() -> BacklogRepository:
    return BacklogRepository()


BacklogRepositoryDep = Annotated[
    BacklogRepository,
    Depends(get_backlog_repository),
]
CurrentUserDep = Annotated[dict[str, int | str], Depends(get_current_user)]


def raise_http_error(error: BacklogRepositoryError):
    status_code = error.status_code
    if status_code < 400 or status_code > 599:
        status_code = status.HTTP_500_INTERNAL_SERVER_ERROR
    raise HTTPException(status_code=status_code, detail=str(error))


@router.get("/work-items")
def list_work_items(
    repository: BacklogRepositoryDep,
    _current_user: CurrentUserDep,
):
    try:
        return repository.list_items()
    except BacklogRepositoryError as error:
        raise_http_error(error)


@router.get("/work-items/parents")
def list_work_item_parents(
    repository: BacklogRepositoryDep,
    _current_user: CurrentUserDep,
):
    try:
        return repository.parent_options()
    except BacklogRepositoryError as error:
        raise_http_error(error)


@router.post(
    "/work-items",
    response_model=OperationResponse,
    status_code=status.HTTP_201_CREATED,
)
def create_work_item(
    item: BacklogItemCreate,
    repository: BacklogRepositoryDep,
    current_user: CurrentUserDep,
):
    try:
        result: OperationResult = repository.create_item(
            item,
            int(current_user["sub"]),
        )
    except BacklogRepositoryError as error:
        raise_http_error(error)
    return OperationResponse(
        status_code=result.status_code,
        message_user=result.message_user,
    )


@router.delete(
    "/work-items/{item_id}",
    response_model=OperationResponse,
)
def delete_work_item(
    item_id: str,
    repository: BacklogRepositoryDep,
    _current_user: CurrentUserDep,
):
    try:
        result = repository.delete_item(item_id)
    except BacklogRepositoryError as error:
        raise_http_error(error)
    return OperationResponse(
        status_code=result.status_code,
        message_user=result.message_user,
    )

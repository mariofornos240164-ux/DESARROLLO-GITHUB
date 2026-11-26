from typing import Any, Callable

from domain.entities.BacklogModels import BacklogItemCreate
from domain.entities.EpicModels import EpicCreate
from domain.entities.FeatureModels import FeatureCreate
from domain.entities.PbiModels import PBICreate
from domain.entities.TaskModels import TaskCreate
from domain.shared.operationResult import OperationResult
from domain.shared.queryResult import QueryResult
from infrastructure.database.base_repository import BaseRepository
from infrastructure.repositories.EpicsRepository import EpicRepository
from infrastructure.repositories.FeaturesRepository import FeatureRepository
from infrastructure.repositories.InitiativesRepository import InitiativeRepository
from infrastructure.repositories.PbisRepository import PbiRepository
from infrastructure.repositories.StatusesRepository import StatusRepository
from infrastructure.repositories.TasksRepository import TasksRepository


class BacklogRepositoryError(Exception):
    def __init__(self, message: str, status_code: int):
        super().__init__(message)
        self.status_code = status_code


class BacklogRepository:
    page_size = 500

    def __init__(self):
        self.epics = EpicRepository()
        self.features = FeatureRepository()
        self.initiatives = InitiativeRepository()
        self.pbis = PbiRepository()
        self.statuses = StatusRepository()
        self.tasks = TasksRepository()

    def _read_all(
        self,
        list_page: Callable[[int, int], QueryResult],
    ) -> list[dict[str, Any]]:
        rows = []
        page_number = 1
        while True:
            result = list_page(page_number, self.page_size)
            if result.status_code >= 400:
                raise BacklogRepositoryError(
                    result.message_user or "No se pudo consultar la base de datos.",
                    result.status_code,
                )
            page = result.data or []
            rows.extend(page)
            if len(page) < self.page_size:
                return rows
            page_number += 1

    @staticmethod
    def _item_id(kind: str, database_id: int) -> str:
        return f"{kind.lower()}:{database_id}"

    @staticmethod
    def _parent_id(kind: str, database_id: int) -> str:
        return f"{kind.lower()}:{database_id}"

    def list_items(self) -> list[dict[str, Any]]:
        epics = self._read_all(self.epics.list_epics)
        features = self._read_all(self.features.list_features)
        pbis = self._read_all(self.pbis.list_pbis)
        tasks = self._read_all(self.tasks.list_tasks)
        statuses = self._read_all(self.statuses.list_statuses)
        status_names = {
            int(row["statusId"]): row["statusName"] for row in statuses
        }

        items = []
        for row in epics:
            items.append(
                self._serialize_item(
                    kind="Epic",
                    database_id=row["epicId"],
                    title=row["epicSummary"],
                    state_id=row["epicStatus"],
                    parent_kind="initiative",
                    parent_database_id=row["epicParentLink"],
                    level=0,
                    status_names=status_names,
                    description=row["epicDescription"],
                )
            )
        for row in features:
            items.append(
                self._serialize_item(
                    kind="Feature",
                    database_id=row["featureId"],
                    title=row["featureSummary"],
                    state_id=row["featureStatus"],
                    parent_kind="epic",
                    parent_database_id=row["featureParentLink"],
                    level=1,
                    status_names=status_names,
                    description=row["featureDescription"],
                    acceptance_criteria=row["featuresAcceptanceCriteria"],
                )
            )
        for row in pbis:
            items.append(
                self._serialize_item(
                    kind="Story",
                    database_id=row["PBIId"],
                    title=row["PBISummary"],
                    state_id=row["PBIStatus"],
                    parent_kind="feature",
                    parent_database_id=row["PBIParentLink"],
                    level=2,
                    status_names=status_names,
                    description=row["PBIDescription"],
                    acceptance_criteria=row["PBIsAcceptanceCriteria"],
                )
            )
        for row in tasks:
            items.append(
                self._serialize_item(
                    kind="Task",
                    database_id=row["taskId"],
                    title=row["taskSummary"],
                    state_id=row["taskStatus"],
                    parent_kind="story",
                    parent_database_id=row["taskParentLink"],
                    level=3,
                    status_names=status_names,
                    description=row["taskDescription"],
                )
            )

        children_by_parent = {}
        for item in items:
            parent_id = item["parentId"]
            children_by_parent.setdefault(parent_id, []).append(item)

        ordered = []
        visited = set()

        def append_tree(item):
            if item["id"] in visited:
                return
            visited.add(item["id"])
            ordered.append(item)
            for child in children_by_parent.get(item["id"], []):
                append_tree(child)

        for item in items:
            if item["type"] == "Epic":
                append_tree(item)
        for item in items:
            append_tree(item)

        parents_with_children = set(children_by_parent)
        for index, item in enumerate(ordered, start=1):
            item["order"] = index
            item["hasChildren"] = item["id"] in parents_with_children
        return ordered

    @classmethod
    def _serialize_item(
        cls,
        *,
        kind: str,
        database_id: int,
        title: str,
        state_id: int,
        parent_kind: str,
        parent_database_id: int,
        level: int,
        status_names: dict[int, str],
        description: str,
        acceptance_criteria: str | None = None,
    ) -> dict[str, Any]:
        state = status_names.get(int(state_id))
        if state is None:
            raise BacklogRepositoryError(
                f"El registro {kind} {database_id} referencia un estado inexistente.",
                500,
            )
        return {
            "id": cls._item_id(kind, int(database_id)),
            "type": kind,
            "title": title,
            "description": description,
            "acceptanceCriteria": acceptance_criteria,
            "state": state,
            "parentId": cls._parent_id(parent_kind, int(parent_database_id)),
            "level": level,
            "order": 0,
            "hasChildren": False,
        }

    def parent_options(self) -> dict[str, list[dict[str, str]]]:
        initiatives = self._read_all(self.initiatives.list_initiatives)
        epics = self._read_all(self.epics.list_epics)
        features = self._read_all(self.features.list_features)
        pbis = self._read_all(self.pbis.list_pbis)
        return {
            "Epic": [
                {
                    "id": self._item_id("Initiative", row["initiativeId"]),
                    "title": row["initiativeSummary"],
                }
                for row in initiatives
            ],
            "Feature": [
                {
                    "id": self._item_id("Epic", row["epicId"]),
                    "title": row["epicSummary"],
                }
                for row in epics
            ],
            "Story": [
                {
                    "id": self._item_id("Feature", row["featureId"]),
                    "title": row["featureSummary"],
                }
                for row in features
            ],
            "Task": [
                {
                    "id": self._item_id("Story", row["PBIId"]),
                    "title": row["PBISummary"],
                }
                for row in pbis
            ],
        }

    def create_item(
        self,
        item: BacklogItemCreate,
        user_id: int,
    ) -> OperationResult:
        title = item.title.strip()
        description = item.description.strip()
        criteria = (item.acceptanceCriteria or "").strip()
        parent_kind = {
            "Epic": "initiative",
            "Feature": "epic",
            "Story": "feature",
            "Task": "story",
        }[item.type]
        try:
            supplied_parent_kind, raw_parent_id = item.parentId.split(":", 1)
            parent_id = int(raw_parent_id)
        except (ValueError, AttributeError):
            raise BacklogRepositoryError(
                "Selecciona un elemento padre válido.", 400
            ) from None
        if supplied_parent_kind.lower() != parent_kind or parent_id < 1:
            raise BacklogRepositoryError(
                f"El elemento padre seleccionado no corresponde a {item.type}.",
                400,
            )

        statuses = self._read_all(self.statuses.list_statuses)
        status = next(
            (
                row
                for row in statuses
                if row["statusName"].casefold() == item.state.casefold()
                and row["statusEnable"]
            ),
            None,
        )
        if status is None:
            raise BacklogRepositoryError(
                f"No existe un estado activo llamado '{item.state}'. "
                "Ejecuta DB/Seed_Backlog_Setup.sql.",
                409,
            )
        status_id = int(status["statusId"])

        if item.type == "Epic":
            if len(title) > 100:
                raise BacklogRepositoryError(
                    "El título de una épica no puede superar 100 caracteres.", 400
                )
            result = self.epics.insert_epic(
                EpicCreate(
                    epicName=title,
                    epicSummary=title,
                    epicDescription=description,
                    epicParentLink=parent_id,
                    epicOwner=user_id,
                    epicCreatorId=user_id,
                    epicStatus=status_id,
                )
            )
        elif item.type == "Feature":
            if not criteria:
                raise BacklogRepositoryError(
                    "Los criterios de aceptación son obligatorios para una feature.",
                    400,
                )
            result = self.features.insert_feature(
                FeatureCreate(
                    featureSummary=title,
                    featureDescription=description,
                    featuresAcceptanceCriteria=criteria,
                    featureParentLink=parent_id,
                    featureOwner=user_id,
                    featureCreatorId=user_id,
                    featureStatus=status_id,
                )
            )
        elif item.type == "Story":
            if not criteria:
                raise BacklogRepositoryError(
                    "Los criterios de aceptación son obligatorios para una story.",
                    400,
                )
            result = self.pbis.insert_pbi(
                PBICreate(
                    PBISummary=title,
                    PBIDescription=description,
                    PBIsAcceptanceCriteria=criteria,
                    PBIOwner=user_id,
                    PBIParentLink=parent_id,
                    PBICreatorId=user_id,
                    PBIStatus=status_id,
                )
            )
        else:
            result = self.tasks.insert_task(
                TaskCreate(
                    taskSummary=title,
                    taskDescription=description,
                    taskOwner=user_id,
                    taskParentLink=parent_id,
                    taskCreatorId=user_id,
                    taskStatus=status_id,
                )
            )
        self._ensure_operation_success(result)
        return result

    def delete_item(self, item_id: str) -> OperationResult:
        try:
            kind, raw_database_id = item_id.split(":", 1)
            database_id = int(raw_database_id)
        except (ValueError, AttributeError):
            raise BacklogRepositoryError("El elemento seleccionado no es válido.", 400) from None

        specifications = {
            "epic": (
                "[SQM_GENERAL].[TBL_Epics]",
                "epicId",
                "[SQM_GENERAL].[TBL_Features]",
                "featureParentLink",
            ),
            "feature": (
                "[SQM_GENERAL].[TBL_Features]",
                "featureId",
                "[SQM_GENERAL].[TBL_ProductBacklogItems]",
                "PBIParentLink",
            ),
            "story": (
                "[SQM_GENERAL].[TBL_ProductBacklogItems]",
                "PBIId",
                "[SQM_GENERAL].[TBL_Tasks]",
                "taskParentLink",
            ),
            "task": (
                "[SQM_GENERAL].[TBL_Tasks]",
                "taskId",
                "[SQM_GENERAL].[TBL_TaskComments]",
                "taskCommentParentLink",
            ),
        }
        specification = specifications.get(kind.lower())
        if specification is None or database_id < 1:
            raise BacklogRepositoryError("El tipo de elemento no es válido.", 400)
        table, id_column, child_table, child_parent_column = specification
        query = f"""
            SET NOCOUNT ON;
            DECLARE @item_id INT = ?;
            DECLARE @status_code INT;
            DECLARE @user_message VARCHAR(500);
            DECLARE @technical_message VARCHAR(500);

            BEGIN TRY
                BEGIN TRANSACTION;

                IF NOT EXISTS (SELECT 1 FROM {table} WHERE {id_column} = @item_id)
                BEGIN
                    SET @status_code = 404;
                    SET @user_message = 'El elemento ya no existe.';
                END
                ELSE IF EXISTS (
                    SELECT 1 FROM {child_table}
                    WHERE {child_parent_column} = @item_id
                )
                BEGIN
                    SET @status_code = 409;
                    SET @user_message = 'No se puede eliminar: hay elementos dependientes asociados.';
                END
                ELSE
                BEGIN
                    DELETE FROM {table} WHERE {id_column} = @item_id;
                    SET @status_code = 200;
                    SET @user_message = 'Elemento eliminado correctamente.';
                END;

                COMMIT TRANSACTION;
            END TRY
            BEGIN CATCH
                IF XACT_STATE() <> 0
                    ROLLBACK TRANSACTION;
                SET @status_code = 500;
                SET @user_message = 'No se pudo eliminar el elemento.';
                SET @technical_message = ERROR_MESSAGE();
            END CATCH;

            SELECT @status_code, @user_message, @technical_message;
        """
        result = BaseRepository.execute_operation(query, (database_id,))
        self._ensure_operation_success(result)
        return result

    @staticmethod
    def _ensure_operation_success(result: OperationResult):
        if result.status_code >= 400:
            raise BacklogRepositoryError(
                result.message_user or "No se pudo completar la operación.",
                result.status_code,
            )

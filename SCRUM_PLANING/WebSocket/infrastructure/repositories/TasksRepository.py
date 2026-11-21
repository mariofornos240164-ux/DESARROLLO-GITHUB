from infrastructure.database.base_repository import BaseRepository
from domain.entities.TaskModels import TaskCreate, TaskUpdate

# pyodbc no puede leer parametros OUTPUT con "?".
# Por eso se declaran las variables en el mismo query y al final se hace un SELECT con ellas.

class TasksRepository:
    def insert_task(self, task: TaskCreate):
        query = """
            SET NOCOUNT ON;
            DECLARE @o_Numero INT, @o_MensajeUsuario VARCHAR(500), @o_MensajeTecnico VARCHAR(500);

            EXEC [SQM_GENERAL].[USP_Tasks]
                @i_taskSummary = ?,
                @i_taskDescription = ?,
                @i_taskOwner = ?,
                @i_taskParentLink = ?,
                @i_taskOriginalEstimate = ?,
                @i_taskCompletedWork = ?,
                @i_taskRemaningWork = ?,
                @i_taskStartDate = ?,
                @i_taskCompletedDate = ?,
                @i_taskDueDate = ?,
                @i_taskActivityType = ?,
                @i_taskCreatorId = ?,
                @i_taskStatus = ?,
                @w_Accion = 'I',
                @o_Numero = @o_Numero OUTPUT,
                @o_MensajeUsuario = @o_MensajeUsuario OUTPUT,
                @o_MensajeTecnico = @o_MensajeTecnico OUTPUT;

            SELECT @o_Numero, @o_MensajeUsuario, @o_MensajeTecnico;
        """
        return BaseRepository.execute_operation(query, (
            task.taskSummary,
            task.taskDescription,
            task.taskOwner,
            task.taskParentLink,
            task.taskOriginalEstimate,
            task.taskCompletedWork,
            task.taskRemaningWork,
            task.taskStartDate,
            task.taskCompletedDate,
            task.taskDueDate,
            task.taskActivityType,
            task.taskCreatorId,
            task.taskStatus
        ))

    def update_task(self, task: TaskUpdate):
        query = """
            SET NOCOUNT ON;
            DECLARE @o_Numero INT, @o_MensajeUsuario VARCHAR(500), @o_MensajeTecnico VARCHAR(500);

            EXEC [SQM_GENERAL].[USP_Tasks]
                @i_taskId = ?,
                @i_taskSummary = ?,
                @i_taskDescription = ?,
                @i_taskOwner = ?,
                @i_taskParentLink = ?,
                @i_taskOriginalEstimate = ?,
                @i_taskCompletedWork = ?,
                @i_taskRemaningWork = ?,
                @i_taskStartDate = ?,
                @i_taskCompletedDate = ?,
                @i_taskDueDate = ?,
                @i_taskActivityType = ?,
                @i_taskModificatorId = ?,
                @i_taskStatus = ?,
                @w_Accion = 'U',
                @o_Numero = @o_Numero OUTPUT,
                @o_MensajeUsuario = @o_MensajeUsuario OUTPUT,
                @o_MensajeTecnico = @o_MensajeTecnico OUTPUT;

            SELECT @o_Numero, @o_MensajeUsuario, @o_MensajeTecnico;
        """
        return BaseRepository.execute_operation(query, (
            task.taskId,
            task.taskSummary,
            task.taskDescription,
            task.taskOwner,
            task.taskParentLink,
            task.taskOriginalEstimate,
            task.taskCompletedWork,
            task.taskRemaningWork,
            task.taskStartDate,
            task.taskCompletedDate,
            task.taskDueDate,
            task.taskActivityType,
            task.taskModificatorId,
            task.taskStatus
        ))

    def list_tasks(self, page_number: int = 1, rows_per_page: int = 10):
        query = """
            SET NOCOUNT ON;
            DECLARE @o_Numero INT, @o_MensajeUsuario VARCHAR(500), @o_MensajeTecnico VARCHAR(500);

            EXEC [SQM_GENERAL].[USP_Tasks]
                @i_PageNumber = ?,
                @i_RowsPerPage = ?,
                @w_Accion = 'S',
                @o_Numero = @o_Numero OUTPUT,
                @o_MensajeUsuario = @o_MensajeUsuario OUTPUT,
                @o_MensajeTecnico = @o_MensajeTecnico OUTPUT;

            SELECT @o_Numero, @o_MensajeUsuario, @o_MensajeTecnico;
        """
        return BaseRepository.execute_query(query, (page_number, rows_per_page))

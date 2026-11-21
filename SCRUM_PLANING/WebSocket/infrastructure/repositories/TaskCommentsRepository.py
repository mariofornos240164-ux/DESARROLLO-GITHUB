from infrastructure.database.base_repository import BaseRepository
from domain.entities.TaskCommentModels import TaskCommentCreate, TaskCommentUpdate

# pyodbc no puede leer parametros OUTPUT con "?".
# Por eso se declaran las variables en el mismo query y al final se hace un SELECT con ellas.

class TaskCommentRepository:
    def insert_task_comment(self, comment: TaskCommentCreate):
        query = """
            SET NOCOUNT ON;
            DECLARE @o_Numero INT, @o_MensajeUsuario VARCHAR(500), @o_MensajeTecnico VARCHAR(500);

            EXEC [SQM_GENERAL].[USP_TaskComments]
                @i_taskCommentParentLink = ?,
                @i_taskCommentOwner = ?,
                @i_taskCommentText = ?,
                @i_taskCommentCreatorId = ?,
                @w_Accion = 'I',
                @o_Numero = @o_Numero OUTPUT,
                @o_MensajeUsuario = @o_MensajeUsuario OUTPUT,
                @o_MensajeTecnico = @o_MensajeTecnico OUTPUT;

            SELECT @o_Numero, @o_MensajeUsuario, @o_MensajeTecnico;
        """
        return BaseRepository.execute_operation(query, (
            comment.taskCommentParentLink,
            comment.taskCommentOwner,
            comment.taskCommentText,
            comment.taskCommentCreatorId
        ))

    def update_task_comment(self, comment: TaskCommentUpdate):
        query = """
            SET NOCOUNT ON;
            DECLARE @o_Numero INT, @o_MensajeUsuario VARCHAR(500), @o_MensajeTecnico VARCHAR(500);

            EXEC [SQM_GENERAL].[USP_TaskComments]
                @i_taskCommentId = ?,
                @i_taskCommentParentLink = ?,
                @i_taskCommentOwner = ?,
                @i_taskCommentText = ?,
                @i_taskCommentModificatorId = ?,
                @i_taskCommentStatus = ?,
                @w_Accion = 'U',
                @o_Numero = @o_Numero OUTPUT,
                @o_MensajeUsuario = @o_MensajeUsuario OUTPUT,
                @o_MensajeTecnico = @o_MensajeTecnico OUTPUT;

            SELECT @o_Numero, @o_MensajeUsuario, @o_MensajeTecnico;
        """
        return BaseRepository.execute_operation(query, (
            comment.taskCommentId,
            comment.taskCommentParentLink,
            comment.taskCommentOwner,
            comment.taskCommentText,
            comment.taskCommentModificatorId,
            comment.taskCommentStatus
        ))

    def list_task_comments(self, page_number: int = 1, rows_per_page: int = 10):
        query = """
            SET NOCOUNT ON;
            DECLARE @o_Numero INT, @o_MensajeUsuario VARCHAR(500), @o_MensajeTecnico VARCHAR(500);

            EXEC [SQM_GENERAL].[USP_TaskComments]
                @i_PageNumber = ?,
                @i_RowsPerPage = ?,
                @w_Accion = 'S',
                @o_Numero = @o_Numero OUTPUT,
                @o_MensajeUsuario = @o_MensajeUsuario OUTPUT,
                @o_MensajeTecnico = @o_MensajeTecnico OUTPUT;

            SELECT @o_Numero, @o_MensajeUsuario, @o_MensajeTecnico;
        """
        return BaseRepository.execute_query(query, (page_number, rows_per_page))

from infrastructure.database.base_repository import BaseRepository
from domain.entities.EpicModels import EpicCreate, EpicUpdate

# pyodbc no puede leer parametros OUTPUT con "?".
# Por eso se declaran las variables en el mismo query y al final se hace un SELECT con ellas.

class EpicRepository:
    def insert_epic(self, epic: EpicCreate):
        query = """
            SET NOCOUNT ON;
            DECLARE @o_Numero INT, @o_MensajeUsuario VARCHAR(500), @o_MensajeTecnico VARCHAR(500);

            EXEC [SQM_GENERAL].[USP_Epics]
                @i_epicName = ?,
                @i_epicSummary = ?,
                @i_epicDescription = ?,
                @i_epicParentLink = ?,
                @i_epicOwner = ?,
                @i_epicStartDate = ?,
                @i_epicDueDate = ?,
                @i_epicPriority = ?,
                @i_epicCreatorId = ?,
                @i_epicStatus = ?,
                @w_Accion = 'I',
                @o_Numero = @o_Numero OUTPUT,
                @o_MensajeUsuario = @o_MensajeUsuario OUTPUT,
                @o_MensajeTecnico = @o_MensajeTecnico OUTPUT;

            SELECT @o_Numero, @o_MensajeUsuario, @o_MensajeTecnico;
        """
        return BaseRepository.execute_operation(query, (
            epic.epicName,
            epic.epicSummary,
            epic.epicDescription,
            epic.epicParentLink,
            epic.epicOwner,
            epic.epicStartDate,
            epic.epicDueDate,
            epic.epicPriority,
            epic.epicCreatorId,
            epic.epicStatus
        ))

    def update_epic(self, epic: EpicUpdate):
        query = """
            SET NOCOUNT ON;
            DECLARE @o_Numero INT, @o_MensajeUsuario VARCHAR(500), @o_MensajeTecnico VARCHAR(500);

            EXEC [SQM_GENERAL].[USP_Epics]
                @i_epicId = ?,
                @i_epicName = ?,
                @i_epicSummary = ?,
                @i_epicDescription = ?,
                @i_epicParentLink = ?,
                @i_epicOwner = ?,
                @i_epicStartDate = ?,
                @i_epicDueDate = ?,
                @i_epicPriority = ?,
                @i_epicModificatorId = ?,
                @i_epicStatus = ?,
                @w_Accion = 'U',
                @o_Numero = @o_Numero OUTPUT,
                @o_MensajeUsuario = @o_MensajeUsuario OUTPUT,
                @o_MensajeTecnico = @o_MensajeTecnico OUTPUT;

            SELECT @o_Numero, @o_MensajeUsuario, @o_MensajeTecnico;
        """
        return BaseRepository.execute_operation(query, (
            epic.epicId,
            epic.epicName,
            epic.epicSummary,
            epic.epicDescription,
            epic.epicParentLink,
            epic.epicOwner,
            epic.epicStartDate,
            epic.epicDueDate,
            epic.epicPriority,
            epic.epicModificatorId,
            epic.epicStatus
        ))

    def list_epics(self, page_number: int = 1, rows_per_page: int = 10):
        query = """
            SET NOCOUNT ON;
            DECLARE @o_Numero INT, @o_MensajeUsuario VARCHAR(500), @o_MensajeTecnico VARCHAR(500);

            EXEC [SQM_GENERAL].[USP_Epics]
                @i_PageNumber = ?,
                @i_RowsPerPage = ?,
                @w_Accion = 'S',
                @o_Numero = @o_Numero OUTPUT,
                @o_MensajeUsuario = @o_MensajeUsuario OUTPUT,
                @o_MensajeTecnico = @o_MensajeTecnico OUTPUT;

            SELECT @o_Numero, @o_MensajeUsuario, @o_MensajeTecnico;
        """
        return BaseRepository.execute_query(query, (page_number, rows_per_page))

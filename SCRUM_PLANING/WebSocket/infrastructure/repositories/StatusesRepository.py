from infrastructure.database.base_repository import BaseRepository
from domain.entities.StatusModels import StatusCreate, StatusUpdate

# pyodbc no puede leer parametros OUTPUT con "?".
# Por eso se declaran las variables en el mismo query y al final se hace un SELECT con ellas.

class StatusRepository:
    def insert_status(self, status: StatusCreate):
        query = """
            SET NOCOUNT ON;
            DECLARE @o_Numero INT, @o_MensajeUsuario VARCHAR(500), @o_MensajeTecnico VARCHAR(500);

            EXEC [SQM_CATALOGS].[USP_Status]
                @i_statusName = ?,
                @i_statusCreatorId = ?,
                @w_Accion = 'I',
                @o_Numero = @o_Numero OUTPUT,
                @o_MensajeUsuario = @o_MensajeUsuario OUTPUT,
                @o_MensajeTecnico = @o_MensajeTecnico OUTPUT;

            SELECT @o_Numero, @o_MensajeUsuario, @o_MensajeTecnico;
        """
        return BaseRepository.execute_operation(query, (
            status.statusName,
            status.statusCreatorId
        ))

    def update_status(self, status: StatusUpdate):
        query = """
            SET NOCOUNT ON;
            DECLARE @o_Numero INT, @o_MensajeUsuario VARCHAR(500), @o_MensajeTecnico VARCHAR(500);

            EXEC [SQM_CATALOGS].[USP_Status]
                @i_statusId = ?,
                @i_statusName = ?,
                @i_statusModificatorId = ?,
                @i_statusEnable = ?,
                @w_Accion = 'U',
                @o_Numero = @o_Numero OUTPUT,
                @o_MensajeUsuario = @o_MensajeUsuario OUTPUT,
                @o_MensajeTecnico = @o_MensajeTecnico OUTPUT;

            SELECT @o_Numero, @o_MensajeUsuario, @o_MensajeTecnico;
        """
        return BaseRepository.execute_operation(query, (
            status.statusId,
            status.statusName,
            status.statusModificatorId,
            status.statusEnable
        ))

    def list_statuses(self, page_number: int = 1, rows_per_page: int = 10):
        query = """
            SET NOCOUNT ON;
            DECLARE @o_Numero INT, @o_MensajeUsuario VARCHAR(500), @o_MensajeTecnico VARCHAR(500);

            EXEC [SQM_CATALOGS].[USP_Status]
                @i_PageNumber = ?,
                @i_RowsPerPage = ?,
                @w_Accion = 'S',
                @o_Numero = @o_Numero OUTPUT,
                @o_MensajeUsuario = @o_MensajeUsuario OUTPUT,
                @o_MensajeTecnico = @o_MensajeTecnico OUTPUT;

            SELECT @o_Numero, @o_MensajeUsuario, @o_MensajeTecnico;
        """
        return BaseRepository.execute_query(query, (page_number, rows_per_page))

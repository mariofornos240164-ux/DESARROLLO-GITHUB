from infrastructure.database.base_repository import BaseRepository
from domain.entities.PbiModels import PBICreate, PBIUpdate

# pyodbc no puede leer parametros OUTPUT con "?".
# Por eso se declaran las variables en el mismo query y al final se hace un SELECT con ellas.

class PbiRepository:
    def insert_pbi(self, pbi: PBICreate):
        query = """
            SET NOCOUNT ON;
            DECLARE @o_Numero INT, @o_MensajeUsuario VARCHAR(500), @o_MensajeTecnico VARCHAR(500);

            EXEC [SQM_GENERAL].[USP_ProductBacklogItems]
                @i_PBISummary = ?,
                @i_PBIDescription = ?,
                @i_PBIsAcceptanceCriteria = ?,
                @i_PBIOwner = ?,
                @i_PBIParentLink = ?,
                @i_PBIStoryPoint = ?,
                @i_PBIStartDate = ?,
                @i_PBIDueDate = ?,
                @i_PBIPriority = ?,
                @i_PBICreatorId = ?,
                @i_PBIStatus = ?,
                @w_Accion = 'I',
                @o_Numero = @o_Numero OUTPUT,
                @o_MensajeUsuario = @o_MensajeUsuario OUTPUT,
                @o_MensajeTecnico = @o_MensajeTecnico OUTPUT;

            SELECT @o_Numero, @o_MensajeUsuario, @o_MensajeTecnico;
        """
        return BaseRepository.execute_operation(query, (
            pbi.PBISummary,
            pbi.PBIDescription,
            pbi.PBIsAcceptanceCriteria,
            pbi.PBIOwner,
            pbi.PBIParentLink,
            pbi.PBIStoryPoint,
            pbi.PBIStartDate,
            pbi.PBIDueDate,
            pbi.PBIPriority,
            pbi.PBICreatorId,
            pbi.PBIStatus
        ))

    def update_pbi(self, pbi: PBIUpdate):
        query = """
            SET NOCOUNT ON;
            DECLARE @o_Numero INT, @o_MensajeUsuario VARCHAR(500), @o_MensajeTecnico VARCHAR(500);

            EXEC [SQM_GENERAL].[USP_ProductBacklogItems]
                @i_PBIId = ?,
                @i_PBISummary = ?,
                @i_PBIDescription = ?,
                @i_PBIsAcceptanceCriteria = ?,
                @i_PBIOwner = ?,
                @i_PBIParentLink = ?,
                @i_PBIStoryPoint = ?,
                @i_PBIStartDate = ?,
                @i_PBIDueDate = ?,
                @i_PBIPriority = ?,
                @i_PBIModificatorId = ?,
                @i_PBIStatus = ?,
                @w_Accion = 'U',
                @o_Numero = @o_Numero OUTPUT,
                @o_MensajeUsuario = @o_MensajeUsuario OUTPUT,
                @o_MensajeTecnico = @o_MensajeTecnico OUTPUT;

            SELECT @o_Numero, @o_MensajeUsuario, @o_MensajeTecnico;
        """
        return BaseRepository.execute_operation(query, (
            pbi.PBIId,
            pbi.PBISummary,
            pbi.PBIDescription,
            pbi.PBIsAcceptanceCriteria,
            pbi.PBIOwner,
            pbi.PBIParentLink,
            pbi.PBIStoryPoint,
            pbi.PBIStartDate,
            pbi.PBIDueDate,
            pbi.PBIPriority,
            pbi.PBIModificatorId,
            pbi.PBIStatus
        ))

    def list_pbis(self, page_number: int = 1, rows_per_page: int = 10):
        query = """
            SET NOCOUNT ON;
            DECLARE @o_Numero INT, @o_MensajeUsuario VARCHAR(500), @o_MensajeTecnico VARCHAR(500);

            EXEC [SQM_GENERAL].[USP_ProductBacklogItems]
                @i_PageNumber = ?,
                @i_RowsPerPage = ?,
                @w_Accion = 'S',
                @o_Numero = @o_Numero OUTPUT,
                @o_MensajeUsuario = @o_MensajeUsuario OUTPUT,
                @o_MensajeTecnico = @o_MensajeTecnico OUTPUT;

            SELECT @o_Numero, @o_MensajeUsuario, @o_MensajeTecnico;
        """
        return BaseRepository.execute_query(query, (page_number, rows_per_page))

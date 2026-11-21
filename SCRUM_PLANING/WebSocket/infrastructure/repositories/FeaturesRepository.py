from infrastructure.database.base_repository import BaseRepository
from domain.entities.FeatureModels import FeatureCreate, FeatureUpdate

# pyodbc no puede leer parametros OUTPUT con "?".
# Por eso se declaran las variables en el mismo query y al final se hace un SELECT con ellas.

class FeatureRepository:
    def insert_feature(self, feature: FeatureCreate):
        query = """
            SET NOCOUNT ON;
            DECLARE @o_Numero INT, @o_MensajeUsuario VARCHAR(500), @o_MensajeTecnico VARCHAR(500);

            EXEC [SQM_GENERAL].[USP_Features]
                @i_featureSummary = ?,
                @i_featureDescription = ?,
                @i_featuresAcceptanceCriteria = ?,
                @i_featureParentLink = ?,
                @i_featureOwner = ?,
                @i_featureStartDate = ?,
                @i_featureDueDate = ?,
                @i_featurePriority = ?,
                @i_featureCreatorId = ?,
                @i_featureStatus = ?,
                @w_Accion = 'I',
                @o_Numero = @o_Numero OUTPUT,
                @o_MensajeUsuario = @o_MensajeUsuario OUTPUT,
                @o_MensajeTecnico = @o_MensajeTecnico OUTPUT;

            SELECT @o_Numero, @o_MensajeUsuario, @o_MensajeTecnico;
        """
        return BaseRepository.execute_operation(query, (
            feature.featureSummary,
            feature.featureDescription,
            feature.featuresAcceptanceCriteria,
            feature.featureParentLink,
            feature.featureOwner,
            feature.featureStartDate,
            feature.featureDueDate,
            feature.featurePriority,
            feature.featureCreatorId,
            feature.featureStatus
        ))

    def update_feature(self, feature: FeatureUpdate):
        query = """
            SET NOCOUNT ON;
            DECLARE @o_Numero INT, @o_MensajeUsuario VARCHAR(500), @o_MensajeTecnico VARCHAR(500);

            EXEC [SQM_GENERAL].[USP_Features]
                @i_featureId = ?,
                @i_featureSummary = ?,
                @i_featureDescription = ?,
                @i_featuresAcceptanceCriteria = ?,
                @i_featureParentLink = ?,
                @i_featureOwner = ?,
                @i_featureStartDate = ?,
                @i_featureDueDate = ?,
                @i_featurePriority = ?,
                @i_featureModificatorId = ?,
                @i_featureStatus = ?,
                @w_Accion = 'U',
                @o_Numero = @o_Numero OUTPUT,
                @o_MensajeUsuario = @o_MensajeUsuario OUTPUT,
                @o_MensajeTecnico = @o_MensajeTecnico OUTPUT;

            SELECT @o_Numero, @o_MensajeUsuario, @o_MensajeTecnico;
        """
        return BaseRepository.execute_operation(query, (
            feature.featureId,
            feature.featureSummary,
            feature.featureDescription,
            feature.featuresAcceptanceCriteria,
            feature.featureParentLink,
            feature.featureOwner,
            feature.featureStartDate,
            feature.featureDueDate,
            feature.featurePriority,
            feature.featureModificatorId,
            feature.featureStatus
        ))

    def list_features(self, page_number: int = 1, rows_per_page: int = 10):
        query = """
            SET NOCOUNT ON;
            DECLARE @o_Numero INT, @o_MensajeUsuario VARCHAR(500), @o_MensajeTecnico VARCHAR(500);

            EXEC [SQM_GENERAL].[USP_Features]
                @i_PageNumber = ?,
                @i_RowsPerPage = ?,
                @w_Accion = 'S',
                @o_Numero = @o_Numero OUTPUT,
                @o_MensajeUsuario = @o_MensajeUsuario OUTPUT,
                @o_MensajeTecnico = @o_MensajeTecnico OUTPUT;

            SELECT @o_Numero, @o_MensajeUsuario, @o_MensajeTecnico;
        """
        return BaseRepository.execute_query(query, (page_number, rows_per_page))

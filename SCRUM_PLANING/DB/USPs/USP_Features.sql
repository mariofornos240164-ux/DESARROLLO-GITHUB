USE [DB_SCRUM_PLANNING]
GO

CREATE OR ALTER PROC [SQM_GENERAL].[USP_Features]
(
    @i_featureId INT = NULL,
    @i_featureSummary VARCHAR(500) = NULL,
    @i_featureDescription VARCHAR(2000) = NULL,
    @i_featuresAcceptanceCriteria VARCHAR(4000) = NULL,
    @i_featureParentLink INT = NULL, 
    @i_featureOwner INT = NULL,      
    @i_featureStartDate DATE = NULL,
    @i_featureDueDate DATE = NULL,
    @i_featurePriority INT = NULL,   
    @i_featureCreationDate DATETIME = NULL,
    @i_featureCreatorId INT = NULL,
    @i_featureModificationDate DATETIME = NULL,
    @i_featureModificatorId INT = NULL,
    @i_featureStatus INT = NULL,     
    @i_PageNumber INT = NULL,
    @i_RowsPerPage INT = NULL,
    @w_Accion CHAR(1),
    @o_Numero INT = NULL OUT,
    @o_MensajeTecnico VARCHAR(500) = NULL OUT,
    @o_MensajeUsuario VARCHAR(500) = NULL OUT
)
AS
BEGIN

    DECLARE @w_totalRows INT;

    IF @i_featureCreationDate IS NULL
        SET @i_featureCreationDate = GETDATE();

    -- INSERTAR
    IF @w_Accion = 'I'
    BEGIN
        SELECT 
            @o_Numero = 400,
            @o_MensajeUsuario = CASE 
                WHEN ISNULL(@i_featureSummary,'') = '' THEN 'EL RESUMEN DE LA FEATURE ES OBLIGATORIO'
                WHEN ISNULL(@i_featureDescription,'') = '' THEN 'LA DESCRIPCION DE LA FEATURE ES OBLIGATORIA'
                WHEN ISNULL(@i_featuresAcceptanceCriteria,'') = '' THEN 'LOS CRITERIOS DE ACEPTACION SON OBLIGATORIOS'
                WHEN ISNULL(@i_featureParentLink,0) = 0 THEN 'LA EPICA ASOCIADA (PARENT LINK) ES OBLIGATORIA'
                WHEN ISNULL(@i_featureOwner,0) = 0 THEN 'EL DUEÑO DE LA FEATURE ES OBLIGATORIO'
                WHEN ISNULL(@i_featureStatus,0) = 0 THEN 'EL ESTADO DE LA FEATURE ES OBLIGATORIO'
                ELSE NULL
            END;

        IF @o_Numero = 400
        BEGIN
            RETURN;
        END

        ELSE IF NOT EXISTS (SELECT 1 FROM [SQM_GENERAL].[TBL_Epics] (NOLOCK) WHERE epicId = @i_featureParentLink)
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'LA EPICA ASOCIADA NO EXISTE';
        END;

        ELSE IF NOT EXISTS (SELECT 1 FROM [SQM_SECURITY].[TBL_Users] (NOLOCK) WHERE userId = @i_featureOwner)
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL DUEÑO (USUARIO) DE LA FEATURE NO EXISTE';
        END;

        ELSE IF @i_featurePriority IS NOT NULL AND NOT EXISTS (SELECT 1 FROM [SQM_CATALOGS].[TBL_Priorities] (NOLOCK) WHERE priorityId = @i_featurePriority AND priorityEnable = 1)
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'LA PRIORIDAD NO EXISTE O NO ESTA ACTIVA';
        END;

        ELSE IF NOT EXISTS (SELECT 1 FROM [SQM_CATALOGS].[TBL_Status] (NOLOCK) WHERE statusId = @i_featureStatus AND statusEnable = 1)
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL ESTADO NO EXISTE O NO ESTA ACTIVO';
        END;
        
        ELSE
        BEGIN
            BEGIN TRANSACTION TRX_INS_FEATURE;

            BEGIN TRY
                INSERT INTO [SQM_GENERAL].[TBL_Features](
                    featureSummary, featureDescription, featuresAcceptanceCriteria, 
                    featureParentLink, featureOwner, featureStartDate, featureDueDate, 
                    featurePriority, featureCreationDate, featureCreatorId, 
                    featureModificationDate, featureModificatorId, featureStatus
                )
                VALUES(
                    @i_featureSummary, @i_featureDescription, @i_featuresAcceptanceCriteria, 
                    @i_featureParentLink, @i_featureOwner, @i_featureStartDate, @i_featureDueDate, 
                    @i_featurePriority, @i_featureCreationDate, @i_featureCreatorId, 
                    NULL, NULL, @i_featureStatus
                );

                COMMIT TRANSACTION TRX_INS_FEATURE;

                SET @o_Numero = 201;
                SET @o_MensajeUsuario = 'FEATURE REGISTRADA CORRECTAMENTE';

            END TRY
            BEGIN CATCH
                ROLLBACK TRANSACTION TRX_INS_FEATURE;

                SET @o_Numero = 500;
                SET @o_MensajeUsuario = 'ERROR AL REGISTRAR LA FEATURE';
                SET @o_MensajeTecnico = CONCAT_WS(' - ', 'ERROR AL REGISTRAR FEATURE', ERROR_PROCEDURE(), ERROR_LINE(), ERROR_MESSAGE());
            END CATCH
        END
    END

    -- UPDATE
    ELSE IF @w_Accion = 'U'
    BEGIN
        IF ISNULL(@i_featureId,0) = 0
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL ID DE LA FEATURE ES OBLIGATORIO';
        END;

        ELSE IF ISNULL(@i_featureModificatorId,0) = 0
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL ID DEL MODIFICADOR ES OBLIGATORIO';
        END;

        ELSE IF NOT EXISTS (SELECT 1 FROM [SQM_GENERAL].[TBL_Features] (NOLOCK) WHERE featureId = @i_featureId)
        BEGIN
            SET @o_Numero = 404;
            SET @o_MensajeUsuario = 'LA FEATURE NO EXISTE';
        END;

        ELSE IF @i_featureParentLink IS NOT NULL AND NOT EXISTS (SELECT 1 FROM [SQM_GENERAL].[TBL_Epics] (NOLOCK) WHERE epicId = @i_featureParentLink)
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'LA EPICA ASOCIADA NO EXISTE';
        END;

        ELSE IF @i_featureOwner IS NOT NULL AND NOT EXISTS (SELECT 1 FROM [SQM_SECURITY].[TBL_Users] (NOLOCK) WHERE userId = @i_featureOwner)
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL DUEÑO (USUARIO) DE LA FEATURE NO EXISTE';
        END;

        ELSE IF @i_featurePriority IS NOT NULL AND NOT EXISTS (SELECT 1 FROM [SQM_CATALOGS].[TBL_Priorities] (NOLOCK) WHERE priorityId = @i_featurePriority AND priorityEnable = 1)
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'LA PRIORIDAD NO EXISTE O NO ESTA ACTIVA';
        END;

        ELSE IF @i_featureStatus IS NOT NULL AND NOT EXISTS (SELECT 1 FROM [SQM_CATALOGS].[TBL_Status] (NOLOCK) WHERE statusId = @i_featureStatus AND statusEnable = 1)
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL ESTADO NO EXISTE O NO ESTA ACTIVO';
        END;
        
        ELSE
        BEGIN
            BEGIN TRANSACTION TRX_UPD_FEATURE;

            BEGIN TRY
                -- Asignar fecha actual si no viene especificada en la modificación
                IF @i_featureModificationDate IS NULL
                    SET @i_featureModificationDate = GETDATE();

                UPDATE [SQM_GENERAL].[TBL_Features]
                SET featureSummary = COALESCE(@i_featureSummary, featureSummary),
                    featureDescription = COALESCE(@i_featureDescription, featureDescription),
                    featuresAcceptanceCriteria = COALESCE(@i_featuresAcceptanceCriteria, featuresAcceptanceCriteria),
                    featureParentLink = COALESCE(@i_featureParentLink, featureParentLink),
                    featureOwner = COALESCE(@i_featureOwner, featureOwner),
                    featureStartDate = COALESCE(@i_featureStartDate, featureStartDate),
                    featureDueDate = COALESCE(@i_featureDueDate, featureDueDate),
                    featurePriority = COALESCE(@i_featurePriority, featurePriority),
                    featureModificationDate = @i_featureModificationDate,
                    featureModificatorId = @i_featureModificatorId,
                    featureStatus = COALESCE(@i_featureStatus, featureStatus)
                WHERE featureId = @i_featureId;

                COMMIT TRANSACTION TRX_UPD_FEATURE;

                SET @o_Numero = 200;
                SET @o_MensajeUsuario = 'FEATURE ACTUALIZADA CORRECTAMENTE';

            END TRY
            BEGIN CATCH
                ROLLBACK TRANSACTION TRX_UPD_FEATURE;

                SET @o_Numero = 500;
                SET @o_MensajeUsuario = 'ERROR AL ACTUALIZAR LA FEATURE';
                SET @o_MensajeTecnico = CONCAT_WS(' - ', 'ERROR AL ACTUALIZAR FEATURE', ERROR_PROCEDURE(), ERROR_LINE(), ERROR_MESSAGE());
            END CATCH
        END
    END

    -- SELECT
    ELSE IF @w_Accion = 'S'
    BEGIN
        BEGIN TRY
            SELECT 
                featureId,
                featureSummary,
                featureDescription,
                featuresAcceptanceCriteria,
                featureParentLink,
                featureOwner,
                featureStartDate,
                featureDueDate,
                featurePriority,
                featureCreationDate,
                featureCreatorId,
                featureModificationDate,
                featureModificatorId,
                featureStatus
            FROM [SQM_GENERAL].[TBL_Features] (NOLOCK)
            ORDER BY featureId
            OFFSET (@i_PageNumber - 1) * @i_RowsPerPage ROWS
            FETCH NEXT @i_RowsPerPage ROWS ONLY;

            SET @w_totalRows = @@ROWCOUNT

            IF (@w_totalRows > 0)
            BEGIN
                SET @o_Numero = 200;
                SET @o_MensajeUsuario = 'FEATURES LISTADAS CORRECTAMENTE';
            END
            ELSE
            BEGIN
                SET @o_Numero = 204;
                SET @o_MensajeUsuario = 'NO HAY MAS REGISTROS PARA LISTAR';
            END

        END TRY
        BEGIN CATCH
            SET @o_Numero = 500;
            SET @o_MensajeUsuario = 'ERROR AL LISTAR LAS FEATURES';
            SET @o_MensajeTecnico = CONCAT_WS(' - ', 'ERROR AL LISTAR FEATURES', ERROR_PROCEDURE(), ERROR_LINE(), ERROR_MESSAGE());
        END CATCH
    END

    -- ACCION INVALIDA
    ELSE
    BEGIN
        SET @o_Numero = 405;
        SET @o_MensajeUsuario = 'METODO NO HABILITADO';
        SET @o_MensajeTecnico = 'EL PROCEDIMIENTO ALMACENADO NO TIENE HABILITADA ESA OPCION';
    END

END;
GO
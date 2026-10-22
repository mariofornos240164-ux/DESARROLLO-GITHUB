USE DB_SCRUM_PLANNING
GO

CREATE OR ALTER PROC [SQM_GENERAL].[USP_TaskComments]
(
    @i_taskCommentId INT = NULL,
    @i_taskCommentParentLink INT = NULL,
    @i_taskCommentOwner INT = NULL,
    @i_taskCommentText NVARCHAR(4000) = NULL,
    @i_taskCommentCreationDate DATETIME = NULL,
    @i_taskCommentCreatorId INT = NULL,
    @i_taskCommentModificationDate DATETIME = NULL,
    @i_taskCommentModificatorId INT = NULL,
    @i_taskCommentStatus BIT = NULL,
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

    IF @i_taskCommentCreationDate IS NULL
        SET @i_taskCommentCreationDate = GETDATE();

    IF @i_taskCommentModificationDate IS NULL
        SET @i_taskCommentModificationDate = GETDATE();

    -- INSERTAR
    IF @w_Accion = 'I'
    BEGIN
        IF ISNULL(@i_taskCommentParentLink,0) = 0
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'LA TAREA ASOCIADA (PARENT LINK) ES OBLIGATORIA';
        END;

        ELSE IF ISNULL(@i_taskCommentOwner,0) = 0
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL DUEÑO DEL COMENTARIO ES OBLIGATORIO';
        END;

        ELSE IF ISNULL(@i_taskCommentText,'') = ''
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL TEXTO DEL COMENTARIO ES OBLIGATORIO';
        END;

        ELSE IF NOT EXISTS (SELECT 1 FROM [SQM_GENERAL].[TBL_Tasks] (NOLOCK) WHERE taskId = @i_taskCommentParentLink)
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'LA TAREA ASOCIADA NO EXISTE';
        END;

        ELSE IF NOT EXISTS (SELECT 1 FROM [SQM_SECURITY].[TBL_Users] (NOLOCK) WHERE userId = @i_taskCommentOwner)
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL DUEÑO (USUARIO) DEL COMENTARIO NO EXISTE';
        END;
        
        ELSE
        BEGIN
            BEGIN TRANSACTION TRX_INS_TASKCOMMENT;

            BEGIN TRY
                INSERT INTO [SQM_GENERAL].[TBL_TaskComments](
                    taskCommentParentLink, taskCommentOwner, taskCommentText, 
                    taskCommentCreationDate, taskCommentCreatorId, 
                    taskCommentModificationDate, taskCommentModificatorId, taskCommentStatus
                )
                VALUES(
                    @i_taskCommentParentLink, @i_taskCommentOwner, @i_taskCommentText, 
                    @i_taskCommentCreationDate, @i_taskCommentCreatorId, 
                    @i_taskCommentModificationDate, @i_taskCommentModificatorId, 1
                );

                COMMIT TRANSACTION TRX_INS_TASKCOMMENT;

                SET @o_Numero = 201;
                SET @o_MensajeUsuario = 'COMENTARIO REGISTRADO CORRECTAMENTE';

            END TRY
            BEGIN CATCH
                ROLLBACK TRANSACTION TRX_INS_TASKCOMMENT;

                SET @o_Numero = 500;
                SET @o_MensajeUsuario = 'ERROR AL REGISTRAR EL COMENTARIO';
                SET @o_MensajeTecnico = CONCAT_WS(' - ', 'ERROR AL REGISTRAR COMENTARIO', ERROR_PROCEDURE(), ERROR_LINE(), ERROR_MESSAGE());
            END CATCH
        END
    END

    -- UPDATE
    ELSE IF @w_Accion = 'U'
    BEGIN
        IF ISNULL(@i_taskCommentId,0) = 0
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL ID DEL COMENTARIO ES OBLIGATORIO';
        END;

        ELSE IF ISNULL(@i_taskCommentModificatorId,0) = 0
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL ID DEL MODIFICADOR ES OBLIGATORIO';
        END;

        ELSE IF NOT EXISTS (SELECT 1 FROM [SQM_GENERAL].[TBL_TaskComments] (NOLOCK) WHERE taskCommentId = @i_taskCommentId)
        BEGIN
            SET @o_Numero = 404;
            SET @o_MensajeUsuario = 'EL COMENTARIO NO EXISTE';
        END;

        ELSE IF @i_taskCommentParentLink IS NOT NULL AND NOT EXISTS (SELECT 1 FROM [SQM_GENERAL].[TBL_Tasks] (NOLOCK) WHERE taskId = @i_taskCommentParentLink)
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'LA TAREA ASOCIADA NO EXISTE';
        END;

        ELSE IF @i_taskCommentOwner IS NOT NULL AND NOT EXISTS (SELECT 1 FROM [SQM_SECURITY].[TBL_Users] (NOLOCK) WHERE userId = @i_taskCommentOwner)
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL DUEÑO (USUARIO) DEL COMENTARIO NO EXISTE';
        END;
        
        ELSE
        BEGIN
            BEGIN TRANSACTION TRX_UPD_TASKCOMMENT;

            BEGIN TRY
                UPDATE [SQM_GENERAL].[TBL_TaskComments]
                SET taskCommentParentLink = COALESCE(@i_taskCommentParentLink, taskCommentParentLink),
                    taskCommentOwner = COALESCE(@i_taskCommentOwner, taskCommentOwner),
                    taskCommentText = COALESCE(@i_taskCommentText, taskCommentText),
                    taskCommentModificationDate = @i_taskCommentModificationDate,
                    taskCommentModificatorId = @i_taskCommentModificatorId,
                    taskCommentStatus = COALESCE(@i_taskCommentStatus, taskCommentStatus)
                WHERE taskCommentId = @i_taskCommentId;

                COMMIT TRANSACTION TRX_UPD_TASKCOMMENT;

                SET @o_Numero = 200;
                SET @o_MensajeUsuario = 'COMENTARIO ACTUALIZADO CORRECTAMENTE';

            END TRY
            BEGIN CATCH
                ROLLBACK TRANSACTION TRX_UPD_TASKCOMMENT;

                SET @o_Numero = 500;
                SET @o_MensajeUsuario = 'ERROR AL ACTUALIZAR EL COMENTARIO';
                SET @o_MensajeTecnico = CONCAT_WS(' - ', 'ERROR AL ACTUALIZAR COMENTARIO', ERROR_PROCEDURE(), ERROR_LINE(), ERROR_MESSAGE());
            END CATCH
        END
    END

    -- SELECT
    ELSE IF @w_Accion = 'S'
    BEGIN
        BEGIN TRY
            SELECT 
                taskCommentId,
                taskCommentParentLink,
                taskCommentOwner,
                taskCommentText,
                taskCommentCreationDate,
                taskCommentCreatorId,
                taskCommentModificationDate,
                taskCommentModificatorId,
                taskCommentStatus
            FROM [SQM_GENERAL].[TBL_TaskComments] (NOLOCK)
            ORDER BY taskCommentId
            OFFSET (@i_PageNumber - 1) * @i_RowsPerPage ROWS
            FETCH NEXT @i_RowsPerPage ROWS ONLY;

            SET @w_totalRows = @@ROWCOUNT

            IF (@w_totalRows > 0)
            BEGIN
                SET @o_Numero = 200;
                SET @o_MensajeUsuario = 'COMENTARIOS LISTADOS CORRECTAMENTE';
            END
            ELSE
            BEGIN
                SET @o_Numero = 204;
                SET @o_MensajeUsuario = 'NO HAY MAS REGISTROS PARA LISTAR';
            END

        END TRY
        BEGIN CATCH
            SET @o_Numero = 500;
            SET @o_MensajeUsuario = 'ERROR AL LISTAR LOS COMENTARIOS';
            SET @o_MensajeTecnico = CONCAT_WS(' - ', 'ERROR AL LISTAR COMENTARIOS', ERROR_PROCEDURE(), ERROR_LINE(), ERROR_MESSAGE());
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
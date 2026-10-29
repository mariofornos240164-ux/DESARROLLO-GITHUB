USE DB_SCRUM_PLANNING
GO

CREATE OR ALTER PROC [SQM_CATALOGS].[USP_BusinessValues]
(
    @i_businessValueId INT = NULL,
    @i_businessValueName VARCHAR(80) = NULL,
    @i_businessValueCreationDate DATETIME = NULL,
    @i_businessValueCreatorId INT = NULL,
    @i_businessValueModificationDate DATETIME = NULL,
    @i_businessValueModificatorId INT = NULL,
    @i_businessValueEnable BIT = NULL,
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

    IF @i_businessValueCreationDate IS NULL
        SET @i_businessValueCreationDate = GETDATE();

    -- INSERTAR
    IF @w_Accion = 'I'
    BEGIN
        IF ISNULL(@i_businessValueName,'') = ''
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL NOMBRE DEL VALOR DE NEGOCIO ES OBLIGATORIO';
        END;

        ELSE IF EXISTS (SELECT 1 FROM [SQM_CATALOGS].[TBL_BusinessValues] (NOLOCK) WHERE businessValueName = @i_businessValueName)
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL NOMBRE DEL VALOR DE NEGOCIO YA EXISTE';
        END;
        
        ELSE
        BEGIN
            BEGIN TRANSACTION TRX_INS_BV;

            BEGIN TRY
                INSERT INTO [SQM_CATALOGS].[TBL_BusinessValues](
                    businessValueName, businessValueCreationDate, businessValueCreatorId, 
                    businessValueModificationDate, businessValueModificatorId, businessValueEnable
                )
                VALUES(
                    @i_businessValueName, @i_businessValueCreationDate, @i_businessValueCreatorId, 
                    NULL, NULL, 1
                );

                COMMIT TRANSACTION TRX_INS_BV;

                SET @o_Numero = 201;
                SET @o_MensajeUsuario = 'VALOR DE NEGOCIO REGISTRADO CORRECTAMENTE';

            END TRY
            BEGIN CATCH
                ROLLBACK TRANSACTION TRX_INS_BV;

                SET @o_Numero = 500;
                SET @o_MensajeUsuario = 'ERROR AL REGISTRAR EL VALOR DE NEGOCIO';
                SET @o_MensajeTecnico = CONCAT_WS(' - ', 'ERROR AL REGISTRAR VALOR DE NEGOCIO', ERROR_PROCEDURE(), ERROR_LINE(), ERROR_MESSAGE());
            END CATCH
        END
    END

    -- UPDATE
    ELSE IF @w_Accion = 'U'
    BEGIN
        IF ISNULL(@i_businessValueId,0) = 0
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL ID DEL VALOR DE NEGOCIO ES OBLIGATORIO';
        END;

        ELSE IF ISNULL(@i_businessValueModificatorId,0) = 0
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL ID DEL MODIFICADOR ES OBLIGATORIO';
        END;

        ELSE IF NOT EXISTS (SELECT 1 FROM [SQM_CATALOGS].[TBL_BusinessValues] (NOLOCK) WHERE businessValueId = @i_businessValueId)
        BEGIN
            SET @o_Numero = 404;
            SET @o_MensajeUsuario = 'EL VALOR DE NEGOCIO NO EXISTE';
        END;

        ELSE IF @i_businessValueName IS NOT NULL AND
            EXISTS (SELECT 1 FROM [SQM_CATALOGS].[TBL_BusinessValues] (NOLOCK) WHERE businessValueName = @i_businessValueName AND businessValueId <> @i_businessValueId)
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL NOMBRE DEL VALOR DE NEGOCIO YA EXISTE';
        END;
        
        ELSE
        BEGIN
            BEGIN TRANSACTION TRX_UPD_BV;

            BEGIN TRY
                IF @i_businessValueModificationDate IS NULL
                    SET @i_businessValueModificationDate = GETDATE();

                UPDATE [SQM_CATALOGS].[TBL_BusinessValues]
                SET businessValueName = COALESCE(@i_businessValueName, businessValueName),
                    businessValueModificationDate = @i_businessValueModificationDate,
                    businessValueModificatorId = @i_businessValueModificatorId,
                    businessValueEnable = COALESCE(@i_businessValueEnable, businessValueEnable)
                WHERE businessValueId = @i_businessValueId;

                COMMIT TRANSACTION TRX_UPD_BV;

                SET @o_Numero = 200;
                SET @o_MensajeUsuario = 'VALOR DE NEGOCIO ACTUALIZADO CORRECTAMENTE';

            END TRY
            BEGIN CATCH
                ROLLBACK TRANSACTION TRX_UPD_BV;

                SET @o_Numero = 500;
                SET @o_MensajeUsuario = 'ERROR AL ACTUALIZAR EL VALOR DE NEGOCIO';
                SET @o_MensajeTecnico = CONCAT_WS(' - ', 'ERROR AL ACTUALIZAR VALOR DE NEGOCIO', ERROR_PROCEDURE(), ERROR_LINE(), ERROR_MESSAGE());
            END CATCH
        END
    END

    -- SELECT
    ELSE IF @w_Accion = 'S'
    BEGIN
        BEGIN TRY
            SELECT 
                businessValueId,
                businessValueName,
                businessValueCreationDate,
                businessValueCreatorId,
                businessValueModificationDate,
                businessValueModificatorId,
                businessValueEnable
            FROM [SQM_CATALOGS].[TBL_BusinessValues] (NOLOCK)
            ORDER BY businessValueId
            OFFSET (@i_PageNumber - 1) * @i_RowsPerPage ROWS
            FETCH NEXT @i_RowsPerPage ROWS ONLY;

            SET @w_totalRows = @@ROWCOUNT

            IF (@w_totalRows > 0)
            BEGIN
                SET @o_Numero = 200;
                SET @o_MensajeUsuario = 'VALORES DE NEGOCIO LISTADOS CORRECTAMENTE';
            END
            ELSE
            BEGIN
                SET @o_Numero = 204;
                SET @o_MensajeUsuario = 'NO HAY MAS REGISTROS PARA LISTAR';
            END

        END TRY
        BEGIN CATCH
            SET @o_Numero = 500;
            SET @o_MensajeUsuario = 'ERROR AL LISTAR LOS VALORES DE NEGOCIO';
            SET @o_MensajeTecnico = CONCAT_WS(' - ', 'ERROR AL LISTAR VALORES DE NEGOCIO', ERROR_PROCEDURE(), ERROR_LINE(), ERROR_MESSAGE());
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
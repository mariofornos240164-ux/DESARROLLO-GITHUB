USE [DB_SCRUM_PLANNING]
GO

CREATE OR ALTER PROC [SQM_SECURITY].[USP_Users]
(
    @i_userId INT = NULL,
    @i_userFullName VARCHAR(80) = NULL,
    @i_userName VARCHAR(80) = NULL,
    @i_userEmail VARCHAR(80) = NULL,
    @i_userPassword VARCHAR(256) = NULL,
    @i_userRolId INT = NULL,
    @i_userCreationDate DATETIME = NULL,
    @i_userCreatorId INT = NULL,
    @i_userModificationDate DATETIME = NULL,
    @i_userModificatorId INT = NULL,
    @i_userEnable BIT = NULL,
    @i_PageNumber INT = NULL,
    @i_RowsPerPage INT = NULL,
    @w_Accion CHAR(1),
    @o_Numero INT = NULL OUT,
    @o_MensajeTecnico VARCHAR(500) = NULL OUT,
    @o_MensajeUsuario VARCHAR(500) = NULL OUT
)
AS
BEGIN

    DECLARE @w_userPasswordEncrypted VARBINARY(256), @w_totalRows INT;

    IF @i_userCreationDate IS NULL
        SET @i_userCreationDate = GETDATE();

    IF @i_userModificationDate IS NULL
        SET @i_userModificationDate = GETDATE();

    -- INSERTAR USER --
    IF @w_Accion = 'I'
    BEGIN
        IF ISNULL(@i_userFullName,'') = ''
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL NOMBRE COMPLETO ES OBLIGATORIO';
        END;

        ELSE IF ISNULL(@i_userName,'') = ''
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL NOMBRE DE USUARIO ES OBLIGATORIO';
        END;

        ELSE IF ISNULL(@i_userEmail,'') = ''
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL CORREO ELECTRONICO ES OBLIGATORIO';
        END;

        ELSE IF ISNULL(@i_userPassword,'') = ''
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'LA CONTRASEÑA ES OBLIGATORIA';
        END;

        ELSE IF EXISTS (SELECT 1 FROM [SQM_SECURITY].[TBL_Users] (NOLOCK) WHERE userName = @i_userName)
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL NOMBRE DE USUARIO YA EXISTE';
        END;

        ELSE IF EXISTS (SELECT 1 FROM [SQM_SECURITY].[TBL_Users] (NOLOCK) WHERE userEmail = @i_userEmail)
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL CORREO YA EXISTE';
        END;

        ELSE IF NOT EXISTS (SELECT 1 FROM [SQM_CATALOGS].[TBL_Roles] (NOLOCK) WHERE rolId = @i_userRolId AND rolEnable = 1)
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL ROL NO EXISTE';
        END;
        
        ELSE
        BEGIN
            BEGIN TRANSACTION TRX_INS_USER;

            BEGIN TRY

                OPEN SYMMETRIC KEY KEY_HASH
                DECRYPTION BY CERTIFICATE CERT_SCRUMPLANNING;

                SET @w_userPasswordEncrypted = [SQM_SECURITY].[Fn_EncryptByKey](@i_userPassword);

                CLOSE SYMMETRIC KEY KEY_HASH;

                INSERT INTO [SQM_SECURITY].[TBL_Users](userFullName,userName,userEmail,userPassword,userRolId,userCreationDate,userCreatorId,userEnable)
                VALUES(@i_userFullName,@i_userName,@i_userEmail,@w_userPasswordEncrypted,@i_userRolId,@i_userCreationDate,@i_userCreatorId,1);

                COMMIT TRANSACTION TRX_INS_USER;

                SET @o_Numero = 201;
                SET @o_MensajeUsuario = 'USUARIO REGISTRADO CORRECTAMENTE';

            END TRY

            BEGIN CATCH

                ROLLBACK TRANSACTION TRX_INS_USER;

                SET @o_Numero = 500;
                SET @o_MensajeUsuario = 'ERROR AL REGISTRAR USUARIO';
                SET @o_MensajeTecnico = CONCAT_WS(' - ', 'ERROR AL REGISTRAR USUARIO', ERROR_PROCEDURE(), ERROR_LINE(), ERROR_MESSAGE());

            END CATCH
        END
    END

    -- UPDATE USER --
    ELSE IF @w_Accion = 'U'
    BEGIN

        IF ISNULL(@i_userId,0) = 0
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL ID DEL USUARIO ES OBLIGATORIO';
        END;

        IF ISNULL(@i_userModificatorId,0) = 0
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL ID DEL MODIFICADOR ES OBLIGATORIO';
        END;

        ELSE IF NOT EXISTS (SELECT 1 FROM [SQM_SECURITY].[TBL_Users] (NOLOCK) WHERE userId = @i_userId)
        BEGIN
            SET @o_Numero = 404;
            SET @o_MensajeUsuario = 'EL USUARIO NO EXISTE';
        END;

        ELSE IF @i_userName IS NOT NULL AND
            EXISTS (SELECT 1 FROM [SQM_SECURITY].[TBL_Users] (NOLOCK) WHERE userName = @i_userName
        AND userId <> @i_userId)
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL NOMBRE DE USUARIO YA EXISTE';
        END;

        ELSE IF @i_userEmail IS NOT NULL AND
            EXISTS (SELECT 1 FROM [SQM_SECURITY].[TBL_Users] (NOLOCK) WHERE userEmail = @i_userEmail
        AND userId <> @i_userId)
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL CORREO YA EXISTE';
        END;

        ELSE IF @i_userRolId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM [SQM_CATALOGS].[TBL_Roles] (NOLOCK) 
		WHERE rolId = @i_userRolId AND rolEnable = 1)
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL ROL NO EXISTE';
        END;
        
        ELSE
        BEGIN
            BEGIN TRANSACTION TRX_UPD_USER;

            BEGIN TRY

                IF @i_userPassword IS NOT NULL
                BEGIN
                    OPEN SYMMETRIC KEY KEY_HASH
                    DECRYPTION BY CERTIFICATE CERT_SCRUMPLANNING;
                        SET @w_userPasswordEncrypted = [SQM_SECURITY].Fn_EncryptByKey(@i_userPassword);
                    CLOSE SYMMETRIC KEY KEY_HASH;
                END

                UPDATE [SQM_SECURITY].[TBL_Users]
                SET userFullName = COALESCE(@i_userFullName,userFullName),
                    userName = COALESCE(@i_userName,userName),
                    userEmail = COALESCE(@i_userEmail,userEmail),
                    userPassword = COALESCE(@w_userPasswordEncrypted,userPassword),
                    userRolId = COALESCE(@i_userRolId,userRolId),
                    userModificationDate = @i_userModificationDate,
                    userModificatorId = @i_userModificatorId,
                    userEnable = COALESCE(@i_userEnable,userEnable)
                WHERE userId = @i_userId;

                COMMIT TRANSACTION TRX_UPD_USER;

                SET @o_Numero = 200;
                SET @o_MensajeUsuario = 'USUARIO ACTUALIZADO CORRECTAMENTE';

            END TRY

            BEGIN CATCH
                ROLLBACK TRANSACTION TRX_UPD_USER;

                SET @o_Numero = 500;
                SET @o_MensajeUsuario = 'ERROR AL ACTUALIZAR USUARIO'
                SET @o_MensajeTecnico =  CONCAT_WS(' - ', 'ERROR AL ACTUALIZAR USUARIO', ERROR_PROCEDURE(), ERROR_LINE(), ERROR_MESSAGE());

            END CATCH
        END
    END

-- SELECT USER --
    ELSE IF @w_Accion = 'S'
    BEGIN

        BEGIN TRY

            SELECT 
                userId, 
                userFullName,
                userName,
                userEmail,
                userRolId,
                userCreationDate,
                userCreatorId,
                userModificationDate,
                userModificatorId,
                userEnable
            FROM [SQM_SECURITY].[TBL_Users] (NOLOCK)
            ORDER BY userId
            OFFSET (@i_PageNumber - 1) * @i_RowsPerPage ROWS
            FETCH NEXT @i_RowsPerPage ROWS ONLY;

            SET @w_totalRows = @@ROWCOUNT

            IF (@w_totalRows > 0)
            BEGIN
                SET @o_Numero = 200;
                SET @o_MensajeUsuario = 'USUARIOS LISTADOS CORRECTAMENTE';
            END
            ELSE
            BEGIN
                SET @o_Numero = 204;
                SET @o_MensajeUsuario = 'NO HAY MAS REGISTROS PARA LISTAR';
            END
        END TRY

        BEGIN CATCH

            SET @o_Numero = 500;
            SET @o_MensajeUsuario = 'ERROR AL LISTAR LOS USUARIOS';
            SET @o_MensajeTecnico = CONCAT_WS(' - ', 'ERROR AL LISTAR USUARIOS', ERROR_PROCEDURE(), ERROR_LINE(), ERROR_MESSAGE());

        END CATCH

    END

 -- ACCION INVALIDA --
    ELSE
    BEGIN

        SET @o_Numero = 405;
        SET @o_MensajeUsuario = 'METODO NO HABILITADO';
        SET @o_MensajeTecnico = 'EL PROCEDIMIENTO ALMACENADO NO TIENE HABILITADA ESA OPCION';

    END

END;
GO


CREATE OR ALTER PROC [SQM_CATALOGS].[USP_Status]
(
    --parametros de la tabla
    @i_statusId INT = NULL,
    @i_statusName VARCHAR(80) = NULL,
    @i_statusCreationDate DATETIME = NULL,
    @i_statusCreatorId INT = NULL,
    @i_statusModificationDate DATETIME = NULL,
    @i_statusModificatorId INT = NULL,
    @i_statusEnable BIT = NULL,
    --parametros obligatorios
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

    IF @i_statusCreationDate IS NULL
        SET @i_statusCreationDate = GETDATE();

    IF @i_statusModificationDate IS NULL
        SET @i_statusModificationDate = GETDATE();

    -- INSERTAR USER --
    IF @w_Accion = 'I'
    BEGIN
        -- 1. Validar que los campos obligatorios no vengan vacíos
        IF ISNULL(@i_statusName,'') = ''
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL NOMBRE DEL ESTADO ES OBLIGATORIO';
        END;

        -- 2. Validar que no exista un registro con el mismo nombre
        ELSE IF EXISTS (SELECT 1 FROM [SQM_CATALOGS].[TBL_Status] (NOLOCK) WHERE statusName = @i_statusName)
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL NOMBRE DEL ESTADO YA EXISTE';
        END;
        
        -- 3. Si pasa las validaciones, procedemos a insertar
        ELSE
        BEGIN
            BEGIN TRANSACTION TRX_INS_STATUS; -- Abrimos una transacción por seguridad

            BEGIN TRY
                INSERT INTO [SQM_CATALOGS].[TBL_Status](statusName, statusCreationDate, statusCreatorId, statusModificationDate, statusModificatorId, statusEnable)
                VALUES(@i_statusName, @i_statusCreationDate, @i_statusCreatorId, @i_statusModificationDate, @i_statusModificatorId, 1);

                COMMIT TRANSACTION TRX_INS_STATUS; -- Si todo sale bien, guardamos los cambios definitivamente

                SET @o_Numero = 201; -- Código HTTP de Creado exitosamente
                SET @o_MensajeUsuario = 'ESTADO REGISTRADO CORRECTAMENTE';

            END TRY
            BEGIN CATCH
                ROLLBACK TRANSACTION TRX_INS_STATUS; -- Si algo falla, cancelamos todo para no dejar datos corruptos

                SET @o_Numero = 500;
                SET @o_MensajeUsuario = 'ERROR AL REGISTRAR EL ESTADO';
                SET @o_MensajeTecnico = CONCAT_WS(' - ', 'ERROR AL REGISTRAR ESTADO', ERROR_PROCEDURE(), ERROR_LINE(), ERROR_MESSAGE());
            END CATCH
        END
    END

    -- UPDATE USER --
    ELSE IF @w_Accion = 'U'
    BEGIN
        -- 1. Validar que el ID a modificar sea obligatorio y exista
        IF ISNULL(@i_statusId,0) = 0
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL ID DEL ESTADO ES OBLIGATORIO';
        END;

        ELSE IF NOT EXISTS (SELECT 1 FROM [SQM_CATALOGS].[TBL_Status] (NOLOCK) WHERE statusId = @i_statusId)
        BEGIN
            SET @o_Numero = 404; -- Código de No Encontrado
            SET @o_MensajeUsuario = 'EL ESTADO NO EXISTE';
        END;
        
        -- 2. Procedemos a actualizar si todo es correcto
        ELSE
        BEGIN
            BEGIN TRANSACTION TRX_UPD_STATUS;

            BEGIN TRY
                UPDATE [SQM_CATALOGS].[TBL_Status]
                SET statusName = COALESCE(@i_statusName, statusName),
                    statusModificationDate = @i_statusModificationDate,
                    statusModificatorId = @i_statusModificatorId,
                    statusEnable = COALESCE(@i_statusEnable, statusEnable)
                WHERE statusId = @i_statusId;

                COMMIT TRANSACTION TRX_UPD_STATUS;

                SET @o_Numero = 200;
                SET @o_MensajeUsuario = 'ESTADO ACTUALIZADO CORRECTAMENTE';

            END TRY
            BEGIN CATCH
                ROLLBACK TRANSACTION TRX_UPD_STATUS;
                -- (Captura de errores técnicos igual que en el Insert)
            END CATCH
        END
    END

-- SELECT USER --
   ELSE IF @w_Accion = 'S'
    BEGIN
        BEGIN TRY
            SELECT 
                statusId, 
                statusName,
                statusCreationDate,
                statusCreatorId,
                statusModificationDate,
                statusModificatorId,
                statusEnable
            FROM [SQM_CATALOGS].[TBL_Status] (NOLOCK)
            ORDER BY statusId
            OFFSET (@i_PageNumber - 1) * @i_RowsPerPage ROWS
            FETCH NEXT @i_RowsPerPage ROWS ONLY;

            SET @w_totalRows = @@ROWCOUNT

            IF (@w_totalRows > 0)
            BEGIN
                SET @o_Numero = 200;
                SET @o_MensajeUsuario = 'ESTADOS LISTADOS CORRECTAMENTE';
            END
            ELSE
            BEGIN
                SET @o_Numero = 204; -- Sin contenido
                SET @o_MensajeUsuario = 'NO HAY MAS REGISTROS PARA LISTAR';
            END

        END TRY
        BEGIN CATCH
            -- Manejo de errores de lectura
        END CATCH
    END

 -- ACCION INVALIDA --
ELSE
    BEGIN
        SET @o_Numero = 405;
        SET @o_MensajeUsuario = 'METODO NO HABILITADO';
        SET @o_MensajeTecnico = 'EL PROCEDIMIENTO ALMACENADO NO TIENE HABILITADA ESA OPCION';
    END

END;
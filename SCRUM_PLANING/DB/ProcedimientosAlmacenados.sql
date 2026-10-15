USE [DB_SCRUM_PLANNING]
GO

--USP PARA TABLA USERS

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

--USP PARA TABLA STATUS

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

--USP PARA TABLA ROLES

CREATE OR ALTER PROC [SQM_SECURITY].[USP_Roles]
(
    -- Todos los parámetros deben terminar en '= NULL'
    @I_rolId INT = NULL,
    @I_rolName VARCHAR(80) = NULL,
    @I_rolCreationDate DATETIME = NULL,
    @I_rolCreatorId INT = NULL,
    @I_rolModificationDate DATETIME = NULL,
    @I_rolModificatorId INT = NULL,
    @I_rolEnable BIT = NULL,
    -- Parámetros obligatorios de control
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

    IF @i_rolCreationDate IS NULL
        SET @i_rolCreationDate = GETDATE();

    IF @i_rolModificationDate IS NULL
        SET @i_rolModificationDate = GETDATE();

    -- INSERTAR ROL --
    IF @w_Accion = 'I'
    BEGIN
        -- 1. Validar que los campos obligatorios no vengan vacíos
        IF ISNULL(@I_rolName,'') = ''
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL NOMBRE DEL ROL ES OBLIGATORIO';
        END;

        -- 2. Validar que no exista un registro con el mismo nombre
        ELSE IF EXISTS (SELECT 1 FROM [SQM_SECURITY].[TBL_Roles] (NOLOCK) WHERE rolName = @I_rolName)
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL NOMBRE DEL ROL YA EXISTE';
        END;
        
        -- 3. Si pasa las validaciones, procedemos a insertar
        ELSE
        BEGIN
            BEGIN TRANSACTION TRX_INS_ROL; -- Abrimos una transacción por seguridad

            BEGIN TRY
                INSERT INTO [SQM_SECURITY].[TBL_Roles](rolName, rolCreationDate, rolCreatorId, rolModificationDate, rolModificatorId, rolEnable)
                VALUES(@i_rolName, @i_rolCreationDate, @i_rolCreatorId, @i_rolModificationDate, @i_rolModificatorId, 1);

                COMMIT TRANSACTION TRX_INS_ROL; -- Si todo sale bien, guardamos los cambios definitivamente

                SET @o_Numero = 201; -- Código HTTP de Creado exitosamente
                SET @o_MensajeUsuario = 'ROL REGISTRADO CORRECTAMENTE';

            END TRY
            BEGIN CATCH
                ROLLBACK TRANSACTION TRX_INS_ROL; -- Si algo falla, cancelamos todo para no dejar datos corruptos

                SET @o_Numero = 500;
                SET @o_MensajeUsuario = 'ERROR AL REGISTRAR EL ROL';
                SET @o_MensajeTecnico = CONCAT_WS(' - ', 'ERROR AL REGISTRAR ROL', ERROR_PROCEDURE(), ERROR_LINE(), ERROR_MESSAGE());
            END CATCH
        END
    END

    -- UPDATE ROL --
    ELSE IF @w_Accion = 'U'
    BEGIN
        -- 1. Validar que el ID a modificar sea obligatorio y exista
        IF ISNULL(@I_rolId,0) = 0
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL ID DEL ROL ES OBLIGATORIO';
        END;

        ELSE IF NOT EXISTS (SELECT 1 FROM [SQM_SECURITY].[TBL_Roles] (NOLOCK) WHERE rolId = @I_rolId)
        BEGIN
            SET @o_Numero = 404; -- Código de No Encontrado
            SET @o_MensajeUsuario = 'EL ROL NO EXISTE';
        END;
        
        -- 2. Procedemos a actualizar si todo es correcto
        ELSE
        BEGIN
            BEGIN TRANSACTION TRX_UPD_ROL;

            BEGIN TRY
                UPDATE [SQM_SECURITY].[TBL_Roles]
                SET rolName = COALESCE(@i_rolName, rolName),
                    rolModificationDate = @i_rolModificationDate,
                    rolModificatorId = @i_rolModificatorId,
                    rolEnable = COALESCE(@i_rolEnable, rolEnable)
                WHERE rolId = @i_rolId;

                COMMIT TRANSACTION TRX_UPD_ROL;

                SET @o_Numero = 200;
                SET @o_MensajeUsuario = 'ROL ACTUALIZADO CORRECTAMENTE';

            END TRY
            BEGIN CATCH
                ROLLBACK TRANSACTION TRX_UPD_ROL;
                -- (Captura de errores técnicos igual que en el Insert)
            END CATCH
        END
    END

-- SELECT USER --
   ELSE IF @w_Accion = 'S'
    BEGIN
        BEGIN TRY
            SELECT 
	            rolId,
	            rolName,
	            rolCreationDate,
	            rolCreatorId,
	            rolModificationDate,
	            rolModificatorId,
	            rolEnable
            FROM [SQM_SECURITY].[TBL_Roles] (NOLOCK)
            ORDER BY rolId
            OFFSET (@i_PageNumber - 1) * @i_RowsPerPage ROWS
            FETCH NEXT @i_RowsPerPage ROWS ONLY;

            SET @w_totalRows = @@ROWCOUNT

            IF (@w_totalRows > 0)
            BEGIN
                SET @o_Numero = 200;
                SET @o_MensajeUsuario = 'ROLES LISTADOS CORRECTAMENTE';
            END
            ELSE
            BEGIN
                SET @o_Numero = 204; -- Sin contenido
                SET @o_MensajeUsuario = 'NO HAY MAS REGISTROS PARA LISTAR';
            END

        END TRY
        BEGIN CATCH
            SET @o_Numero = 500;
            SET @o_MensajeUsuario = 'ERROR AL LISTAR LOS ROLES';
            SET @o_MensajeTecnico = CONCAT_WS(' - ', 'ERROR AL LISTAR ROLES', ERROR_PROCEDURE(), ERROR_LINE(), ERROR_MESSAGE());
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

--USP PARA TABLA BUSINESVALUE

CREATE OR ALTER PROC [SQM_CATALOGS].[USP_BusinessValues]
(
    -- Parámetros de la tabla
    @i_businessValueId INT = NULL,
    @i_businessValueName VARCHAR(80) = NULL,
    @i_businessValueCreationDate DATETIME = NULL,
    @i_businessValueCreatorId INT = NULL,
    @i_businessValueModificationDate DATETIME = NULL,
    @i_businessValueModificatorId INT = NULL,
    @i_businessValueEnable BIT = NULL,
    -- Parámetros obligatorios de control
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

    IF @i_businessValueModificationDate IS NULL
        SET @i_businessValueModificationDate = GETDATE();

    -- INSERTAR BUSINESS VALUE --
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
            BEGIN TRANSACTION TRX_INS_BUSVAL;

            BEGIN TRY
                INSERT INTO [SQM_CATALOGS].[TBL_BusinessValues](businessValueName, businessValueCreationDate, businessValueCreatorId, businessValueModificationDate, businessValueModificatorId, businessValueEnable)
                VALUES(@i_businessValueName, @i_businessValueCreationDate, @i_businessValueCreatorId, @i_businessValueModificationDate, @i_businessValueModificatorId, 1);

                COMMIT TRANSACTION TRX_INS_BUSVAL;

                SET @o_Numero = 201;
                SET @o_MensajeUsuario = 'VALOR DE NEGOCIO REGISTRADO CORRECTAMENTE';

            END TRY
            BEGIN CATCH
                ROLLBACK TRANSACTION TRX_INS_BUSVAL;

                SET @o_Numero = 500;
                SET @o_MensajeUsuario = 'ERROR AL REGISTRAR EL VALOR DE NEGOCIO';
                SET @o_MensajeTecnico = CONCAT_WS(' - ', 'ERROR AL REGISTRAR VALOR DE NEGOCIO', ERROR_PROCEDURE(), ERROR_LINE(), ERROR_MESSAGE());
            END CATCH
        END
    END

    -- UPDATE BUSINESS VALUE --
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
            BEGIN TRANSACTION TRX_UPD_BUSVAL;

            BEGIN TRY
                UPDATE [SQM_CATALOGS].[TBL_BusinessValues]
                SET businessValueName = COALESCE(@i_businessValueName, businessValueName),
                    businessValueModificationDate = @i_businessValueModificationDate,
                    businessValueModificatorId = @i_businessValueModificatorId,
                    businessValueEnable = COALESCE(@i_businessValueEnable, businessValueEnable)
                WHERE businessValueId = @i_businessValueId;

                COMMIT TRANSACTION TRX_UPD_BUSVAL;

                SET @o_Numero = 200;
                SET @o_MensajeUsuario = 'VALOR DE NEGOCIO ACTUALIZADO CORRECTAMENTE';

            END TRY
            BEGIN CATCH
                ROLLBACK TRANSACTION TRX_UPD_BUSVAL;

                SET @o_Numero = 500;
                SET @o_MensajeUsuario = 'ERROR AL ACTUALIZAR EL VALOR DE NEGOCIO';
                SET @o_MensajeTecnico = CONCAT_WS(' - ', 'ERROR AL ACTUALIZAR VALOR DE NEGOCIO', ERROR_PROCEDURE(), ERROR_LINE(), ERROR_MESSAGE());
            END CATCH
        END
    END

    -- SELECT BUSINESS VALUE --
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

    -- ACCION INVALIDA --
    ELSE
    BEGIN
        SET @o_Numero = 405;
        SET @o_MensajeUsuario = 'METODO NO HABILITADO';
        SET @o_MensajeTecnico = 'EL PROCEDIMIENTO ALMACENADO NO TIENE HABILITADA ESA OPCION';
    END

END;
GO

--USP PARA TABLA INITIATIVES

USE [DB_SCRUM_PLANNING]
GO

CREATE OR ALTER PROC [SQM_GENERAL].[USP_Initiatives]
(
    -- Parámetros de la tabla TBL_Initiatives
    @i_initiativeId INT = NULL,
    @i_initiativeSummary VARCHAR(200) = NULL,
    @i_initiativeDescription VARCHAR(2000) = NULL,
    @i_initiativeOwner INT = NULL,
    @i_initiativeGoals VARCHAR(255) = NULL,
    @i_initiativeBusinessValue INT = NULL,
    @i_initiativeTargetStart DATE = NULL,
    @i_initiativeTargetEnd DATE = NULL,
    @i_initiativeCreationDate DATETIME = NULL,
    @i_initiativeCreatorId INT = NULL,
    @i_initiativeModificationDate DATETIME = NULL,
    @i_initiativeModificatorId INT = NULL,
    @i_initiativeStatus INT = NULL,
    -- Parámetros obligatorios de control
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

    IF @i_initiativeCreationDate IS NULL
        SET @i_initiativeCreationDate = GETDATE();

    IF @i_initiativeModificationDate IS NULL
        SET @i_initiativeModificationDate = GETDATE();

    -- INSERTAR INITIATIVE --
    IF @w_Accion = 'I'
    BEGIN
        IF ISNULL(@i_initiativeSummary,'') = ''
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL RESUMEN DE LA INICIATIVA ES OBLIGATORIO';
        END;

        ELSE IF ISNULL(@i_initiativeDescription,'') = ''
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'LA DESCRIPCION DE LA INICIATIVA ES OBLIGATORIA';
        END;

        ELSE IF ISNULL(@i_initiativeOwner,0) = 0
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL DUEÑO DE LA INICIATIVA ES OBLIGATORIO';
        END;

        ELSE IF ISNULL(@i_initiativeBusinessValue,0) = 0
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL VALOR DE NEGOCIO ES OBLIGATORIO';
        END;

        ELSE IF ISNULL(@i_initiativeStatus,0) = 0
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL ESTADO DE LA INICIATIVA ES OBLIGATORIO';
        END;

        ELSE IF NOT EXISTS (SELECT 1 FROM [SQM_SECURITY].[TBL_Users] (NOLOCK) WHERE userId = @i_initiativeOwner)
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL DUEÑO (USUARIO) DE LA INICIATIVA NO EXISTE';
        END;

        ELSE IF NOT EXISTS (SELECT 1 FROM [SQM_CATALOGS].[TBL_BusinessValues] (NOLOCK) WHERE businessValueId = @i_initiativeBusinessValue AND businessValueEnable = 1)
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL VALOR DE NEGOCIO NO EXISTE O NO ESTA ACTIVO';
        END;

        ELSE IF NOT EXISTS (SELECT 1 FROM [SQM_CATALOGS].[TBL_Status] (NOLOCK) WHERE statusId = @i_initiativeStatus AND statusEnable = 1)
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL ESTADO NO EXISTE O NO ESTA ACTIVO';
        END;
        
        ELSE
        BEGIN
            BEGIN TRANSACTION TRX_INS_INITIATIVE;

            BEGIN TRY
                INSERT INTO [SQM_GENERAL].[TBL_Initiatives](
                    initiativeSummary, initiativeDescription, initiativeOwner, initiativeGoals, 
                    initiativeBusinessValue, initiativeTargetStart, initiativeTargetEnd, 
                    initiativeCreationDate, initiativeCreatorId, initiativeModificationDate, 
                    initiativeModificatorId, initiativeStatus
                )
                VALUES(
                    @i_initiativeSummary, @i_initiativeDescription, @i_initiativeOwner, @i_initiativeGoals, 
                    @i_initiativeBusinessValue, @i_initiativeTargetStart, @i_initiativeTargetEnd, 
                    @i_initiativeCreationDate, @i_initiativeCreatorId, @i_initiativeModificationDate, 
                    @i_initiativeModificatorId, @i_initiativeStatus
                );

                COMMIT TRANSACTION TRX_INS_INITIATIVE;

                SET @o_Numero = 201;
                SET @o_MensajeUsuario = 'INICIATIVA REGISTRADA CORRECTAMENTE';

            END TRY
            BEGIN CATCH
                ROLLBACK TRANSACTION TRX_INS_INITIATIVE;

                SET @o_Numero = 500;
                SET @o_MensajeUsuario = 'ERROR AL REGISTRAR LA INICIATIVA';
                SET @o_MensajeTecnico = CONCAT_WS(' - ', 'ERROR AL REGISTRAR INICIATIVA', ERROR_PROCEDURE(), ERROR_LINE(), ERROR_MESSAGE());
            END CATCH
        END
    END

    -- UPDATE INITIATIVE --
    ELSE IF @w_Accion = 'U'
    BEGIN
        IF ISNULL(@i_initiativeId,0) = 0
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL ID DE LA INICIATIVA ES OBLIGATORIO';
        END;

        ELSE IF ISNULL(@i_initiativeModificatorId,0) = 0
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL ID DEL MODIFICADOR ES OBLIGATORIO';
        END;

        ELSE IF NOT EXISTS (SELECT 1 FROM [SQM_GENERAL].[TBL_Initiatives] (NOLOCK) WHERE initiativeId = @i_initiativeId)
        BEGIN
            SET @o_Numero = 404;
            SET @o_MensajeUsuario = 'LA INICIATIVA NO EXISTE';
        END;

        ELSE IF @i_initiativeOwner IS NOT NULL AND NOT EXISTS (SELECT 1 FROM [SQM_SECURITY].[TBL_Users] (NOLOCK) WHERE userId = @i_initiativeOwner)
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL DUEÑO (USUARIO) DE LA INICIATIVA NO EXISTE';
        END;

        ELSE IF @i_initiativeBusinessValue IS NOT NULL AND NOT EXISTS (SELECT 1 FROM [SQM_CATALOGS].[TBL_BusinessValues] (NOLOCK) WHERE businessValueId = @i_initiativeBusinessValue AND businessValueEnable = 1)
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL VALOR DE NEGOCIO NO EXISTE O NO ESTA ACTIVO';
        END;

        ELSE IF @i_initiativeStatus IS NOT NULL AND NOT EXISTS (SELECT 1 FROM [SQM_CATALOGS].[TBL_Status] (NOLOCK) WHERE statusId = @i_initiativeStatus AND statusEnable = 1)
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL ESTADO NO EXISTE O NO ESTA ACTIVO';
        END;
        
        ELSE
        BEGIN
            BEGIN TRANSACTION TRX_UPD_INITIATIVE;

            BEGIN TRY
                UPDATE [SQM_GENERAL].[TBL_Initiatives]
                SET initiativeSummary = COALESCE(@i_initiativeSummary, initiativeSummary),
                    initiativeDescription = COALESCE(@i_initiativeDescription, initiativeDescription),
                    initiativeOwner = COALESCE(@i_initiativeOwner, initiativeOwner),
                    initiativeGoals = COALESCE(@i_initiativeGoals, initiativeGoals),
                    initiativeBusinessValue = COALESCE(@i_initiativeBusinessValue, initiativeBusinessValue),
                    initiativeTargetStart = COALESCE(@i_initiativeTargetStart, initiativeTargetStart),
                    initiativeTargetEnd = COALESCE(@i_initiativeTargetEnd, initiativeTargetEnd),
                    initiativeModificationDate = @i_initiativeModificationDate,
                    initiativeModificatorId = @i_initiativeModificatorId,
                    initiativeStatus = COALESCE(@i_initiativeStatus, initiativeStatus)
                WHERE initiativeId = @i_initiativeId;

                COMMIT TRANSACTION TRX_UPD_INITIATIVE;

                SET @o_Numero = 200;
                SET @o_MensajeUsuario = 'INICIATIVA ACTUALIZADA CORRECTAMENTE';

            END TRY
            BEGIN CATCH
                ROLLBACK TRANSACTION TRX_UPD_INITIATIVE;

                SET @o_Numero = 500;
                SET @o_MensajeUsuario = 'ERROR AL ACTUALIZAR LA INICIATIVA';
                SET @o_MensajeTecnico = CONCAT_WS(' - ', 'ERROR AL ACTUALIZAR INICIATIVA', ERROR_PROCEDURE(), ERROR_LINE(), ERROR_MESSAGE());
            END CATCH
        END
    END

    -- SELECT INITIATIVE --
    ELSE IF @w_Accion = 'S'
    BEGIN
        BEGIN TRY
            SELECT 
                initiativeId,
                initiativeSummary,
                initiativeDescription,
                initiativeOwner,
                initiativeGoals,
                initiativeBusinessValue,
                initiativeTargetStart,
                initiativeTargetEnd,
                initiativeCreationDate,
                initiativeCreatorId,
                initiativeModificationDate,
                initiativeModificatorId,
                initiativeStatus
            FROM [SQM_GENERAL].[TBL_Initiatives] (NOLOCK)
            ORDER BY initiativeId
            OFFSET (@i_PageNumber - 1) * @i_RowsPerPage ROWS
            FETCH NEXT @i_RowsPerPage ROWS ONLY;

            SET @w_totalRows = @@ROWCOUNT

            IF (@w_totalRows > 0)
            BEGIN
                SET @o_Numero = 200;
                SET @o_MensajeUsuario = 'INICIATIVAS LISTADAS CORRECTAMENTE';
            END
            ELSE
            BEGIN
                SET @o_Numero = 204;
                SET @o_MensajeUsuario = 'NO HAY MAS REGISTROS PARA LISTAR';
            END

        END TRY
        BEGIN CATCH
            SET @o_Numero = 500;
            SET @o_MensajeUsuario = 'ERROR AL LISTAR LAS INICIATIVAS';
            SET @o_MensajeTecnico = CONCAT_WS(' - ', 'ERROR AL LISTAR INICIATIVAS', ERROR_PROCEDURE(), ERROR_LINE(), ERROR_MESSAGE());
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

--USP PARA TABLA PRIORITIES

CREATE OR ALTER PROC [SQM_CATALOGS].[USP_Priorities]
(
    -- Parámetros de la tabla TBL_Priorities
    @i_priorityId INT = NULL,
    @i_priorityName VARCHAR(80) = NULL,
    @i_priorityCreationDate DATETIME = NULL,
    @i_priorityCreatorId INT = NULL,
    @i_priorityModificationDate DATETIME = NULL,
    @i_priorityModificatorId INT = NULL,
    @i_priorityEnable BIT = NULL,
    -- Parámetros obligatorios de control
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

    IF @i_priorityCreationDate IS NULL
        SET @i_priorityCreationDate = GETDATE();

    IF @i_priorityModificationDate IS NULL
        SET @i_priorityModificationDate = GETDATE();

    -- INSERTAR PRIORITY --
    IF @w_Accion = 'I'
    BEGIN
        IF ISNULL(@i_priorityName,'') = ''
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL NOMBRE DE LA PRIORIDAD ES OBLIGATORIO';
        END;

        ELSE IF EXISTS (SELECT 1 FROM [SQM_CATALOGS].[TBL_Priorities] (NOLOCK) WHERE priorityName = @i_priorityName)
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL NOMBRE DE LA PRIORIDAD YA EXISTE';
        END;
        
        ELSE
        BEGIN
            BEGIN TRANSACTION TRX_INS_PRIORITY;

            BEGIN TRY
                INSERT INTO [SQM_CATALOGS].[TBL_Priorities](
                    priorityName, priorityCreationDate, priorityCreatorId, 
                    priorityModificationDate, priorityModificatorId, priorityEnable
                )
                VALUES(
                    @i_priorityName, @i_priorityCreationDate, @i_priorityCreatorId, 
                    @i_priorityModificationDate, @i_priorityModificatorId, 1
                );

                COMMIT TRANSACTION TRX_INS_PRIORITY;

                SET @o_Numero = 201;
                SET @o_MensajeUsuario = 'PRIORIDAD REGISTRADA CORRECTAMENTE';

            END TRY
            BEGIN CATCH
                ROLLBACK TRANSACTION TRX_INS_PRIORITY;

                SET @o_Numero = 500;
                SET @o_MensajeUsuario = 'ERROR AL REGISTRAR LA PRIORIDAD';
                SET @o_MensajeTecnico = CONCAT_WS(' - ', 'ERROR AL REGISTRAR PRIORIDAD', ERROR_PROCEDURE(), ERROR_LINE(), ERROR_MESSAGE());
            END CATCH
        END
    END

    -- UPDATE PRIORITY --
    ELSE IF @w_Accion = 'U'
    BEGIN
        IF ISNULL(@i_priorityId,0) = 0
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL ID DE LA PRIORIDAD ES OBLIGATORIO';
        END;

        ELSE IF ISNULL(@i_priorityModificatorId,0) = 0
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL ID DEL MODIFICADOR ES OBLIGATORIO';
        END;

        ELSE IF NOT EXISTS (SELECT 1 FROM [SQM_CATALOGS].[TBL_Priorities] (NOLOCK) WHERE priorityId = @i_priorityId)
        BEGIN
            SET @o_Numero = 404;
            SET @o_MensajeUsuario = 'LA PRIORIDAD NO EXISTE';
        END;

        ELSE IF @i_priorityName IS NOT NULL AND
            EXISTS (SELECT 1 FROM [SQM_CATALOGS].[TBL_Priorities] (NOLOCK) WHERE priorityName = @i_priorityName AND priorityId <> @i_priorityId)
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL NOMBRE DE LA PRIORIDAD YA EXISTE';
        END;
        
        ELSE
        BEGIN
            BEGIN TRANSACTION TRX_UPD_PRIORITY;

            BEGIN TRY
                UPDATE [SQM_CATALOGS].[TBL_Priorities]
                SET priorityName = COALESCE(@i_priorityName, priorityName),
                    priorityModificationDate = @i_priorityModificationDate,
                    priorityModificatorId = @i_priorityModificatorId,
                    priorityEnable = COALESCE(@i_priorityEnable, priorityEnable)
                WHERE priorityId = @i_priorityId;

                COMMIT TRANSACTION TRX_UPD_PRIORITY;

                SET @o_Numero = 200;
                SET @o_MensajeUsuario = 'PRIORIDAD ACTUALIZADA CORRECTAMENTE';

            END TRY
            BEGIN CATCH
                ROLLBACK TRANSACTION TRX_UPD_PRIORITY;

                SET @o_Numero = 500;
                SET @o_MensajeUsuario = 'ERROR AL REGISTRAR LA ACTUALIZACION'; -- o actualizar la prioridad
                SET @o_MensajeTecnico = CONCAT_WS(' - ', 'ERROR AL ACTUALIZAR PRIORIDAD', ERROR_PROCEDURE(), ERROR_LINE(), ERROR_MESSAGE());
            END CATCH
        END
    END

    -- SELECT PRIORITY --
    ELSE IF @w_Accion = 'S'
    BEGIN
        BEGIN TRY
            SELECT 
                priorityId,
                priorityName,
                priorityCreationDate,
                priorityCreatorId,
                priorityModificationDate,
                priorityModificatorId,
                priorityEnable
            FROM [SQM_CATALOGS].[TBL_Priorities] (NOLOCK)
            ORDER BY priorityId
            OFFSET (@i_PageNumber - 1) * @i_RowsPerPage ROWS
            FETCH NEXT @i_RowsPerPage ROWS ONLY;

            SET @w_totalRows = @@ROWCOUNT

            IF (@w_totalRows > 0)
            BEGIN
                SET @o_Numero = 200;
                SET @o_MensajeUsuario = 'PRIORIDADES LISTADAS CORRECTAMENTE';
            END
            ELSE
            BEGIN
                SET @o_Numero = 204;
                SET @o_MensajeUsuario = 'NO HAY MAS REGISTROS PARA LISTAR';
            END

        END TRY
        BEGIN CATCH
            SET @o_Numero = 500;
            SET @o_MensajeUsuario = 'ERROR AL LISTAR LAS PRIORIDADES';
            SET @o_MensajeTecnico = CONCAT_WS(' - ', 'ERROR AL LISTAR PRIORIDADES', ERROR_PROCEDURE(), ERROR_LINE(), ERROR_MESSAGE());
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

--USP PARA TABLA EPICS

CREATE OR ALTER PROC [SQM_GENERAL].[USP_Epics]
(
    -- Parámetros de la tabla TBL_Epics
    @i_epicId INT = NULL,
    @i_epicName VARCHAR(100) = NULL,
    @i_epicSummary VARCHAR(500) = NULL,
    @i_epicDescription VARCHAR(4000) = NULL,
    @i_epicParentLink INT = NULL, -- Iniciativa padre
    @i_epicOwner INT = NULL,      -- Dueño de la épica
    @i_epicStartDate DATE = NULL,
    @i_epicDueDate DATE = NULL,
    @i_epicPriority INT = NULL,   -- Prioridad
    @i_epicCreationDate DATETIME = NULL,
    @i_epicCreatorId INT = NULL,
    @i_epicModificationDate DATETIME = NULL,
    @i_epicModificatorId INT = NULL,
    @i_epicStatus INT = NULL,     -- Estado
    -- Parámetros obligatorios de control
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

    IF @i_epicCreationDate IS NULL
        SET @i_epicCreationDate = GETDATE();

    IF @i_epicModificationDate IS NULL
        SET @i_epicModificationDate = GETDATE();

    -- INSERTAR EPIC --
    IF @w_Accion = 'I'
    BEGIN
        IF ISNULL(@i_epicName,'') = ''
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL NOMBRE DE LA EPICA ES OBLIGATORIO';
        END;

        ELSE IF ISNULL(@i_epicSummary,'') = ''
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL RESUMEN DE LA EPICA ES OBLIGATORIO';
        END;

        ELSE IF ISNULL(@i_epicDescription,'') = ''
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'LA DESCRIPCION DE LA EPICA ES OBLIGATORIA';
        END;

        ELSE IF ISNULL(@i_epicParentLink,0) = 0
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'LA INICIATIVA ASOCIADA (PARENT LINK) ES OBLIGATORIA';
        END;

        ELSE IF ISNULL(@i_epicOwner,0) = 0
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL DUEÑO DE LA EPICA ES OBLIGATORIO';
        END;

        ELSE IF ISNULL(@i_epicStatus,0) = 0
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL ESTADO DE LA EPICA ES OBLIGATORIO';
        END;

        -- Validaciones cruzadas de llaves foráneas
        ELSE IF NOT EXISTS (SELECT 1 FROM [SQM_GENERAL].[TBL_Initiatives] (NOLOCK) WHERE initiativeId = @i_epicParentLink)
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'LA INICIATIVA ASOCIADA NO EXISTE';
        END;

        ELSE IF NOT EXISTS (SELECT 1 FROM [SQM_SECURITY].[TBL_Users] (NOLOCK) WHERE userId = @i_epicOwner)
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL DUEÑO (USUARIO) DE LA EPICA NO EXISTE';
        END;

        ELSE IF @i_epicPriority IS NOT NULL AND NOT EXISTS (SELECT 1 FROM [SQM_CATALOGS].[TBL_Priorities] (NOLOCK) WHERE priorityId = @i_epicPriority AND priorityEnable = 1)
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'LA PRIORIDAD NO EXISTE O NO ESTA ACTIVA';
        END;

        ELSE IF NOT EXISTS (SELECT 1 FROM [SQM_CATALOGS].[TBL_Status] (NOLOCK) WHERE statusId = @i_epicStatus AND statusEnable = 1)
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL ESTADO NO EXISTE O NO ESTA ACTIVO';
        END;
        
        ELSE
        BEGIN
            BEGIN TRANSACTION TRX_INS_EPIC;

            BEGIN TRY
                INSERT INTO [SQM_GENERAL].[TBL_Epics](
                    epicName, epicSummary, epicDescription, epicParentLink, epicOwner, 
                    epicStartDate, epicDueDate, epicPriority, epicCreationDate, 
                    epicCreatorId, epicModificationDate, epicModificatorId, epicStatus
                )
                VALUES(
                    @i_epicName, @i_epicSummary, @i_epicDescription, @i_epicParentLink, @i_epicOwner, 
                    @i_epicStartDate, @i_epicDueDate, @i_epicPriority, @i_epicCreationDate, 
                    @i_epicCreatorId, @i_epicModificationDate, @i_epicModificatorId, @i_epicStatus
                );

                COMMIT TRANSACTION TRX_INS_EPIC;

                SET @o_Numero = 201;
                SET @o_MensajeUsuario = 'EPICA REGISTRADA CORRECTAMENTE';

            END TRY
            BEGIN CATCH
                ROLLBACK TRANSACTION TRX_INS_EPIC;

                SET @o_Numero = 500;
                SET @o_MensajeUsuario = 'ERROR AL REGISTRAR LA EPICA';
                SET @o_MensajeTecnico = CONCAT_WS(' - ', 'ERROR AL REGISTRAR EPICA', ERROR_PROCEDURE(), ERROR_LINE(), ERROR_MESSAGE());
            END CATCH
        END
    END

    -- UPDATE EPIC --
    ELSE IF @w_Accion = 'U'
    BEGIN
        IF ISNULL(@i_epicId,0) = 0
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL ID DE LA EPICA ES OBLIGATORIO';
        END;

        ELSE IF ISNULL(@i_epicModificatorId,0) = 0
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL ID DEL MODIFICADOR ES OBLIGATORIO';
        END;

        ELSE IF NOT EXISTS (SELECT 1 FROM [SQM_GENERAL].[TBL_Epics] (NOLOCK) WHERE epicId = @i_epicId)
        BEGIN
            SET @o_Numero = 404;
            SET @o_MensajeUsuario = 'LA EPICA NO EXISTE';
        END;

        -- Validaciones cruzadas opcionales durante la actualización
        ELSE IF @i_epicParentLink IS NOT NULL AND NOT EXISTS (SELECT 1 FROM [SQM_GENERAL].[TBL_Initiatives] (NOLOCK) WHERE initiativeId = @i_epicParentLink)
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'LA INICIATIVA ASOCIADA NO EXISTE';
        END;

        ELSE IF @i_epicOwner IS NOT NULL AND NOT EXISTS (SELECT 1 FROM [SQM_SECURITY].[TBL_Users] (NOLOCK) WHERE userId = @i_epicOwner)
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL DUEÑO (USUARIO) DE LA EPICA NO EXISTE';
        END;

        ELSE IF @i_epicPriority IS NOT NULL AND NOT EXISTS (SELECT 1 FROM [SQM_CATALOGS].[TBL_Priorities] (NOLOCK) WHERE priorityId = @i_epicPriority AND priorityEnable = 1)
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'LA PRIORIDAD NO EXISTE O NO ESTA ACTIVA';
        END;

        ELSE IF @i_epicStatus IS NOT NULL AND NOT EXISTS (SELECT 1 FROM [SQM_CATALOGS].[TBL_Status] (NOLOCK) WHERE statusId = @i_epicStatus AND statusEnable = 1)
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL ESTADO NO EXISTE O NO ESTA ACTIVO';
        END;
        
        ELSE
        BEGIN
            BEGIN TRANSACTION TRX_UPD_EPIC;

            BEGIN TRY
                UPDATE [SQM_GENERAL].[TBL_Epics]
                SET epicName = COALESCE(@i_epicName, epicName),
                    epicSummary = COALESCE(@i_epicSummary, epicSummary),
                    epicDescription = COALESCE(@i_epicDescription, epicDescription),
                    epicParentLink = COALESCE(@i_epicParentLink, epicParentLink),
                    epicOwner = COALESCE(@i_epicOwner, epicOwner),
                    epicStartDate = COALESCE(@i_epicStartDate, epicStartDate),
                    epicDueDate = COALESCE(@i_epicDueDate, epicDueDate),
                    epicPriority = COALESCE(@i_epicPriority, epicPriority),
                    epicModificationDate = @i_epicModificationDate,
                    epicModificatorId = @i_epicModificatorId,
                    epicStatus = COALESCE(@i_epicStatus, epicStatus)
                WHERE epicId = @i_epicId;

                COMMIT TRANSACTION TRX_UPD_EPIC;

                SET @o_Numero = 200;
                SET @o_MensajeUsuario = 'EPICA ACTUALIZADA CORRECTAMENTE';

            END TRY
            BEGIN CATCH
                ROLLBACK TRANSACTION TRX_UPD_EPIC;

                SET @o_Numero = 500;
                SET @o_MensajeUsuario = 'ERROR AL ACTUALIZAR LA EPICA';
                SET @o_MensajeTecnico = CONCAT_WS(' - ', 'ERROR AL ACTUALIZAR EPICA', ERROR_PROCEDURE(), ERROR_LINE(), ERROR_MESSAGE());
            END CATCH
        END
    END

    -- SELECT EPIC --
    ELSE IF @w_Accion = 'S'
    BEGIN
        BEGIN TRY
            SELECT 
                epicId,
                epicName,
                epicSummary,
                epicDescription,
                epicParentLink,
                epicOwner,
                epicStartDate,
                epicDueDate,
                epicPriority,
                epicCreationDate,
                epicCreatorId,
                epicModificationDate,
                epicModificatorId,
                epicStatus
            FROM [SQM_GENERAL].[TBL_Epics] (NOLOCK)
            ORDER BY epicId
            OFFSET (@i_PageNumber - 1) * @i_RowsPerPage ROWS
            FETCH NEXT @i_RowsPerPage ROWS ONLY;

            SET @w_totalRows = @@ROWCOUNT

            IF (@w_totalRows > 0)
            BEGIN
                SET @o_Numero = 200;
                SET @o_MensajeUsuario = 'EPICAS LISTADAS CORRECTAMENTE';
            END
            ELSE
            BEGIN
                SET @o_Numero = 204;
                SET @o_MensajeUsuario = 'NO HAY MAS REGISTROS PARA LISTAR';
            END

        END TRY
        BEGIN CATCH
            SET @o_Numero = 500;
            SET @o_MensajeUsuario = 'ERROR AL LISTAR LAS EPICAS';
            SET @o_MensajeTecnico = CONCAT_WS(' - ', 'ERROR AL LISTAR EPICAS', ERROR_PROCEDURE(), ERROR_LINE(), ERROR_MESSAGE());
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

--USP PARA TABLA FEATURES

USE [DB_SCRUM_PLANNING]
GO

USE [DB_SCRUM_PLANNING]
GO

CREATE OR ALTER PROC [SQM_GENERAL].[USP_Features]
(
    -- Parámetros de la tabla TBL_Features (Corregido: featureSummary en singular)
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
    -- Parámetros obligatorios de control
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

    IF @i_featureModificationDate IS NULL
        SET @i_featureModificationDate = GETDATE();

    -- INSERTAR FEATURE --
    IF @w_Accion = 'I'
    BEGIN
        IF ISNULL(@i_featureSummary,'') = ''
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL RESUMEN DE LA FEATURE ES OBLIGATORIO';
        END;

        ELSE IF ISNULL(@i_featureDescription,'') = ''
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'LA DESCRIPCION DE LA FEATURE ES OBLIGATORIA';
        END;

        ELSE IF ISNULL(@i_featuresAcceptanceCriteria,'') = ''
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'LOS CRITERIOS DE ACEPTACION SON OBLIGATORIOS';
        END;

        ELSE IF ISNULL(@i_featureParentLink,0) = 0
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'LA EPICA ASOCIADA (PARENT LINK) ES OBLIGATORIA';
        END;

        ELSE IF ISNULL(@i_featureOwner,0) = 0
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL DUEÑO DE LA FEATURE ES OBLIGATORIO';
        END;

        ELSE IF ISNULL(@i_featureStatus,0) = 0
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL ESTADO DE LA FEATURE ES OBLIGATORIO';
        END;

        -- Validaciones cruzadas de llaves foráneas
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
                    @i_featureModificationDate, @i_featureModificatorId, @i_featureStatus
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

    -- UPDATE FEATURE --
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

        -- Validaciones cruzadas opcionales durante la actualización
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

    -- SELECT FEATURE --
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

    -- ACCION INVALIDA --
    ELSE
    BEGIN
        SET @o_Numero = 405;
        SET @o_MensajeUsuario = 'METODO NO HABILITADO';
        SET @o_MensajeTecnico = 'EL PROCEDIMIENTO ALMACENADO NO TIENE HABILITADA ESA OPCION';
    END

END;
GO

--USP PARA TABLA ProductBacklogItems

USE [DB_SCRUM_PLANNING]
GO

CREATE OR ALTER PROC [SQM_GENERAL].[USP_ProductBacklogItems]
(
    -- Parámetros de la tabla TBL_ProductBacklogItems
    @i_PBIId INT = NULL,
    @i_PBISummary VARCHAR(500) = NULL,
    @i_PBIDescription VARCHAR(2000) = NULL,
    @i_PBIsAcceptanceCriteria VARCHAR(4000) = NULL,
    @i_PBIOwner INT = NULL,          -- Dueño del PBI
    @i_PBIParentLink INT = NULL,     -- Feature padre
    @i_PBIStoryPoint INT = NULL,     -- Story Points
    @i_PBIStartDate DATE = NULL,
    @i_PBIDueDate DATE = NULL,
    @i_PBIPriority INT = NULL,       -- Prioridad
    @i_PBICreationDate DATETIME = NULL,
    @i_PBICreatorId INT = NULL,
    @i_PBIModificationDate DATETIME = NULL,
    @i_PBIModificatorId INT = NULL,
    @i_PBIStatus INT = NULL,         -- Estado
    -- Parámetros obligatorios de control
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

    IF @i_PBICreationDate IS NULL
        SET @i_PBICreationDate = GETDATE();

    IF @i_PBIModificationDate IS NULL
        SET @i_PBIModificationDate = GETDATE();

    -- INSERTAR PBI --
    IF @w_Accion = 'I'
    BEGIN
        IF ISNULL(@i_PBISummary,'') = ''
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL RESUMEN DEL PBI ES OBLIGATORIO';
        END;

        ELSE IF ISNULL(@i_PBIDescription,'') = ''
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'LA DESCRIPCION DEL PBI ES OBLIGATORIA';
        END;

        ELSE IF ISNULL(@i_PBIsAcceptanceCriteria,'') = ''
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'LOS CRITERIOS DE ACEPTACION SON OBLIGATORIOS';
        END;

        ELSE IF ISNULL(@i_PBIOwner,0) = 0
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL DUEÑO DEL PBI ES OBLIGATORIO';
        END;

        ELSE IF ISNULL(@i_PBIParentLink,0) = 0
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'LA FEATURE ASOCIADA (PARENT LINK) ES OBLIGATORIA';
        END;

        ELSE IF ISNULL(@i_PBIStatus,0) = 0
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL ESTADO DEL PBI ES OBLIGATORIO';
        END;

        -- Validaciones cruzadas de llaves foráneas
        ELSE IF NOT EXISTS (SELECT 1 FROM [SQM_GENERAL].[TBL_Features] (NOLOCK) WHERE featureId = @i_PBIParentLink)
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'LA FEATURE ASOCIADA NO EXISTE';
        END;

        ELSE IF NOT EXISTS (SELECT 1 FROM [SQM_SECURITY].[TBL_Users] (NOLOCK) WHERE userId = @i_PBIOwner)
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL DUEÑO (USUARIO) DEL PBI NO EXISTE';
        END;

        ELSE IF @i_PBIPriority IS NOT NULL AND NOT EXISTS (SELECT 1 FROM [SQM_CATALOGS].[TBL_Priorities] (NOLOCK) WHERE priorityId = @i_PBIPriority AND priorityEnable = 1)
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'LA PRIORIDAD NO EXISTE O NO ESTA ACTIVA';
        END;

        ELSE IF NOT EXISTS (SELECT 1 FROM [SQM_CATALOGS].[TBL_Status] (NOLOCK) WHERE statusId = @i_PBIStatus AND statusEnable = 1)
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL ESTADO NO EXISTE O NO ESTA ACTIVO';
        END;
        
        ELSE
        BEGIN
            BEGIN TRANSACTION TRX_INS_PBI;

            BEGIN TRY
                INSERT INTO [SQM_GENERAL].[TBL_ProductBacklogItems](
                    PBISummary, PBIDescription, PBIsAcceptanceCriteria, PBIOwner, 
                    PBIParentLink, PBIStoryPoint, PBIStartDate, PBIDueDate, 
                    PBIPriority, PBICreationDate, PBICreatorId, 
                    PBIModificationDate, PBIModificatorId, PBIStatus
                )
                VALUES(
                    @i_PBISummary, @i_PBIDescription, @i_PBIsAcceptanceCriteria, @i_PBIOwner, 
                    @i_PBIParentLink, @i_PBIStoryPoint, @i_PBIStartDate, @i_PBIDueDate, 
                    @i_PBIPriority, @i_PBICreationDate, @i_PBICreatorId, 
                    @i_PBIModificationDate, @i_PBIModificatorId, @i_PBIStatus
                );

                COMMIT TRANSACTION TRX_INS_PBI;

                SET @o_Numero = 201;
                SET @o_MensajeUsuario = 'PBI REGISTRADO CORRECTAMENTE';

            END TRY
            BEGIN CATCH
                ROLLBACK TRANSACTION TRX_INS_PBI;

                SET @o_Numero = 500;
                SET @o_MensajeUsuario = 'ERROR AL REGISTRAR EL PBI';
                SET @o_MensajeTecnico = CONCAT_WS(' - ', 'ERROR AL REGISTRAR PBI', ERROR_PROCEDURE(), ERROR_LINE(), ERROR_MESSAGE());
            END CATCH
        END
    END

    -- UPDATE PBI --
    ELSE IF @w_Accion = 'U'
    BEGIN
        IF ISNULL(@i_PBIId,0) = 0
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL ID DEL PBI ES OBLIGATORIO';
        END;

        ELSE IF ISNULL(@i_PBIModificatorId,0) = 0
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL ID DEL MODIFICADOR ES OBLIGATORIO';
        END;

        ELSE IF NOT EXISTS (SELECT 1 FROM [SQM_GENERAL].[TBL_ProductBacklogItems] (NOLOCK) WHERE PBIId = @i_PBIId)
        BEGIN
            SET @o_Numero = 404;
            SET @o_MensajeUsuario = 'EL PBI NO EXISTE';
        END;

        -- Validaciones cruzadas opcionales durante la actualización
        ELSE IF @i_PBIParentLink IS NOT NULL AND NOT EXISTS (SELECT 1 FROM [SQM_GENERAL].[TBL_Features] (NOLOCK) WHERE featureId = @i_PBIParentLink)
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'LA FEATURE ASOCIADA NO EXISTE';
        END;

        ELSE IF @i_PBIOwner IS NOT NULL AND NOT EXISTS (SELECT 1 FROM [SQM_SECURITY].[TBL_Users] (NOLOCK) WHERE userId = @i_PBIOwner)
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL DUEÑO (USUARIO) DEL PBI NO EXISTE';
        END;

        ELSE IF @i_PBIPriority IS NOT NULL AND NOT EXISTS (SELECT 1 FROM [SQM_CATALOGS].[TBL_Priorities] (NOLOCK) WHERE priorityId = @i_PBIPriority AND priorityEnable = 1)
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'LA PRIORIDAD NO EXISTE O NO ESTA ACTIVA';
        END;

        ELSE IF @i_PBIStatus IS NOT NULL AND NOT EXISTS (SELECT 1 FROM [SQM_CATALOGS].[TBL_Status] (NOLOCK) WHERE statusId = @i_PBIStatus AND statusEnable = 1)
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL ESTADO NO EXISTE O NO ESTA ACTIVO';
        END;
        
        ELSE
        BEGIN
            BEGIN TRANSACTION TRX_UPD_PBI;

            BEGIN TRY
                UPDATE [SQM_GENERAL].[TBL_ProductBacklogItems]
                SET PBISummary = COALESCE(@i_PBISummary, PBISummary),
                    PBIDescription = COALESCE(@i_PBIDescription, PBIDescription),
                    PBIsAcceptanceCriteria = COALESCE(@i_PBIsAcceptanceCriteria, PBIsAcceptanceCriteria),
                    PBIOwner = COALESCE(@i_PBIOwner, PBIOwner),
                    PBIParentLink = COALESCE(@i_PBIParentLink, PBIParentLink),
                    PBIStoryPoint = COALESCE(@i_PBIStoryPoint, PBIStoryPoint),
                    PBIStartDate = COALESCE(@i_PBIStartDate, PBIStartDate),
                    PBIDueDate = COALESCE(@i_PBIDueDate, PBIDueDate),
                    PBIPriority = COALESCE(@i_PBIPriority, PBIPriority),
                    PBIModificationDate = @i_PBIModificationDate,
                    PBIModificatorId = @i_PBIModificatorId,
                    PBIStatus = COALESCE(@i_PBIStatus, PBIStatus)
                WHERE PBIId = @i_PBIId;

                COMMIT TRANSACTION TRX_UPD_PBI;

                SET @o_Numero = 200;
                SET @o_MensajeUsuario = 'PBI ACTUALIZADO CORRECTAMENTE';

            END TRY
            BEGIN CATCH
                ROLLBACK TRANSACTION TRX_UPD_PBI;

                SET @o_Numero = 500;
                SET @o_MensajeUsuario = 'ERROR AL ACTUALIZAR EL PBI';
                SET @o_MensajeTecnico = CONCAT_WS(' - ', 'ERROR AL ACTUALIZAR PBI', ERROR_PROCEDURE(), ERROR_LINE(), ERROR_MESSAGE());
            END CATCH
        END
    END

    -- SELECT PBI --
    ELSE IF @w_Accion = 'S'
    BEGIN
        BEGIN TRY
            SELECT 
                PBIId,
                PBISummary,
                PBIDescription,
                PBIsAcceptanceCriteria,
                PBIOwner,
                PBIParentLink,
                PBIStoryPoint,
                PBIStartDate,
                PBIDueDate,
                PBIPriority,
                PBICreationDate,
                PBICreatorId,
                PBIModificationDate,
                PBIModificatorId,
                PBIStatus
            FROM [SQM_GENERAL].[TBL_ProductBacklogItems] (NOLOCK)
            ORDER BY PBIId
            OFFSET (@i_PageNumber - 1) * @i_RowsPerPage ROWS
            FETCH NEXT @i_RowsPerPage ROWS ONLY;

            SET @w_totalRows = @@ROWCOUNT

            IF (@w_totalRows > 0)
            BEGIN
                SET @o_Numero = 200;
                SET @o_MensajeUsuario = 'PBIS LISTADOS CORRECTAMENTE';
            END
            ELSE
            BEGIN
                SET @o_Numero = 204;
                SET @o_MensajeUsuario = 'NO HAY MAS REGISTROS PARA LISTAR';
            END

        END TRY
        BEGIN CATCH
            SET @o_Numero = 500;
            SET @o_MensajeUsuario = 'ERROR AL LISTAR LOS PBIS';
            SET @o_MensajeTecnico = CONCAT_WS(' - ', 'ERROR AL LISTAR PBIS', ERROR_PROCEDURE(), ERROR_LINE(), ERROR_MESSAGE());
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

--USP PARA TABLA ProductBacklogItems

USE [DB_SCRUM_PLANNING]
GO

CREATE OR ALTER PROC [SQM_GENERAL].[USP_ProductBacklogItems]
(
    -- Parámetros de la tabla TBL_ProductBacklogItems
    @i_PBIId INT = NULL,
    @i_PBISummary VARCHAR(500) = NULL,
    @i_PBIDescription VARCHAR(2000) = NULL,
    @i_PBIsAcceptanceCriteria VARCHAR(4000) = NULL,
    @i_PBIOwner INT = NULL,
    @i_PBIParentLink INT = NULL,   
    @i_PBIStoryPoint INT = NULL,    
    @i_PBIStartDate DATE = NULL,
    @i_PBIDueDate DATE = NULL,
    @i_PBIPriority INT = NULL,       
    @i_PBICreationDate DATETIME = NULL,
    @i_PBICreatorId INT = NULL,
    @i_PBIModificationDate DATETIME = NULL,
    @i_PBIModificatorId INT = NULL,
    @i_PBIStatus INT = NULL,         
    -- Parámetros obligatorios de control
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

    IF @i_PBICreationDate IS NULL
        SET @i_PBICreationDate = GETDATE();

    IF @i_PBIModificationDate IS NULL
        SET @i_PBIModificationDate = GETDATE();

    -- INSERTAR PBI --
    IF @w_Accion = 'I'
    BEGIN
        IF ISNULL(@i_PBISummary,'') = ''
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL RESUMEN DEL PBI ES OBLIGATORIO';
        END;

        ELSE IF ISNULL(@i_PBIDescription,'') = ''
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'LA DESCRIPCION DEL PBI ES OBLIGATORIA';
        END;

        ELSE IF ISNULL(@i_PBIsAcceptanceCriteria,'') = ''
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'LOS CRITERIOS DE ACEPTACION SON OBLIGATORIOS';
        END;

        ELSE IF ISNULL(@i_PBIOwner,0) = 0
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL DUEÑO DEL PBI ES OBLIGATORIO';
        END;

        ELSE IF ISNULL(@i_PBIParentLink,0) = 0
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'LA FEATURE ASOCIADA (PARENT LINK) ES OBLIGATORIA';
        END;

        ELSE IF ISNULL(@i_PBIStatus,0) = 0
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL ESTADO DEL PBI ES OBLIGATORIO';
        END;

        -- Validaciones cruzadas de llaves foráneas
        ELSE IF NOT EXISTS (SELECT 1 FROM [SQM_GENERAL].[TBL_Features] (NOLOCK) WHERE featureId = @i_PBIParentLink)
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'LA FEATURE ASOCIADA NO EXISTE';
        END;

        ELSE IF NOT EXISTS (SELECT 1 FROM [SQM_SECURITY].[TBL_Users] (NOLOCK) WHERE userId = @i_PBIOwner)
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL DUEÑO (USUARIO) DEL PBI NO EXISTE';
        END;

        ELSE IF @i_PBIPriority IS NOT NULL AND NOT EXISTS (SELECT 1 FROM [SQM_CATALOGS].[TBL_Priorities] (NOLOCK) WHERE priorityId = @i_PBIPriority AND priorityEnable = 1)
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'LA PRIORIDAD NO EXISTE O NO ESTA ACTIVA';
        END;

        ELSE IF NOT EXISTS (SELECT 1 FROM [SQM_CATALOGS].[TBL_Status] (NOLOCK) WHERE statusId = @i_PBIStatus AND statusEnable = 1)
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL ESTADO NO EXISTE O NO ESTA ACTIVO';
        END;
        
        ELSE
        BEGIN
            BEGIN TRANSACTION TRX_INS_PBI;

            BEGIN TRY
                INSERT INTO [SQM_GENERAL].[TBL_ProductBacklogItems](
                    PBISummary, PBIDescription, PBIsAcceptanceCriteria, PBIOwner, 
                    PBIParentLink, PBIStoryPoint, PBIStartDate, PBIDueDate, 
                    PBIPriority, PBICreationDate, PBICreatorId, 
                    PBIModificationDate, PBIModificatorId, PBIStatus
                )
                VALUES(
                    @i_PBISummary, @i_PBIDescription, @i_PBIsAcceptanceCriteria, @i_PBIOwner, 
                    @i_PBIParentLink, @i_PBIStoryPoint, @i_PBIStartDate, @i_PBIDueDate, 
                    @i_PBIPriority, @i_PBICreationDate, @i_PBICreatorId, 
                    @i_PBIModificationDate, @i_PBIModificatorId, @i_PBIStatus
                );

                COMMIT TRANSACTION TRX_INS_PBI;

                SET @o_Numero = 201;
                SET @o_MensajeUsuario = 'PBI REGISTRADO CORRECTAMENTE';

            END TRY
            BEGIN CATCH
                ROLLBACK TRANSACTION TRX_INS_PBI;

                SET @o_Numero = 500;
                SET @o_MensajeUsuario = 'ERROR AL REGISTRAR EL PBI';
                SET @o_MensajeTecnico = CONCAT_WS(' - ', 'ERROR AL REGISTRAR PBI', ERROR_PROCEDURE(), ERROR_LINE(), ERROR_MESSAGE());
            END CATCH
        END
    END

    -- UPDATE PBI --
    ELSE IF @w_Accion = 'U'
    BEGIN
        IF ISNULL(@i_PBIId,0) = 0
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL ID DEL PBI ES OBLIGATORIO';
        END;

        ELSE IF ISNULL(@i_PBIModificatorId,0) = 0
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL ID DEL MODIFICADOR ES OBLIGATORIO';
        END;

        ELSE IF NOT EXISTS (SELECT 1 FROM [SQM_GENERAL].[TBL_ProductBacklogItems] (NOLOCK) WHERE PBIId = @i_PBIId)
        BEGIN
            SET @o_Numero = 404;
            SET @o_MensajeUsuario = 'EL PBI NO EXISTE';
        END;

        -- Validaciones cruzadas opcionales durante la actualización
        ELSE IF @i_PBIParentLink IS NOT NULL AND NOT EXISTS (SELECT 1 FROM [SQM_GENERAL].[TBL_Features] (NOLOCK) WHERE featureId = @i_PBIParentLink)
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'LA FEATURE ASOCIADA NO EXISTE';
        END;

        ELSE IF @i_PBIOwner IS NOT NULL AND NOT EXISTS (SELECT 1 FROM [SQM_SECURITY].[TBL_Users] (NOLOCK) WHERE userId = @i_PBIOwner)
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL DUEÑO (USUARIO) DEL PBI NO EXISTE';
        END;

        ELSE IF @i_PBIPriority IS NOT NULL AND NOT EXISTS (SELECT 1 FROM [SQM_CATALOGS].[TBL_Priorities] (NOLOCK) WHERE priorityId = @i_PBIPriority AND priorityEnable = 1)
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'LA PRIORIDAD NO EXISTE O NO ESTA ACTIVA';
        END;

        ELSE IF @i_PBIStatus IS NOT NULL AND NOT EXISTS (SELECT 1 FROM [SQM_CATALOGS].[TBL_Status] (NOLOCK) WHERE statusId = @i_PBIStatus AND statusEnable = 1)
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL ESTADO NO EXISTE O NO ESTA ACTIVO';
        END;
        
        ELSE
        BEGIN
            BEGIN TRANSACTION TRX_UPD_PBI;

            BEGIN TRY
                UPDATE [SQM_GENERAL].[TBL_ProductBacklogItems]
                SET PBISummary = COALESCE(@i_PBISummary, PBISummary),
                    PBIDescription = COALESCE(@i_PBIDescription, PBIDescription),
                    PBIsAcceptanceCriteria = COALESCE(@i_PBIsAcceptanceCriteria, PBIsAcceptanceCriteria),
                    PBIOwner = COALESCE(@i_PBIOwner, PBIOwner),
                    PBIParentLink = COALESCE(@i_PBIParentLink, PBIParentLink),
                    PBIStoryPoint = COALESCE(@i_PBIStoryPoint, PBIStoryPoint),
                    PBIStartDate = COALESCE(@i_PBIStartDate, PBIStartDate),
                    PBIDueDate = COALESCE(@i_PBIDueDate, PBIDueDate),
                    PBIPriority = COALESCE(@i_PBIPriority, PBIPriority),
                    PBIModificationDate = @i_PBIModificationDate,
                    PBIModificatorId = @i_PBIModificatorId,
                    PBIStatus = COALESCE(@i_PBIStatus, PBIStatus)
                WHERE PBIId = @i_PBIId;

                COMMIT TRANSACTION TRX_UPD_PBI;

                SET @o_Numero = 200;
                SET @o_MensajeUsuario = 'PBI ACTUALIZADO CORRECTAMENTE';

            END TRY
            BEGIN CATCH
                ROLLBACK TRANSACTION TRX_UPD_PBI;

                SET @o_Numero = 500;
                SET @o_MensajeUsuario = 'ERROR AL ACTUALIZAR EL PBI';
                SET @o_MensajeTecnico = CONCAT_WS(' - ', 'ERROR AL ACTUALIZAR PBI', ERROR_PROCEDURE(), ERROR_LINE(), ERROR_MESSAGE());
            END CATCH
        END
    END

    -- SELECT PBI --
    ELSE IF @w_Accion = 'S'
    BEGIN
        BEGIN TRY
            SELECT 
                PBIId,
                PBISummary,
                PBIDescription,
                PBIsAcceptanceCriteria,
                PBIOwner,
                PBIParentLink,
                PBIStoryPoint,
                PBIStartDate,
                PBIDueDate,
                PBIPriority,
                PBICreationDate,
                PBICreatorId,
                PBIModificationDate,
                PBIModificatorId,
                PBIStatus
            FROM [SQM_GENERAL].[TBL_ProductBacklogItems] (NOLOCK)
            ORDER BY PBIId
            OFFSET (@i_PageNumber - 1) * @i_RowsPerPage ROWS
            FETCH NEXT @i_RowsPerPage ROWS ONLY;

            SET @w_totalRows = @@ROWCOUNT

            IF (@w_totalRows > 0)
            BEGIN
                SET @o_Numero = 200;
                SET @o_MensajeUsuario = 'PBIS LISTADOS CORRECTAMENTE';
            END
            ELSE
            BEGIN
                SET @o_Numero = 204;
                SET @o_MensajeUsuario = 'NO HAY MAS REGISTROS PARA LISTAR';
            END

        END TRY
        BEGIN CATCH
            SET @o_Numero = 500;
            SET @o_MensajeUsuario = 'ERROR AL LISTAR LOS PBIS';
            SET @o_MensajeTecnico = CONCAT_WS(' - ', 'ERROR AL LISTAR PBIS', ERROR_PROCEDURE(), ERROR_LINE(), ERROR_MESSAGE());
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

--USP PARA TABLA ActivityTypes

USE [DB_SCRUM_PLANNING]
GO

CREATE OR ALTER PROC [SQM_CATALOGS].[USP_ActivityTypes]
(
    -- Parámetros de la tabla TBL_ActivityTypes
    @i_activityTypeId INT = NULL,
    @i_activityTypeName VARCHAR(80) = NULL,
    @i_activityTypeCreationDate DATETIME = NULL,
    @i_activityTypeCreatorId INT = NULL,
    @i_activityTypeModificationDate DATETIME = NULL,
    @i_activityTypeModificatorId INT = NULL,
    @i_activityTypeEnable BIT = NULL,
    -- Parámetros obligatorios de control
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

    IF @i_activityTypeCreationDate IS NULL
        SET @i_activityTypeCreationDate = GETDATE();

    IF @i_activityTypeModificationDate IS NULL
        SET @i_activityTypeModificationDate = GETDATE();

    -- INSERTAR ACTIVITY TYPE --
    IF @w_Accion = 'I'
    BEGIN
        IF ISNULL(@i_activityTypeName,'') = ''
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL NOMBRE DEL TIPO DE ACTIVIDAD ES OBLIGATORIO';
        END;

        ELSE IF EXISTS (SELECT 1 FROM [SQM_CATALOGS].[TBL_ActivityTypes] (NOLOCK) WHERE activityTypeName = @i_activityTypeName)
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL NOMBRE DEL TIPO DE ACTIVIDAD YA EXISTE';
        END;
        
        ELSE
        BEGIN
            BEGIN TRANSACTION TRX_INS_ACTIVITYTYPE;

            BEGIN TRY
                INSERT INTO [SQM_CATALOGS].[TBL_ActivityTypes](
                    activityTypeName, activityTypeCreationDate, activityTypeCreatorId, 
                    activityTypeModificationDate, activityTypeModificatorId, activityTypeEnable
                )
                VALUES(
                    @i_activityTypeName, @i_activityTypeCreationDate, @i_activityTypeCreatorId, 
                    @i_activityTypeModificationDate, @i_activityTypeModificatorId, 1
                );

                COMMIT TRANSACTION TRX_INS_ACTIVITYTYPE;

                SET @o_Numero = 201;
                SET @o_MensajeUsuario = 'TIPO DE ACTIVIDAD REGISTRADO CORRECTAMENTE';

            END TRY
            BEGIN CATCH
                ROLLBACK TRANSACTION TRX_INS_ACTIVITYTYPE;

                SET @o_Numero = 500;
                SET @o_MensajeUsuario = 'ERROR AL REGISTRAR EL TIPO DE ACTIVIDAD';
                SET @o_MensajeTecnico = CONCAT_WS(' - ', 'ERROR AL REGISTRAR TIPO DE ACTIVIDAD', ERROR_PROCEDURE(), ERROR_LINE(), ERROR_MESSAGE());
            END CATCH
        END
    END

    -- UPDATE ACTIVITY TYPE --
    ELSE IF @w_Accion = 'U'
    BEGIN
        IF ISNULL(@i_activityTypeId,0) = 0
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL ID DEL TIPO DE ACTIVIDAD ES OBLIGATORIO';
        END;

        ELSE IF ISNULL(@i_activityTypeModificatorId,0) = 0
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL ID DEL MODIFICADOR ES OBLIGATORIO';
        END;

        ELSE IF NOT EXISTS (SELECT 1 FROM [SQM_CATALOGS].[TBL_ActivityTypes] (NOLOCK) WHERE activityTypeId = @i_activityTypeId)
        BEGIN
            SET @o_Numero = 404;
            SET @o_MensajeUsuario = 'EL TIPO DE ACTIVIDAD NO EXISTE';
        END;

        ELSE IF @i_activityTypeName IS NOT NULL AND
            EXISTS (SELECT 1 FROM [SQM_CATALOGS].[TBL_ActivityTypes] (NOLOCK) WHERE activityTypeName = @i_activityTypeName AND activityTypeId <> @i_activityTypeId)
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL NOMBRE DEL TIPO DE ACTIVIDAD YA EXISTE';
        END;
        
        ELSE
        BEGIN
            BEGIN TRANSACTION TRX_UPD_ACTIVITYTYPE;

            BEGIN TRY
                UPDATE [SQM_CATALOGS].[TBL_ActivityTypes]
                SET activityTypeName = COALESCE(@i_activityTypeName, activityTypeName),
                    activityTypeModificationDate = @i_activityTypeModificationDate,
                    activityTypeModificatorId = @i_activityTypeModificatorId,
                    activityTypeEnable = COALESCE(@i_activityTypeEnable, activityTypeEnable)
                WHERE activityTypeId = @i_activityTypeId;

                COMMIT TRANSACTION TRX_UPD_ACTIVITYTYPE;

                SET @o_Numero = 200;
                SET @o_MensajeUsuario = 'TIPO DE ACTIVIDAD ACTUALIZADO CORRECTAMENTE';

            END TRY
            BEGIN CATCH
                ROLLBACK TRANSACTION TRX_UPD_ACTIVITYTYPE;

                SET @o_Numero = 500;
                SET @o_MensajeUsuario = 'ERROR AL ACTUALIZAR EL TIPO DE ACTIVIDAD';
                SET @o_MensajeTecnico = CONCAT_WS(' - ', 'ERROR AL ACTUALIZAR TIPO DE ACTIVIDAD', ERROR_PROCEDURE(), ERROR_LINE(), ERROR_MESSAGE());
            END CATCH
        END
    END

    -- SELECT ACTIVITY TYPE --
    ELSE IF @w_Accion = 'S'
    BEGIN
        BEGIN TRY
            SELECT 
                activityTypeId,
                activityTypeName,
                activityTypeCreationDate,
                activityTypeCreatorId,
                activityTypeModificationDate,
                activityTypeModificatorId,
                activityTypeEnable
            FROM [SQM_CATALOGS].[TBL_ActivityTypes] (NOLOCK)
            ORDER BY activityTypeId
            OFFSET (@i_PageNumber - 1) * @i_RowsPerPage ROWS
            FETCH NEXT @i_RowsPerPage ROWS ONLY;

            SET @w_totalRows = @@ROWCOUNT

            IF (@w_totalRows > 0)
            BEGIN
                SET @o_Numero = 200;
                SET @o_MensajeUsuario = 'TIPOS DE ACTIVIDAD LISTADOS CORRECTAMENTE';
            END
            ELSE
            BEGIN
                SET @o_Numero = 204;
                SET @o_MensajeUsuario = 'NO HAY MAS REGISTROS PARA LISTAR';
            END

        END TRY
        BEGIN CATCH
            SET @o_Numero = 500;
            SET @o_MensajeUsuario = 'ERROR AL LISTAR LOS TIPOS DE ACTIVIDAD';
            SET @o_MensajeTecnico = CONCAT_WS(' - ', 'ERROR AL LISTAR TIPOS DE ACTIVIDAD', ERROR_PROCEDURE(), ERROR_LINE(), ERROR_MESSAGE());
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

--USP PARA TABLA TASKS

USE [DB_SCRUM_PLANNING]
GO

CREATE OR ALTER PROC [SQM_GENERAL].[USP_Tasks]
(
    -- Parámetros de la tabla TBL_Tasks
    @i_taskId INT = NULL,
    @i_taskSummary VARCHAR(500) = NULL,
    @i_taskDescription VARCHAR(2000) = NULL,
    @i_taskOwner INT = NULL,
    @i_taskParentLink INT = NULL, -- PBI padre
    @i_taskOriginalEstimate DECIMAL(4,2) = NULL,
    @i_taskCompletedWork DECIMAL(4,2) = NULL,
    @i_taskRemaningWork DECIMAL(4,2) = NULL,
    @i_taskStartDate DATE = NULL,
    @i_taskCompletedDate DATE = NULL,
    @i_taskDueDate DATE = NULL,
    @i_taskActivityType INT = NULL,
    @i_taskCreationDate DATETIME = NULL,
    @i_taskCreatorId INT = NULL,
    @i_taskModificationDate DATETIME = NULL,
    @i_taskModificatorId INT = NULL,
    @i_taskStatus INT = NULL,
    -- Parámetros obligatorios de control
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

    IF @i_taskCreationDate IS NULL
        SET @i_taskCreationDate = GETDATE();

    IF @i_taskModificationDate IS NULL
        SET @i_taskModificationDate = GETDATE();

    -- INSERTAR TASK --
    IF @w_Accion = 'I'
    BEGIN
        IF ISNULL(@i_taskSummary,'') = ''
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL RESUMEN DE LA TAREA ES OBLIGATORIO';
        END;

        ELSE IF ISNULL(@i_taskDescription,'') = ''
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'LA DESCRIPCION DE LA TAREA ES OBLIGATORIA';
        END;

        ELSE IF ISNULL(@i_taskOwner,0) = 0
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL DUEÑO DE LA TAREA ES OBLIGATORIO';
        END;

        ELSE IF ISNULL(@i_taskParentLink,0) = 0
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL PBI ASOCIADO (PARENT LINK) ES OBLIGATORIO';
        END;

        ELSE IF ISNULL(@i_taskStatus,0) = 0
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL ESTADO DE LA TAREA ES OBLIGATORIO';
        END;

        -- Validaciones cruzadas de llaves foráneas
        ELSE IF NOT EXISTS (SELECT 1 FROM [SQM_GENERAL].[TBL_ProductBacklogItems] (NOLOCK) WHERE PBIId = @i_taskParentLink)
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL PBI ASOCIADO NO EXISTE';
        END;

        ELSE IF NOT EXISTS (SELECT 1 FROM [SQM_SECURITY].[TBL_Users] (NOLOCK) WHERE userId = @i_taskOwner)
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL DUEÑO (USUARIO) DE LA TAREA NO EXISTE';
        END;

        ELSE IF @i_taskActivityType IS NOT NULL AND NOT EXISTS (SELECT 1 FROM [SQM_CATALOGS].[TBL_ActivityTypes] (NOLOCK) WHERE activityTypeId = @i_taskActivityType AND activityTypeEnable = 1)
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL TIPO DE ACTIVIDAD NO EXISTE O NO ESTA ACTIVO';
        END;

        ELSE IF NOT EXISTS (SELECT 1 FROM [SQM_CATALOGS].[TBL_Status] (NOLOCK) WHERE statusId = @i_taskStatus AND statusEnable = 1)
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL ESTADO NO EXISTE O NO ESTA ACTIVO';
        END;
        
        ELSE
        BEGIN
            BEGIN TRANSACTION TRX_INS_TASK;

            BEGIN TRY
                INSERT INTO [SQM_GENERAL].[TBL_Tasks](
                    taskSummary, taskDescription, taskOwner, taskParentLink, 
                    taskOriginalEstimate, taskCompletedWork, taskRemaningWork, 
                    taskStartDate, taskCompletedDate, taskDueDate, taskActivityType, 
                    taskCreationDate, taskCreatorId, taskModificationDate, taskModificatorId, taskStatus
                )
                VALUES(
                    @i_taskSummary, @i_taskDescription, @i_taskOwner, @i_taskParentLink, 
                    @i_taskOriginalEstimate, @i_taskCompletedWork, @i_taskRemaningWork, 
                    @i_taskStartDate, @i_taskCompletedDate, @i_taskDueDate, @i_taskActivityType, 
                    @i_taskCreationDate, @i_taskCreatorId, @i_taskModificationDate, @i_taskModificatorId, @i_taskStatus
                );

                COMMIT TRANSACTION TRX_INS_TASK;

                SET @o_Numero = 201;
                SET @o_MensajeUsuario = 'TAREA REGISTRADA CORRECTAMENTE';

            END TRY
            BEGIN CATCH
                ROLLBACK TRANSACTION TRX_INS_TASK;

                SET @o_Numero = 500;
                SET @o_MensajeUsuario = 'ERROR AL REGISTRAR LA TAREA';
                SET @o_MensajeTecnico = CONCAT_WS(' - ', 'ERROR AL REGISTRAR TAREA', ERROR_PROCEDURE(), ERROR_LINE(), ERROR_MESSAGE());
            END CATCH
        END
    END

    -- UPDATE TASK --
    ELSE IF @w_Accion = 'U'
    BEGIN
        IF ISNULL(@i_taskId,0) = 0
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL ID DE LA TAREA ES OBLIGATORIO';
        END;

        ELSE IF ISNULL(@i_taskModificatorId,0) = 0
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL ID DEL MODIFICADOR ES OBLIGATORIO';
        END;

        ELSE IF NOT EXISTS (SELECT 1 FROM [SQM_GENERAL].[TBL_Tasks] (NOLOCK) WHERE taskId = @i_taskId)
        BEGIN
            SET @o_Numero = 404;
            SET @o_MensajeUsuario = 'LA TAREA NO EXISTE';
        END;

        -- Validaciones cruzadas opcionales durante la actualización
        ELSE IF @i_taskParentLink IS NOT NULL AND NOT EXISTS (SELECT 1 FROM [SQM_GENERAL].[TBL_ProductBacklogItems] (NOLOCK) WHERE PBIId = @i_taskParentLink)
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL PBI ASOCIADO NO EXISTE';
        END;

        ELSE IF @i_taskOwner IS NOT NULL AND NOT EXISTS (SELECT 1 FROM [SQM_SECURITY].[TBL_Users] (NOLOCK) WHERE userId = @i_taskOwner)
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL DUEÑO (USUARIO) DE LA TAREA NO EXISTE';
        END;

        ELSE IF @i_taskActivityType IS NOT NULL AND NOT EXISTS (SELECT 1 FROM [SQM_CATALOGS].[TBL_ActivityTypes] (NOLOCK) WHERE activityTypeId = @i_taskActivityType AND activityTypeEnable = 1)
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL TIPO DE ACTIVIDAD NO EXISTE O NO ESTA ACTIVO';
        END;

        ELSE IF @i_taskStatus IS NOT NULL AND NOT EXISTS (SELECT 1 FROM [SQM_CATALOGS].[TBL_Status] (NOLOCK) WHERE statusId = @i_taskStatus AND statusEnable = 1)
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL ESTADO NO EXISTE O NO ESTA ACTIVO';
        END;
        
        ELSE
        BEGIN
            BEGIN TRANSACTION TRX_UPD_TASK;

            BEGIN TRY
                UPDATE [SQM_GENERAL].[TBL_Tasks]
                SET taskSummary = COALESCE(@i_taskSummary, taskSummary),
                    taskDescription = COALESCE(@i_taskDescription, taskDescription),
                    taskOwner = COALESCE(@i_taskOwner, taskOwner),
                    taskParentLink = COALESCE(@i_taskParentLink, taskParentLink),
                    taskOriginalEstimate = COALESCE(@i_taskOriginalEstimate, taskOriginalEstimate),
                    taskCompletedWork = COALESCE(@i_taskCompletedWork, taskCompletedWork),
                    taskRemaningWork = COALESCE(@i_taskRemaningWork, taskRemaningWork),
                    taskStartDate = COALESCE(@i_taskStartDate, taskStartDate),
                    taskCompletedDate = COALESCE(@i_taskCompletedDate, taskCompletedDate),
                    taskDueDate = COALESCE(@i_taskDueDate, taskDueDate),
                    taskActivityType = COALESCE(@i_taskActivityType, taskActivityType),
                    taskModificationDate = @i_taskModificationDate,
                    taskModificatorId = @i_taskModificatorId,
                    taskStatus = COALESCE(@i_taskStatus, taskStatus)
                WHERE taskId = @i_taskId;

                COMMIT TRANSACTION TRX_UPD_TASK;

                SET @o_Numero = 200;
                SET @o_MensajeUsuario = 'TAREA ACTUALIZADA CORRECTAMENTE';

            END TRY
            BEGIN CATCH
                ROLLBACK TRANSACTION TRX_UPD_TASK;

                SET @o_Numero = 500;
                SET @o_MensajeUsuario = 'ERROR AL ACTUALIZAR LA TAREA';
                SET @o_MensajeTecnico = CONCAT_WS(' - ', 'ERROR AL ACTUALIZAR TAREA', ERROR_PROCEDURE(), ERROR_LINE(), ERROR_MESSAGE());
            END CATCH
        END
    END

    -- SELECT TASK --
    ELSE IF @w_Accion = 'S'
    BEGIN
        BEGIN TRY
            SELECT 
                taskId,
                taskSummary,
                taskDescription,
                taskOwner,
                taskParentLink,
                taskOriginalEstimate,
                taskCompletedWork,
                taskRemaningWork,
                taskStartDate,
                taskCompletedDate,
                taskDueDate,
                taskActivityType,
                taskCreationDate,
                taskCreatorId,
                taskModificationDate,
                taskModificatorId,
                taskStatus
            FROM [SQM_GENERAL].[TBL_Tasks] (NOLOCK)
            ORDER BY taskId
            OFFSET (@i_PageNumber - 1) * @i_RowsPerPage ROWS
            FETCH NEXT @i_RowsPerPage ROWS ONLY;

            SET @w_totalRows = @@ROWCOUNT

            IF (@w_totalRows > 0)
            BEGIN
                SET @o_Numero = 200;
                SET @o_MensajeUsuario = 'TAREAS LISTADAS CORRECTAMENTE';
            END
            ELSE
            BEGIN
                SET @o_Numero = 204;
                SET @o_MensajeUsuario = 'NO HAY MAS REGISTROS PARA LISTAR';
            END

        END TRY
        BEGIN CATCH
            SET @o_Numero = 500;
            SET @o_MensajeUsuario = 'ERROR AL LISTAR LAS TAREAS';
            SET @o_MensajeTecnico = CONCAT_WS(' - ', 'ERROR AL LISTAR TAREAS', ERROR_PROCEDURE(), ERROR_LINE(), ERROR_MESSAGE());
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

--USP PARA TABLA TaskComents

CREATE OR ALTER PROC [SQM_GENERAL].[USP_TaskComments]
(
    -- Parámetros de la tabla TBL_TaskComments
    @i_taskCommentId INT = NULL,
    @i_taskCommentParentLink INT = NULL, -- Tarea padre
    @i_taskCommentOwner INT = NULL,      -- Dueño del comentario
    @i_taskCommentText NVARCHAR(4000) = NULL,
    @i_taskCommentCreationDate DATETIME = NULL,
    @i_taskCommentCreatorId INT = NULL,
    @i_taskCommentModificationDate DATETIME = NULL,
    @i_taskCommentModificatorId INT = NULL,
    @i_taskCommentStatus BIT = NULL,     -- Estado (BIT)
    -- Parámetros obligatorios de control
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

    -- INSERTAR TASK COMMENT --
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

        -- Validaciones cruzadas de llaves foráneas
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
                    @i_taskCommentModificationDate, @i_taskCommentModificatorId, 1 -- Activo por defecto
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

    -- UPDATE TASK COMMENT --
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

        -- Validaciones cruzadas opcionales durante la actualización
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

    -- SELECT TASK COMMENT --
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

    -- ACCION INVALIDA --
    ELSE
    BEGIN
        SET @o_Numero = 405;
        SET @o_MensajeUsuario = 'METODO NO HABILITADO';
        SET @o_MensajeTecnico = 'EL PROCEDIMIENTO ALMACENADO NO TIENE HABILITADA ESA OPCION';
    END

END;
GO
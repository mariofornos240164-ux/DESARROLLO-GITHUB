USE [DB_SCRUM_PLANNING]
GO

SET NOCOUNT ON;

-- Solo para desarrollo/pruebas; cambia o elimina esta cuenta antes de usar producción.
DECLARE @TestUserName VARCHAR(80) = 'demo.scrum';
DECLARE @TestEmail VARCHAR(80) = 'demo.scrum@example.test';
DECLARE @TestPassword VARCHAR(256) = 'ScrumDemo#2026';
DECLARE @TestFullName VARCHAR(80) = 'Usuario de prueba Scrum';
DECLARE @TestRoleId INT;
DECLARE @TestUserId INT;
DECLARE @MatchingUserCount INT;
DECLARE @StatusCode INT;
DECLARE @UserMessage VARCHAR(500);
DECLARE @TechnicalMessage VARCHAR(500);
DECLARE @ErrorMessage NVARCHAR(2048);
DECLARE @LockResult INT;

IF OBJECT_ID(N'SQM_SECURITY.TBL_Roles', N'U') IS NULL
   OR OBJECT_ID(N'SQM_SECURITY.TBL_Users', N'U') IS NULL
   OR OBJECT_ID(N'SQM_SECURITY.USP_Roles', N'P') IS NULL
   OR OBJECT_ID(N'SQM_SECURITY.USP_Users', N'P') IS NULL
   OR OBJECT_ID(N'SQM_SECURITY.Fn_EncryptByKey', N'FN') IS NULL
   OR OBJECT_ID(N'SQM_SECURITY.Fn_DecryptByKey', N'FN') IS NULL
    THROW 51000, 'Faltan tablas, procedimientos o funciones de autenticacion de DB_SCRUM_PLANNING.', 1;

IF NOT EXISTS (SELECT 1 FROM sys.symmetric_keys WHERE name = '##MS_DatabaseMasterKey##')
   OR NOT EXISTS (SELECT 1 FROM sys.certificates WHERE name = 'CERT_SCRUMPLANNING')
   OR NOT EXISTS (SELECT 1 FROM sys.symmetric_keys WHERE name = 'KEY_HASH')
    THROW 51001, 'Faltan la clave maestra, el certificado o la clave simetrica. Ejecuta SYMMETRIC_KEY.sql una sola vez antes de este script.', 1;

EXEC @LockResult = sys.sp_getapplock
    @Resource = N'SCRUM_PLANNING.Seed_Demo_User',
    @LockMode = 'Exclusive',
    @LockOwner = 'Session',
    @LockTimeout = 10000;

IF @LockResult < 0
    THROW 51002, 'No se pudo obtener el bloqueo para preparar el usuario de prueba.', 1;

BEGIN TRY
    SELECT TOP (1) @TestRoleId = rolId
    FROM [SQM_SECURITY].[TBL_Roles]
    WHERE rolEnable = 1
    ORDER BY rolId;

    IF @TestRoleId IS NULL
    BEGIN
        SELECT TOP (1) @TestRoleId = rolId
        FROM [SQM_SECURITY].[TBL_Roles]
        WHERE rolName = 'Usuario de prueba'
        ORDER BY rolId;

        SET @StatusCode = NULL;
        SET @UserMessage = NULL;
        SET @TechnicalMessage = NULL;

        IF @TestRoleId IS NULL
        BEGIN
            EXEC [SQM_SECURITY].[USP_Roles]
                @i_rolName = 'Usuario de prueba',
                @i_rolCreatorId = 0,
                @i_rolEnable = 1,
                @w_Accion = 'I',
                @o_Numero = @StatusCode OUTPUT,
                @o_MensajeTecnico = @TechnicalMessage OUTPUT,
                @o_MensajeUsuario = @UserMessage OUTPUT;

            IF @StatusCode <> 201
            BEGIN
                SET @ErrorMessage = CONCAT('No se pudo crear el rol requerido: ', COALESCE(@UserMessage, @TechnicalMessage, 'sin detalle'));
                THROW 51003, @ErrorMessage, 1;
            END;

            SELECT TOP (1) @TestRoleId = rolId
            FROM [SQM_SECURITY].[TBL_Roles]
            WHERE rolName = 'Usuario de prueba'
              AND rolEnable = 1
            ORDER BY rolId;
        END;
        ELSE
        BEGIN
            EXEC [SQM_SECURITY].[USP_Roles]
                @i_rolId = @TestRoleId,
                @i_rolModificatorId = @TestRoleId,
                @i_rolEnable = 1,
                @w_Accion = 'U',
                @o_Numero = @StatusCode OUTPUT,
                @o_MensajeTecnico = @TechnicalMessage OUTPUT,
                @o_MensajeUsuario = @UserMessage OUTPUT;

            IF @StatusCode <> 200
            BEGIN
                SET @ErrorMessage = CONCAT('No se pudo activar el rol de prueba: ', COALESCE(@UserMessage, @TechnicalMessage, 'sin detalle'));
                THROW 51009, @ErrorMessage, 1;
            END;
        END;
    END;

    IF @TestRoleId IS NULL
        THROW 51004, 'No se encontro un rol activo para el usuario de prueba.', 1;

    SELECT @MatchingUserCount = COUNT(*)
    FROM [SQM_SECURITY].[TBL_Users]
    WHERE userName = @TestUserName
       OR userEmail = @TestEmail;

    IF @MatchingUserCount > 1
        THROW 51005, 'Hay varias cuentas que coinciden con el nombre o correo de prueba; no se modifico ninguna.', 1;

    SELECT @TestUserId = userId
    FROM [SQM_SECURITY].[TBL_Users]
    WHERE userName = @TestUserName
      AND userEmail = @TestEmail;

    IF @MatchingUserCount = 1 AND @TestUserId IS NULL
        THROW 51006, 'El nombre o correo de prueba ya pertenece a otra cuenta; no se modifico ninguna.', 1;

    SET @StatusCode = NULL;
    SET @UserMessage = NULL;
    SET @TechnicalMessage = NULL;

    IF @TestUserId IS NULL
    BEGIN
        EXEC [SQM_SECURITY].[USP_Users]
            @i_userFullName = @TestFullName,
            @i_userName = @TestUserName,
            @i_userEmail = @TestEmail,
            @i_userPassword = @TestPassword,
            @i_userRolId = @TestRoleId,
            @i_userCreatorId = 0,
            @i_userEnable = 1,
            @w_Accion = 'I',
            @o_Numero = @StatusCode OUTPUT,
            @o_MensajeTecnico = @TechnicalMessage OUTPUT,
            @o_MensajeUsuario = @UserMessage OUTPUT;

        IF @StatusCode <> 201
        BEGIN
            SET @ErrorMessage = CONCAT('No se pudo crear el usuario de prueba: ', COALESCE(@UserMessage, @TechnicalMessage, 'sin detalle'));
            THROW 51007, @ErrorMessage, 1;
        END;
    END
    ELSE
    BEGIN
        EXEC [SQM_SECURITY].[USP_Users]
            @i_userId = @TestUserId,
            @i_userPassword = @TestPassword,
            @i_userRolId = @TestRoleId,
            @i_userModificatorId = @TestUserId,
            @i_userEnable = 1,
            @w_Accion = 'U',
            @o_Numero = @StatusCode OUTPUT,
            @o_MensajeTecnico = @TechnicalMessage OUTPUT,
            @o_MensajeUsuario = @UserMessage OUTPUT;

        IF @StatusCode <> 200
        BEGIN
            SET @ErrorMessage = CONCAT('No se pudo actualizar el usuario de prueba: ', COALESCE(@UserMessage, @TechnicalMessage, 'sin detalle'));
            THROW 51008, @ErrorMessage, 1;
        END;
    END;

    EXEC sys.sp_releaseapplock
        @Resource = N'SCRUM_PLANNING.Seed_Demo_User',
        @LockOwner = 'Session';

    PRINT 'Usuario de prueba listo: demo.scrum / ScrumDemo#2026';
END TRY
BEGIN CATCH
    EXEC sys.sp_releaseapplock
        @Resource = N'SCRUM_PLANNING.Seed_Demo_User',
        @LockOwner = 'Session';
    THROW;
END CATCH;
GO

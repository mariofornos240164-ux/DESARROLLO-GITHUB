USE [DB_SCRUM_PLANNING]
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @DemoUserId INT;
DECLARE @BusinessValueId INT;
DECLARE @StatusId INT;
DECLARE @LockResult INT;
DECLARE @Now DATETIME = GETDATE();

BEGIN TRANSACTION;

EXEC @LockResult = sys.sp_getapplock
    @Resource = N'SCRUM_PLANNING.Seed_Backlog_Setup',
    @LockMode = 'Exclusive',
    @LockOwner = 'Transaction',
    @LockTimeout = 10000;

IF @LockResult < 0
    THROW 51100, 'No se pudo bloquear la preparacion del backlog.', 1;

SELECT @DemoUserId = userId
FROM [SQM_SECURITY].[TBL_Users]
WHERE userName = 'demo.scrum'
  AND userEmail = 'demo.scrum@example.test'
  AND userEnable = 1;

IF @DemoUserId IS NULL
    THROW 51101, 'No existe el usuario demo activo. Ejecuta primero Seed_Demo_User.sql.', 1;

IF NOT EXISTS (
    SELECT 1 FROM [SQM_CATALOGS].[TBL_Status] WHERE statusName = 'New'
)
BEGIN
    INSERT INTO [SQM_CATALOGS].[TBL_Status] (
        statusName, statusCreationDate, statusCreatorId, statusModificationDate,
        statusModificatorId, statusEnable
    )
    VALUES ('New', @Now, @DemoUserId, @Now, NULL, 1);
END;

IF NOT EXISTS (
    SELECT 1 FROM [SQM_CATALOGS].[TBL_Status] WHERE statusName = 'Active'
)
BEGIN
    INSERT INTO [SQM_CATALOGS].[TBL_Status] (
        statusName, statusCreationDate, statusCreatorId, statusModificationDate,
        statusModificatorId, statusEnable
    )
    VALUES ('Active', @Now, @DemoUserId, @Now, NULL, 1);
END;

IF NOT EXISTS (
    SELECT 1 FROM [SQM_CATALOGS].[TBL_Status] WHERE statusName = 'Closed'
)
BEGIN
    INSERT INTO [SQM_CATALOGS].[TBL_Status] (
        statusName, statusCreationDate, statusCreatorId, statusModificationDate,
        statusModificatorId, statusEnable
    )
    VALUES ('Closed', @Now, @DemoUserId, @Now, NULL, 1);
END;

IF NOT EXISTS (
    SELECT 1 FROM [SQM_CATALOGS].[TBL_BusinessValues]
    WHERE businessValueName = 'Standard'
)
BEGIN
    INSERT INTO [SQM_CATALOGS].[TBL_BusinessValues] (
        businessValueName, businessValueCreationDate, businessValueCreatorId,
        businessValueModificationDate, businessValueModificatorId, businessValueEnable
    )
    VALUES ('Standard', @Now, @DemoUserId, NULL, NULL, 1);
END;

SELECT @BusinessValueId = businessValueId
FROM [SQM_CATALOGS].[TBL_BusinessValues]
WHERE businessValueName = 'Standard'
  AND businessValueEnable = 1;

IF @BusinessValueId IS NULL
    THROW 51102, 'El valor de negocio Standard no esta activo.', 1;

SELECT @StatusId = statusId
FROM [SQM_CATALOGS].[TBL_Status]
WHERE statusName = 'New'
  AND statusEnable = 1;

IF @StatusId IS NULL
    THROW 51103, 'El estado New no esta activo.', 1;

IF NOT EXISTS (
    SELECT 1
    FROM [SQM_GENERAL].[TBL_Initiatives]
    WHERE initiativeSummary = 'Proyecto Scrum de demostracion'
)
BEGIN
    INSERT INTO [SQM_GENERAL].[TBL_Initiatives] (
        initiativeSummary, initiativeDescription, initiativeOwner, initiativeGoals,
        initiativeBusinessValue, initiativeTargetStart, initiativeTargetEnd,
        initiativeCreationDate, initiativeCreatorId, initiativeModificationDate,
        initiativeModificatorId, initiativeStatus
    )
    VALUES (
        'Proyecto Scrum de demostracion',
        'Iniciativa inicial para crear epicas, features, stories y tasks desde Scrum Planning.',
        @DemoUserId,
        'Preparar la jerarquia inicial del backlog.',
        @BusinessValueId,
        NULL,
        NULL,
        @Now,
        @DemoUserId,
        NULL,
        NULL,
        @StatusId
    );
END;

COMMIT TRANSACTION;

PRINT 'Catalogos y la iniciativa inicial del backlog estan listos.';
GO

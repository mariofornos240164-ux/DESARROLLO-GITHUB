USE DB_SCRUM_PLANNING
GO

DECLARE @Numero INT, @MensajeUsuario VARCHAR(500), @MensajeTecnico VARCHAR(500)

EXEC [SQM_SECURITY].[USP_Users]
    @i_PageNumber = 3,
    @i_RowsPerPage = 10,
    @w_Accion = 'S',
    @o_Numero = @Numero OUTPUT,
    @o_MensajeUsuario = @MensajeUsuario OUTPUT,
    @o_MensajeTecnico = @MensajeTecnico OUTPUT;

SELECT @Numero AS Codigo, @MensajeUsuario AS MensajeUsuario, @MensajeTecnico AS MensajeTecnico

EXEC [SQM_SECURITY].[USP_Users]
    @i_userFullName = 'Jose Luis Espinoza',
    @i_userEmail = 'j',
    @i_userName = 'joseespinoza@udem.edu.ni',
    @i_userPassword = 'MiPassword123',
    @i_userRolId = 2,
    @i_userCreatorId = 3,
    @w_Accion = 'I'

    EXEC [SQM_SECURITY].[USP_Users]
    @i_userId = 3,
    @i_userModificatorId = 6,
    @i_userRolId = 1,
    @w_Accion = 'U'


EXEC [SQM_SECURITY].[USP_Users]
    @i_PageNumber = 2,
    @i_RowsPerPage = 10,
    @w_Accion = 'S'

    EXEC [SQM_SECURITY].[USP_Users]
    @w_Accion = 'X'

    -- EXEC [SQM_CATALOGS].[USP_Status]
--     @w_Accion = 'S',
--     @o_Numero = @Numero OUTPUT,
--     @o_MensajeUsuario = @MensajeUsuario OUTPUT,
--     @o_MensajeTecnico = @MensajeTecnico OUTPUT;
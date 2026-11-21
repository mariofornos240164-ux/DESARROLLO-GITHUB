from infrastructure.database.base_repository import BaseRepository
from domain.interfaces.IusersRepository import IUserRepository
from domain.entities.UserModels import UserCreate, UserLogin, UserUpdate

# pyodbc no puede leer parametros OUTPUT con "?".
# Por eso se declaran las variables en el mismo query y al final se hace un SELECT con ellas.

class UserRepository(IUserRepository):
    def insert_user(self, user: UserCreate, creator_id: int):
        query = """
            SET NOCOUNT ON;
            DECLARE @o_Numero INT, @o_MensajeUsuario VARCHAR(500), @o_MensajeTecnico VARCHAR(500);

            EXEC [SQM_SECURITY].[USP_Users]
                @i_userFullName = ?,
                @i_userName = ?,
                @i_userEmail = ?,
                @i_userPassword = ?,
                @i_userRolId = ?,
                @i_userCreatorId = ?,
                @w_Accion = 'I',
                @o_Numero = @o_Numero OUTPUT,
                @o_MensajeUsuario = @o_MensajeUsuario OUTPUT,
                @o_MensajeTecnico = @o_MensajeTecnico OUTPUT;

            SELECT @o_Numero, @o_MensajeUsuario, @o_MensajeTecnico;
        """
        return BaseRepository.execute_operation(query, (
            user.userFullName,
            user.userName,
            user.userEmail,
            user.userPassword,
            user.userRolId,
            creator_id
        ))

    def update_user(self, user: UserUpdate, modificator_id: int):
        query = """
            SET NOCOUNT ON;
            DECLARE @o_Numero INT, @o_MensajeUsuario VARCHAR(500), @o_MensajeTecnico VARCHAR(500);

            EXEC [SQM_SECURITY].[USP_Users]
                @i_userId = ?,
                @i_userFullName = ?,
                @i_userName = ?,
                @i_userEmail = ?,
                @i_userPassword = ?,
                @i_userRolId = ?,
                @i_userEnable = ?,
                @i_userModificatorId = ?,
                @w_Accion = 'U',
                @o_Numero = @o_Numero OUTPUT,
                @o_MensajeUsuario = @o_MensajeUsuario OUTPUT,
                @o_MensajeTecnico = @o_MensajeTecnico OUTPUT;

            SELECT @o_Numero, @o_MensajeUsuario, @o_MensajeTecnico;
        """
        return BaseRepository.execute_operation(query, (
            user.userId,
            user.userFullName,
            user.userName,
            user.userEmail,
            user.userPassword,
            user.userRolId,
            user.userEnable,
            modificator_id
        ))

    def list_users(self, page_number: int, rows_per_page: int):
        query = """
            SET NOCOUNT ON;
            DECLARE @o_Numero INT, @o_MensajeUsuario VARCHAR(500), @o_MensajeTecnico VARCHAR(500);

            EXEC [SQM_SECURITY].[USP_Users]
                @i_PageNumber = ?,
                @i_RowsPerPage = ?,
                @w_Accion = 'S',
                @o_Numero = @o_Numero OUTPUT,
                @o_MensajeUsuario = @o_MensajeUsuario OUTPUT,
                @o_MensajeTecnico = @o_MensajeTecnico OUTPUT;

            SELECT @o_Numero, @o_MensajeUsuario, @o_MensajeTecnico;
        """
        return BaseRepository.execute_query(query, (page_number, rows_per_page))

    def authenticate_user(self, user: UserLogin):
        query = """
            SET NOCOUNT ON;
            DECLARE @o_Numero INT, @o_MensajeUsuario VARCHAR(500), @o_MensajeTecnico VARCHAR(500);

            EXEC [SQM_SECURITY].[USP_Users]
                @i_userName = ?,
                @i_userPassword = ?,
                @w_Accion = 'A',
                @o_Numero = @o_Numero OUTPUT,
                @o_MensajeUsuario = @o_MensajeUsuario OUTPUT,
                @o_MensajeTecnico = @o_MensajeTecnico OUTPUT;

            SELECT @o_Numero, @o_MensajeUsuario, @o_MensajeTecnico;
        """
        return BaseRepository.execute_query(query, (user.userName, user.userPassword))

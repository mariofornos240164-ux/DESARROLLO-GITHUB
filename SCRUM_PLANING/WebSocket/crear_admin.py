# Crea el PRIMER usuario administrador (solo se usa una vez).
# Para crear usuarios por la API se necesita un token de administrador,
# por eso el primero se crea con este script:
#
#     python crear_admin.py
#
# Antes debe existir el rol de administrador en SQM_SECURITY.TBL_Roles
# (rolId = JWT_ADMIN_ROLE_ID del .env, normalmente 1).

import os
from dotenv import load_dotenv

load_dotenv()

from domain.entities.UserModels import UserCreate
from infrastructure.repositories.UsersRepository import UserRepository

user = UserCreate(
    userFullName=input("Nombre completo: "),
    userName=input("Nombre de usuario: "),
    userEmail=input("Correo: "),
    userPassword=input("Contraseña: "),
    userRolId=int(os.getenv("JWT_ADMIN_ROLE_ID", "1"))
)

# creator_id = 0 porque lo crea el sistema
result = UserRepository().insert_user(user, 0)
print(result.status_code, result.message_user)
if result.message_tech:
    print(result.message_tech)

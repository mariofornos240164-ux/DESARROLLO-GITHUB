# Backend de Scrum Planning

## Preparación de SQL Server

Para una base nueva, ejecuta una sola vez `../DB/DB_SCRUM_PLANNING.sql` con una
cuenta con permisos para crear bases y tablas. Después, en `DB_SCRUM_PLANNING`,
ejecuta `../DB/SYMMETRIC_KEY.sql` una sola vez, reemplazando el valor de ejemplo
de `CREATE MASTER KEY` por una contraseña larga y guardándola fuera del
repositorio.

No vuelvas a generar la clave maestra, el certificado ni `KEY_HASH` después de
cifrar contraseñas. Los datos existentes dependen de esas claves. Despliega
después `../DB/Fn_EncryptByKey.sql`, `../DB/Fn_DecryptByKey.sql`,
`USP_Roles.sql`, `USP_Users.sql`, `USP_Status.sql`, `USP_Initiatives.sql`,
`USP_Epics.sql`, `USP_Features.sql`, `USP_ProductBacklogItems.sql` y
`USP_Tasks.sql`, todos dentro de `../DB/USPs/`. Para crear el rol y la cuenta
de prueba de forma repetible, ejecuta `../DB/Seed_Demo_User.sql`. Después
ejecuta `../DB/Seed_Backlog_Setup.sql` para preparar los estados New/Active/
Closed, el valor de negocio y una iniciativa inicial; el script es idempotente
y requiere la cuenta demo activa.

Con SQL Server local y autenticación integrada, puedes ejecutar el seed de
backlog desde PowerShell, situado en esta carpeta:

```powershell
sqlcmd -S localhost -d DB_SCRUM_PLANNING -E -C -i ..\DB\Seed_Backlog_Setup.sql
```

La cuenta creada por ese seed es:

- Usuario: `demo.scrum`
- Correo: `demo.scrum@example.test`
- Contraseña: `ScrumDemo#2026`

La contraseña se cifra mediante la clave simétrica de SQL Server. No insertes
el valor directamente en `TBL_Users`.

## Configuración del backend

Copia `.env.example` como `.env` y configura:

- `DB_SERVER` y `DB_NAME`: servidor y base de datos.
- `DB_TRUSTED_CONNECTION=true`: usa la identidad Windows que ejecuta uvicorn.
  Esa identidad debe tener acceso a la base y permiso para ejecutar los
  procedimientos de autenticación.
- O bien `DB_TRUSTED_CONNECTION=false` junto con `DB_USER` y `DB_PASSWORD`
  para autenticación SQL.
- `JWT_SECRET_KEY`: secreto aleatorio de al menos 32 caracteres. Se puede
  generar con `python -c "import secrets; print(secrets.token_urlsafe(48))"`.
- `JWT_EXPIRE_MINUTES`: duración del token.
- `JWT_ADMIN_ROLE_ID`: ID del rol que autoriza las rutas administrativas.
  No se necesita para iniciar sesión ni para mostrar la home.

Las claves del cifrado de contraseñas son objetos de SQL Server, no variables
de `.env`. El archivo `.env` contiene secretos locales y no debe subirse al
repositorio.

## Arranque local en Windows

Desde PowerShell:

```powershell
Set-Location "C:\Users\MarioCfl\Desktop\DESARROLLO GITHUB\SCRUM_PLANING\WebSocket"
if (-not (Test-Path .env)) { Copy-Item .env.example .env }
notepad .env
if (-not (Test-Path .venv)) { python -m venv .venv }
.\.venv\Scripts\python.exe -m pip install -r requirements.txt
.\.venv\Scripts\python.exe -m uvicorn main:app --reload --host 127.0.0.1 --port 8000
```

Comprueba que la API responde en `http://127.0.0.1:8000/docs`.

## Arranque y login del frontend

El frontend usa el backend por defecto (`VITE_AUTH_MODE=api`) y apunta a
`http://localhost:8000`. Su origen Vite predeterminado (`http://localhost:5173`)
está permitido por CORS.

En otra terminal:

```powershell
Set-Location "C:\Users\MarioCfl\Desktop\DESARROLLO GITHUB\SCRUM_WEB\SCRUM_PLANING"
npm run dev
```

En el formulario, usa `demo.scrum` o `demo.scrum@example.test` y la contraseña
de prueba indicada arriba. El endpoint de autenticación es
`POST /websocket/users/authenticate`; al responder correctamente, el frontend
guarda la sesión y `AppRoot` muestra la home sin cambiar la ruta del navegador.

`/work-items` lee y escribe Epics, Features, Stories y Tasks en SQL Server a
través de sus procedimientos almacenados. Al crear elementos, selecciona el
padre del nivel anterior y completa descripción y criterios de aceptación
cuando el tipo lo requiere. Los sprints de `/sprints` aún están en memoria: no
se guardan en SQL Server porque la base no tiene una tabla de sprints.
Para verificar una tarea guardada, consulta el esquema explícito:

```sql
SELECT taskId, taskSummary, taskDescription, taskOwner, taskParentLink, taskStatus
FROM [SQM_GENERAL].[TBL_Tasks]
ORDER BY taskId DESC;
```

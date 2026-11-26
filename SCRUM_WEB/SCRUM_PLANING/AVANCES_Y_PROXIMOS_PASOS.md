# Avances del proyecto Scrum Planning

**Actualizado:** 26 de noviembre de 2026  
**Estado:** frontend y backend integrados para login y work items; quedan pendientes la verificación de administración de usuarios contra la API reiniciada y la persistencia SQL de Sprints.

## Resumen

Se conservó la Home y su marco principal, y se completó el flujo de navegación entre módulos. El login se conecta al backend y SQL Server; el backlog puede leer y guardar work items; se añadieron tema oscuro, avisos temporales, registro administrativo de usuarios y controles para la vista de tablero y de lista.

## Modificaciones realizadas

### Login, sesión y configuración del backend

- Se reorganizó la pantalla de login: fondo claro con degradado, formulario con floating labels, marca y descripción del proyecto, notificaciones toast y mensajes de validación en español.
- El login acepta usuario o correo. El backend verifica las credenciales mediante el procedimiento almacenado y devuelve un token JWT y el nombre de usuario canónico.
- El frontend guarda y restaura la sesión de acuerdo con la opción de recordar sesión, redirige a la Home y permite cerrar sesión.
- La conexión del backend admite autenticación integrada de Windows o autenticación SQL. Las variables, el arranque y la preparación de SQL están documentados en [README del backend](../../SCRUM_PLANING/WebSocket/README.md) y en [`.env.example`](../../SCRUM_PLANING/WebSocket/.env.example). No se deben incluir secretos reales en el repositorio.
- Las claves y certificados de cifrado de contraseñas pertenecen a SQL Server; no son variables de `.env`. No regenerarlos si ya hay contraseñas cifradas.

### Base de datos y work items

- Se incorporó el acceso SQL desde el backend para Epics, Features, Stories/Product Backlog Items y Tasks, con validación de relaciones padre-hijo y autorización por token.
- Se añadió [Seed_Backlog_Setup.sql](../../SCRUM_PLANING/DB/Seed_Backlog_Setup.sql), idempotente, para preparar los estados, el valor de negocio y una iniciativa inicial necesarios para empezar a crear work items.
- El formulario solicita el padre requerido y los campos necesarios según el tipo. Los errores de dependencias al eliminar se presentan en una alerta temporal y en un toast.
- Se corrigió el comportamiento de carga y mutación de `useBacklog`.
- Los Sprints continúan en memoria: la base de datos actual no tiene una tabla SQL de Sprints.

### Navegación, tema y vistas

- Se mantiene el shell de navegación al cambiar de módulo. La ruta determina el título y el elemento activo; se soportan navegación interna e historial del navegador.
- El sidebar conserva Home, Usuarios, Tareas, Boards, Work Items, Backlogs y Sprints. Se retiraron los enlaces que no llevaban a una vista funcional.
- Tareas filtra los work items por tipo; Boards muestra columnas New, Active y Closed. El selector de vista cambia entre tablero y lista, y las opciones de columna permiten mostrar u ocultar estados o columnas.
- Se agregaron placeholders para módulos que aún no tienen una funcionalidad completa, sin reemplazar la Home.
- El modo oscuro está disponible en las interfaces de login y aplicación, se conserva entre visitas y usa sombras oscuras. El modo claro conserva su estilo previo.
- Se revisó el desbordamiento horizontal en tamaños móvil, tablet y escritorio.

### Registro de usuarios

- Se añadió una vista de administración para listar usuarios y crear cuentas indicando nombre, usuario, correo, contraseña y rol activo.
- El backend expone `GET /websocket/users/roles`; la creación y el listado existentes siguen protegidos por autorización administrativa. La contraseña se procesa mediante el procedimiento almacenado de usuarios.
- Se añadió validación de longitud y de identificador de rol en el modelo de creación.
- Para crear el primer administrador se incluye [crear_admin.py](../../SCRUM_PLANING/WebSocket/crear_admin.py). El rol configurado en `JWT_ADMIN_ROLE_ID` debe existir y estar activo.

## Archivos principales

| Área | Archivos |
|---|---|
| Navegación y shell | [`src/App.tsx`](./src/App.tsx), [`src/AppRoot.tsx`](./src/AppRoot.tsx), [`src/application/useAppNavigation.ts`](./src/application/useAppNavigation.ts) |
| Login y tema | [`src/presentation/auth/LoginPage.tsx`](./src/presentation/auth/LoginPage.tsx), [`src/presentation/ThemeToggle.tsx`](./src/presentation/ThemeToggle.tsx), [`src/index.css`](./src/index.css) |
| Backlog y work items | [`src/application/useBacklog.ts`](./src/application/useBacklog.ts), [`src/infrastructure/backlogApi.ts`](./src/infrastructure/backlogApi.ts), [`src/infrastructure/httpClient.ts`](./src/infrastructure/httpClient.ts), [`src/presentation/NewWorkItemForm.tsx`](./src/presentation/NewWorkItemForm.tsx), [`src/presentation/WorkItemsTable.tsx`](./src/presentation/WorkItemsTable.tsx) |
| Tablero y columnas | [`src/presentation/WorkItemsBoard.tsx`](./src/presentation/WorkItemsBoard.tsx), [`src/presentation/ColumnOptionsMenu.tsx`](./src/presentation/ColumnOptionsMenu.tsx) |
| Usuarios y alertas | [`src/application/useUsers.ts`](./src/application/useUsers.ts), [`src/infrastructure/usersApi.ts`](./src/infrastructure/usersApi.ts), [`src/presentation/UserManagementPage.tsx`](./src/presentation/UserManagementPage.tsx), [`src/presentation/ToastNotification.tsx`](./src/presentation/ToastNotification.tsx) |
| API y SQL | [`WebSocket/main.py`](../../SCRUM_PLANING/WebSocket/main.py), [`WebSocket/infrastructure/database/connection.py`](../../SCRUM_PLANING/WebSocket/infrastructure/database/connection.py), [`WebSocket/presentation/controlers/dependences/users_controller.py`](../../SCRUM_PLANING/WebSocket/presentation/controlers/dependences/users_controller.py), [`WebSocket/presentation/controlers/dependences/backlog_controller.py`](../../SCRUM_PLANING/WebSocket/presentation/controlers/dependences/backlog_controller.py), [`DB/Seed_Demo_User.sql`](../../SCRUM_PLANING/DB/Seed_Demo_User.sql), [`DB/Seed_Backlog_Setup.sql`](../../SCRUM_PLANING/DB/Seed_Backlog_Setup.sql) |

## Verificaciones realizadas

- `npm.cmd run lint` y `npm.cmd run build`: pasaron.
- `python -m py_compile` para el controlador y el modelo de usuarios: pasó.
- Se confirmó en el OpenAPI del código que las rutas de usuarios, creación, listado y roles están registradas.
- Prueba de interfaz: el tablero mostró New/Active/Closed; se ocultó/restauró un estado y se ocultó/restauró una columna.
- Prueba responsive: no se detectó desbordamiento horizontal a 375, 768 y 1280 píxeles.
- En las pruebas de integración previas, el login llegó a Home y se probaron las operaciones de backlog contra SQL. No se debe interpretar el resultado como una prueba reciente del registro de usuarios.

## Pendiente conocido

En la última prueba de Usuarios, el navegador recibió `404` para la nueva consulta de roles y `403` al listar usuarios. El código local sí contiene la ruta, pero la instancia de API que estaba activa era anterior y no la había cargado. Además, la cuenta demo no tiene el rol configurado como administrador; en la configuración local comprobada, el ID de rol de demo no coincidía con `JWT_ADMIN_ROLE_ID`.

Por ello, la creación de usuarios desde la interfaz aún requiere reiniciar el backend y probar con una cuenta administradora. No se creó una cuenta nueva ni se alteraron datos de SQL como parte de esos cambios.

## Próximos avances recomendados

1. **Reiniciar el backend** desde la carpeta `WebSocket` para cargar el endpoint de roles:
   ```powershell
   .\.venv\Scripts\python.exe -m uvicorn main:app --reload --host 127.0.0.1 --port 8000
   ```
2. **Preparar una cuenta administradora**: comprobar que el rol indicado por `JWT_ADMIN_ROLE_ID` exista y esté activo; ejecutar `.\.venv\Scripts\python.exe crear_admin.py` y completar los datos solicitados. No promover la cuenta demo automáticamente.
3. **Probar Usuarios** con la cuenta administrativa: carga de roles y usuarios, creación, validación de duplicados y actualización de la lista. Usar una base de desarrollo.
4. **Completar pruebas automatizadas** para navegación directa e historial, autorización, errores de dependencias/toast, tema oscuro y opciones de columnas.
5. **Persistir Sprints en SQL Server**: acordar primero el modelo y las relaciones, luego implementar tabla, procedimientos, repositorio, endpoints y frontend.
6. **Completar los módulos placeholder** solo cuando se definan sus necesidades; conservar el shell y los patrones de navegación actuales.
7. **Preparar producción**: sustituir las credenciales demo, proteger secretos, revisar permisos SQL, CORS, expiración JWT y configuración del servidor.

## Arranque local

- **Backend:** seguir los pasos y variables de [README del backend](../../SCRUM_PLANING/WebSocket/README.md); API predeterminada en `http://127.0.0.1:8000`.
- **Frontend:** desde esta carpeta, ejecutar `npm run dev`; Vite predeterminado en `http://localhost:5173`.
- En una base nueva, seguir el orden de scripts descrito en el README del backend. Ejecutar los seeds solo según el estado de la base y no regenerar las claves de cifrado después de almacenar contraseñas.

from infrastructure.database.connection import get_connection
from domain.entities.EpicModels import EpicCreate, EpicUpdate

class EpicRepository:
    def insert_epic(self, epic: EpicCreate):
        conn = get_connection()
        cursor = conn.cursor()

        o_Numero = 0
        o_Mensaje = ""

        cursor.execute("""
            EXEC [SQM_GENERAL].[USP_Epics]
                @i_epicName = ?,
                @i_epicSummary = ?,
                @i_epicDescription = ?,
                @i_epicParentLink = ?,
                @i_epicOwner = ?,
                @i_epicStartDate = ?,
                @i_epicDueDate = ?,
                @i_epicPriority = ?,
                @i_epicCreatorId = ?,
                @i_epicStatus = ?,
                @w_Accion = 'I',
                @o_Numero = ? OUTPUT,
                @o_Mensaje = ? OUTPUT
        """, (
            epic.epicName,
            epic.epicSummary,
            epic.epicDescription,
            epic.epicParentLink,
            epic.epicOwner,
            epic.epicStartDate,
            epic.epicDueDate,
            epic.epicPriority,
            epic.epicCreatorId,
            epic.epicStatus,
            o_Numero,
            o_Mensaje
        ))

        result = cursor.fetchone()
        conn.commit()
        cursor.close()
        conn.close()

        return {
            "status_code": result[0] if result else o_Numero,
            "message": result[1] if result else o_Mensaje
        }

    def update_epic(self, epic: EpicUpdate):
        conn = get_connection()
        cursor = conn.cursor()

        o_Numero = 0
        o_Mensaje = ""

        cursor.execute("""
            EXEC [SQM_GENERAL].[USP_Epics]
                @i_epicId = ?,
                @i_epicName = ?,
                @i_epicSummary = ?,
                @i_epicDescription = ?,
                @i_epicParentLink = ?,
                @i_epicOwner = ?,
                @i_epicStartDate = ?,
                @i_epicDueDate = ?,
                @i_epicPriority = ?,
                @i_epicModificatorId = ?,
                @i_epicStatus = ?,
                @w_Accion = 'U',
                @o_Numero = ? OUTPUT,
                @o_Mensaje = ? OUTPUT
        """, (
            epic.epicId,
            epic.epicName,
            epic.epicSummary,
            epic.epicDescription,
            epic.epicParentLink,
            epic.epicOwner,
            epic.epicStartDate,
            epic.epicDueDate,
            epic.epicPriority,
            epic.epicModificatorId,
            epic.epicStatus,
            o_Numero,
            o_Mensaje
        ))

        result = cursor.fetchone()
        conn.commit()
        cursor.close()
        conn.close()

        return {
            "status_code": result[0] if result else o_Numero,
            "message": result[1] if result else o_Mensaje
        }

    def list_epics(self):
        conn = get_connection()
        cursor = conn.cursor()

        o_Numero = 0
        o_Mensaje = ""

        cursor.execute("""
            EXEC [SQM_GENERAL].[USP_Epics]
                @w_Accion = 'S',
                @o_Numero = ? OUTPUT,
                @o_Mensaje = ? OUTPUT
        """, (o_Numero, o_Mensaje))

        columns = [col[0] for col in cursor.description]
        data = [dict(zip(columns, row)) for row in cursor.fetchall()]

        conn.commit()
        cursor.close()
        conn.close()

        return {"status_code": o_Numero, "message": o_Mensaje, "data": data}
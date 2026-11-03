from infrastructure.database.connection import get_connection
from domain.entities.InitiativeModels import InitiativeCreate, InitiativeUpdate

class InitiativeRepository:
    def insert_initiative(self, initiative: InitiativeCreate):
        conn = get_connection()
        cursor = conn.cursor()

        o_Numero = 0
        o_Mensaje = ""

        cursor.execute("""
            EXEC [SQM_GENERAL].[USP_Initiatives]
                @i_initiativeSummary = ?,
                @i_initiativeDescription = ?,
                @i_initiativeOwner = ?,
                @i_initiativeGoals = ?,
                @i_initiativeBusinessValue = ?,
                @i_initiativeTargetStart = ?,
                @i_initiativeTargetEnd = ?,
                @i_initiativeCreatorId = ?,
                @i_initiativeStatus = ?,
                @w_Accion = 'I',
                @o_Numero = ? OUTPUT,
                @o_Mensaje = ? OUTPUT
        """, (
            initiative.initiativeSummary,
            initiative.initiativeDescription,
            initiative.initiativeOwner,
            initiative.initiativeGoals,
            initiative.initiativeBusinessValue,
            initiative.initiativeTargetStart,
            initiative.initiativeTargetEnd,
            initiative.initiativeCreatorId,
            initiative.initiativeStatus,
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

    def update_initiative(self, initiative: InitiativeUpdate):
        conn = get_connection()
        cursor = conn.cursor()

        o_Numero = 0
        o_Mensaje = ""

        cursor.execute("""
            EXEC [SQM_GENERAL].[USP_Initiatives]
                @i_initiativeId = ?,
                @i_initiativeSummary = ?,
                @i_initiativeDescription = ?,
                @i_initiativeOwner = ?,
                @i_initiativeGoals = ?,
                @i_initiativeBusinessValue = ?,
                @i_initiativeTargetStart = ?,
                @i_initiativeTargetEnd = ?,
                @i_initiativeModificatorId = ?,
                @i_initiativeStatus = ?,
                @w_Accion = 'U',
                @o_Numero = ? OUTPUT,
                @o_Mensaje = ? OUTPUT
        """, (
            initiative.initiativeId,
            initiative.initiativeSummary,
            initiative.initiativeDescription,
            initiative.initiativeOwner,
            initiative.initiativeGoals,
            initiative.initiativeBusinessValue,
            initiative.initiativeTargetStart,
            initiative.initiativeTargetEnd,
            initiative.initiativeModificatorId,
            initiative.initiativeStatus,
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

    def list_initiatives(self):
        conn = get_connection()
        cursor = conn.cursor()

        o_Numero = 0
        o_Mensaje = ""

        cursor.execute("""
            EXEC [SQM_GENERAL].[USP_Initiatives]
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
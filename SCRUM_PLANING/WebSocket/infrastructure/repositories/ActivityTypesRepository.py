from infrastructure.database.connection import get_connection
from domain.entities.ActivityTypeModels import ActivityTypeCreate, ActivityTypeUpdate

class ActivityTypeRepository:
    def insert_activity_type(self, activity_type: ActivityTypeCreate):
        conn = get_connection()
        cursor = conn.cursor()

        o_Numero = 0
        o_Mensaje = ""

        cursor.execute("""
            EXEC [SQM_CATALOGS].[USP_ActivityTypes]
                @i_activityTypeName = ?,
                @i_activityTypeCreatorId = ?,
                @w_Accion = 'I',
                @o_Numero = ? OUTPUT,
                @o_Mensaje = ? OUTPUT
        """, (
            activity_type.activityTypeName,
            activity_type.activityTypeCreatorId,
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

    def update_activity_type(self, activity_type: ActivityTypeUpdate):
        conn = get_connection()
        cursor = conn.cursor()

        o_Numero = 0
        o_Mensaje = ""

        cursor.execute("""
            EXEC [SQM_CATALOGS].[USP_ActivityTypes]
                @i_activityTypeId = ?,
                @i_activityTypeName = ?,
                @i_activityTypeModificatorId = ?,
                @i_activityTypeEnable = ?,
                @w_Accion = 'U',
                @o_Numero = ? OUTPUT,
                @o_Mensaje = ? OUTPUT
        """, (
            activity_type.activityTypeId,
            activity_type.activityTypeName,
            activity_type.activityTypeModificatorId,
            activity_type.activityEnable,
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

    def list_activity_types(self):
        conn = get_connection()
        cursor = conn.cursor()

        o_Numero = 0
        o_Mensaje = ""

        cursor.execute("""
            EXEC [SQM_CATALOGS].[USP_ActivityTypes]
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
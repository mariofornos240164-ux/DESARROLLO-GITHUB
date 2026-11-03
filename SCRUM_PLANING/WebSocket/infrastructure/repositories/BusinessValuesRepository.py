from infrastructure.database.connection import get_connection
from domain.entities.BusinessValueModels import BusinessValueCreate, BusinessValueUpdate

class BusinessValueRepository:
    def insert_business_value(self, bv: BusinessValueCreate):
        conn = get_connection()
        cursor = conn.cursor()

        o_Numero = 0
        o_Mensaje = ""

        cursor.execute("""
            EXEC [SQM_CATALOGS].[USP_BusinessValues]
                @i_businessValueName = ?,
                @i_businessValueCreatorId = ?,
                @w_Accion = 'I',
                @o_Numero = ? OUTPUT,
                @o_Mensaje = ? OUTPUT
        """, (
            bv.businessValueName,
            bv.businessValueCreatorId,
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

    def update_business_value(self, bv: BusinessValueUpdate):
        conn = get_connection()
        cursor = conn.cursor()

        o_Numero = 0
        o_Mensaje = ""

        cursor.execute("""
            EXEC [SQM_CATALOGS].[USP_BusinessValues]
                @i_businessValueId = ?,
                @i_businessValueName = ?,
                @i_businessValueModificatorId = ?,
                @i_businessValueEnable = ?,
                @w_Accion = 'U',
                @o_Numero = ? OUTPUT,
                @o_Mensaje = ? OUTPUT
        """, (
            bv.businessValueId,
            bv.businessValueName,
            bv.businessValueModificatorId,
            bv.businessValueEnable,
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

    def list_business_values(self):
        conn = get_connection()
        cursor = conn.cursor()

        o_Numero = 0
        o_Mensaje = ""

        cursor.execute("""
            EXEC [SQM_CATALOGS].[USP_BusinessValues]
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
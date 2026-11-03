from infrastructure.database.connection import get_connection
from domain.entities.PbiModels import PBICreate, PBIUpdate

class PbiRepository:
    def insert_pbi(self, pbi: PBICreate):
        conn = get_connection()
        cursor = conn.cursor()

        o_Numero = 0
        o_Mensaje = ""

        cursor.execute("""
            EXEC [SQM_GENERAL].[USP_ProductBacklogItems]
                @i_PBISummary = ?,
                @i_PBIDescription = ?,
                @i_PBIsAcceptanceCriteria = ?,
                @i_PBIOwner = ?,
                @i_PBIParentLink = ?,
                @i_PBIStoryPoint = ?,
                @i_PBIStartDate = ?,
                @i_PBIDueDate = ?,
                @i_PBIPriority = ?,
                @i_PBICreatorId = ?,
                @i_PBIStatus = ?,
                @w_Accion = 'I',
                @o_Numero = ? OUTPUT,
                @o_Mensaje = ? OUTPUT
        """, (
            pbi.PBISummary,
            pbi.PBIDescription,
            pbi.PBIsAcceptanceCriteria,
            pbi.PBIOwner,
            pbi.PBIParentLink,
            pbi.PBIStoryPoint,
            pbi.PBIStartDate,
            pbi.PBIDueDate,
            pbi.PBIPriority,
            pbi.PBICreatorId,
            pbi.PBIStatus,
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

    def update_pbi(self, pbi: PBIUpdate):
        conn = get_connection()
        cursor = conn.cursor()

        o_Numero = 0
        o_Mensaje = ""

        cursor.execute("""
            EXEC [SQM_GENERAL].[USP_ProductBacklogItems]
                @i_PBIId = ?,
                @i_PBISummary = ?,
                @i_PBIDescription = ?,
                @i_PBIsAcceptanceCriteria = ?,
                @i_PBIOwner = ?,
                @i_PBIParentLink = ?,
                @i_PBIStoryPoint = ?,
                @i_PBIStartDate = ?,
                @i_PBIDueDate = ?,
                @i_PBIPriority = ?,
                @i_PBIModificatorId = ?,
                @i_PBIStatus = ?,
                @w_Accion = 'U',
                @o_Numero = ? OUTPUT,
                @o_Mensaje = ? OUTPUT
        """, (
            pbi.PBIId,
            pbi.PBISummary,
            pbi.PBIDescription,
            pbi.PBIsAcceptanceCriteria,
            pbi.PBIOwner,
            pbi.PBIParentLink,
            pbi.PBIStoryPoint,
            pbi.PBIStartDate,
            pbi.PBIDueDate,
            pbi.PBIPriority,
            pbi.PBIModificatorId,
            pbi.PBIStatus,
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

    def list_pbis(self):
        conn = get_connection()
        cursor = conn.cursor()

        o_Numero = 0
        o_Mensaje = ""

        cursor.execute("""
            EXEC [SQM_GENERAL].[USP_ProductBacklogItems]
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
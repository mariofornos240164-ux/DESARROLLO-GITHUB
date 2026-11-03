from infrastructure.database.connection import get_connection
from domain.entities.TaskCommentModels import TaskCommentCreate, TaskCommentUpdate

class TaskCommentRepository:
    def insert_task_comment(self, comment: TaskCommentCreate):
        conn = get_connection()
        cursor = conn.cursor()

        o_Numero = 0
        o_Mensaje = ""

        cursor.execute("""
            EXEC [SQM_GENERAL].[USP_TaskComments]
                @i_taskCommentParentLink = ?,
                @i_taskCommentOwner = ?,
                @i_taskCommentText = ?,
                @i_taskCommentCreatorId = ?,
                @w_Accion = 'I',
                @o_Numero = ? OUTPUT,
                @o_Mensaje = ? OUTPUT
        """, (
            comment.taskCommentParentLink,
            comment.taskCommentOwner,
            comment.taskCommentText,
            comment.taskCommentCreatorId,
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

    def update_task_comment(self, comment: TaskCommentUpdate):
        conn = get_connection()
        cursor = conn.cursor()

        o_Numero = 0
        o_Mensaje = ""

        cursor.execute("""
            EXEC [SQM_GENERAL].[USP_TaskComments]
                @i_taskCommentId = ?,
                @i_taskCommentParentLink = ?,
                @i_taskCommentOwner = ?,
                @i_taskCommentText = ?,
                @i_taskCommentModificatorId = ?,
                @i_taskCommentStatus = ?,
                @w_Accion = 'U',
                @o_Numero = ? OUTPUT,
                @o_Mensaje = ? OUTPUT
        """, (
            comment.taskCommentId,
            comment.taskCommentParentLink,
            comment.taskCommentOwner,
            comment.taskCommentText,
            comment.taskCommentModificatorId,
            comment.taskCommentStatus,
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

    def list_task_comments(self):
        conn = get_connection()
        cursor = conn.cursor()

        o_Numero = 0
        o_Mensaje = ""

        cursor.execute("""
            EXEC [SQM_GENERAL].[USP_TaskComments]
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
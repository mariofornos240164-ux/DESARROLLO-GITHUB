from infrastructure.database.connection import get_connection
from domain.entities.TaskModels import TaskCreate, TaskUpdate

class TasksRepository:
    def insert_task(self, task: TaskCreate):
        conn = get_connection()
        cursor = conn.cursor()

        o_Numero = 0
        o_Mensaje = ""

        cursor.execute("""
            EXEC [SQM_GENERAL].[USP_Tasks]
                @i_taskSummary = ?,
                @i_taskDescription = ?,
                @i_taskOwner = ?,
                @i_taskParentLink = ?,
                @i_taskOriginalEstimate = ?,
                @i_taskCompletedWork = ?,
                @i_taskRemaningWork = ?,
                @i_taskStartDate = ?,
                @i_taskCompletedDate = ?,
                @i_taskDueDate = ?,
                @i_taskActivityType = ?,
                @i_taskCreatorId = ?,
                @i_taskStatus = ?,
                @w_Accion = 'I',
                @o_Numero = ? OUTPUT,
                @o_Mensaje = ? OUTPUT
        """, (
            task.taskSummary,
            task.taskDescription,
            task.taskOwner,
            task.taskParentLink,
            task.taskOriginalEstimate,
            task.taskCompletedWork,
            task.taskRemaningWork,
            task.taskStartDate,
            task.taskCompletedDate,
            task.taskDueDate,
            task.taskActivityType,
            task.taskCreatorId,
            task.taskStatus,
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

    def update_task(self, task: TaskUpdate):
        conn = get_connection()
        cursor = conn.cursor()

        o_Numero = 0
        o_Mensaje = ""

        cursor.execute("""
            EXEC [SQM_GENERAL].[USP_Tasks]
                @i_taskId = ?,
                @i_taskSummary = ?,
                @i_taskDescription = ?,
                @i_taskOwner = ?,
                @i_taskParentLink = ?,
                @i_taskOriginalEstimate = ?,
                @i_taskCompletedWork = ?,
                @i_taskRemaningWork = ?,
                @i_taskStartDate = ?,
                @i_taskCompletedDate = ?,
                @i_taskDueDate = ?,
                @i_taskActivityType = ?,
                @i_taskModificatorId = ?,
                @i_taskStatus = ?,
                @w_Accion = 'U',
                @o_Numero = ? OUTPUT,
                @o_Mensaje = ? OUTPUT
        """, (
            task.taskId,
            task.taskSummary,
            task.taskDescription,
            task.taskOwner,
            task.taskParentLink,
            task.taskOriginalEstimate,
            task.taskCompletedWork,
            task.taskRemaningWork,
            task.taskStartDate,
            task.taskCompletedDate,
            task.taskDueDate,
            task.taskActivityType,
            task.taskModificatorId,
            task.taskStatus,
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

    def list_tasks(self):
        conn = get_connection()
        cursor = conn.cursor()

        o_Numero = 0
        o_Mensaje = ""

        cursor.execute("""
            EXEC [SQM_GENERAL].[USP_Tasks]
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
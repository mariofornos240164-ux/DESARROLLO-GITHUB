from infrastructure.database.connection import get_connection
from domain.entities.PersonModels import PersonCreate

class PersonRepository:
    def insert_person(self, person: PersonCreate):
        conn = get_connection()
        cursor = conn.cursor()

        o_Numero = 0
        o_Mensaje = ""

        cursor.execute("""
            EXEC [SQM_SECURITY].[USP_Persons]
                @i_personFirstName = ?,
                @i_personSecondName = ?,
                @i_personFirstSurname = ?,
                @i_personSecondSurname = ?,
                @i_personBirthday = ?,
                @i_personDNI = ?,
                @w_Accion = 'I',
                @o_Numero = ? OUTPUT,
                @o_Mensaje = ? OUTPUT
        """, (
            person.personFirstName,
            person.personSecondName,
            person.personFirstSurname,
            person.personSecondSurname,
            person.personBirthday,
            person.personDNI,
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

    def list_persons(self):
        conn = get_connection()
        cursor = conn.cursor()

        o_Numero = 0
        o_Mensaje = ""

        cursor.execute("""
            EXEC [SQM_SECURITY].[USP_Persons]
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
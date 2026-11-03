import pyodbc
from typing import Dict, Any, List, Tuple, Optional

class BaseRepository:
    def __init__(self):
        self.server = 'localhost\\DESKTOP-R4DDRPE'
        self.database = 'DB_SCRUM_PLANNING'
        self.driver = '{ODBC Driver 17 for SQL Server}'
        
    def _get_connection(self) -> pyodbc.Connection:
        """Establece y retorna una nueva conexión a la base de datos."""
        connection_string = (
            f'DRIVER={self.driver};'
            f'SERVER={self.server};'
            f'DATABASE={self.database};'
            f'Trusted_Connection=yes;'
        )
        return pyodbc.connect(connection_string)

    def execute_non_query(self, sql: str, params: tuple) -> Tuple[int, Optional[str], Optional[str]]:
        """
        Ejecuta USPs de tipo INSERT, UPDATE (Acciones 'I' o 'U') 
        y captura los parámetros de salida (@o_Numero, @o_MensajeTecnico, @o_MensajeUsuario).
        """
        conn = self._get_connection()
        cursor = conn.cursor()
        
        try:
            cursor.execute(sql, params)
            conn.commit() 
            return 200, None, "Operación exitosa"        
            
        except Exception as e:
            conn.rollback()
            raise e
        finally:
            cursor.close()
            conn.close()

    def execute_query(self, sql: str, params: tuple = ()) -> List[Dict[str, Any]]:
        """
        Ejecuta USPs de tipo SELECT (Acción 'S') y retorna los registros 
        convertidos en una lista de diccionarios listos para Pydantic.
        """
        conn = self._get_connection()
        cursor = conn.cursor()
        
        try:
            cursor.execute(sql, params)
            if cursor.description:
                columns = [column[0] for column in cursor.description]
                rows = cursor.fetchall()
                result = [dict(zip(columns, row)) for row in rows]
                return result
            return []
            
        finally:
            cursor.close()
            conn.close()
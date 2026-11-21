import os
import pyodbc

# Los datos de conexión se leen del archivo .env (ver .env.example).
# No escribas usuarios ni contraseñas aquí: este archivo se sube a GitHub.

def get_connection():
    return pyodbc.connect(
        "DRIVER={ODBC Driver 17 for SQL Server};"
        f"SERVER={os.getenv('DB_SERVER', 'localhost')};"
        f"DATABASE={os.getenv('DB_NAME', 'DB_SCRUM_PLANNING')};"
        f"UID={os.getenv('DB_USER')};"
        f"PWD={os.getenv('DB_PASSWORD')};"
    )

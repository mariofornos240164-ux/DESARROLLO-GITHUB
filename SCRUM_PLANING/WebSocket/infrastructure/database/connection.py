import os
import pyodbc

# Los datos de conexión se leen del archivo .env (ver .env.example).
# No escribas usuarios ni contraseñas aquí: este archivo se sube a GitHub.

def _odbc_value(value: str) -> str:
    return "{" + value.replace("}", "}}") + "}"


def get_connection():
    trusted_setting = os.getenv("DB_TRUSTED_CONNECTION", "false").strip().lower()
    if trusted_setting in {"true", "1", "yes"}:
        authentication = "Trusted_Connection=yes;"
    elif trusted_setting in {"false", "0", "no", ""}:
        user = os.getenv("DB_USER", "").strip()
        password = os.getenv("DB_PASSWORD", "")
        if not user or not password:
            raise RuntimeError(
                "Configura DB_USER y DB_PASSWORD o activa DB_TRUSTED_CONNECTION."
            )
        authentication = (
            f"UID={_odbc_value(user)};"
            f"PWD={_odbc_value(password)};"
        )
    else:
        raise RuntimeError("DB_TRUSTED_CONNECTION debe ser true o false.")

    driver = "ODBC Driver 17 for SQL Server"
    server = os.getenv("DB_SERVER", "localhost").strip()
    database = os.getenv("DB_NAME", "DB_SCRUM_PLANNING").strip()

    if not server or not database:
        raise RuntimeError("DB_SERVER y DB_NAME no pueden estar vacíos.")

    connection_string = (
        f"DRIVER={_odbc_value(driver)};"
        f"SERVER={_odbc_value(server)};"
        f"DATABASE={_odbc_value(database)};"
        f"{authentication}"
    )
    return pyodbc.connect(connection_string)

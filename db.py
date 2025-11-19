# =======================================================
# db.py
# Conexión a PostgreSQL y ejecución de scripts SQL
# =======================================================

import psycopg2
import os

DB_CONFIG = {
    "dbname": "test_db",
    "user": "postgres",
    "password": "postgres",
    "host": "localhost",
    "port": "5432"
}

def run_sql_file(filename):
    print(f"\n>>> Ejecutando: {filename}")

    with open(filename, "r", encoding="utf-8") as file:
        sql_script = file.read()

    try:
        conn = psycopg2.connect(**DB_CONFIG)
        conn.autocommit = True
        cursor = conn.cursor()

        cursor.execute(sql_script)

        print(f"✔ OK: {filename}")

        cursor.close()
        conn.close()

    except Exception as e:
        print(f"❌ Error en {filename}: {e}")


if __name__ == "__main__":

    # SQL files están EN RAÍZ, no en /tests/
    files = [
        "01_create_tables.sql",
        "02_insert_data.sql",
        "03_functions_and_procedures.sql",
        "04_triggers.sql",
        "05_test_queries.sql"
    ]

    for f in files:
        path = os.path.join(os.getcwd(), f)
        if os.path.exists(path):
            run_sql_file(path)
        else:
            print(f"⚠ Archivo no encontrado: {path}")

        path = os.path.join(BASE_PATH, f)
        if os.path.exists(path):
            run_sql_file(path)
        else:
            print(f"⚠ Archivo no encontrado: {path}")

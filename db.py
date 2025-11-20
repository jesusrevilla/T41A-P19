
import psycopg2
import os

DB_CONFIG = {
    "dbname": "test_db",
    "user": "postgres",
    "password": "postgres",
    "host": "localhost",
    "port": "5432"
}

def run_sql_file(path):
    """Leer y ejecutar un archivo SQL."""
    print(f"\n>>> Ejecutando: {path}")

    try:
        with open(path, "r", encoding="utf-8") as file:
            sql_script = file.read()

        conn = psycopg2.connect(**DB_CONFIG)
        conn.autocommit = True
        cur = conn.cursor()

        cur.execute(sql_script)

        print(f"✔ OK: {path}")

        cur.close()
        conn.close()

    except Exception as e:
        print(f"❌ Error en {path}: {e}")


if __name__ == "__main__":

    # Los SQL están en la raíz del proyecto
    sql_files = [
        "01_create_tables.sql",
        "02_insert_data.sql",
        "03_functions_and_procedures.sql",
        "04_triggers.sql",
        "05_test_queries.sql"
    ]

    project_root = os.getcwd()

    for filename in sql_files:
        full_path = os.path.join(project_root, filename)

        if os.path.exists(full_path):
            run_sql_file(full_path)
        else:
            print(f"⚠ Archivo no encontrado: {full_path}")


import psycopg2
import os

# Configuración de la base de datos
DB_CONFIG = {
    "dbname": "test_db",
    "user": "postgres",
    "password": "postgres",
    "host": "localhost",
    "port": "5432"
}

def run_sql_file(filename):
    """Lee y ejecuta un archivo SQL."""
    print(f"\n>>> Ejecutando: {filename}")

    with open(filename, "r", encoding="utf-8") as file:
        sql_script = file.read()

    try:
        conn = psycopg2.connect(**DB_CONFIG)
        conn.autocommit = True
        cursor = conn.cursor()

        cursor.execute(sql_script)
        print(f"✔ Archivo ejecutado correctamente: {filename}")

        cursor.close()
        conn.close()

    except Exception as e:
        print(f"❌ Error ejecutando {filename}: {e}")


if __name__ == "__main__":
    # Carpeta donde están los SQL
    BASE_PATH = os.path.join(os.getcwd(), "tests")

    files = [
        "01_create_tables.sql",
        "02_insert_data.sql",
        "03_functions_and_procedures.sql",
        "04_triggers.sql",
        "05_test_queries.sql"
    ]

    for f in files:
        path = os.path.join(BASE_PATH, f)
        if os.path.exists(path):
            run_sql_file(path)
        else:
            print(f"⚠ Archivo no encontrado: {path}")

# test.py
import os
import sys
import psycopg2

FILES = [
    "01_crear_tablas.sql",
    "02_insertar_datos.sql",
    "03_crud_usuarios_roles.sql",
    "04_funciones_geom_y_utilizacion.sql",
    "05_procedimientos.sql",
    "06_triggers.sql",
    "07_eventos_json.sql",
    "08_seguridad.sql",
    "09_pruebas_unitarias.sql",
]

def get_conn():
    db_url = os.getenv("DATABASE_URL")
    if db_url:
        return psycopg2.connect(db_url)
    params = {
        "host": os.getenv("PGHOST", "localhost"),
        "port": os.getenv("PGPORT", "5432"),
        "dbname": os.getenv("PGDATABASE", "postgres"),
        "user": os.getenv("PGUSER", "postgres"),
        "password": os.getenv("PGPASSWORD", "postgres"),
    }
    return psycopg2.connect(**params)

def run_sql(cur, path):
    with open(path, "r", encoding="utf-8") as f:
        sql = f.read()
    print(f"\n==> Ejecutando {path} ...")
    cur.execute(sql)

def main():
    try:
        conn = get_conn()
        conn.autocommit = False
    except Exception as e:
        print("Error conectando a PostgreSQL:", e)
        sys.exit(1)

    try:
        with conn.cursor() as cur:
            for f in FILES:
                run_sql(cur, f)
                conn.commit()
                print(f"OK: {f}")

            # Verificación adicional: leer utilización calculada
            cur.execute("""
                SET search_path TO corte, public;
                SELECT numero_parte, utilizacion_pct
                FROM materia_prima
                WHERE numero_parte = 'MP-800x400';
            """)
            row = cur.fetchone()
            if row:
                mp, util = row
                print(f"\nUtilización de {mp}: {util:.4f}%")

            # Mostrar resultados de pruebas
            cur.execute("SELECT name, success, COALESCE(details,'') FROM corte.test_results ORDER BY id;")
            rows = cur.fetchall()
            print("\nResultados de pruebas:")
            ok = 0
            for name, success, details in rows:
                status = "OK" if success else "FAIL"
                if success: ok += 1
                print(f" - {status}: {name} -> {details}")
            print(f"\nPasadas: {ok}/{len(rows)}")

        conn.commit()
    except Exception as e:
        conn.rollback()
        print("Error durante la ejecución:", e)
        sys.exit(2)
    finally:
        conn.close()
        print("\nHecho.")

if __name__ == "__main__":
    main()

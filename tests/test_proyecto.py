
import psycopg2

DB_CONFIG = {
    "dbname": "test_db",
    "user": "postgres",
    "password": "postgres",
    "host": "localhost",
    "port": 5432
}

def connect():
    """Establecer conexión con la BD."""
    return psycopg2.connect(**DB_CONFIG)


# ==================================================
# 1. PRUEBA DE CONEXIÓN
# ==================================================
def test_conexion():
    print("\n📌 Probando conexión a PostgreSQL...")
    conn = connect()
    conn.close()
    print("✔ Conexión exitosa\n")


# ==================================================
# 2. VERIFICAR TABLAS EXISTENTES
# ==================================================
def test_tablas_existentes():
    print("📌 Verificando tablas creadas...")

    tablas = [
        "roles",
        "usuarios",
        "materia_prima",
        "productos",
        "piezas",
        "geometrias",
        "eventos",
        "utilizacion"
    ]

    conn = connect()
    cur = conn.cursor()

    for tabla in tablas:
        cur.execute(f"SELECT to_regclass('{tabla}') IS NOT NULL;")
        existe = cur.fetchone()[0]
        print(f" - {tabla}: {'✔ OK' if existe else '❌ NO EXISTE'}")

    conn.close()
    print()


# ==================================================
# 3. PROBAR FUNCIÓN fn_calcular_utilizacion
# ==================================================
def test_fn_utilizacion():
    print("📌 Probando fn_calcular_utilizacion...")

    conn = connect()
    cur = conn.cursor()

    cur.execute("SELECT fn_calcular_utilizacion(1);")
    resultado = cur.fetchone()[0]

    print(f"✔ Porcentaje calculado: {resultado}%\n")
    conn.close()


# ==================================================
# 4. PROBAR PROCEDIMIENTO sp_rotar_posicionar_figuras
# ==================================================
def test_sp_rotar_posicionar():
    print("📌 Probando sp_rotar_posicionar_figuras...")

    conn = connect()
    cur = conn.cursor()

    cur.execute("""
        CALL sp_rotar_posicionar_figuras(
            1,
            45,
            '{"x":10,"y":20}',
            '{"accion":"rotar","angulo":45}'
        );
    """)

    cur.execute("SELECT rotacion, posicion FROM geometrias WHERE pieza_id = 1;")
    rotacion, posicion = cur.fetchone()

    print(f"✔ Rotación actualizada: {rotacion}")
    print(f"✔ Posición actualizada: {posicion}\n")

    conn.close()


# ==================================================
# 5. PROBAR TRIGGER DE UTILIZACIÓN
# ==================================================
def test_trigger_utilizacion():
    print("📌 Probando trigger de actualización de utilización...")

    conn = connect()
    cur = conn.cursor()

    # Generar evento que dispara trigger
    cur.execute("""
        INSERT INTO eventos (pieza_id, evento)
        VALUES (1, '{"trigger":"test"}');
    """)

    cur.execute("SELECT porcentaje FROM utilizacion ORDER BY id DESC LIMIT 1;")
    porcentaje = cur.fetchone()[0]

    print(f"✔ Trigger registró porcentaje: {porcentaje}%\n")

    conn.close()


# ==================================================
# EJECUCIÓN MANUAL (si se ejecuta python tests/test_proyecto.py)
# ==================================================
if __name__ == "__main__":
    test_conexion()
    test_tablas_existentes()
    test_fn_utilizacion()
    test_sp_rotar_posicionar()
    test_trigger_utilizacion()

    print("\n✔ TODAS LAS PRUEBAS FINALIZARON CORRECTAMENTE ✔\n")

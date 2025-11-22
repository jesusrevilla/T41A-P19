import psycopg2
import pytest
import json

DB_CONFIG = {
    "dbname": "test_db",
    "user": "postgres",
    "password": "postgres",
    "host": "localhost",
    "port": 5432
}

@pytest.fixture(scope="module")
def db_connection():
    conn = psycopg2.connect(**DB_CONFIG)
    conn.autocommit = True 
    yield conn
    conn.close()

def test_crud_usuarios(db_connection):
    with db_connection.cursor() as cur:
        # Crear usuario
        cur.execute("CALL sp_crear_usuario('Test User', 'test@email.com', 'operador');")
        
        cur.execute("SELECT * FROM fn_obtener_usuario('test@email.com');")
        result = cur.fetchone()
        assert result[0] == 'Test User'
        assert result[1] == 'operador'

def test_calculo_utilizacion(db_connection):
    with db_connection.cursor() as cur:
        # 1. Alta Materia Prima (100x100 = 10000 area)
        # Se define margen de orilla = 5
        cur.execute("CALL sp_alta_materia_prima('LAMINA-001', 100, 100, 5, 5);")
        
        # Obtener ID de materia prima
        cur.execute("SELECT id FROM materia_prima WHERE numero_parte = 'LAMINA-001'")
        mp_id = cur.fetchone()[0]

        # 2. Alta Producto y Pieza
        cur.execute("CALL sp_alta_producto('PROD-X', 'Mesa', 1, 'rectangulo', '{\"w\":50, \"h\":50}', 2500);")
        
        
        cur.execute("UPDATE piezas SET materia_prima_id = %s, posicion_x = 10, posicion_y = 10 WHERE nombre_pieza = 'Pieza Base PROD-X'", (mp_id,))
        
        # 3. Probar función de cálculo
        cur.execute(f"SELECT fn_calcular_utilizacion({mp_id});")
        utilizacion = cur.fetchone()[0]
        
        # Debe ser 25.00%
        assert float(utilizacion) == 25.00

def test_trigger_eventos_json(db_connection):
    with db_connection.cursor() as cur:
        # Obtener ID de la pieza creada antes
        cur.execute("SELECT id FROM piezas WHERE nombre_pieza = 'Pieza Base PROD-X'")
        pieza_id = cur.fetchone()[0]

        # Insertar evento JSON para rotar la pieza a 90 grados en posicion 20,20
        # (Usamos 20,20 para mantenerla válida dentro del margen)
        payload = json.dumps({"pieza_id": pieza_id, "x": 20, "y": 20, "rotacion": 90})
        cur.execute(f"INSERT INTO eventos (tipo_evento, payload) VALUES ('ajuste_pieza', '{payload}');")

    
        cur.execute(f"SELECT rotacion_grados, posicion_x FROM piezas WHERE id = {pieza_id}")
        data = cur.fetchone()
        
        assert float(data[0]) == 90.00 # Rotación actualizada
        assert float(data[1]) == 20.00 # Posición X actualizada

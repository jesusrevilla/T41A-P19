import pytest
import psycopg2
import json
from psycopg2.extras import RealDictCursor

# --- CONFIGURACIÓN DE LA BASE DE DATOS ---
DB_CONFIG = {
    "dbname": "test_db",
    "user": "postgres",     
    "password": "postgres", 
    "host": "localhost",
    "port": "5432"
}

# --- CONFIGURACION INICIAL PARA CADA PRUEBA---
@pytest.fixture(scope="module")
def db_conn():
    """Crea una conexión única para todas las pruebas del módulo."""
    conn = psycopg2.connect(**DB_CONFIG)
    conn.autocommit = False #Manejamos transacciones manualmente
    yield conn
    conn.close()

@pytest.fixture(scope="function")
def cursor(db_conn):
    """
    Entrega un cursor para ejecutar SQL. 
    Al finalizar la prueba, hace ROLLBACK para dejar la BD limpia.
    """
    cur = db_conn.cursor(cursor_factory=RealDictCursor)
    yield cur
    db_conn.rollback() # ¡Importante! Deshace cambios después de cada test para no ensuciar la base de datos

# --- PRUEBAS UNITARIAS ---

def test_crud_usuarios(cursor):
    """Prueba la creación, modificación y baja de usuarios."""
    # 1. Alta
    cursor.execute("SELECT alta_usuario(%s, %s)", ('Admin', 1))
    user_id = cursor.fetchone()['alta_usuario']
    assert user_id is not None
    # 2. Verificar existencia
    cursor.execute("SELECT * FROM usuario WHERE id = %s", (user_id,))
    user = cursor.fetchone()
    assert user['nombre'] == 'Admin'
    # 3. Modificación
    cursor.execute("SELECT modificar_usuario(%s, %s, %s)", (user_id, 'Operador', 2))
    cursor.execute("SELECT * FROM usuario WHERE id = %s", (user_id,))
    user = cursor.fetchone()
    assert user['nombre'] == 'Operador'
    assert user['rol'] == 2
    # 4. Baja
    cursor.execute("SELECT baja_usuario(%s)", (user_id,))
    cursor.execute("SELECT * FROM usuario WHERE id = %s", (user_id,))
    assert cursor.fetchone() is None

def test_alta_materia_y_producto(cursor):
    """Prueba los Procedures de alta con JSON."""
    
    # 1. Alta Materia Prima
    cursor.execute("CALL alta_materia_prima(%s, %s, %s, %s)", (200, 300, 5, 10))
    cursor.execute("SELECT * FROM materia_prima WHERE ancho = 200 AND alto = 300")
    materia = cursor.fetchone()
    assert materia is not None
    
    # 2. Alta Producto
    piezas_json = [
        {
            "nombre_pieza": "RelojTest",
            "descripcion": "Mecánico",
            "cantidad_elementos": 1,
            "geometria": "((0,0),(4,0),(4,2),(0,2))"
        }
    ]
    
    cursor.execute(
        "CALL alta_producto(%s, %s, box(point(0,0), point(10,5)), %s)",
        ('Reloj', 'Reloj Mecanico', json.dumps(piezas_json))
    )
    # Verificar que se crearon la pieza y la geometría
    cursor.execute(
        "SELECT p.id, g.id_geometria FROM pieza p JOIN geometrias g ON p.id = g.id_pieza "
        "JOIN producto pr ON p.producto_id = pr.id WHERE pr.nombre = 'Reloj'"
    )
    resultado = cursor.fetchone()
    assert resultado is not None, "No se generaron las piezas o geometrías correctamente"

def test_logica_corte_valido(cursor):
    """Prueba de un corte que si debe entrar."""
    cursor.execute("CALL alta_materia_prima(100, 100, 0, 0)")
    cursor.execute("SELECT id FROM materia_prima ORDER BY id DESC LIMIT 1")
    id_mp = cursor.fetchone()['id']
    cursor.execute("CALL alta_producto('Valido', 'Producto Valido', box(point(0,0), point(10,10)), %s)", 
                   (json.dumps([{"nombre_pieza": "P1", "descripcion": "D", "cantidad_elementos": 1, "geometria": "((0,0),(10,0),(10,10),(0,10))"}]),))
    cursor.execute("SELECT g.id_geometria FROM geometrias g JOIN pieza p ON g.id_pieza = p.id JOIN producto pr ON p.producto_id = pr.id WHERE pr.nombre = 'Valido' LIMIT 1")
    id_geo = cursor.fetchone()['id_geometria']
    
    # Crear usuario 
    cursor.execute("INSERT INTO usuario (nombre, rol) VALUES ('Tester', 1) RETURNING id")
    id_user = cursor.fetchone()['id']
    # --- EJECUCIÓN DEL TEST ---
    cursor.execute(
        "CALL sp_rotar_posicionar_figuras(%s, %s, %s, %s, %s, %s, %s)",
        (id_geo, id_mp, 0, 10, 10, json.dumps({'test': 'ok'}), id_user)
    )
    # Validación
    cursor.execute("SELECT COUNT(*) as total FROM cortes_planificados WHERE id_materia = %s", (id_mp,))
    assert cursor.fetchone()['total'] == 1

def test_logica_colision_trigger(cursor):
    """Prueba que el TRIGGER bloquee una colisión."""
    
    # 1. Setup (Mismo que el anterior)
    cursor.execute("CALL alta_materia_prima(100, 100, 0, 0)")
    cursor.execute("SELECT id FROM materia_prima ORDER BY id DESC LIMIT 1")
    id_mp = cursor.fetchone()['id']
    
    cursor.execute("CALL alta_producto('Colision', 'Producto Colision', box(point(0,0), point(10,10)), %s)", 
                   (json.dumps([{"nombre_pieza": "P1", "descripcion": "D", "cantidad_elementos": 1, "geometria": "((0,0),(10,0),(10,10),(0,10))"}]),))
    
    cursor.execute("SELECT g.id_geometria FROM geometrias g JOIN pieza p ON g.id_pieza = p.id JOIN producto pr ON p.producto_id = pr.id WHERE pr.nombre = 'Colision' LIMIT 1")
    id_geo = cursor.fetchone()['id_geometria']
    
    cursor.execute("INSERT INTO usuario (nombre, rol) VALUES ('Tester', 1) RETURNING id")
    id_user = cursor.fetchone()['id']

    # 2. Insertar primera pieza (Válida)
    cursor.execute("CALL sp_rotar_posicionar_figuras(%s, %s, 0, 10, 10, '{}', %s)", (id_geo, id_mp, id_user))
    
    # 3. Insertar segunda pieza ENCIMA (Debe fallar)
    with pytest.raises(psycopg2.errors.RaiseException) as excinfo:
        cursor.execute("CALL sp_rotar_posicionar_figuras(%s, %s, 0, 11, 11, '{}', %s)", (id_geo, id_mp, id_user))

def test_calculo_utilizacion(cursor):
    """Verifica que la función matemática de utilización no de cero."""
    # Insertamos datos manuales para controlar el cálculo
    cursor.execute("INSERT INTO materia_prima (num_parte, ancho, alto, distancia_minima_entre_piezas, distancia_minima_a_orilla) VALUES ('TEST-UTIL', 100, 100, 0, 0) RETURNING id")
    id_mp = cursor.fetchone()['id']
    
    # Insertamos un corte manual de 50x50 (Area 2500). Total 10000. Utilización esperada 25%.
    cursor.execute("INSERT INTO usuario (nombre, rol) VALUES ('U', 1) RETURNING id")
    u_id = cursor.fetchone()['id']
    
    # Necesitamos una pieza y producto
    cursor.execute("INSERT INTO producto (nombre, descripcion, geometria) VALUES ('D', 'D', box(point(0,0), point(1,1))) RETURNING id")
    prod_id = cursor.fetchone()['id']
    cursor.execute("INSERT INTO pieza (producto_id, nombre_pieza, descripcion, cantidad_elementos) VALUES (%s, 'P', 'D', 1) RETURNING id", (prod_id,))
    pieza_id = cursor.fetchone()['id']
    
    cursor.execute("INSERT INTO cortes_planificados (id_materia, id_pieza, id_usuario, geometria_final) VALUES (%s, %s, %s, '((0,0),(50,0),(50,50),(0,50))')", (id_mp, pieza_id, u_id))
    
    # Llamar función
    cursor.execute("SELECT fn_calcular_utilizacion(%s) as util", (id_mp,))
    resultado = cursor.fetchone()['util']
    
    assert resultado == 25.00

def test_seguridad_permisos():
    """Prueba que el usuario 'operador' no pueda borrar datos."""
    # Configurar conexión como OPERADOR
    config_operador = DB_CONFIG.copy()
    config_operador['user'] = 'operador'
    config_operador['password'] = '456789'
    try:
        conn_op = psycopg2.connect(**config_operador)
        cur_op = conn_op.cursor()
        
        # Intentar borrar (Debe fallar)
        with pytest.raises(psycopg2.errors.InsufficientPrivilege):
            cur_op.execute("DELETE FROM materia_prima")
            
        conn_op.rollback()
        conn_op.close()
        
    except psycopg2.OperationalError:
        pytest.skip("No se pudo conectar como usuario 'operador'. Verifica que el usuario exista en la BD.")

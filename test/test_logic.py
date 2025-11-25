# tests/test_logic.py
 
import pytest
import psycopg2
import json
from psycopg2.errors import RaiseException, IntegrityError
 
# NOTA: La conexión debe coincidir con la configuración del servicio 'postgres' en .github/workflows/postgresql_workflow.yml
DB_HOST = "localhost"
DB_NAME = "test_db"
DB_USER = "postgres"
DB_PASSWORD = "postgres"
 
 
@pytest.fixture(scope="module")
def db_conn():
    """Fixture para establecer y configurar la conexión a la base de datos de prueba."""
    try:
        conn = psycopg2.connect(
            host=DB_HOST, database=DB_NAME, user=DB_USER, password=DB_PASSWORD
        )
        conn.autocommit = True
        yield conn
        conn.close()
    except Exception as e:
        pytest.fail(f"No se pudo conectar a la base de datos: {e}")
 
 
# --- PRUEBAS DE FUNCIONES Y TRIGGERS ---
 
def test_fn_calcular_utilizacion_correct(db_conn):
    """Prueba que la función fn_calcular_utilizacion retorne 2.0% (basado en 02_insert_data.sql)."""
    sql_call = "SELECT fn_calcular_utilizacion(1);"
    with db_conn.cursor() as cur:
        cur.execute(sql_call)
        result = cur.fetchone()[0]
        assert abs(result - 2.0) < 0.001, f"Utilización esperada 2.0, obtenida {result}"
 
 
def test_trigger_validation_raises_exception_for_boundary(db_conn):
    """Prueba que el trigger rechace una posición inválida (X=5.0, Mínimo 10.0)."""
    invalid_x = 5.0
    insert_sql = """
    INSERT INTO piezas_colocadas (opt_corte_id, pieza_id, geometria_actual, rotacion_grados, posicion_x, posicion_y)
    VALUES (1, 1, 'GEOM_TRIGGER_FAIL_PYTHON', 0.0, %s, 50.0);
    """
    with db_conn.cursor() as cur:
        with pytest.raises(RaiseException, match="demasiado cerca del borde"):
            cur.execute(insert_sql, (invalid_x,))
 
 
def test_sp_rotar_posicionar_updates_and_logs(db_conn):
    """Prueba el SP sp_rotar_posicionar_figuras y el registro JSONB."""
    pieza_colocada_id = 1
    new_rotation = 45.0
    new_pos_x = 200.0
    event_payload = '{"usuario": "test_operador", "algoritmo": "python_test"}'
 
    sql_call = f"CALL sp_rotar_posicionar_figuras({pieza_colocada_id}, {new_rotation}, {new_pos_x}, 50.0, '{event_payload}'::JSONB);"
 
    with db_conn.cursor() as cur:
        # Ejecutar el SP
        cur.execute(sql_call)
 
        # Verificar actualización de posición
        cur.execute(f"SELECT rotacion_grados, posicion_x FROM piezas_colocadas WHERE pieza_colocada_id = {pieza_colocada_id};")
        rotacion, pos_x = cur.fetchone()
        assert rotacion == new_rotation
        assert pos_x == new_pos_x
 
        # Verificar registro del evento JSONB
        cur.execute(f"SELECT payload FROM eventos_optimizacion WHERE pieza_colocada_id = {pieza_colocada_id} ORDER BY fecha_evento DESC LIMIT 1;")
        payload_data = cur.fetchone()[0]
        assert "python_test" in str(payload_data), "El evento JSONB no fue registrado correctamente."
 
# --- PRUEBAS DE CRUD Y SEGURIDAD ---
 
def test_sp_crud_roles_cycle(db_conn):
    """Prueba el ciclo completo de Crear, Actualizar y Eliminar roles."""
    rol_name = 'Test_ROL_Cycle_Py'
    with db_conn.cursor() as cur:
        # CREAR
        cur.execute(f"CALL sp_crear_rol('{rol_name}', 'Rol de prueba python');")
        cur.execute(f"SELECT rol_id, descripcion FROM roles WHERE nombre = '{rol_name}';")
        rol_id, desc = cur.fetchone()
        assert rol_id is not None
        # ELIMINAR
        cur.execute(f"CALL sp_eliminar_rol({rol_id});")
        cur.execute(f"SELECT rol_id FROM roles WHERE rol_id = {rol_id};")
        assert cur.fetchone() is None
 
def test_sp_crud_usuarios_and_auth(db_conn):
    """Prueba la creación, autenticación (seguridad), actualización y eliminación de usuarios."""
    username = 'ci_test_user_py'
    password = 'SecurePasswordPy'
    with db_conn.cursor() as cur:
        # Asegurar rol 1
        cur.execute("SELECT rol_id FROM roles WHERE nombre = 'Administrador';")
        rol_id = cur.fetchone()[0]
        # CREAR USUARIO (HASHING)
        cur.execute(f"CALL sp_crear_usuario('{username}', '{password}', {rol_id});")
        cur.execute(f"SELECT usuario_id FROM usuarios WHERE username = '{username}';")
        user_id = cur.fetchone()[0]
        assert user_id is not None
 
        # AUTENTICACIÓN (fn_autenticar_usuario)
        cur.execute(f"SELECT fn_autenticar_usuario('{username}', '{password}');")
        assert cur.fetchone()[0] is True # Correcta
        # Actualizar a inactivo
        cur.execute(f"CALL sp_actualizar_usuario({user_id}, '{username}', NULL, FALSE);")
        # Autenticación debe fallar por inactivo
        cur.execute(f"SELECT fn_autenticar_usuario('{username}', '{password}');")
        assert cur.fetchone()[0] is False 
        # ELIMINAR
        cur.execute(f"CALL sp_eliminar_usuario({user_id});")
        cur.execute(f"SELECT usuario_id FROM usuarios WHERE usuario_id = {user_id};")
        assert cur.fetchone() is None

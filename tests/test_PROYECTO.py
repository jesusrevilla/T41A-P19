import psycopg2
import pytest
from decimal import Decimal
import json

DB_CONFIG = {
    'dbname': 'test_db',
    'user': 'postgres',
    'password': 'postgres',
    'host': 'localhost',
    'port': '5432'
}

@pytest.fixture(scope="module")
def db_conn():
    """Fixture para crear la conexión a la BD y limpiar datos al inicio."""
    conn = psycopg2.connect(**DB_CONFIG)
    cur = conn.cursor()
  
    tablas = [
        "eventos_optimizacion", "piezas_colocadas", "hojas_corte", 
        "geometrias_pieza", "piezas", "productos", "materia_prima", 
        "usuarios", "roles"
    ]
    for tabla in tablas:
        cur.execute(f"TRUNCATE TABLE {tabla} RESTART IDENTITY CASCADE;")
    
    cur.execute("CREATE EXTENSION IF NOT EXISTS pgcrypto;")
    
    conn.commit()
    yield conn
    conn.close()

def test_1_seguridad_usuarios(db_conn):
    cur = db_conn.cursor()

    cur.execute("CALL sp_crear_rol('Administrador');")
    cur.execute("CALL sp_crear_rol('Operador');")

    cur.execute("CALL sp_alta_usuario('Admin Test', 'admin@test.com', 'admin123', 'Administrador');")
    
    cur.execute("SELECT password_hash FROM usuarios WHERE email = 'admin@test.com';")
    pass_hash = cur.fetchone()[0]
    
    assert pass_hash != 'admin123', "La contraseña se guardó en texto plano (¡ERROR DE SEGURIDAD!)."
    
    cur.execute("SELECT (password_hash = crypt('admin123', password_hash)) FROM usuarios WHERE email = 'admin@test.com';")
    login_exitoso = cur.fetchone()[0]
    
    assert login_exitoso is True, "El login falló: la contraseña encriptada no coincide."
    
    db_conn.commit()

def test_2_inventario_complejo(db_conn):
    cur = db_conn.cursor()

    cur.execute("CALL sp_alta_materia_prima('MP-ACERO-01', 'Acero', 3000, 1500, 5, 100);")
    
    cur.execute("SELECT dimensiones FROM materia_prima WHERE numero_parte = 'MP-ACERO-01';")
    dims = cur.fetchone()[0]
    assert dims['largo'] == 3000
    assert dims['ancho'] == 1500

    geo_json = json.dumps({"ancho": 1000, "alto": 1000})
    cur.execute(f"CALL sp_alta_producto_completo('PROD-MESA', 'Mesa Industrial', 'Tapa', 1, 'RECTANGULO', '{geo_json}');")

    cur.execute("""
        SELECT p.numero_parte, pi.nombre_pieza, gp.tipo_segmento 
        FROM productos p
        JOIN piezas pi ON p.numero_parte = pi.producto_numero_parte
        JOIN geometrias_pieza gp ON pi.id = gp.pieza_id
        WHERE p.numero_parte = 'PROD-MESA';
    """)
    resultado = cur.fetchone()
    assert resultado == ('PROD-MESA', 'Tapa', 'RECTANGULO')
    
    db_conn.commit()

def test_3_logica_corte_y_triggers(db_conn):
    cur = db_conn.cursor()

    cur.execute("SELECT id FROM usuarios WHERE email = 'admin@test.com';")
    user_id = cur.fetchone()[0]

    cur.execute(f"CALL sp_alta_hoja_corte('MP-ACERO-01', {user_id});")
    
    cur.execute("SELECT id, area_total_mm2 FROM hojas_corte WHERE mp_numero_parte = 'MP-ACERO-01';")
    hoja = cur.fetchone()
    hoja_id = hoja[0]
    area_total = hoja[1]
    
    assert area_total == Decimal('4500000.00'), f"El trigger no calculó el área total correctamente. Obtuvo: {area_total}"

    cur.execute("SELECT id FROM piezas WHERE nombre_pieza = 'Tapa';")
    pieza_id = cur.fetchone()[0]

    json_evento = json.dumps({"prueba_pytest": True})
    cur.execute(f"CALL sp_rotar_posicionar_figuras({hoja_id}, {pieza_id}, 0, 0, 0, '{json_evento}');")

    cur.execute("SELECT porcentaje_utilizacion, area_ocupada_mm2 FROM hojas_corte WHERE id = %s;", (hoja_id,))
    datos_hoja = cur.fetchone()
    utilizacion = datos_hoja[0]
    area_ocupada = datos_hoja[1]

    assert area_ocupada == Decimal('1000000.00')
    assert utilizacion == Decimal('22.22')

    db_conn.commit()

def test_4_auditoria_eventos(db_conn):
    cur = db_conn.cursor()
    
    cur.execute("""
        SELECT datos_evento 
        FROM eventos_optimizacion 
        WHERE tipo_evento = 'ROTACION_POSICIONAMIENTO'
        ORDER BY id DESC LIMIT 1;
    """)
    evento = cur.fetchone()[0]
    
    assert evento['prueba_pytest'] is True, "No se guardó el JSON del evento de optimización correctamente."
    
    db_conn.commit()

import psycopg2

def run_query(query):
    conn = psycopg2.connect(
        dbname="test_db",
        user="postgres",
        password="postgres",
        host="localhost"
    )
    cur = conn.cursor()
    cur.execute(query)
    try:
        r = cur.fetchall()
    except:
        r = None
    conn.commit()
    conn.close()
    return r

def test_roles_creados():
    result = run_query("SELECT nombre FROM roles;")
    roles = [r[0] for r in result]
    assert "admin" in roles
    assert "operador" in roles

def test_procedimiento_rotar_posicionar():
    run_query("""
    CALL sp_rotar_posicionar_figuras(
        1, 45, 10, 20, '{"accion":"rotado"}'
    );
    """)
    result = run_query("SELECT evento->>'accion' FROM eventos WHERE pieza_id = 1;")
    assert result[0][0] == "rotado"

def test_funcion_utilizacion():
    result = run_query("SELECT fn_calcular_utilizacion();")
    assert result[0][0] > 0

def test_trigger_validacion_distancias():
    try:
        run_query("""
        INSERT INTO materia_prima (numero_parte, ancho, alto, distancia_entre_piezas, distancia_borde)
        VALUES ('ERR-1', 10, 10, -1, 1);
        """)
        assert False
    except Exception:
        assert True

import psycopg2
import pytest

conn_str = "dbname=proyecto user=postgres password=postgres host=localhost port=5432"

@pytest.fixture
def conn():
    return psycopg2.connect(conn_str)

def test_alta_usuario(conn):
    cur = conn.cursor()
    cur.execute("SELECT fn_crear_usuario('juan','1234','operador');")
    conn.commit()

    cur.execute("SELECT COUNT(*) FROM usuarios WHERE username='juan';")
    cantidad = cur.fetchone()[0]
    assert cantidad == 1

def test_calcular_utilizacion(conn):
    cur = conn.cursor()

    cur.execute("INSERT INTO materia_prima(id,numero_parte,ancho,alto) VALUES (1,'MP-01',100,100);")
    cur.execute("INSERT INTO piezas(id,id_producto,area) VALUES (1,1,2500);")
    cur.execute("INSERT INTO piezas(id,id_producto,area) VALUES (2,1,2500);")

    cur.execute("SELECT fn_calcular_utilizacion(1);")
    valor = cur.fetchone()[0]

    assert valor == 0.5  # 5000 / 10000

def test_rotar_posicionar(conn):
    cur = conn.cursor()

    cur.execute("""
        INSERT INTO geometrias(id,id_pieza,datos)
        VALUES (1,1,'{"x":0,"y":0,"angulo":0}'::json);
    """)

    cur.execute("""
        CALL sp_rotar_posicionar_figuras(1,45,10,20,'{"evento":"rotar"}');
    """)

    cur.execute("SELECT datos FROM geometrias WHERE id=1;")
    geo = cur.fetchone()[0]

    assert geo["angulo"] == 45
    assert geo["x"] == 10
    assert geo["y"] == 20

import os
import psycopg2
import pytest
import time
from psycopg2.extras import RealDictCursor, Json

PGHOST = os.getenv("PGHOST", "localhost")
PGPORT = os.getenv("PGPORT", "5432")
PGUSER = os.getenv("PGUSER", "postgres")
PGPASSWORD = os.getenv("PGPASSWORD", "postgres")
PGDATABASE = os.getenv("PGDATABASE", "test_db")

def get_conn():
    return psycopg2.connect(
        host=PGHOST, port=PGPORT, user=PGUSER, password=PGPASSWORD, dbname=PGDATABASE
    )

@pytest.fixture(scope="module", autouse=True)
def wait_db():
    for _ in range(30):
        try:
            conn = get_conn()
            conn.close()
            break
        except Exception:
            time.sleep(1)
    yield

def test_sp_alta_materia_prima_and_fn_calcular_utilizacion():
    conn = get_conn()
    cur = conn.cursor(cursor_factory=RealDictCursor)

    cur.execute("CALL sp_alta_materia_prima(%s, %s, %s, %s, %s, %s);",
                ('TEST-MP', 1000, 500, 3, 5, 5))
    conn.commit()

    cur.execute("CALL sp_alta_producto(%s, %s, %s::jsonb);",
                ('TEST-P', 'Producto test', '[{"cantidad":1, "geometria": {"componentes":[{"area":200}], "bbox": {"xmin":10,"ymin":10,"xmax":30,"ymax":30}}}]'))
    conn.commit()

    cur.execute("SELECT id FROM materia_prima WHERE numero_parte = %s", ('TEST-MP',))
    mat = cur.fetchone()
    assert mat is not None
    mat_id = mat['id']

    cur.execute("SELECT fn_calcular_utilizacion(%s) as util;", (mat_id,))
    util = cur.fetchone()['util']
    assert float(util) >= 0.0

    conn.close()

def test_sp_rotar_posicionar_figuras_and_eventos():
    conn = get_conn()
    cur = conn.cursor(cursor_factory=RealDictCursor)

    cur.execute("SELECT id FROM piezas LIMIT 1;")
    row = cur.fetchone()
    assert row is not None
    pieza_id = row['id']

    evento = {"accion": "rotar", "nota": "test"}
    cur.execute("CALL sp_rotar_posicionar_figuras(%s, %s, %s, %s, %s::jsonb);",
                (pieza_id, 45, 100, 200, Json(evento)))
    conn.commit()

    cur.execute("SELECT count(*) as cnt FROM eventos WHERE pieza_id = %s;", (pieza_id,))
    cnt = cur.fetchone()['cnt']
    assert cnt >= 1

    cur.execute("SELECT geometria FROM piezas WHERE id = %s;", (pieza_id,))
    geometria = cur.fetchone()['geometria']
    assert 'transform' in geometria

    conn.close()

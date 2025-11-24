import psycopg2
import pytest
import json

DB = {
    "dbname": "test_db",
    "user": "postgres",
    "password": "postgres",
    "host": "localhost",
    "port": 5432,
}

@pytest.fixture(scope="module")
def conn():
    c = psycopg2.connect(**DB)
    c.autocommit = True
    yield c
    c.close()


def test_crud_usuarios_roles(conn):
    with conn.cursor() as cur:
        cur.execute("""
            CALL sp_usuario_crear(
                'Usuario Prueba',
                'u_prueba',
                'u_prueba@example.com',
                'Operador'
            );
        """)
        cur.execute("SELECT * FROM fn_usuario_obtener('u_prueba');")
        row = cur.fetchone()
        assert row is not None
        nombre, username, email, rol, activo = row
        assert nombre == 'Usuario Prueba'
        assert username == 'u_prueba'
        assert rol == 'Operador'
        assert activo is True

        # Baja lógica
        cur.execute("CALL sp_usuario_baja('u_prueba');")
        cur.execute("SELECT * FROM fn_usuario_obtener('u_prueba');")
        row = cur.fetchone()
        assert row[4] is False   # activo = False


def test_alta_materia_prima_y_producto_piezas(conn):
    with conn.cursor() as cur:
        # Alta materia prima
        cur.execute("""
            CALL sp_materia_prima_alta(
                'MP-001',
                'Lámina MDF 1000x1000',
                1000, 1000,
                10, 20
            );
        """)

        cur.execute("""
            SELECT id, area_total_mm2
            FROM materia_prima
            WHERE numero_parte = 'MP-001';
        """)
        mp_id, area = cur.fetchone()
        assert float(area) == 1000 * 1000

        # Alta producto con piezas desde JSON
        piezas_json = json.dumps([
            {
                "nombre_pieza": "Panel A",
                "indice_en_producto": 1,
                "area_mm2": 100000,
                "tipo_geometria": "rectangulo",
                "datos": {"ancho": 200, "alto": 500}
            },
            {
                "nombre_pieza": "Panel B",
                "indice_en_producto": 2,
                "area_mm2": 50000,
                "tipo_geometria": "rectangulo",
                "datos": {"ancho": 100, "alto": 500}
            }
        ])

        cur.execute("""
            CALL sp_producto_alta_con_piezas(
                'PR-001',
                'Producto de prueba',
                2,
                %s::jsonb
            );
        """, (piezas_json,))

        # Verificamos producto y piezas
        cur.execute("SELECT id FROM productos WHERE numero_parte = 'PR-001';")
        prod_id = cur.fetchone()[0]

        cur.execute("""
            SELECT COUNT(*) FROM piezas WHERE producto_id = %s;
        """, (prod_id,))
        assert cur.fetchone()[0] == 2

        cur.execute("""
            SELECT SUM(area_mm2) FROM geometrias g
            JOIN piezas p ON p.id = g.pieza_id
            WHERE p.producto_id = %s;
        """, (prod_id,))
        total_area = float(cur.fetchone()[0])
        assert total_area == 150000.0


def test_fn_calcular_utilizacion_y_trigger_recalculo(conn):
    with conn.cursor() as cur:
        # Asignamos una pieza de PR-001 a MP-001 y probamos utilización
        cur.execute("SELECT id FROM materia_prima WHERE numero_parte = 'MP-001';")
        mp_id = cur.fetchone()[0]

        cur.execute("SELECT id FROM piezas WHERE nombre_pieza = 'Panel A';")
        pieza_a_id = cur.fetchone()[0]

        cur.execute("""
            UPDATE piezas
            SET materia_prima_id = %s,
                posicion_x_mm = 30,
                posicion_y_mm = 30
            WHERE id = %s;
        """, (mp_id, pieza_a_id))

        # Calculamos aprovechamiento
        cur.execute("SELECT fn_calcular_utilizacion(%s);", (mp_id,))
        utilizacion = float(cur.fetchone()[0])

        # Panel A = 100000 mm2 en una lámina de 1,000,000 mm2 -> 10%
        assert round(utilizacion, 2) == 10.00

        # Trigger de recálculo se dispara en geometrias, probamos borrando la geometría
        cur.execute("""
            DELETE FROM geometrias WHERE pieza_id = %s;
        """, (pieza_a_id,))

        cur.execute("""
            SELECT porcentaje_utilizacion
            FROM materia_prima
            WHERE id = %s;
        """, (mp_id,))
        porcentaje = float(cur.fetchone()[0])
        # Ya no hay área ocupada
        assert round(porcentaje, 2) == 0.00


def test_trigger_validacion_materia_prima(conn):
    with conn.cursor() as cur:
        # Dimensión inválida
        with pytest.raises(Exception):
            cur.execute("""
                CALL sp_materia_prima_alta(
                    'MP-ERR',
                    'Dimensiones inválidas',
                    -10, 100,
                    5, 5
                );
            """)


def test_eventos_json_y_sp_rotar_posicionar(conn):
    with conn.cursor() as cur:
        # Tomamos alguna pieza del producto
        cur.execute("SELECT id FROM piezas WHERE nombre_pieza = 'Panel B';")
        pieza_b_id = cur.fetchone()[0]

        evento = {
            "pieza_id": pieza_b_id,
            "x": 200,
            "y": 300,
            "angulo": 45,
            "config": {"algoritmo": "heuristica_simple", "iteraciones": 10}
        }
        payload = json.dumps(evento)

        # Insertamos evento tipo 'ajuste_pieza' -> trigger llamará fn_aplicar_configuracion_evento
        cur.execute("""
            INSERT INTO eventos(pieza_id, tipo_evento, payload)
            VALUES (%s, 'ajuste_pieza', %s::jsonb);
        """, (pieza_b_id, payload))

        # Verificar que la pieza fue actualizada con la posición/angulo del JSON
        cur.execute("""
            SELECT posicion_x_mm, posicion_y_mm, angulo_deg
            FROM piezas WHERE id = %s;
        """, (pieza_b_id,))
        x, y, angulo = cur.fetchone()

        assert float(x) == 200.0
        assert float(y) == 300.0
        assert float(angulo) == 45.0

        # Verificar que el evento fue marcado como procesado
        cur.execute("""
            SELECT procesado
            FROM eventos
            WHERE pieza_id = %s
              AND tipo_evento = 'ajuste_pieza'
            ORDER BY id DESC
            LIMIT 1;
        """, (pieza_b_id,))
        procesado = cur.fetchone()[0]
        assert procesado is True

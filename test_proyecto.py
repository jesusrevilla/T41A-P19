import pytest
import psycopg2
import os
import json

# Configuración de conexión
DB_CONFIG = {
    'host': 'localhost',
    'database': 'test_db',
    'user': 'postgres',
    'password': 'postgres',
    'port': 5432
}

def get_connection():
    """Obtener conexión a la base de datos"""
    return psycopg2.connect(**DB_CONFIG)

def test_datos_iniciales():
    """
    Verificar que la estructura base y los datos iniciales existen.
    Prueba tablas: usuarios, roles, materia_prima, productos.
    """
    conn = get_connection()
    cur = conn.cursor()

    # 1. Verificar Roles
    cur.execute("SELECT COUNT(*) FROM roles")
    count_roles = cur.fetchone()[0]
    assert count_roles >= 2, "Deben existir al menos los roles Administrador y Operador"

    # 2. Verificar Usuario Admin creado en el init_data
    cur.execute("SELECT email, id_rol FROM usuarios WHERE email = 'admin@sys.com'")
    usuario = cur.fetchone()
    assert usuario is not None
    assert usuario[0] == 'admin@sys.com'

    # 3. Verificar Materia Prima del init_data
    cur.execute("SELECT ancho, alto FROM materia_prima WHERE numero_parte = 'MP-Madera-std'")
    mp = cur.fetchone()
    assert mp is not None
    assert mp[0] == 244.00
    
    cur.close()
    conn.close()

def test_sp_creacion_inventario():
    """
    Probar los procedimientos almacenados de alta:
    - sp_alta_materia_prima
    - sp_alta_producto
    """
    conn = get_connection()
    cur = conn.cursor()

    # 1. Probar Alta de Materia Prima
    cur.execute("SELECT sp_alta_materia_prima('MP-TEST-PY', 100.0, 100.0, 1, 1, 50)")
    id_materia = cur.fetchone()[0]
    assert id_materia > 0

    # Verificar cálculo automático de área
    cur.execute("SELECT area_total FROM materia_prima WHERE id_materia = %s", (id_materia,))
    area = cur.fetchone()[0]
    assert area == 10000.00  # 100 * 100

    # 2. Probar Alta de Producto
    cur.execute("SELECT sp_alta_producto('PROD-TEST-PY', 'Producto de Prueba Python')")
    id_prod = cur.fetchone()[0]
    assert id_prod > 0
    
    conn.commit()
    cur.close()
    conn.close()

def test_definicion_geometria_compleja():
    """
    Probar la relación Producto -> Pieza -> Geometría (JSON)
    """
    conn = get_connection()
    cur = conn.cursor()

    # Obtener ID del producto creado en el test anterior
    cur.execute("SELECT id_producto FROM productos WHERE numero_parte = 'PROD-TEST-PY'")
    id_prod = cur.fetchone()[0]

    # 1. Agregar Pieza
    cur.execute("SELECT sp_agregar_pieza(%s, 'Pieza Triangular', 2, 50.0)", (id_prod,))
    id_pieza = cur.fetchone()[0]

    # 2. Agregar Geometría 
    params_json = json.dumps({"x1": 0, "y1": 0, "x2": 10, "y2": 10})
    cur.execute("SELECT sp_agregar_geometria(%s, 1, 'LINEA', %s)", (id_pieza, params_json))
    conn.commit()

    # Validar inserción
    cur.execute("SELECT parametros_geo FROM geometrias WHERE id_pieza = %s", (id_pieza,))
    geo_data = cur.fetchone()[0]
    
    assert geo_data['x2'] == 10
    
    cur.close()
    conn.close()

def test_procedimiento_corte_exitoso():
    """
    Probar el procedimiento principal: sp_rotar_posicionar_figuras
    """
    conn = get_connection()
    cur = conn.cursor()

    payload = json.dumps({
        "id_pieza": 1,
        "id_materia": 1,
        "x": 10.0,
        "y": 10.0,
        "rotacion": 45.0
    })

    # Ejecutar el Procedure
    cur.execute("CALL sp_rotar_posicionar_figuras(%s)", (payload,))
    conn.commit()

    # Verificar que se registró en 'cortes_optimizados'
    cur.execute("SELECT posicion_x, rotacion_grados FROM cortes_optimizados WHERE id_materia = 1 ORDER BY id_corte DESC LIMIT 1")
    corte = cur.fetchone()
    assert corte is not None
    assert float(corte[0]) == 10.0
    assert float(corte[1]) == 45.0

    # Verificar que se registró el evento
    cur.execute("SELECT procesado FROM eventos ORDER BY id_evento DESC LIMIT 1")
    evento = cur.fetchone()
    assert evento[0] is True

    cur.close()
    conn.close()

def test_funcion_calculo_utilizacion():
    """
    Probar la función matemática fn_calcular_utilizacion
    """
    conn = get_connection()
    cur = conn.cursor()

    # Materia Prima 1 tiene 244x122 = 29768 area total
    # Pieza 1  tiene 5000 area base
    # Utilización esperada: (5000 / 29768) * 100 = ~16.79%

    cur.execute("SELECT fn_calcular_utilizacion(1)")
    utilizacion = cur.fetchone()[0]

    assert utilizacion > 0
    assert utilizacion < 100
    print(f"Utilización calculada: {utilizacion}%")

    cur.close()
    conn.close()

def test_trigger_validacion_limites():
    """
    Probar que el TRIGGER impide colocar piezas fuera del tablero.
    """
    conn = get_connection()
    cur = conn.cursor()

    payload_error = json.dumps({
        "id_pieza": 1,
        "id_materia": 1,
        "x": 5000.0, 
        "y": 10.0
    })

    try:
        cur.execute("CALL sp_rotar_posicionar_figuras(%s)", (payload_error,))
        conn.commit()
        assert False, "El trigger debió impedir esta inserción fuera de límites"
    except Exception as e:
        conn.rollback()
        error_msg = str(e)
        print(f"Error esperado capturado: {error_msg}")
        # Buscamos el mensaje que definimos en el trigger
        assert "Coordenadas fuera de límites" in error_msg or "fuera de los límites" in error_msg

    cur.close()
    conn.close()

def test_seguridad_roles():
    """
    Probar que el Rol 'db_operador' no puede borrar usuarios.
    Simulamos el cambio de sesión con SET ROLE.
    """
    conn = get_connection()
    cur = conn.cursor()

    # 1. Cambiar a rol Operador
    cur.execute("SET ROLE db_operador")

    # 2. Intentar borrar un usuario (Acción Prohibida)
    try:
        cur.execute("DELETE FROM usuarios WHERE id_usuario = 1")
        conn.commit()
        assert False, "El Operador no debería poder borrar usuarios"
    except psycopg2.errors.InsufficientPrivilege:
        conn.rollback()
        print("Seguridad verificada: Operador no tiene permisos de borrado.")
    except Exception as e:
        # Capturar otros errores de permisos
        conn.rollback()
        assert "permission denied" in str(e) or "permiso denegado" in str(e)

    # 3. Regresar a Admin para limpiar o seguir
    cur.execute("RESET ROLE")
    
    cur.close()
    conn.close()

def test_integracion_completa_flujo():
    """
    Prueba de integración: Ciclo completo de optimización
    """
    conn = get_connection()
    cur = conn.cursor()

    # 1. Obtener uso inicial
    cur.execute("SELECT fn_calcular_utilizacion(1)")
    uso_inicial = float(cur.fetchone()[0])

    # 2. Insertar 3 piezas nuevas
    piezas_a_insertar = [
        {"id_pieza": 1, "id_materia": 1, "x": 50, "y": 50},
        {"id_pieza": 1, "id_materia": 1, "x": 60, "y": 60},
        {"id_pieza": 1, "id_materia": 1, "x": 70, "y": 70}
    ]

    for p in piezas_a_insertar:
        cur.execute("CALL sp_rotar_posicionar_figuras(%s)", (json.dumps(p),))
    
    conn.commit()

    # 3. Obtener uso final
    cur.execute("SELECT fn_calcular_utilizacion(1)")
    uso_final = float(cur.fetchone()[0])

    # 4. Validaciones finales
    assert uso_final > uso_inicial
    
    cur.execute("SELECT COUNT(*) FROM eventos WHERE procesado = TRUE")
    total_eventos = cur.fetchone()[0]
    assert total_eventos >= 3

    print(f"Integración completada. Uso subió de {uso_inicial}% a {uso_final}%")

    cur.close()
    conn.close()

if __name__ == "__main__":
    pytest.main([__file__, "-v", "-s"])
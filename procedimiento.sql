--PROCEDIMIENTO ALTA DE MATERIA PRIMA
--Secuencia para generación de numero de parte
CREATE SEQUENCE num_materiap_aum
START 1 INCREMENT 1 MINVALUE 1;
--Procedimiento de alta
CREATE PROCEDURE alta_materia_prima(ancho NUMERIC,alto NUMERIC,dist_min_piezas NUMERIC,dist_min_orilla NUMERIC)
LANGUAGE plpgsql AS $$
DECLARE
    num_nuevo INT;
    num_completo TEXT;
BEGIN
    num_nuevo := nextval('num_materiap_aum');

    num_completo := 'NUM-' || LPAD(num_nuevo::TEXT, 4, '0');

    INSERT INTO materia_prima (num_parte, ancho, alto,distancia_minima_entre_piezas,distancia_minima_a_orilla)
    VALUES (num_completo, ancho, alto,dist_min_piezas, dist_min_orilla);
END;
$$;

CALL alta_materia_prima(200, 300, 5, 10);
CALL alta_materia_prima(300, 260, 4, 11);

SELECT * FROM materia_prima;

--PROCEDIMIENTO DE ALTA DE PRODUCTO 
CREATE PROCEDURE alta_producto(nombre TEXT,descripcion TEXT,geometria BOX,piezas JSONB )
LANGUAGE plpgsql AS $$
DECLARE
    producto_id INT;
    pieza_arreglo JSONB;
    pieza_id INT;
BEGIN
    --Inserar producto
    INSERT INTO producto (nombre, descripcion, geometria) VALUES (nombre, descripcion, geometria)
    RETURNING id INTO producto_id;

    --Cada producto tiene sus piezas y geometrias
    FOR pieza_arreglo IN SELECT * FROM jsonb_array_elements(piezas)
    LOOP
        --Insertar piezas
        INSERT INTO pieza (producto_id, nombre_pieza, descripcion, cantidad_elementos)
        VALUES ( producto_id, pieza_arreglo->>'nombre_pieza', pieza_arreglo->>'descripcion', (pieza_arreglo->>'cantidad_elementos')::INT)
        RETURNING id INTO pieza_id;

        --Insertar geometría
        INSERT INTO geometrias (id_pieza, forma_geometrica)
        VALUES (pieza_id, (pieza_arreglo->>'geometria')::POLYGON);
    END LOOP;
END;
$$;
CALL alta_producto('Omnitrix','Producto espacial',box(point(0,0), point(10,5)), 
    '[{"nombre_pieza": "Correa",
       "descripcion": "Soporte",
       "cantidad_elementos": 2,
       "geometria": "((0,0),(5,0),(5,3),(0,3))"},
        {"nombre_pieza": "Reloj",
         "descripcion": "Mecánico",
         "cantidad_elementos": 1,
         "geometria": "((0,0),(4,0),(4,2),(0,2))"}]');

CALL alta_producto('La caja','Producto cajil',box(point(0,0), point(10,5)), 
    '[{"nombre_pieza": "Tapa",
       "descripcion": "Cubierta",
       "cantidad_elementos": 2,
       "geometria": "((0,0),(5,0),(5,3),(0,3))"},
        {"nombre_pieza": "Recipiente",
         "descripcion": "Contenedor",
         "cantidad_elementos": 1,
         "geometria": "((0,0),(4,0),(4,2),(0,2))"}]');

SELECT * FROM producto;
SELECT * FROM pieza;
SELECT * FROM geometrias;
-- FUNCIÓN CRÍTICA DE VALIDACIÓN (USANDO TIPOS NATIVOS)
CREATE OR REPLACE FUNCTION fn_validar_colocacion_nativo(
    p_id_geometria_original INT,     -- ID de la geometría base (para identificación)
    p_nueva_geometria_polygon POLYGON, -- La geometría final (POLYGON) a validar
    p_id_materia_prima INT          -- ID del material base
)
RETURNS BOOLEAN
AS $$
DECLARE
    v_mp_ancho NUMERIC;
    v_mp_alto NUMERIC;
    v_min_distancia_piezas NUMERIC;
    v_min_distancia_orilla NUMERIC;
    v_nueva_caja BOX;
    v_limite_caja BOX;
    v_solapamiento_conteo INT;
BEGIN
    -- 1. Obtener parámetros de la Materia Prima (MP)
    SELECT ancho, alto, distancia_minima_entre_piezas, distancia_minima_a_orilla
    INTO v_mp_ancho, v_mp_alto, v_min_distancia_piezas, v_min_distancia_orilla
    FROM materia_prima WHERE id = p_id_materia_prima;

    IF v_mp_ancho IS NULL THEN RETURN FALSE; END IF;

    -- Obtener la caja delimitadora (BOX) de la nueva geometría
    v_nueva_caja := p_nueva_geometria_polygon::BOX;

    -- 2. Validar Límites de la Materia Prima (MP) y Margen de Orilla
    v_limite_caja := BOX(
        POINT(v_min_distancia_orilla, v_min_distancia_orilla),
        POINT(v_mp_ancho - v_min_distancia_orilla, v_mp_alto - v_min_distancia_orilla)
    );

    -- Comprobación: La caja límite debe contener a la caja de la pieza (@> operador nativo)
    IF NOT (v_limite_caja @> v_nueva_caja) THEN
        RETURN FALSE;
    END IF;

    -- 3. Validar Solapamiento (Colisión)
    -- Operador '&&' chequea si dos cajas se solapan. Usaremos la distancia mínima para aumentar el tamaño de la caja (buffer).
    -- Esto es una APROXIMACIÓN simplificada sin PostGIS:
    SELECT COUNT(cp.id)
    INTO v_solapamiento_conteo
    FROM cortes_planificados cp
    WHERE cp.id_materia = p_id_materia_prima
      AND cp.geometria_final::BOX && v_nueva_caja; -- Chequeo simple de solapamiento de cajas.
      
    -- Si hay solapamiento, asumimos que también viola la distancia mínima en este modelo simple.
    IF v_solapamiento_conteo > 0 THEN
        RETURN FALSE;
    END IF;

    RETURN TRUE;

END;
$$ LANGUAGE plpgsql;
---------------------------------------------------------------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE sp_rotar_posicionar_figuras(
    p_id_geometria INT,          -- ID de la geometría específica (de tabla 'geometrias')
    p_id_materia_prima INT,      -- ID de la materia prima a usar
    p_angulo_rot NUMERIC,        -- Ángulo de rotación en grados (solo 0 o 90 soportado)
    p_pos_x NUMERIC,             -- Posición de traslación en X (esquina inferior izquierda)
    p_pos_y NUMERIC,             -- Posición de traslación en Y
    p_evento_json JSONB,         -- Datos JSONB para el registro de evento
    p_id_usuario INT DEFAULT NULL -- ID del usuario
)
AS $$
DECLARE
    v_geometria_base POLYGON;
    v_id_pieza_maestra INT;
    v_es_valido BOOLEAN;
    
    -- Variables para dimensionamiento obtenidas del BOX
    v_ancho_base NUMERIC;
    v_alto_base NUMERIC;
    
    v_geometria_final POLYGON;
    v_corte_id INT;
BEGIN
    -- 1. Obtener geometría base y ID de pieza maestra
    SELECT
        g.forma_geometrica,
        g.id_pieza
    INTO
        v_geometria_base,
        v_id_pieza_maestra
    FROM
        geometrias g
    WHERE
        g.id_geometria = p_id_geometria;

    IF v_geometria_base IS NULL THEN
        RAISE EXCEPTION 'Geometría con ID % no encontrada.', p_id_geometria;
    END IF;

    -- 2. CÁLCULO DE ANCHO Y ALTO CORREGIDO
    -- Usamos la conversión POLYGON::BOX y las funciones nativas width() y height()
    v_ancho_base := width(v_geometria_base::BOX);
    v_alto_base := height(v_geometria_base::BOX);

    -- Verificar que las dimensiones no sean nulas (aunque width/height deberían evitarlo)
    IF v_ancho_base IS NULL OR v_alto_base IS NULL THEN
        RAISE EXCEPTION 'No se pudo obtener las dimensiones de la geometría base (%).', p_id_geometria;
    END IF;

    -- 3. Calcular nueva geometría (Rotación y Traslación manual SIN PostGIS)
    -- Solo se permite rotación en múltiplos de 90 grados para rectángulos
    IF MOD(p_angulo_rot, 90) = 0 THEN
        IF MOD(p_angulo_rot / 90, 2) = 0 THEN
            -- Rotación 0, 180, 360: Ejes paralelos (Ancho sigue siendo Ancho, Alto sigue siendo Alto)
            v_geometria_final := format('((%s,%s), (%s,%s), (%s,%s), (%s,%s), (%s,%s))',
                p_pos_x, p_pos_y,
                p_pos_x + v_ancho_base, p_pos_y,
                p_pos_x + v_ancho_base, p_pos_y + v_alto_base,
                p_pos_x, p_pos_y + v_alto_base,
                p_pos_x, p_pos_y
            )::POLYGON;
        ELSE
            -- Rotación 90, 270: Ejes intercambiados (Ancho se vuelve Alto, Alto se vuelve Ancho)
            v_geometria_final := format('((%s,%s), (%s,%s), (%s,%s), (%s,%s), (%s,%s))',
                p_pos_x, p_pos_y,
                p_pos_x + v_alto_base, p_pos_y,
                p_pos_x + v_alto_base, p_pos_y + v_ancho_base,
                p_pos_x, p_pos_y + v_ancho_base,
                p_pos_x, p_pos_y
            )::POLYGON;
        END IF;
    ELSE
        RAISE EXCEPTION 'Rotaciones no ortogonales (no múltiplos de 90) no son soportadas sin PostGIS.';
    END IF;

    -- 4. Validar restricciones (Llama a fn_validar_colocacion_nativo)
    v_es_valido := fn_validar_colocacion_nativo(
        p_id_geometria,
        v_geometria_final,          
        p_id_materia_prima
    );

    IF NOT v_es_valido THEN
        RAISE NOTICE 'Advertencia: Colocación no válida detectada.';
    END IF;

-- 5. Insertar la tabla de cortes_planificados (SOLO SI ES VÁLIDO)
IF v_es_valido THEN
    
    -- Insertar un nuevo corte planificado
    INSERT INTO cortes_planificados (
        id_materia,
        id_pieza,
        geometria_final
    )
    VALUES (
        p_id_materia_prima,
        v_id_pieza_maestra,
        v_geometria_final
    )
    RETURNING id INTO v_corte_id; -- Usamos RETURNING para capturar el ID del corte

    -- NOTA: Como la tabla historial_utilizacion necesita el ID del corte, 
    -- usamos la variable v_corte_id en el paso 6.
    
END IF;
    

    -- 6. Registrar evento
    INSERT INTO evento (id_materiap, id_usuario, fecha_hora, tipo_evento, descripcion)
    VALUES (
        p_id_materia_prima,
        p_id_usuario,
        NOW(),
        'Ajuste Geométrico',
        p_evento_json || jsonb_build_object(
            'id_geometria_base', p_id_geometria,
            'validez', v_es_valido,
            'angulo_deg', p_angulo_rot,
            'pos_x', p_pos_x,
            'pos_y', p_pos_y
        )
    );
END;
$$ LANGUAGE plpgsql;

-- DESCRIPCION: Lógica de posicionamiento JSON y cálculo de uso

CREATE OR REPLACE PROCEDURE sp_rotar_posicionar_figuras(
    p_payload JSONB
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_id_evento INT;
    v_id_pieza INT;
    v_id_materia INT;
    v_pos_x NUMERIC;
    v_pos_y NUMERIC;
    v_rotacion NUMERIC;
BEGIN
    INSERT INTO eventos (tipo_evento, payload_json, procesado)
    VALUES ('POSICIONAMIENTO', p_payload, TRUE)
    RETURNING id_evento INTO v_id_evento;

    v_id_pieza   := (p_payload ->> 'id_pieza')::INT;
    v_id_materia := (p_payload ->> 'id_materia')::INT;
    v_pos_x      := (p_payload ->> 'x')::NUMERIC;
    v_pos_y      := (p_payload ->> 'y')::NUMERIC;
    v_rotacion   := COALESCE((p_payload ->> 'rotacion')::NUMERIC, 0);

    IF NOT EXISTS (SELECT 1 FROM piezas WHERE id_pieza = v_id_pieza) THEN
        RAISE EXCEPTION 'La pieza ID % no existe.', v_id_pieza;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM materia_prima WHERE id_materia = v_id_materia) THEN
        RAISE EXCEPTION 'La materia prima ID % no existe.', v_id_materia;
    END IF;

    INSERT INTO cortes_optimizados (
        id_materia, id_pieza, posicion_x, posicion_y, rotacion_grados, orden_colocacion
    ) VALUES (
        v_id_materia, v_id_pieza, v_pos_x, v_pos_y, v_rotacion, v_id_evento
    );
    
    RAISE NOTICE 'Pieza posicionada. Evento ID: %', v_id_evento;
END;
$$;

CREATE OR REPLACE FUNCTION fn_calcular_utilizacion(p_id_materia INT)
RETURNS NUMERIC AS $$
DECLARE
    v_area_total_materia NUMERIC;
    v_area_ocupada NUMERIC;
    v_porcentaje NUMERIC;
BEGIN
    SELECT area_total INTO v_area_total_materia
    FROM materia_prima WHERE id_materia = p_id_materia;

    SELECT COALESCE(SUM(p.area_base), 0) INTO v_area_ocupada
    FROM cortes_optimizados c
    JOIN piezas p ON c.id_pieza = p.id_pieza
    WHERE c.id_materia = p_id_materia;

    IF v_area_total_materia IS NULL OR v_area_total_materia = 0 THEN
        RETURN 0;
    END IF;

    v_porcentaje := (v_area_ocupada / v_area_total_materia) * 100;
    RETURN ROUND(v_porcentaje, 2);
END;
$$ LANGUAGE plpgsql;
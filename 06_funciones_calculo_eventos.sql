-- Calcula % de aprovechamiento de una lámina
CREATE OR REPLACE FUNCTION fn_calcular_utilizacion(
    p_materia_prima_id INT
)
RETURNS NUMERIC
LANGUAGE plpgsql
AS $$
DECLARE
    v_area_total   NUMERIC;
    v_area_ocupada NUMERIC;
    v_porcentaje   NUMERIC;
BEGIN
    SELECT area_total_mm2
    INTO v_area_total
    FROM materia_prima
    WHERE id = p_materia_prima_id;

    IF v_area_total IS NULL OR v_area_total = 0 THEN
        RETURN 0;
    END IF;

    SELECT COALESCE(SUM(g.area_mm2), 0)
    INTO v_area_ocupada
    FROM piezas p
    JOIN geometrias g ON g.pieza_id = p.id
    WHERE p.materia_prima_id = p_materia_prima_id;

    v_porcentaje := (v_area_ocupada / v_area_total) * 100;

    UPDATE materia_prima
    SET porcentaje_utilizacion = ROUND(v_porcentaje, 2)
    WHERE id = p_materia_prima_id;

    RETURN ROUND(v_porcentaje, 2);
END;
$$;

-- Función para parsear evento JSON y aplicar configuración/rotación
-- Estructura sugerida:
-- { "pieza_id": 1, "x": 100, "y": 50, "angulo": 45, "origen": "algoritmo_genetico", "config": {...} }
CREATE OR REPLACE FUNCTION fn_aplicar_configuracion_evento(
    p_evento JSONB
)
RETURNS VOID
LANGUAGE plpgsql
AS $$
DECLARE
    v_pieza_id  INT;
    v_x         NUMERIC;
    v_y         NUMERIC;
    v_angulo    NUMERIC;
    v_config    JSONB;
BEGIN
    v_pieza_id := (p_evento->>'pieza_id')::INT;
    v_x        := (p_evento->>'x')::NUMERIC;
    v_y        := (p_evento->>'y')::NUMERIC;
    v_angulo   := (p_evento->>'angulo')::NUMERIC;
    v_config   := COALESCE(p_evento->'config', '{}'::jsonb);

    -- Aplica la rotación/posición
    CALL sp_rotar_posicionar_figuras(
        v_pieza_id,
        v_angulo,
        v_x,
        v_y,
        p_evento
    );

    -- Guarda configuración si viene incluida
    IF v_config <> '{}'::jsonb THEN
        INSERT INTO configuraciones(nombre, parametros)
        VALUES (
            'evento_' || v_pieza_id || '_' || now()::text,
            v_config
        );
    END IF;
END;
$$;

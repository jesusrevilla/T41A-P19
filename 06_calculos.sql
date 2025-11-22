-- Calcula qué porcentaje de la materia prima está ocupado por piezas
CREATE OR REPLACE FUNCTION fn_calcular_utilizacion(p_materia_prima_id INT)
RETURNS NUMERIC
LANGUAGE plpgsql
AS $$
DECLARE
    v_area_total NUMERIC;
    v_area_ocupada NUMERIC;
    v_porcentaje NUMERIC;
BEGIN
    -- Obtener área total de la lámina
    SELECT area_total INTO v_area_total
    FROM materia_prima
    WHERE id = p_materia_prima_id;

    IF v_area_total IS NULL THEN 
        RETURN 0; 
    END IF;

    -- Calcular suma de áreas de las piezas asignadas a esa lámina
    SELECT COALESCE(SUM(g.area), 0)
    INTO v_area_ocupada
    FROM piezas p
    JOIN geometrias g ON p.id = g.pieza_id
    WHERE p.materia_prima_id = p_materia_prima_id;

    -- Calcular porcentaje
    IF v_area_total > 0 THEN
        v_porcentaje := (v_area_ocupada / v_area_total) * 100;
    ELSE
        v_porcentaje := 0;
    END IF;

    RETURN ROUND(v_porcentaje, 2);
END;
$$;

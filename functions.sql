CREATE OR REPLACE FUNCTION fn_calcular_area_manual(p_geometria POLYGON) 
RETURNS DECIMAL AS $$
DECLARE
    v_texto TEXT;
    v_puntos TEXT[];
    v_coord TEXT[];
    x1 DECIMAL; y1 DECIMAL;
    x2 DECIMAL; y2 DECIMAL;
    v_suma1 DECIMAL := 0;
    v_suma2 DECIMAL := 0;
    i INT;
    n INT;
BEGIN
    -- 1. Convertir polígono a texto limpio: '((0,0),(10,0))' -> '0,0|10,0'
    -- Quitamos paréntesis dobles y simples
    v_texto := replace(p_geometria::text, '((', '');
    v_texto := replace(v_texto, '))', '');
    v_texto := replace(v_texto, '),(', '|');
    
    -- 2. Separar en array de puntos
    v_puntos := string_to_array(v_texto, '|');
    n := array_length(v_puntos, 1);

    -- 3. Aplicar fórmula de Shoelace
    FOR i IN 1..n LOOP
        -- Extraer X e Y del punto actual
        v_coord := string_to_array(v_puntos[i], ',');
        x1 := CAST(v_coord[1] AS DECIMAL);
        y1 := CAST(v_coord[2] AS DECIMAL);

        -- Extraer X e Y del siguiente punto (o del primero si es el último)
        IF i < n THEN
            v_coord := string_to_array(v_puntos[i+1], ',');
        ELSE
            v_coord := string_to_array(v_puntos[1], ',');
        END IF;
        x2 := CAST(v_coord[1] AS DECIMAL);
        y2 := CAST(v_coord[2] AS DECIMAL);

        -- Sumas cruzadas
        v_suma1 := v_suma1 + (x1 * y2);
        v_suma2 := v_suma2 + (x2 * y1);
    END LOOP;

    -- 4. El área es la mitad de la diferencia absoluta
    RETURN ABS(v_suma1 - v_suma2) / 2.0;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION fn_calcular_utilizacion(p_id_materia INT) 
RETURNS DECIMAL(5,2) AS $$
DECLARE
    v_area_total_materia DECIMAL(15,2);
    v_area_ocupada DECIMAL(15,2);
    v_porcentaje DECIMAL(5,2);
BEGIN
    -- 1. Obtener el área total de la lámina (ya calculada en tu columna generada)
    SELECT area_total INTO v_area_total_materia
    FROM materia_prima
    WHERE id = p_id_materia;

    -- Validación: Si la materia prima no existe
    IF v_area_total_materia IS NULL THEN
        RAISE EXCEPTION 'La materia prima con ID % no existe', p_id_materia;
    END IF;

    -- 2. Sumar el área de todas las piezas colocadas (usando función nativa AREA de Postgres)
    -- COALESCE asegura que si no hay piezas, devuelva 0 en lugar de NULL
    SELECT COALESCE(SUM(fn_calcular_area_manual(geometria_final)), 0.0)
    INTO v_area_ocupada
    FROM cortes_planificados
    WHERE id_materia = p_id_materia;

    -- 3. Cálculo del porcentaje
    IF v_area_total_materia > 0 THEN
        v_porcentaje := (v_area_ocupada / v_area_total_materia) * 100;
    ELSE
        v_porcentaje := 0;
    END IF;

    -- 4. Retornar resultado
    RETURN v_porcentaje;
END;
$$ LANGUAGE plpgsql;

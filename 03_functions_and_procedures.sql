
-- FUNCIÓN: Calcular % de utilización de materia prima
CREATE OR REPLACE FUNCTION fn_calcular_utilizacion(materia_id INT)
RETURNS NUMERIC AS $$
DECLARE
    area_total NUMERIC;
    area_ocupada NUMERIC := 0;
    pieza RECORD;
BEGIN
    SELECT ancho * alto INTO area_total
    FROM materia_prima WHERE id = materia_id;

    FOR pieza IN
        SELECT p.*, g.datos
        FROM piezas p
        JOIN geometrias g ON g.pieza_id = p.id
    LOOP
        area_ocupada := area_ocupada +
            (pieza.ancho * pieza.alto);
    END LOOP;

    RETURN ROUND((area_ocupada / area_total) * 100, 2);
END;
$$ LANGUAGE plpgsql;


-- PROCEDIMIENTO: Rotar y posicionar figuras
CREATE OR REPLACE PROCEDURE sp_rotar_posicionar_figuras(
    p_pieza_id INT,
    p_angulo NUMERIC,
    p_posicion JSONB,
    p_evento JSONB
)
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE geometrias
    SET rotacion = p_angulo,
        posicion = p_posicion
    WHERE pieza_id = p_pieza_id;

    INSERT INTO eventos (pieza_id, evento)
    VALUES (p_pieza_id, p_evento);
END;
$$;

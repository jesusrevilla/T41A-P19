
CREATE OR REPLACE PROCEDURE sp_rotar_posicionar_figuras(
    p_pieza_id INT,
    p_angulo NUMERIC,
    p_posicion JSONB,
    p_evento JSONB
)
LANGUAGE plpgsql
AS $$
BEGIN
    -- Actualiza la geometría
    UPDATE geometrias
    SET rotacion = p_angulo,
        posicion = p_posicion
    WHERE pieza_id = p_pieza_id;

    -- Guarda el evento en el log
    INSERT INTO eventos (pieza_id, evento)
    VALUES (p_pieza_id, p_evento);

    RAISE NOTICE 'Figura % rotada a % grados y movida a %, evento registrado.',
                 p_pieza_id, p_angulo, p_posicion;
END;
$$;

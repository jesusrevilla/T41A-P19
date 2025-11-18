CREATE OR REPLACE PROCEDURE sp_rotar_posicionar_figuras(
    p_pieza_id INT,
    p_angulo NUMERIC,
    p_x NUMERIC,
    p_y NUMERIC,
    p_evento JSONB
)
LANGUAGE plpgsql AS $$
BEGIN
    UPDATE geometrias
    SET datos = jsonb_set(datos, '{rotacion}', to_jsonb(p_angulo)),
        datos = jsonb_set(datos, '{posicion}', jsonb_build_object('x', p_x, 'y', p_y))
    WHERE pieza_id = p_pieza_id;

    INSERT INTO eventos(pieza_id, evento)
    VALUES (p_pieza_id, p_evento);
END;
$$;

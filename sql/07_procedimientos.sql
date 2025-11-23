CREATE OR REPLACE PROCEDURE sp_rotar_posicionar_figuras(
    _id_pieza INT,
    _angulo NUMERIC,
    _x NUMERIC,
    _y NUMERIC,
    _evento JSON
)
AS $$
BEGIN
    UPDATE geometrias
    SET datos = jsonb_set(
        jsonb_set(
            jsonb_set(datos::jsonb,'{angulo}',to_jsonb(_angulo)),
        '{x}',to_jsonb(_x)),
    '{y}',to_jsonb(_y))
    WHERE id_pieza=_id_pieza;

    PERFORM fn_registrar_evento(_id_pieza,_evento);
END;
$$ LANGUAGE plpgsql;

--Función para parsear JSON
CREATE OR REPLACE FUNCTION fn_parse_evento(json_evento JSONB)
RETURNS TABLE (
    accion TEXT,
    angulo NUMERIC,
    pos_x NUMERIC,
    pos_y NUMERIC,
    motivo TEXT
)
AS $$
BEGIN
    RETURN QUERY
    SELECT
        json_evento->>'accion',
        (json_evento->>'angulo')::numeric,
        (json_evento->'posicion'->>'x')::numeric,
        (json_evento->'posicion'->>'y')::numeric,
        json_evento->>'motivo';
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION fn_aplicar_evento_json(p_evento JSONB)
RETURNS TABLE (
    angulo NUMERIC,
    pos_x NUMERIC,
    pos_y NUMERIC
)
LANGUAGE plpgsql
AS $$
BEGIN
    angulo := COALESCE(p_evento->>'rotacion', '0')::NUMERIC;
    pos_x  := COALESCE(p_evento->>'pos_x', '0')::NUMERIC;
    pos_y  := COALESCE(p_evento->>'pos_y', '0')::NUMERIC;

    RETURN NEXT;
END;
$$;

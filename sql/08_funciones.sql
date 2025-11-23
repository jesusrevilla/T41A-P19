CREATE OR REPLACE FUNCTION fn_calcular_utilizacion(_id_mp INT)
RETURNS NUMERIC AS $$
DECLARE
    area_mp NUMERIC;
    area_total_piezas NUMERIC;
BEGIN
    SELECT ancho * alto INTO area_mp FROM materia_prima WHERE id=_id_mp;

    SELECT COALESCE(SUM(area),0)
    INTO area_total_piezas
    FROM piezas;

    RETURN area_total_piezas / area_mp;
END;
$$ LANGUAGE plpgsql;

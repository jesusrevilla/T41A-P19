CREATE OR REPLACE PROCEDURE sp_alta_materia_prima(
    _numero_parte TEXT,
    _ancho NUMERIC,
    _alto NUMERIC
)
AS $$
BEGIN
    INSERT INTO materia_prima(numero_parte, ancho, alto)
    VALUES (_numero_parte,_ancho,_alto);
END;
$$ LANGUAGE plpgsql;

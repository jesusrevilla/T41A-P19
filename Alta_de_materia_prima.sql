CREATE OR REPLACE PROCEDURE sp_alta_materia_prima(
    p_numero_parte TEXT,
    p_ancho NUMERIC,
    p_alto NUMERIC,
    p_distancia_entre NUMERIC,
    p_distancia_borde NUMERIC
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO materia_prima (
        numero_parte, ancho, alto,
        distancia_entre_piezas, distancia_borde
    )
    VALUES (
        p_numero_parte, p_ancho, p_alto,
        p_distancia_entre, p_distancia_borde
    );

    RAISE NOTICE 'Materia prima % registrada correctamente', p_numero_parte;
END $$;

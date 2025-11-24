CREATE OR REPLACE PROCEDURE sp_alta_producto(
    p_numero_parte TEXT,
    p_descripcion TEXT,
    p_cantidad_piezas INT
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO productos (numero_parte, descripcion, cantidad_piezas)
    VALUES (p_numero_parte, p_descripcion, p_cantidad_piezas);

    RAISE NOTICE 'Producto % registrado correctamente', p_numero_parte;
END $$;

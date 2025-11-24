CREATE OR REPLACE PROCEDURE sp_alta_pieza(
    p_producto_id INT,
    p_nombre TEXT
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO piezas(producto_id, nombre)
    VALUES(p_producto_id, p_nombre);

    RAISE NOTICE 'Pieza % registrada para producto %', p_nombre, p_producto_id;
END $$;

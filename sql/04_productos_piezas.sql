CREATE OR REPLACE PROCEDURE sp_alta_producto(
    _numero_parte TEXT,
    _descripcion TEXT,
    _cantidad INT
)
AS $$
BEGIN
    INSERT INTO productos(numero_parte, descripcion, cantidad_elementos)
    VALUES (_numero_parte,_descripcion,_cantidad);
END;
$$ LANGUAGE plpgsql;

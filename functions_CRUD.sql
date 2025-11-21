CREATE OR REPLACE FUNCTION alta_usuario(
    p_nombre TEXT,
    p_rol INTEGER
)
RETURNS INTEGER AS $$
DECLARE
    nuevo_id INTEGER;
BEGIN
    IF NOT EXISTS (SELECT * FROM rol WHERE id = p_rol) THEN
        RAISE EXCEPTION 'El rol % no existe', p_rol;
    END IF;

    INSERT INTO usuario(nombre, rol)
    VALUES (p_nombre, p_rol)
    RETURNING id INTO nuevo_id;

    RETURN nuevo_id;
END;
$$ LANGUAGE plpgsql;

SELECT alta_usuario('Uriel', 2);
SELECT alta_usuario('Coral', 1);
SELECT alta_usuario('Fernanda', 2);
SELECT alta_usuario('Bryan', 1);
SELECT alta_usuario('Yael', 1);

SELECT * FROM usuario;

CREATE OR REPLACE FUNCTION baja_usuario(
    usuario_id INTEGER
)
RETURNS BOOLEAN AS $$

BEGIN
    IF NOT EXISTS (SELECT * FROM usuario WHERE id = usuario_id) THEN
        RAISE EXCEPTION 'El usuario con id de % no existe', usuario_id;
    END IF;
    
    DELETE FROM usuario WHERE id = usuario_id;
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

SELECT baja_usuario(3);
SELECT * FROM usuario;

CREATE OR REPLACE FUNCTION modificar_usuario(
    usuario_id INTEGER,
    nombre_nuevo TEXT,
    rol_nuevo INTEGER
)
RETURNS BOOLEAN AS $$

BEGIN
    IF NOT EXISTS (SELECT * FROM usuario WHERE id = usuario_id) THEN
        RAISE EXCEPTION 'El usuario con id de % no existe', usuario_id;
    END IF;
    
    UPDATE usuario
  SET nombre = nombre_nuevo, rol = rol_nuevo
  WHERE id=usuario_id;
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

SELECT modificar_usuario(5,'Andre',1);
SELECT * FROM usuario ORDER BY id;


CREATE OR REPLACE FUNCTION consulta_usuario(
    usuario_id INTEGER
)
RETURNS TABLE(nombre TEXT, rol_nombre TEXT)AS $$
BEGIN
    IF NOT EXISTS (SELECT * FROM usuario WHERE id = usuario_id) THEN
        RAISE EXCEPTION 'El usuario con id de % no existe', usuario_id;
    END IF;
    
    RETURN QUERY SELECT u.nombre, r.rol_nombre FROM usuario AS u 
    JOIN rol AS r ON r.id = u.rol
    WHERE usuario_id = u.id ;
END;
$$ LANGUAGE plpgsql;

SELECT consulta_usuario(4);

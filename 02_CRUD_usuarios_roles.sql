--2.4 Crear roles CRUD
CREATE OR REPLACE FUNCTION fn_crear_rol(p_nombre VARCHAR)
RETURNS INTEGER AS $$
DECLARE v_id INT;
BEGIN
    INSERT INTO roles(nombre) VALUES (p_nombre)
    RETURNING rol_id INTO v_id;
    RETURN v_id;
END;
$$ LANGUAGE plpgsql;


--2.5 actualizar/modificar roles CRUD
CREATE OR REPLACE FUNCTION fn_actualizar_rol(p_id INT, p_nombre VARCHAR)
RETURNS VOID AS $$
BEGIN
    UPDATE roles SET nombre = p_nombre WHERE rol_id = p_id;
END;
$$ LANGUAGE plpgsql;


--2.6 eliminar roles CRUD
CREATE OR REPLACE FUNCTION fn_eliminar_rol(p_id INT)
RETURNS VOID AS $$
BEGIN
    DELETE FROM roles WHERE rol_id = p_id;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION fn_consultar_roles()
RETURNS TABLE(rol_id INT, nombre VARCHAR) AS $$
BEGIN
    RETURN QUERY SELECT rol_id, nombre FROM roles;
END;
$$ LANGUAGE plpgsql;


--2.7 Crear usuarios CRUD
CREATE OR REPLACE FUNCTION fn_crear_usuario(
    p_username VARCHAR,
    p_password TEXT,
    p_rol_id INT
)
RETURNS INTEGER AS $$
DECLARE v_id INT;
BEGIN
    INSERT INTO usuarios(username, password_hash, rol_id)
    VALUES (p_username, crypt(p_password, gen_salt('bf')), p_rol_id)
    RETURNING usuario_id INTO v_id;

    RETURN v_id;
END;
$$ LANGUAGE plpgsql;

--2.8 actualizar/modificar usuarios CRUD
CREATE OR REPLACE FUNCTION fn_actualizar_usuario(
    p_id INT,
    p_username VARCHAR,
    p_rol_id INT
)
RETURNS VOID AS $$
BEGIN
    UPDATE usuarios
       SET username = p_username,
           rol_id = p_rol_id
     WHERE usuario_id = p_id;
END;
$$ LANGUAGE plpgsql;



--2.8 eliminar usuarios CRUD
CREATE OR REPLACE FUNCTION fn_eliminar_usuario(p_id INT)
RETURNS VOID AS $$
BEGIN
    DELETE FROM usuarios WHERE usuario_id = p_id;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION fn_obtener_usuarios()
RETURNS TABLE(
    usuario_id INT,
    username VARCHAR,
    rol VARCHAR
) AS $$
BEGIN
    RETURN QUERY
    SELECT u.usuario_id, u.username, r.nombre
    FROM usuarios u
    JOIN roles r ON u.rol_id = r.rol_id;
END;
$$ LANGUAGE plpgsql;

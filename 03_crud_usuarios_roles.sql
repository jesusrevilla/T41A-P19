-- Alta de usuario
CREATE OR REPLACE PROCEDURE sp_usuario_crear(
    p_nombre        VARCHAR,
    p_username      VARCHAR,
    p_email         VARCHAR,
    p_nombre_rol    VARCHAR
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_rol_id INT;
BEGIN
    SELECT id INTO v_rol_id FROM roles WHERE nombre_rol = p_nombre_rol;

    IF v_rol_id IS NULL THEN
        RAISE EXCEPTION 'El rol % no existe', p_nombre_rol;
    END IF;

    INSERT INTO usuarios (nombre, username, email, rol_id)
    VALUES (p_nombre, p_username, p_email, v_rol_id);
END;
$$;

-- Lectura de usuario por username
CREATE OR REPLACE FUNCTION fn_usuario_obtener(p_username VARCHAR)
RETURNS TABLE(
    nombre      VARCHAR,
    username    VARCHAR,
    email       VARCHAR,
    rol         VARCHAR,
    activo      BOOLEAN
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT u.nombre, u.username, u.email, r.nombre_rol, u.activo
    FROM usuarios u
    JOIN roles r ON r.id = u.rol_id
    WHERE u.username = p_username;
END;
$$;

-- Actualización de usuario (nombre y rol)
CREATE OR REPLACE PROCEDURE sp_usuario_actualizar(
    p_username      VARCHAR,
    p_nuevo_nombre  VARCHAR,
    p_nuevo_rol     VARCHAR
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_rol_id INT;
BEGIN
    SELECT id INTO v_rol_id FROM roles WHERE nombre_rol = p_nuevo_rol;
    IF v_rol_id IS NULL THEN
        RAISE EXCEPTION 'El rol % no existe', p_nuevo_rol;
    END IF;

    UPDATE usuarios
    SET nombre = p_nuevo_nombre,
        rol_id = v_rol_id
    WHERE username = p_username;
END;
$$;

-- Baja lógica de usuario
CREATE OR REPLACE PROCEDURE sp_usuario_baja(
    p_username VARCHAR
)
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE usuarios
    SET activo = FALSE
    WHERE username = p_username;
END;
$$;

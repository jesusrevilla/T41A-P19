-- DESCRIPCION: CRUD de Usuarios y Roles

CREATE OR REPLACE FUNCTION fn_listar_roles()
RETURNS TABLE(id INT, nombre VARCHAR, descripcion TEXT) AS $$
BEGIN
    RETURN QUERY SELECT id_rol, nombre_rol, roles.descripcion FROM roles;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION sp_crear_usuario(
    p_nombre VARCHAR,
    p_email VARCHAR,
    p_password VARCHAR,
    p_nombre_rol VARCHAR
) RETURNS INTEGER AS $$
DECLARE
    v_id_rol INT;
    v_id_nuevo_usuario INT;
BEGIN
    SELECT id_rol INTO v_id_rol FROM roles WHERE nombre_rol = p_nombre_rol;
    
    IF v_id_rol IS NULL THEN
        RAISE EXCEPTION 'El rol "%" no existe.', p_nombre_rol;
    END IF;

    INSERT INTO usuarios (nombre_completo, email, password_hash, id_rol)
    VALUES (p_nombre, p_email, MD5(p_password), v_id_rol)
    RETURNING id_usuario INTO v_id_nuevo_usuario;

    RETURN v_id_nuevo_usuario;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION fn_obtener_usuario(p_identificador VARCHAR)
RETURNS TABLE(id INT, nombre VARCHAR, email VARCHAR, rol VARCHAR, activo BOOLEAN) AS $$
BEGIN
    RETURN QUERY 
    SELECT u.id_usuario, u.nombre_completo, u.email, r.nombre_rol, u.activo
    FROM usuarios u JOIN roles r ON u.id_rol = r.id_rol
    WHERE (u.email = p_identificador OR u.id_usuario::TEXT = p_identificador);
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION sp_actualizar_usuario(
    p_id_usuario INT,
    p_nuevo_nombre VARCHAR DEFAULT NULL,
    p_nuevo_rol VARCHAR DEFAULT NULL
) RETURNS VOID AS $$
DECLARE
    v_id_rol_nuevo INT;
BEGIN
    IF p_nuevo_nombre IS NOT NULL THEN
        UPDATE usuarios SET nombre_completo = p_nuevo_nombre WHERE id_usuario = p_id_usuario;
    END IF;

    IF p_nuevo_rol IS NOT NULL THEN
        SELECT id_rol INTO v_id_rol_nuevo FROM roles WHERE nombre_rol = p_nuevo_rol;
        IF v_id_rol_nuevo IS NOT NULL THEN
            UPDATE usuarios SET id_rol = v_id_rol_nuevo WHERE id_usuario = p_id_usuario;
        END IF;
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION sp_eliminar_usuario(p_id_usuario INT) 
RETURNS BOOLEAN AS $$
BEGIN
    UPDATE usuarios SET activo = FALSE WHERE id_usuario = p_id_usuario;
    RETURN FOUND;
END;
$$ LANGUAGE plpgsql;
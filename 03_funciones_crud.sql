-- Crear usuario
CREATE OR REPLACE PROCEDURE sp_crear_usuario(
    p_nombre VARCHAR, 
    p_email VARCHAR, 
    p_rol_nombre VARCHAR
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_rol_id INT;
BEGIN
    SELECT id INTO v_rol_id FROM roles WHERE nombre_rol = p_rol_nombre;
    
    IF v_rol_id IS NULL THEN
        RAISE EXCEPTION 'El rol % no existe', p_rol_nombre;
    END IF;

    INSERT INTO usuarios (nombre, email, rol_id) VALUES (p_nombre, p_email, v_rol_id);
END;
$$;

-- Consultar usuario 
CREATE OR REPLACE FUNCTION fn_obtener_usuario(p_email VARCHAR)
RETURNS TABLE(nombre VARCHAR, rol VARCHAR, activo BOOLEAN)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY 
    SELECT u.nombre, r.nombre_rol, u.activo
    FROM usuarios u
    JOIN roles r ON u.rol_id = r.id
    WHERE u.email = p_email;
END;
$$;

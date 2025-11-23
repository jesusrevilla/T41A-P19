-- 03_crud_usuarios_roles.sql
-- CRUD para usuarios y roles (lógica de negocio)

SET search_path TO corte, public;

-- ===== ROLES =====
CREATE OR REPLACE FUNCTION fn_crear_rol(p_nombre TEXT, p_descripcion TEXT)
RETURNS INT LANGUAGE plpgsql AS $$
DECLARE v_id INT;
BEGIN
  INSERT INTO roles(nombre, descripcion) VALUES (p_nombre, p_descripcion)
  ON CONFLICT (nombre) DO UPDATE SET descripcion = EXCLUDED.descripcion
  RETURNING id INTO v_id;
  RETURN v_id;
END $$;

CREATE OR REPLACE FUNCTION fn_actualizar_rol(p_id INT, p_nombre TEXT, p_descripcion TEXT)
RETURNS VOID LANGUAGE plpgsql AS $$
BEGIN
  UPDATE roles SET nombre = p_nombre, descripcion = p_descripcion WHERE id = p_id;
END $$;

CREATE OR REPLACE FUNCTION fn_eliminar_rol(p_id INT)
RETURNS VOID LANGUAGE plpgsql AS $$
BEGIN
  DELETE FROM roles WHERE id = p_id;
END $$;

CREATE OR REPLACE FUNCTION fn_listar_roles()
RETURNS TABLE(id INT, nombre TEXT, descripcion TEXT) LANGUAGE sql AS $$
  SELECT id, nombre, descripcion FROM roles ORDER BY id;
$$;

-- ===== USUARIOS =====
CREATE OR REPLACE FUNCTION fn_crear_usuario(p_username TEXT, p_email TEXT, p_password TEXT, p_rol_nombre TEXT)
RETURNS INT LANGUAGE plpgsql AS $$
DECLARE v_id INT;
DECLARE v_rol_id INT;
BEGIN
  SELECT id INTO v_rol_id FROM roles WHERE nombre = p_rol_nombre;
  IF v_rol_id IS NULL THEN
    RAISE EXCEPTION 'Rol % no existe', p_rol_nombre;
  END IF;

  INSERT INTO usuarios(username, email, password_hash, rol_id)
  VALUES (p_username, p_email, crypt(p_password, gen_salt('bf')), v_rol_id)
  RETURNING id INTO v_id;

  RETURN v_id;
END $$;

CREATE OR REPLACE FUNCTION fn_actualizar_usuario(p_id INT, p_email TEXT, p_password TEXT, p_rol_nombre TEXT, p_activo BOOLEAN)
RETURNS VOID LANGUAGE plpgsql AS $$
DECLARE v_rol_id INT;
BEGIN
  SELECT id INTO v_rol_id FROM roles WHERE nombre = p_rol_nombre;
  IF v_rol_id IS NULL THEN
    RAISE EXCEPTION 'Rol % no existe', p_rol_nombre;
  END IF;

  UPDATE usuarios
     SET email = COALESCE(p_email, email),
         password_hash = CASE WHEN p_password IS NULL THEN password_hash ELSE crypt(p_password, gen_salt('bf')) END,
         rol_id = v_rol_id,
         activo = COALESCE(p_activo, activo)
   WHERE id = p_id;
END $$;

CREATE OR REPLACE FUNCTION fn_eliminar_usuario(p_id INT)
RETURNS VOID LANGUAGE plpgsql AS $$
BEGIN
  DELETE FROM usuarios WHERE id = p_id;
END $$;

CREATE OR REPLACE FUNCTION fn_listar_usuarios()
RETURNS TABLE(id INT, username TEXT, email TEXT, rol TEXT, activo BOOLEAN, creado_en TIMESTAMP) LANGUAGE sql AS $$
  SELECT u.id, u.username, u.email, r.nombre AS rol, u.activo, u.creado_en
    FROM usuarios u
    JOIN roles r ON r.id = u.rol_id
   ORDER BY u.id;
$$;

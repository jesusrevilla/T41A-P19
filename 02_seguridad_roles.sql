-- roles base
INSERT INTO roles (nombre_rol) VALUES ('admin'), ('operador');

-- Crear usuarios de base de datos
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'rol_admin_db') THEN
        CREATE ROLE rol_admin_db;
    END IF;
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'rol_operador_db') THEN
        CREATE ROLE rol_operador_db;
    END IF;
END
$$;

-- Asignar permisos (Seguridad)
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO rol_admin_db;
GRANT SELECT, INSERT, UPDATE ON piezas, eventos TO rol_operador_db;

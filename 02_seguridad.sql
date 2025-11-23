-- Roles lógicos
INSERT INTO roles (nombre_rol) VALUES ('Administrador'), ('Operador')
ON CONFLICT (nombre_rol) DO NOTHING;

-- Roles de BD (si no existen)
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'rol_admin_app') THEN
        CREATE ROLE rol_admin_app LOGIN PASSWORD 'adminpass';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'rol_operador_app') THEN
        CREATE ROLE rol_operador_app LOGIN PASSWORD 'operpass';
    END IF;
END;
$$;

-- Privilegios por rol
GRANT CONNECT ON DATABASE test_db TO rol_admin_app, rol_operador_app;

GRANT USAGE ON SCHEMA public TO rol_admin_app, rol_operador_app;

-- Admin puede todo
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO rol_admin_app;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO rol_admin_app;

-- Operador: acceso restringido
GRANT SELECT, INSERT, UPDATE ON
    piezas,
    geometrias,
    eventos
TO rol_operador_app;

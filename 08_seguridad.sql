-- 08_seguridad.sql
-- Roles en PostgreSQL y privilegios según rol

-- IMPORTANTE: Estos roles son de base de datos (distintos a la tabla "roles" de negocio)
-- Ajusta según tu entorno (puedes asignar usuarios a estos roles)

SET search_path TO corte, public;

-- Crear roles de base de datos
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'corte_admin') THEN
    CREATE ROLE corte_admin NOINHERIT;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'corte_operador') THEN
    CREATE ROLE corte_operador NOINHERIT;
  END IF;
END $$;

-- Revocar por seguridad
REVOKE ALL ON SCHEMA corte FROM PUBLIC;
GRANT USAGE ON SCHEMA corte TO corte_admin, corte_operador;

-- Permisos para admin
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA corte TO corte_admin;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA corte TO corte_admin;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA corte TO corte_admin;

-- Permisos para operador: lectura + insertar/actualizar en piezas, geometrias y eventos
GRANT SELECT ON ALL TABLES IN SCHEMA corte TO corte_operador;
GRANT INSERT, UPDATE ON TABLE corte.piezas, corte.geometrias, corte.eventos TO corte_operador;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA corte TO corte_operador;

-- Default privileges para futuros objetos
ALTER DEFAULT PRIVILEGES IN SCHEMA corte GRANT SELECT ON TABLES TO corte_operador;
ALTER DEFAULT PRIVILEGES IN SCHEMA corte GRANT INSERT, UPDATE ON TABLES TO corte_operador;
ALTER DEFAULT PRIVILEGES IN SCHEMA corte GRANT EXECUTE ON FUNCTIONS TO corte_operador;

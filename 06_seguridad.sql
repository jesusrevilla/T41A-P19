-- DESCRIPCION: Configuración de permisos (DCL)

-- Crear roles si no existen (bloque idempotente simple)
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'db_admin') THEN
        CREATE ROLE db_admin WITH NOLOGIN;
    END IF;
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'db_operador') THEN
        CREATE ROLE db_operador WITH NOLOGIN;
    END IF;
END
$$;

-- Permisos Admin
GRANT ALL PRIVILEGES ON DATABASE postgres TO db_admin;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO db_admin;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO db_admin;
GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA public TO db_admin;

-- Permisos Operador
GRANT CONNECT ON DATABASE postgres TO db_operador;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO db_operador;
GRANT INSERT ON TABLE eventos, cortes_optimizados TO db_operador;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO db_operador;
GRANT EXECUTE ON PROCEDURE sp_rotar_posicionar_figuras TO db_operador;
GRANT EXECUTE ON FUNCTION fn_calcular_utilizacion TO db_operador;
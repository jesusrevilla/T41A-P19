-- Crea roles de ejemplo
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'admin') THEN
    CREATE ROLE admin LOGIN PASSWORD 'admin' NOINHERIT;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'operador') THEN
    CREATE ROLE operador LOGIN PASSWORD 'operador' NOINHERIT;
  END IF;
END;
$$;

INSERT INTO roles (nombre) VALUES ('Administrador') ON CONFLICT DO NOTHING;
INSERT INTO roles (nombre) VALUES ('Operador') ON CONFLICT DO NOTHING;

INSERT INTO usuarios (username, password_hash, role_id)
SELECT 'admin', 'hash-demo', r.id FROM roles r WHERE r.nombre = 'Administrador'
ON CONFLICT DO NOTHING;

CALL sp_alta_materia_prima('MP-1000', 2000, 1000, 5, 10, 5);

CALL sp_alta_producto('P-100', 'Producto demo', 
  '[
    {"cantidad":2, "geometria": {"componentes":[{"area":200},{"area":50}], "bbox": {"xmin":0,"ymin":0,"xmax":50,"ymax":50}}},
    {"cantidad":1, "geometria": {"componentes":[{"area":300}], "bbox": {"xmin":100,"ymin":100,"xmax":160,"ymax":160}}}
  ]'::jsonb
);

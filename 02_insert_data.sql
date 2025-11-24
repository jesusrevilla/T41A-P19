-- 02_insertar_datos.sql
-- Semillas mínimas y dataset ejemplo seguro (no depende de funciones/trigger)

SET search_path TO corte, public;

-- Roles lógicos de negocio
INSERT INTO roles (nombre, descripcion)
VALUES ('Administrador','Acceso total'), ('Operador','Operaciones de corte')
ON CONFLICT (nombre) DO NOTHING;

-- Usuario admin (password: admin123) - para demo
INSERT INTO usuarios (username, email, password_hash, rol_id)
SELECT 'admin', 'admin@example.com', crypt('admin123', gen_salt('bf')), r.id
FROM roles r WHERE r.nombre = 'Administrador'
ON CONFLICT (username) DO NOTHING;

-- Materia prima ejemplo (lámina)
-- 800 x 400 mm, borde 20 mm, separación mínima 10 mm
INSERT INTO materia_prima (numero_parte, descripcion, ancho, alto, unidad, distancia_minima_entre_piezas, distancia_minima_a_orilla)
VALUES ('MP-800x400', 'Lámina estándar 800x400 mm', 800, 400, 'mm', 10, 20)
ON CONFLICT (numero_parte) DO NOTHING;

-- Producto ejemplo: Rectángulo 200x100 mm
INSERT INTO productos (numero_parte, descripcion, cantidad_elementos_por_pieza)
VALUES ('PR-RECT-200x100', 'Pieza rectangular 200x100 mm', 1)
ON CONFLICT (numero_parte) DO NOTHING;

-- Dos piezas de ese producto, asignadas a la misma lámina
WITH prod AS (
  SELECT id FROM productos WHERE numero_parte = 'PR-RECT-200x100'
), mp AS (
  SELECT id FROM materia_prima WHERE numero_parte = 'MP-800x400'
)
INSERT INTO piezas (producto_id, materia_prima_id, etiqueta, estado)
SELECT prod.id, mp.id, 'PZ-001', 'nuevo' FROM prod, mp
UNION ALL
SELECT prod.id, mp.id, 'PZ-002', 'nuevo' FROM prod, mp
ON CONFLICT DO NOTHING;

-- Geometría para cada pieza: un rectángulo como polígono (0,0)-(200,0)-(200,100)-(0,100)
-- NOTA: Inicialmente en origen; luego será rotado/posicionado por procedimiento/evento.
WITH p AS (
  SELECT id, etiqueta FROM piezas WHERE etiqueta IN ('PZ-001','PZ-002')
)
INSERT INTO geometrias (pieza_id, tipo, params, factor_area, orden)
SELECT p.id, 'poligono',
       jsonb_build_object(
         'vertices', jsonb_build_array(
            jsonb_build_object('x',0,'y',0),
            jsonb_build_object('x',200,'y',0),
            jsonb_build_object('x',200,'y',100),
            jsonb_build_object('x',0,'y',100)
         )
       ),
       1, 1
FROM p
ON CONFLICT DO NOTHING;

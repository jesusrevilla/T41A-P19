
-- ROLES
INSERT INTO roles (nombre) VALUES 
('Administrador'),
('Operador');

-- USUARIOS
INSERT INTO usuarios (nombre, email, password, rol_id) VALUES
('Admin Principal', 'admin@sistema.com', 'admin123', 1),
('Operador 1', 'operador@sistema.com', 'operador123', 2);

-- MATERIA PRIMA
INSERT INTO materia_prima (numero_parte, ancho, alto, distancia_minima_piezas, distancia_minima_borde)
VALUES ('MP-001', 200, 300, 2, 1);

-- PRODUCTOS
INSERT INTO productos (numero_parte, descripcion, cantidad_elementos)
VALUES ('P-100', 'Producto de prueba', 2);

-- PIEZAS
INSERT INTO piezas (producto_id, nombre, ancho, alto)
VALUES (1, 'Pieza A', 20, 30),
       (1, 'Pieza B', 15, 25);

-- GEOMETRÍAS
INSERT INTO geometrias (pieza_id, tipo, datos)
VALUES 
(1, 'rectangulo', '{"x":0, "y":0, "ancho":20, "alto":30}'),
(2, 'rectangulo', '{"x":0, "y":0, "ancho":15, "alto":25}');

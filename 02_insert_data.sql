INSERT INTO roles (nombre) VALUES ('admin'), ('operador');

INSERT INTO usuarios (nombre, username, rol_id)
VALUES ('Administrador', 'admin', 1),
       ('Operador 1', 'op1', 2);

INSERT INTO materia_prima (numero_parte, ancho, alto, distancia_entre_piezas, distancia_borde)
VALUES ('MP-100', 100, 200, 2, 1);

INSERT INTO productos (numero_parte, descripcion, cantidad_piezas)
VALUES ('P-500', 'Panel metálico', 3);

INSERT INTO piezas (producto_id, nombre)
VALUES (1, 'Pieza A'), (1, 'Pieza B');

INSERT INTO geometrias (pieza_id, tipo, datos)
VALUES 
(1, 'recta', '{"x1":0,"y1":0,"x2":10,"y2":0}'),
(1, 'figura', '{"lados":4,"area":50}');

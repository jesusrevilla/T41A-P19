
-------------------------------
-- 1. PRUEBA fn_calcular_utilizacion
-------------------------------
SELECT fn_calcular_utilizacion(1) AS porcentaje_aprovechamiento;


-------------------------------
-- 2. PRUEBA sp_rotar_posicionar_figuras
-------------------------------
CALL sp_rotar_posicionar_figuras(
    1,
    45,
    '{"x": 10, "y": 20}',
    '{"accion":"rotar","angulo":45}'
);

SELECT * FROM geometrias WHERE pieza_id = 1;
SELECT * FROM eventos ORDER BY id DESC LIMIT 1;


-------------------------------
-- 3. PRUEBA Trigger de distancias
-------------------------------
INSERT INTO piezas (producto_id, nombre, ancho, alto)
VALUES (1, 'Test Distancia', 0.5, 10);  -- Debe fallar

-------------------------------
-- 4. PRUEBA Trigger de actualización automática
-------------------------------
INSERT INTO eventos (pieza_id, evento)
VALUES (1, '{"test":"evento"}');

SELECT * FROM utilizacion ORDER BY fecha DESC LIMIT 1;

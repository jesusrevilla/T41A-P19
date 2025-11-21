-- DESCRIPCION: Datos iniciales de prueba

-- 1. Usuarios
SELECT sp_crear_usuario('Admin Principal', 'admin@sys.com', 'admin123', 'Administrador');
SELECT sp_crear_usuario('Juan Operador', 'juan@sys.com', 'juan123', 'Operador');

-- 2. Materia Prima (Hoja 244x122)
SELECT sp_alta_materia_prima('MP-Madera-std', 244.00, 122.00, 1.0, 2.0, 100);

-- 3. Producto (Mesa)
SELECT sp_alta_producto('PROD-001', 'Mesa de Centro');

-- 4. Pieza (Tablero 100x50)
SELECT sp_agregar_pieza(1, 'Tablero Principal', 1, 5000);

-- 5. Geometría de la pieza (Rectángulo)
SELECT sp_agregar_geometria(1, 1, 'LINEA', '{"x1": 0, "y1": 0, "x2": 100, "y2": 0}'::jsonb);
SELECT sp_agregar_geometria(1, 2, 'LINEA', '{"x1": 100, "y1": 0, "x2": 100, "y2": 50}'::jsonb);
SELECT sp_agregar_geometria(1, 3, 'LINEA', '{"x1": 100, "y1": 50, "x2": 0, "y2": 50}'::jsonb);
SELECT sp_agregar_geometria(1, 4, 'LINEA', '{"x1": 0, "y1": 50, "x2": 0, "y2": 0}'::jsonb);
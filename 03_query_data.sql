--Cálculo de utilización de materia prima.
CREATE OR REPLACE FUNCTION fn_calcular_utilizacion(p_hoja_corte_id INT)
RETURNS NUMERIC
LANGUAGE plpgsql
AS $$
DECLARE
    v_area_total NUMERIC := 0;
    v_area_ocupada NUMERIC := 0;
    v_porcentaje NUMERIC := 0;
BEGIN
    SELECT 
        (mp.dimensiones->>'largo')::NUMERIC * (mp.dimensiones->>'ancho')::NUMERIC
    INTO v_area_total
    FROM hojas_corte hc
    JOIN materia_prima mp ON hc.mp_numero_parte = mp.numero_parte
    WHERE hc.id = p_hoja_corte_id;

    IF v_area_total IS NULL OR v_area_total = 0 THEN
        RAISE NOTICE 'No se pudo calcular el área total para la hoja %', p_hoja_corte_id;
        RETURN 0;
    END IF;

    -- 2. Calcular el Área Ocupada
    SELECT COALESCE(SUM(
        (geometria_final->>'ancho_original')::NUMERIC * (geometria_final->>'alto_original')::NUMERIC
    ), 0)
    INTO v_area_ocupada
    FROM piezas_colocadas
    WHERE hoja_corte_id = p_hoja_corte_id;

    -- 3. Calcular el Porcentaje
    v_porcentaje := (v_area_ocupada / v_area_total) * 100.0;

    -- 4. Actualizar la tabla hojas_corte con los nuevos valores
    UPDATE hojas_corte
    SET 
        area_total_mm2 = v_area_total,
        area_ocupada_mm2 = v_area_ocupada,
        porcentaje_utilizacion = ROUND(v_porcentaje, 2) 
    WHERE id = p_hoja_corte_id;

    -- 5. Retornar el valor calculado
    RETURN ROUND(v_porcentaje, 2);
END;
$$;

-- Trigger: calcular área total de la hoja al crearla
CREATE OR REPLACE FUNCTION fn_set_area_total()
RETURNS TRIGGER AS $$
DECLARE
    v_largo NUMERIC;
    v_ancho NUMERIC;
BEGIN
    SELECT (dimensiones->>'largo')::NUMERIC, (dimensiones->>'ancho')::NUMERIC
    INTO v_largo, v_ancho
    FROM materia_prima
    WHERE numero_parte = NEW.mp_numero_parte;

    NEW.area_total_mm2 := v_largo * v_ancho;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_set_area_total
BEFORE INSERT ON hojas_corte
FOR EACH ROW
EXECUTE FUNCTION fn_set_area_total();

-- Trigger: recalcular utilización al insertar/actualizar piezas colocadas
CREATE OR REPLACE FUNCTION fn_trigger_utilizacion()
RETURNS TRIGGER AS $$
BEGIN
    PERFORM fn_calcular_utilizacion(NEW.hoja_corte_id);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_utilizacion_update
AFTER INSERT OR UPDATE ON piezas_colocadas
FOR EACH ROW
EXECUTE FUNCTION fn_trigger_utilizacion();


--Gestión
-- Modificar materia prima
CREATE OR REPLACE PROCEDURE sp_modificar_materia_prima(
    p_numero_parte VARCHAR,
    p_nuevo_tipo VARCHAR,
    p_largo INT,
    p_ancho INT,
    p_espesor INT,
    p_stock INT
)
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE materia_prima
    SET 
        tipo_material = p_nuevo_tipo,
        dimensiones = jsonb_build_object('largo', p_largo, 'ancho', p_ancho, 'espesor', p_espesor),
        stock_disponible = p_stock
    WHERE numero_parte = p_numero_parte;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Materia prima % no encontrada.', p_numero_parte;
    END IF;
END;
$$;

-- Baja lógica de materia prima
CREATE OR REPLACE PROCEDURE sp_baja_materia_prima(p_numero_parte VARCHAR)
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE materia_prima
    SET stock_disponible = 0
    WHERE numero_parte = p_numero_parte;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Materia prima % no encontrada.', p_numero_parte;
    ELSE
        RAISE NOTICE 'Materia prima % dada de baja (stock = 0).', p_numero_parte;
    END IF;
END;
$$;


--Hojas de corte
-- Alta de hoja de corte
CREATE OR REPLACE PROCEDURE sp_alta_hoja_corte(
    p_mp_numero_parte VARCHAR,
    p_usuario_id INT
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO hojas_corte(mp_numero_parte, usuario_id, estado)
    VALUES (p_mp_numero_parte, p_usuario_id, 'PLANIFICACION');
    
    RAISE NOTICE 'Hoja de corte creada para materia prima %', p_mp_numero_parte;
END;
$$;

-- Finalizar hoja de corte
CREATE OR REPLACE PROCEDURE sp_finalizar_hoja_corte(p_id INT)
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE hojas_corte
    SET estado = 'FINALIZADO'
    WHERE id = p_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Hoja de corte % no encontrada.', p_id;
    ELSE
        RAISE NOTICE 'Hoja de corte % finalizada.', p_id;
    END IF;
END;
$$;


--Vistas de apoyo
-- Vista de stock actual
CREATE OR REPLACE VIEW vw_stock_materia_prima AS
SELECT 
    numero_parte,
    tipo_material,
    (dimensiones->>'largo')::INT AS largo,
    (dimensiones->>'ancho')::INT AS ancho,
    (dimensiones->>'espesor')::INT AS espesor,
    stock_disponible
FROM materia_prima;

-- Vista de hojas de corte con utilización
CREATE OR REPLACE VIEW vw_hojas_corte_utilizacion AS
SELECT 
    hc.id,
    hc.mp_numero_parte,
    hc.area_total_mm2,
    hc.area_ocupada_mm2,
    hc.porcentaje_utilizacion,
    hc.estado,
    hc.fecha_inicio
FROM hojas_corte hc;


--Seguridad y roles
-- Crear roles de base de datos
CREATE ROLE administrador LOGIN PASSWORD 'admin_pass';
CREATE ROLE operador LOGIN PASSWORD 'oper_pass';

-- Permisos para Administrador
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO administrador;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO administrador;
GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA public TO administrador;

-- Permisos para Operador (solo ejecutar procedimientos y consultar vistas)
GRANT EXECUTE ON FUNCTION sp_alta_producto_completo TO operador;
GRANT EXECUTE ON FUNCTION sp_rotar_posicionar_figuras TO operador;
GRANT EXECUTE ON FUNCTION fn_calcular_utilizacion TO operador;
GRANT EXECUTE ON FUNCTION sp_alta_hoja_corte TO operador;
GRANT EXECUTE ON FUNCTION sp_finalizar_hoja_corte TO operador;

GRANT SELECT ON vw_stock_materia_prima TO operador;
GRANT SELECT ON vw_hojas_corte_utilizacion TO operador;
GRANT SELECT ON vw_usuarios_activos TO operador;

-- Bloquear acceso directo a tablas
REVOKE ALL ON ALL TABLES IN SCHEMA public FROM operador;

--PRUEBAS UNITARIAS
DO $$
DECLARE
    v_hoja_id INT;
    v_utilizacion NUMERIC;
    v_login_ok BOOLEAN;
BEGIN
    RAISE NOTICE '--- INICIANDO PRUEBAS UNITARIAS ---';

    -- PRUEBA GESTIÓN DE USUARIOS Y ROLES
    RAISE NOTICE '1. Probando Roles y Usuarios...';
    
    TRUNCATE roles RESTART IDENTITY CASCADE;
    
    CALL sp_crear_rol('Administrador');
    CALL sp_crear_rol('Operador');
    
    -- Alta de usuario
    CALL sp_alta_usuario('Test Admin', 'admin@test.com', 'admin123', 'Administrador');
    
    -- Validar Login
    v_login_ok := fn_login('admin@test.com', 'admin123');
    
    IF v_login_ok THEN
        RAISE NOTICE '   [OK] Login exitoso.';
    ELSE
        RAISE EXCEPTION '   [FALLO] Login falló.';
    END IF;

    -- PRUEBA: ALTA DE MATERIA PRIMA Y PRODUCTOS
    RAISE NOTICE '2. Probando Inventario...';
    
    CALL sp_alta_materia_prima('MP-TEST-01', 'Acero', 3000, 1500, 5, 100);
    
    CALL sp_alta_producto_completo('PROD-TEST', 'Mesa Test', 'Tapa', 1, 'RECTANGULO', '{"ancho": 1000, "alto": 1000}'::jsonb);
    
    PERFORM * FROM materia_prima WHERE numero_parte = 'MP-TEST-01';
    RAISE NOTICE '   [OK] Materia prima y producto registrados.';

    -- PRUEBA: PROCESO DE CORTE Y TRIGGERS (Área Total)

    RAISE NOTICE '3. Probando Hoja de Corte y Trigger de Área...';
    
    CALL sp_alta_hoja_corte('MP-TEST-01', 1);
    
    SELECT id INTO v_hoja_id FROM hojas_corte WHERE mp_numero_parte = 'MP-TEST-01' ORDER BY id DESC LIMIT 1;
    
    PERFORM * FROM hojas_corte WHERE id = v_hoja_id AND area_total_mm2 = 4500000;
    
    IF FOUND THEN
        RAISE NOTICE '   [OK] Trigger calculó área total correctamente (4,500,000).';
    ELSE
        RAISE EXCEPTION '   [FALLO] Trigger no calculó el área total.';
    END IF;

    -- PRUEBA 4: ROTACIÓN, POSICIONAMIENTO Y CÁLCULO DE UTILIZACIÓN
    RAISE NOTICE '4. Probando Rotación y Utilización...';
    
    CALL sp_rotar_posicionar_figuras(v_hoja_id, 1, 0, 0, 0, '{"prueba": true}'::jsonb);
    
    SELECT porcentaje_utilizacion INTO v_utilizacion FROM hojas_corte WHERE id = v_hoja_id;
    
    IF v_utilizacion = 22.22 THEN
        RAISE NOTICE '   [OK] Utilización calculada correctamente: %%', v_utilizacion;
    ELSE
        RAISE EXCEPTION '   [FALLO] Utilización incorrecta. Esperado 22.22, Obtenido %%', v_utilizacion;
    END IF;
    
    -- PRUEBA:GESTIÓN DE EVENTOS JSON
    RAISE NOTICE '5. Probando Registro de Eventos JSON...';
    
    PERFORM * FROM eventos_optimizacion WHERE hoja_corte_id = v_hoja_id AND datos_evento->>'prueba' = 'true';
    
    IF FOUND THEN
        RAISE NOTICE '   [OK] Evento JSON registrado correctamente.';
    ELSE
        RAISE EXCEPTION '   [FALLO] No se encontró el evento JSON.';
    END IF;

    RAISE NOTICE '--- TODAS LAS PRUEBAS FINALIZARON EXITOSAMENTE ---';
END;
$$;

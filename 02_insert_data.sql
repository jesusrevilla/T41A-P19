CREATE OR REPLACE PROCEDURE sp_crear_rol(
    p_nombre VARCHAR
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO roles (nombre) VALUES (p_nombre);
    RAISE NOTICE 'Rol "%" creado exitosamente.', p_nombre;
END;
$$;

CREATE OR REPLACE PROCEDURE sp_modificar_rol(
    p_id INT,
    p_nuevo_nombre VARCHAR
)
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE roles 
    SET nombre = p_nuevo_nombre
    WHERE id = p_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'No se encontró el rol con ID %', p_id;
    END IF;
END;
$$;

CREATE OR REPLACE PROCEDURE sp_eliminar_rol(p_id INT)
LANGUAGE plpgsql
AS $$
BEGIN
    DELETE FROM roles WHERE id = p_id;
    
    IF NOT FOUND THEN
        RAISE NOTICE 'No se encontró el rol con ID %', p_id;
    END IF;
END;
$$;

CREATE OR REPLACE PROCEDURE sp_alta_usuario(
    p_nombre VARCHAR,
    p_email VARCHAR,
    p_password_plana TEXT,
    p_rol_nombre VARCHAR
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_rol_id INT;
BEGIN
    SELECT id INTO v_rol_id FROM roles WHERE nombre = p_rol_nombre;
    
    IF v_rol_id IS NULL THEN
        RAISE EXCEPTION 'El rol "%" no existe.', p_rol_nombre;
    END IF;

    INSERT INTO usuarios (nombre, email, password_hash, rol_id, activo)
    VALUES (
        p_nombre, 
        p_email, 
        crypt(p_password_plana, gen_salt('bf')), --encriptacion por eso se usa la del principio
        v_rol_id, 
        TRUE
    );
    
    RAISE NOTICE 'Usuario % registrado correctamente.', p_nombre;
END;
$$;

CREATE OR REPLACE PROCEDURE sp_modificar_usuario(
    p_id INT,
    p_nombre VARCHAR,
    p_email VARCHAR,
    p_rol_id INT
)
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE usuarios
    SET 
        nombre = p_nombre,
        email = p_email,
        rol_id = p_rol_id
    WHERE id = p_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Usuario con ID % no encontrado.', p_id;
    END IF;
END;
$$;

CREATE OR REPLACE PROCEDURE sp_baja_usuario(p_id INT)
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE usuarios
    SET activo = FALSE
    WHERE id = p_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Usuario con ID % no encontrado.', p_id;
    ELSE
        RAISE NOTICE 'Usuario % desactivado.', p_id;
    END IF;
END;
$$;

CREATE OR REPLACE VIEW vw_usuarios_activos AS
SELECT 
    u.id,
    u.nombre,
    u.email,
    r.nombre AS rol,
    u.activo,
    u.fecha_creacion
FROM usuarios u
JOIN roles r ON u.rol_id = r.id
WHERE u.activo = TRUE; 

--Alta materia prima 
CREATE OR REPLACE PROCEDURE sp_alta_materia_prima(
    p_numero_parte VARCHAR,
    p_tipo_material VARCHAR,
    p_largo INT,
    p_ancho INT,
    p_espesor INT,
    p_stock INT
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO materia_prima (
        numero_parte, 
        tipo_material, 
        dimensiones, 
        parametros_corte, 
        stock_disponible
    ) VALUES (
        p_numero_parte,
        p_tipo_material,
        jsonb_build_object('largo', p_largo, 'ancho', p_ancho, 'espesor', p_espesor),
        jsonb_build_object('margen_seguridad', 5, 'distancia_piezas', 2), 
        p_stock
    );
    
    RAISE NOTICE 'Materia prima % registrada correctamente.', p_numero_parte;
END;
$$;

--Alta de producto
CREATE OR REPLACE PROCEDURE sp_alta_producto_completo(
    p_prod_num_parte VARCHAR,
    p_descripcion VARCHAR,
    p_nombre_pieza VARCHAR,
    p_cantidad INT,
    p_tipo_segmento VARCHAR, 
    p_geometria_json JSONB 
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_pieza_id INT;
BEGIN
    INSERT INTO productos (numero_parte, descripcion)
    VALUES (p_prod_num_parte, p_descripcion)
    ON CONFLICT (numero_parte) DO NOTHING;

    INSERT INTO piezas (producto_numero_parte, nombre_pieza, cantidad_requerida)
    VALUES (p_prod_num_parte, p_nombre_pieza, p_cantidad)
    RETURNING id INTO v_pieza_id;

    INSERT INTO geometrias_pieza (pieza_id, orden_secuencia, tipo_segmento, datos_geometricos)
    VALUES (v_pieza_id, 1, p_tipo_segmento, p_geometria_json);

    RAISE NOTICE 'Producto % y pieza % registrados.', p_prod_num_parte, p_nombre_pieza;
END;
$$;

--Rotación y posicionamiento de figuras.
CREATE OR REPLACE PROCEDURE sp_rotar_posicionar_figuras(
    p_hoja_corte_id INT,
    p_pieza_id INT,
    p_pos_x NUMERIC,      
    p_pos_y NUMERIC,    
    p_rotacion_grados NUMERIC,
    p_evento_json JSONB 
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_geom_original JSONB;
    v_geom_final JSONB;
    v_rads NUMERIC;
    v_cos NUMERIC;
    v_sin NUMERIC;
    
    v_ancho NUMERIC;
    v_alto NUMERIC;
    v_p1_x NUMERIC; v_p1_y NUMERIC; 
    v_p2_x NUMERIC; v_p2_y NUMERIC; 
BEGIN
    SELECT datos_geometricos INTO v_geom_original
    FROM geometrias_pieza
    WHERE pieza_id = p_pieza_id
    LIMIT 1;

    v_rads := p_rotacion_grados * PI() / 180.0;
    v_cos := COS(v_rads);
    v_sin := SIN(v_rads);

    v_ancho := (v_geom_original->>'ancho')::NUMERIC;
    v_alto  := (v_geom_original->>'alto')::NUMERIC;

    v_p1_x := p_pos_x; 
    v_p1_y := p_pos_y;
    
    v_p2_x := (v_ancho * v_cos - v_alto * v_sin) + p_pos_x;
    v_p2_y := (v_ancho * v_sin + v_alto * v_cos) + p_pos_y;

    v_geom_final := jsonb_build_object(
        'x_origen', v_p1_x,
        'y_origen', v_p1_y,
        'x_fin', v_p2_x,
        'y_fin', v_p2_y,
        'ancho_original', v_ancho,
        'alto_original', v_alto,
        'rotacion_aplicada', p_rotacion_grados
    );

    IF EXISTS (SELECT 1 FROM piezas_colocadas WHERE hoja_corte_id = p_hoja_corte_id AND pieza_id = p_pieza_id) THEN
        UPDATE piezas_colocadas
        SET 
            posicion_x = p_pos_x,
            posicion_y = p_pos_y,
            rotacion_grados = p_rotacion_grados,
            geometria_final = v_geom_final
        WHERE hoja_corte_id = p_hoja_corte_id AND pieza_id = p_pieza_id;
    ELSE
        INSERT INTO piezas_colocadas (hoja_corte_id, pieza_id, posicion_x, posicion_y, rotacion_grados, geometria_final)
        VALUES (p_hoja_corte_id, p_pieza_id, p_pos_x, p_pos_y, p_rotacion_grados, v_geom_final);
    END IF;

    INSERT INTO eventos_optimizacion (hoja_corte_id, tipo_evento, datos_evento)
    VALUES (p_hoja_corte_id, 'ROTACION_POSICIONAMIENTO', p_evento_json);

    RAISE NOTICE 'Pieza % posicionada en [%, %] con rotación %°', p_pieza_id, p_pos_x, p_pos_y, p_rotacion_grados;
END;
$$;

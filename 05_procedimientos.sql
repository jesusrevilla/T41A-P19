-- 05_procedimientos.sql
-- Altas y sp de rotación/posicionamiento

SET search_path TO corte, public;

-- Alta de materia prima
CREATE OR REPLACE FUNCTION sp_alta_materia_prima(p_numero_parte TEXT, p_descripcion TEXT,
                                                 p_ancho NUMERIC, p_alto NUMERIC, p_unidad TEXT,
                                                 p_dist_piezas NUMERIC, p_dist_orilla NUMERIC)
RETURNS INT LANGUAGE plpgsql AS $$
DECLARE v_id INT;
BEGIN
  INSERT INTO materia_prima(numero_parte, descripcion, ancho, alto, unidad,
                            distancia_minima_entre_piezas, distancia_minima_a_orilla)
  VALUES (p_numero_parte, p_descripcion, p_ancho, p_alto, p_unidad, p_dist_piezas, p_dist_orilla)
  RETURNING id INTO v_id;
  RETURN v_id;
END $$;

-- Alta de productos
CREATE OR REPLACE FUNCTION sp_alta_producto(p_numero_parte TEXT, p_descripcion TEXT,
                                            p_geometria_base JSONB, p_cantidad INT)
RETURNS INT LANGUAGE plpgsql AS $$
DECLARE v_id INT;
BEGIN
  INSERT INTO productos(numero_parte, descripcion, geometria_base, cantidad_elementos_por_pieza)
  VALUES (p_numero_parte, p_descripcion, p_geometria_base, p_cantidad)
  RETURNING id INTO v_id;
  RETURN v_id;
END $$;

-- Alta de pieza (opcionalmente asignada a una materia prima)
CREATE OR REPLACE FUNCTION sp_alta_pieza(p_producto_id INT, p_materia_prima_id INT, p_etiqueta TEXT)
RETURNS INT LANGUAGE plpgsql AS $$
DECLARE v_id INT;
BEGIN
  INSERT INTO piezas(producto_id, materia_prima_id, etiqueta, estado)
  VALUES (p_producto_id, p_materia_prima_id, p_etiqueta, 'nuevo')
  RETURNING id INTO v_id;
  RETURN v_id;
END $$;

-- === SP principal: rotar y posicionar figuras de una pieza ===
-- Aplica delta (ángulo, dx, dy) a los params JSON de cada geometría de la pieza.
-- Registra el evento JSON y recalcula bbox y utilización.
CREATE OR REPLACE FUNCTION sp_rotar_posicionar_figuras(p_pieza_id INT,
                                                       p_angulo_deg DOUBLE PRECISION,
                                                       p_dx NUMERIC, p_dy NUMERIC,
                                                       p_evento JSONB)
RETURNS VOID LANGUAGE plpgsql AS $$
DECLARE g RECORD; v_mp_id INT;
BEGIN
  FOR g IN SELECT * FROM geometrias WHERE pieza_id = p_pieza_id ORDER BY orden LOOP
    UPDATE geometrias
       SET params = fn_transform_params(g.tipo, g.params, p_angulo_deg, p_dx, p_dy)
     WHERE id = g.id;
  END LOOP;

  -- Recalcular area/bbox de geometrías (lo hará trigger BEFORE)
  -- Recalcular bbox de pieza
  PERFORM sp_recalcular_pieza_bbox(p_pieza_id);

  -- Actualizar acumulado de pose en pieza
  UPDATE piezas
     SET angulo_deg = angulo_deg + p_angulo_deg,
         pos_x      = pos_x + p_dx,
         pos_y      = pos_y + p_dy,
         estado     = CASE WHEN estado = 'nuevo' THEN 'colocado' ELSE 'ajustado' END
   WHERE id = p_pieza_id
  RETURNING materia_prima_id INTO v_mp_id;

  -- Validaciones de separación/márgenes
  PERFORM fn_validar_colocacion(p_pieza_id);

  -- Recalcular utilización si la pieza pertenece a una lámina
  IF v_mp_id IS NOT NULL THEN
    PERFORM sp_recalcular_utilizacion(v_mp_id);
  END IF;

  -- Registrar evento
  INSERT INTO eventos(pieza_id, tipo, payload)
  VALUES (p_pieza_id, 'rotar_posicionar', COALESCE(p_evento, jsonb_build_object(
    'pieza_id', p_pieza_id, 'angulo_deg', p_angulo_deg, 'dx', p_dx, 'dy', p_dy
  )));
END $$;

-- fn_area_from_geometria
CREATE OR REPLACE FUNCTION fn_area_from_geometria(geometria JSONB)
RETURNS NUMERIC LANGUAGE plpgsql AS $$
DECLARE
  comp JSONB;
  total NUMERIC := 0;
BEGIN
  IF geometria IS NULL THEN RETURN 0; END IF;
  FOR comp IN SELECT * FROM jsonb_array_elements(COALESCE(geometria->'componentes','[]'::jsonb)) LOOP
    BEGIN
      total := total + ( (comp->>'area')::NUMERIC );
    EXCEPTION WHEN others THEN
      total := total + 0;
    END;
  END LOOP;
  RETURN total;
END;
$$;

-- sp_alta_materia_prima
CREATE OR REPLACE PROCEDURE sp_alta_materia_prima(
  p_num_parte TEXT,
  p_ancho NUMERIC,
  p_alto NUMERIC,
  p_thickness NUMERIC DEFAULT 0,
  p_min_dist_piece NUMERIC DEFAULT 0,
  p_min_dist_edge NUMERIC DEFAULT 0
)
LANGUAGE plpgsql
AS $$
BEGIN
  INSERT INTO materia_prima(numero_parte, ancho, alto, thickness, min_dist_piece, min_dist_edge)
  VALUES (p_num_parte, p_ancho, p_alto, p_thickness, p_min_dist_piece, p_min_dist_edge)
  ON CONFLICT (numero_parte) DO UPDATE
    SET ancho = EXCLUDED.ancho,
        alto = EXCLUDED.alto,
        thickness = EXCLUDED.thickness,
        min_dist_piece = EXCLUDED.min_dist_piece,
        min_dist_edge = EXCLUDED.min_dist_edge;
END;
$$;

-- sp_alta_producto
CREATE OR REPLACE PROCEDURE sp_alta_producto(
  p_num_parte TEXT,
  p_descripcion TEXT,
  p_piezas_json JSONB
)
LANGUAGE plpgsql
AS $$
DECLARE
  prod_id INTEGER;
  item JSONB;
BEGIN
  INSERT INTO productos(numero_parte, descripcion)
  VALUES (p_num_parte, p_descripcion)
  ON CONFLICT (numero_parte) DO UPDATE
    SET descripcion = EXCLUDED.descripcion
  RETURNING id INTO prod_id;

  FOR item IN SELECT * FROM jsonb_array_elements(COALESCE(p_piezas_json,'[]'::jsonb)) LOOP
    INSERT INTO piezas(producto_id, cantidad, geometria, area, bbox)
    VALUES (
      prod_id,
      COALESCE((item->>'cantidad')::INTEGER,1),
      COALESCE(item->'geometria','{}'::jsonb),
      fn_area_from_geometria(COALESCE(item->'geometria','{}'::jsonb)),
      COALESCE(item->'bbox','{}'::jsonb)
    );
  END LOOP;
END;
$$;

-- sp_rotar_posicionar_figuras
CREATE OR REPLACE PROCEDURE sp_rotar_posicionar_figuras(
  p_pieza_id INTEGER,
  p_angulo NUMERIC,
  p_x NUMERIC,
  p_y NUMERIC,
  p_evento JSONB
)
LANGUAGE plpgsql
AS $$
DECLARE
  g JSONB;
  newg JSONB;
  newarea NUMERIC;
  newbbox JSONB;
BEGIN
  SELECT geometria INTO g FROM piezas WHERE id = p_pieza_id FOR UPDATE;
  IF g IS NULL THEN
    RAISE EXCEPTION 'Pieza % no existe o geometria vacía', p_pieza_id;
  END IF;

  newg := g || jsonb_build_object('transform', jsonb_build_object('rotate', p_angulo, 'x', p_x, 'y', p_y));
  newarea := fn_area_from_geometria(newg);

  IF (newg ? 'bbox') THEN
    newbbox := newg->'bbox';
  ELSE
    newbbox := '{}'::jsonb;
  END IF;

  UPDATE piezas SET geometria = newg, area = newarea, bbox = newbbox WHERE id = p_pieza_id;
  INSERT INTO eventos(pieza_id, evento) VALUES (p_pieza_id, jsonb_build_object('evento', p_evento, 'rotate', p_angulo, 'x', p_x, 'y', p_y));
END;
$$;

-- fn_calcular_utilizacion
CREATE OR REPLACE FUNCTION fn_calcular_utilizacion(p_materia_id INTEGER)
RETURNS NUMERIC LANGUAGE plpgsql AS $$
DECLARE
  total_piezas_area NUMERIC := 0;
  mat_area NUMERIC := 0;
BEGIN
  SELECT area INTO mat_area FROM materia_prima WHERE id = p_materia_id;
  IF mat_area IS NULL OR mat_area <= 0 THEN
    RETURN 0;
  END IF;

  SELECT COALESCE(SUM(p.area * p.cantidad),0) INTO total_piezas_area FROM piezas p;

  RETURN ROUND((total_piezas_area / mat_area) * 100, 4);
END;
$$;

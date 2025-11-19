-- 04_funciones_geom_y_utilizacion.sql
-- Funciones utilitarias: transformación geométrica, área, bbox, validaciones y cálculo de utilización

SET search_path TO corte, public;

-- ==== Conversions / Math helpers ====
CREATE OR REPLACE FUNCTION fn_deg2rad(d DOUBLE PRECISION)
RETURNS DOUBLE PRECISION LANGUAGE sql IMMUTABLE AS $$
  SELECT radians(d);
$$;

CREATE OR REPLACE FUNCTION fn_rotate_point(px NUMERIC, py NUMERIC, ang_deg DOUBLE PRECISION)
RETURNS TABLE(x NUMERIC, y NUMERIC) LANGUAGE sql IMMUTABLE AS $$
  SELECT
    px * COS(radians(ang_deg)) - py * SIN(radians(ang_deg)) AS x,
    px * SIN(radians(ang_deg)) + py * COS(radians(ang_deg)) AS y;
$$;

CREATE OR REPLACE FUNCTION fn_rotate_point_json(p JSONB, ang_deg DOUBLE PRECISION)
RETURNS JSONB LANGUAGE plpgsql IMMUTABLE AS $$
DECLARE x NUMERIC; y NUMERIC; rx NUMERIC; ry NUMERIC;
BEGIN
  x := (p->>'x')::NUMERIC; y := (p->>'y')::NUMERIC;
  SELECT r.x, r.y INTO rx, ry FROM fn_rotate_point(x, y, ang_deg) r;
  RETURN jsonb_build_object('x', rx, 'y', ry);
END $$;

CREATE OR REPLACE FUNCTION fn_translate_point_json(p JSONB, dx NUMERIC, dy NUMERIC)
RETURNS JSONB LANGUAGE plpgsql IMMUTABLE AS $$
DECLARE x NUMERIC; y NUMERIC;
BEGIN
  x := (p->>'x')::NUMERIC; y := (p->>'y')::NUMERIC;
  RETURN jsonb_build_object('x', x + dx, 'y', y + dy);
END $$;

-- === Transformación genérica de params JSON por tipo ===
CREATE OR REPLACE FUNCTION fn_transform_params(p_tipo TEXT, p_params JSONB, p_ang DOUBLE PRECISION, p_dx NUMERIC, p_dy NUMERIC)
RETURNS JSONB LANGUAGE plpgsql IMMUTABLE AS $$
DECLARE new_params JSONB := p_params;
BEGIN
  IF p_tipo IN ('poligono','rectangulo') AND p_params ? 'vertices' THEN
    new_params := jsonb_set(
      new_params, '{vertices}',
      (
        SELECT jsonb_agg(
                 fn_translate_point_json(fn_rotate_point_json(v.elem, p_ang), p_dx, p_dy)
               )
          FROM jsonb_array_elements(p_params->'vertices') AS v(elem)
      ),
      TRUE
    );
    RETURN new_params;
  ELSIF p_tipo = 'segmento' AND (p_params ? 'p1') AND (p_params ? 'p2') THEN
    new_params := jsonb_set(new_params, '{p1}', fn_translate_point_json(fn_rotate_point_json(p_params->'p1', p_ang), p_dx, p_dy), TRUE);
    new_params := jsonb_set(new_params, '{p2}', fn_translate_point_json(fn_rotate_point_json(p_params->'p2', p_ang), p_dx, p_dy), TRUE);
    RETURN new_params;
  ELSIF p_tipo IN ('circulo','arco') AND (p_params ? 'center') THEN
    new_params := jsonb_set(new_params, '{center}', fn_translate_point_json(fn_rotate_point_json(p_params->'center', p_ang), p_dx, p_dy), TRUE);
    -- Para arco, mantenemos start_angle/end_angle relativos (no alteramos).
    RETURN new_params;
  ELSE
    -- Si no se reconoce estructura, devolvemos sin cambios
    RETURN p_params;
  END IF;
END $$;

-- === Área de polígonos (fórmula Shoelace) ===
CREATE OR REPLACE FUNCTION fn_polygon_area(p_vertices JSONB)
RETURNS NUMERIC LANGUAGE plpgsql IMMUTABLE AS $$
DECLARE n INT; i INT; j INT; xi NUMERIC; yi NUMERIC; xj NUMERIC; yj NUMERIC; sum NUMERIC := 0;
BEGIN
  IF p_vertices IS NULL OR jsonb_typeof(p_vertices) <> 'array' THEN
    RETURN 0;
  END IF;
  n := jsonb_array_length(p_vertices);
  IF n < 3 THEN
    RETURN 0;
  END IF;

  FOR i IN 0..n-1 LOOP
    j := (i + 1) % n;
    xi := (p_vertices -> i ->> 'x')::NUMERIC;
    yi := (p_vertices -> i ->> 'y')::NUMERIC;
    xj := (p_vertices -> j ->> 'x')::NUMERIC;
    yj := (p_vertices -> j ->> 'y')::NUMERIC;
    sum := sum + (xi * yj - xj * yi);
  END LOOP;

  RETURN abs(sum) / 2.0;
END $$;

-- === Cálculo de área por tipo ===
CREATE OR REPLACE FUNCTION fn_area_from_geom(p_tipo TEXT, p_params JSONB)
RETURNS NUMERIC LANGUAGE plpgsql IMMUTABLE AS $$
DECLARE a NUMERIC := 0;
DECLARE w NUMERIC; h NUMERIC; r NUMERIC;
BEGIN
  IF p_tipo = 'poligono' AND p_params ? 'vertices' THEN
     a := fn_polygon_area(p_params->'vertices');
  ELSIF p_tipo = 'rectangulo' AND p_params ? 'vertices' THEN
     a := fn_polygon_area(p_params->'vertices');
  ELSIF p_tipo = 'circulo' AND p_params ? 'radius' THEN
     r := (p_params->>'radius')::NUMERIC;
     a := pi() * r * r;
  ELSIF p_tipo = 'segmento' THEN
     a := 0;
  ELSIF p_tipo = 'arco' THEN
     a := 0; -- Área de arco no se computa (solo borde); si requiere, extender.
  END IF;
  RETURN COALESCE(a,0);
END $$;

-- === BBox desde params ===
CREATE OR REPLACE FUNCTION fn_bbox_from_params(p_tipo TEXT, p_params JSONB)
RETURNS TABLE(xmin NUMERIC, ymin NUMERIC, xmax NUMERIC, ymax NUMERIC) LANGUAGE plpgsql IMMUTABLE AS $$
DECLARE n INT; i INT; x NUMERIC; y NUMERIC; r NUMERIC; cx NUMERIC; cy NUMERIC;
BEGIN
  IF p_tipo IN ('poligono','rectangulo') AND p_params ? 'vertices' THEN
    xmin := NULL; ymin := NULL; xmax := NULL; ymax := NULL;
    n := jsonb_array_length(p_params->'vertices');
    FOR i IN 0..n-1 LOOP
      x := (p_params->'vertices'->i->>'x')::NUMERIC;
      y := (p_params->'vertices'->i->>'y')::NUMERIC;
      xmin := CASE WHEN xmin IS NULL OR x < xmin THEN x ELSE xmin END;
      ymin := CASE WHEN ymin IS NULL OR y < ymin THEN y ELSE ymin END;
      xmax := CASE WHEN xmax IS NULL OR x > xmax THEN x ELSE xmax END;
      ymax := CASE WHEN ymax IS NULL OR y > ymax THEN y ELSE ymax END;
    END LOOP;
    RETURN;
  ELSIF p_tipo = 'segmento' AND (p_params ? 'p1') AND (p_params ? 'p2') THEN
    xmin := LEAST((p_params->'p1'->>'x')::NUMERIC, (p_params->'p2'->>'x')::NUMERIC);
    ymin := LEAST((p_params->'p1'->>'y')::NUMERIC, (p_params->'p2'->>'y')::NUMERIC);
    xmax := GREATEST((p_params->'p1'->>'x')::NUMERIC, (p_params->'p2'->>'x')::NUMERIC);
    ymax := GREATEST((p_params->'p1'->>'y')::NUMERIC, (p_params->'p2'->>'y')::NUMERIC);
    RETURN;
  ELSIF p_tipo IN ('circulo','arco') AND (p_params ? 'center') AND (p_params ? 'radius') THEN
    cx := (p_params->'center'->>'x')::NUMERIC;
    cy := (p_params->'center'->>'y')::NUMERIC;
    r := (p_params->>'radius')::NUMERIC;
    xmin := cx - r; ymin := cy - r; xmax := cx + r; ymax := cy + r;
    RETURN;
  ELSE
    -- Sin info, bbox nulo
    xmin := NULL; ymin := NULL; xmax := NULL; ymax := NULL;
    RETURN;
  END IF;
END $$;

-- === Recalcular bbox de pieza a partir de sus geometrías ===
CREATE OR REPLACE FUNCTION sp_recalcular_pieza_bbox(p_pieza_id INT)
RETURNS VOID LANGUAGE plpgsql AS $$
DECLARE v RECORD;
BEGIN
  SELECT
    MIN(g.bbox_xmin) AS xmin,
    MIN(g.bbox_ymin) AS ymin,
    MAX(g.bbox_xmax) AS xmax,
    MAX(g.bbox_ymax) AS ymax
  INTO v
  FROM geometrias g
  WHERE g.pieza_id = p_pieza_id;

  UPDATE piezas
     SET bbox_xmin = v.xmin,
         bbox_ymin = v.ymin,
         bbox_xmax = v.xmax,
         bbox_ymax = v.ymax
   WHERE id = p_pieza_id;
END $$;

-- === Cálculo de utilización ===
-- Utilización (%) = (área total de piezas colocadas dentro de una lámina / área utilizable de la lámina) * 100
-- Área utilizable considera la distancia mínima a la orilla
CREATE OR REPLACE FUNCTION fn_calcular_utilizacion(p_materia_prima_id INT)
RETURNS NUMERIC LANGUAGE plpgsql AS $$
DECLARE v_ancho NUMERIC; v_alto NUMERIC; v_borde NUMERIC;
DECLARE area_total NUMERIC; area_usable NUMERIC; area_piezas NUMERIC;
BEGIN
  SELECT ancho, alto, distancia_minima_a_orilla
    INTO v_ancho, v_alto, v_borde
  FROM materia_prima WHERE id = p_materia_prima_id;

  IF v_ancho IS NULL THEN
    RAISE EXCEPTION 'Materia prima % no existe', p_materia_prima_id;
  END IF;

  area_total := v_ancho * v_alto;
  area_usable := GREATEST( (v_ancho - 2*v_borde) * (v_alto - 2*v_borde), 0 );

  SELECT COALESCE(SUM(g.area * g.factor_area), 0)
    INTO area_piezas
  FROM piezas p
  JOIN geometrias g ON g.pieza_id = p.id
  WHERE p.materia_prima_id = p_materia_prima_id;

  IF area_usable = 0 THEN
    RETURN 0;
  END IF;

  RETURN ROUND( (area_piezas / area_usable) * 100.0, 4);
END $$;

CREATE OR REPLACE FUNCTION sp_recalcular_utilizacion(p_materia_prima_id INT)
RETURNS VOID LANGUAGE plpgsql AS $$
DECLARE v NUMERIC;
BEGIN
  v := fn_calcular_utilizacion(p_materia_prima_id);
  UPDATE materia_prima SET utilizacion_pct = v WHERE id = p_materia_prima_id;
END $$;

-- === Validaciones de colocación con bbox y separaciones ===
CREATE OR REPLACE FUNCTION fn_bboxes_intersect_with_gap(axmin NUMERIC, aymin NUMERIC, axmax NUMERIC, aymax NUMERIC,
                                                        bxmin NUMERIC, bymin NUMERIC, bxmax NUMERIC, bymax NUMERIC,
                                                        gap NUMERIC)
RETURNS BOOLEAN LANGUAGE plpgsql IMMUTABLE AS $$
BEGIN
  -- Requiere separación >= gap. Si se solapan considerando gap, entonces intersectan.
  -- Expandimos cajas por gap/2 a cada lado -> si siguen intersectando, no cumplen separación.
  RETURN NOT (
      (axmax + gap) <= bxmin OR
      (bxmax + gap) <= axmin OR
      (aymax + gap) <= bymin OR
      (bymax + gap) <= aymin
  );
END $$;

CREATE OR REPLACE FUNCTION fn_validar_colocacion(p_pieza_id INT)
RETURNS VOID LANGUAGE plpgsql AS $$
DECLARE p RECORD; mp RECORD; q RECORD;
BEGIN
  SELECT * INTO p FROM piezas WHERE id = p_pieza_id;
  IF p IS NULL THEN
    RAISE EXCEPTION 'Pieza % no existe', p_pieza_id;
  END IF;

  IF p.materia_prima_id IS NULL THEN
    RETURN; -- No valida hasta asignación a lámina
  END IF;

  SELECT * INTO mp FROM materia_prima WHERE id = p.materia_prima_id;

  -- Validar bbox definido
  IF p.bbox_xmin IS NULL OR p.bbox_ymin IS NULL OR p.bbox_xmax IS NULL OR p.bbox_ymax IS NULL THEN
    RETURN; -- Aún sin geometría/bbox
  END IF;

  -- Validar dentro del área utilizable (bordes)
  IF p.bbox_xmin < mp.distancia_minima_a_orilla
     OR p.bbox_ymin < mp.distancia_minima_a_orilla
     OR p.bbox_xmax > (mp.ancho - mp.distancia_minima_a_orilla)
     OR p.bbox_ymax > (mp.alto  - mp.distancia_minima_a_orilla) THEN
     RAISE EXCEPTION 'Pieza % viola margen de orilla en materia prima %', p_pieza_id, p.materia_prima_id;
  END IF;

  -- Validar separación mínima con otras piezas
  FOR q IN
    SELECT id, bbox_xmin, bbox_ymin, bbox_xmax, bbox_ymax
    FROM piezas
    WHERE materia_prima_id = p.materia_prima_id
      AND id <> p.id
      AND bbox_xmin IS NOT NULL
  LOOP
    IF fn_bboxes_intersect_with_gap(p.bbox_xmin, p.bbox_ymin, p.bbox_xmax, p.bbox_ymax,
                                    q.bbox_xmin, q.bbox_ymin, q.bbox_xmax, q.bbox_ymax,
                                    mp.distancia_minima_entre_piezas) THEN
      RAISE EXCEPTION 'Pieza % está a menos de % de la pieza % en la misma lámina %',
        p.id, mp.distancia_minima_entre_piezas, q.id, p.materia_prima_id;
    END IF;
  END LOOP;

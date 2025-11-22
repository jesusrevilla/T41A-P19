-- Validar parametros de materia_prima
CREATE OR REPLACE FUNCTION trg_validate_materia_params()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  IF NEW.ancho <= 0 OR NEW.alto <= 0 THEN
    RAISE EXCEPTION 'Dimensiones deben ser positivas';
  END IF;
  IF NEW.min_dist_piece < 0 OR NEW.min_dist_edge < 0 THEN
    RAISE EXCEPTION 'Distancias minimas no deben ser negativas';
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER validate_materia_params
BEFORE INSERT OR UPDATE ON materia_prima
FOR EACH ROW EXECUTE FUNCTION trg_validate_materia_params();

-- Recalcular utilizacion después de cambios en piezas
CREATE OR REPLACE FUNCTION trg_recalc_utilizacion()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE
  util NUMERIC;
  mat RECORD;
BEGIN
  FOR mat IN SELECT id FROM materia_prima LOOP
    util := fn_calcular_utilizacion(mat.id);
    UPDATE materia_prima SET last_utilizacion = util WHERE id = mat.id;
  END LOOP;
  RETURN NEW;
END;
$$;

CREATE TRIGGER recalc_utilizacion_after_piezas
AFTER INSERT OR UPDATE OR DELETE ON piezas
FOR EACH STATEMENT EXECUTE FUNCTION trg_recalc_utilizacion();

-- Funciones de soporte para validacion de distancia con bbox
CREATE OR REPLACE FUNCTION fn_centroid_from_bbox(bbox JSONB)
RETURNS TABLE(cx NUMERIC, cy NUMERIC) LANGUAGE plpgsql AS $$
BEGIN
  IF bbox IS NULL OR bbox = '{}'::jsonb THEN
    RETURN QUERY SELECT 0::NUMERIC, 0::NUMERIC;
  ELSE
    RETURN QUERY SELECT ((bbox->>'xmin')::NUMERIC + (bbox->>'xmax')::NUMERIC)/2,
                         ((bbox->>'ymin')::NUMERIC + (bbox->>'ymax')::NUMERIC)/2;
  END IF;
END;
$$;

CREATE OR REPLACE FUNCTION trg_validate_pieza_distance()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE
  other RECORD;
  x1 NUMERIC; y1 NUMERIC;
  x2 NUMERIC; y2 NUMERIC;
  min_dist NUMERIC;
BEGIN
  SELECT cx, cy INTO x1, y1 FROM fn_centroid_from_bbox(NEW.bbox);

  SELECT min_dist_piece INTO min_dist FROM materia_prima LIMIT 1;
  IF min_dist IS NULL THEN min_dist := 0; END IF;

  FOR other IN SELECT id, bbox FROM piezas WHERE id <> COALESCE(NEW.id, -1) LOOP
    SELECT cx, cy INTO x2, y2 FROM fn_centroid_from_bbox(other.bbox);
    IF ( (x1 - x2)*(x1 - x2) + (y1 - y2)*(y1 - y2) ) < (min_dist * min_dist) THEN
      RAISE EXCEPTION 'Distancia entre piezas es menor que la minima (%). Conflicto con pieza %', min_dist, other.id;
    END IF;
  END LOOP;

  RETURN NEW;
END;
$$;

CREATE TRIGGER validate_distance_before_pieza
BEFORE INSERT OR UPDATE ON piezas
FOR EACH ROW EXECUTE FUNCTION trg_validate_pieza_distance();

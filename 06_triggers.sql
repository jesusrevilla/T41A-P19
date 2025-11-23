-- 06_triggers.sql
-- Triggers para validar y recalcular automáticamente

SET search_path TO corte, public;

-- BEFORE INSERT/UPDATE en geometrias: calcula area y bbox
CREATE OR REPLACE FUNCTION trgfn_geometrias_pre()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE b RECORD; a NUMERIC;
BEGIN
  a := fn_area_from_geom(NEW.tipo, NEW.params);
  NEW.area := COALESCE(a,0);

  SELECT * INTO b FROM fn_bbox_from_params(NEW.tipo, NEW.params);
  NEW.bbox_xmin := b.xmin;
  NEW.bbox_ymin := b.ymin;
  NEW.bbox_xmax := b.xmax;
  NEW.bbox_ymax := b.ymax;

  NEW.actualizado_en := NOW();
  RETURN NEW;
END $$;

DROP TRIGGER IF EXISTS trg_geometrias_pre ON geometrias;
CREATE TRIGGER trg_geometrias_pre
BEFORE INSERT OR UPDATE ON geometrias
FOR EACH ROW EXECUTE FUNCTION trgfn_geometrias_pre();

-- AFTER cambios en geometrias: recalc bbox de pieza, validar y recalc utilización
CREATE OR REPLACE FUNCTION trgfn_geometrias_post()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE v_mp_id INT;
BEGIN
  PERFORM sp_recalcular_pieza_bbox(COALESCE(NEW.pieza_id, OLD.pieza_id));

  -- Validar colocación si tiene lámina
  SELECT materia_prima_id INTO v_mp_id FROM piezas WHERE id = COALESCE(NEW.pieza_id, OLD.pieza_id);
  IF v_mp_id IS NOT NULL THEN
    PERFORM fn_validar_colocacion(COALESCE(NEW.pieza_id, OLD.pieza_id));
    PERFORM sp_recalcular_utilizacion(v_mp_id);
  END IF;

  RETURN NULL;
END $$;

DROP TRIGGER IF EXISTS trg_geometrias_post ON geometrias;
CREATE TRIGGER trg_geometrias_post
AFTER INSERT OR UPDATE OR DELETE ON geometrias
FOR EACH ROW EXECUTE FUNCTION trgfn_geometrias_post();

-- AFTER UPDATE de piezas: al cambiar asignación de lámina o estado, validar y recalcular
CREATE OR REPLACE FUNCTION trgfn_piezas_post()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE v_mp_id INT;
BEGIN
  PERFORM sp_recalcular_pieza_bbox(NEW.id);
  SELECT materia_prima_id INTO v_mp_id FROM piezas WHERE id = NEW.id;
  IF v_mp_id IS NOT NULL THEN
    PERFORM fn_validar_colocacion(NEW.id);
    PERFORM sp_recalcular_utilizacion(v_mp_id);
  END IF;
  RETURN NULL;
END $$;

DROP TRIGGER IF EXISTS trg_piezas_post ON piezas;
CREATE TRIGGER trg_piezas_post
AFTER INSERT OR UPDATE ON piezas
FOR EACH ROW EXECUTE FUNCTION trgfn_piezas_post();

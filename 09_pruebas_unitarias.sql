-- 09_pruebas_unitarias.sql
-- Pruebas básicas (sin pgTAP) usando aserciones y resultados en tabla

SET search_path TO corte, public;

-- Tabla para registrar resultados
CREATE TABLE IF NOT EXISTS test_results (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  success BOOLEAN NOT NULL,
  details TEXT,
  executed_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE OR REPLACE FUNCTION test_assert(name TEXT, cond BOOLEAN, details TEXT)
RETURNS VOID LANGUAGE plpgsql AS $$
BEGIN
  INSERT INTO test_results(name, success, details) VALUES (name, cond, details);
  IF NOT cond THEN
    RAISE NOTICE 'Test FAILED: % -> %', name, details;
  ELSE
    RAISE NOTICE 'Test OK: %', name;
  END IF;
END $$;

-- === Dataset: posicionar piezas válidas ===
DO $$
DECLARE p1 INT; p2 INT; mp INT; util NUMERIC;
BEGIN
  SELECT id INTO mp FROM materia_prima WHERE numero_parte = 'MP-800x400';
  SELECT id INTO p1 FROM piezas WHERE etiqueta = 'PZ-001';
  SELECT id INTO p2 FROM piezas WHERE etiqueta = 'PZ-002';

  -- Colocar la primera pieza en (50,50)
  PERFORM sp_rotar_posicionar_figuras(p1, 0, 50, 50, jsonb_build_object('tipo','rotar_posicionar','pieza_id',p1,'dx',50,'dy',50));

  -- Colocar la segunda pieza en (300,50)
  PERFORM sp_rotar_posicionar_figuras(p2, 0, 300, 50, jsonb_build_object('tipo','rotar_posicionar','pieza_id',p2,'dx',300,'dy',50));

  -- Validar utilización esperada:
  -- Área de piezas: 2 * (200x100) = 40,000
  -- Área utilizable lámina: (800-2*20)*(400-2*20) = 760*360 = 273,600
  -- Utilización % ≈ 40000 / 273600 * 100 = 14.6296...
  SELECT utilizacion_pct INTO util FROM materia_prima WHERE id = mp;
  PERFORM test_assert('Utilizacion approx', abs(util - (40000.0 / 273600.0 * 100.0)) < 0.05, 'util='||util::TEXT);
END $$;

-- === Prueba de validación de separación: intentar colocar pieza muy cerca de PZ-001 (debe fallar) ===
DO $$
DECLARE p1 INT; p3 INT; prod INT; mp INT; caught BOOLEAN := FALSE;
BEGIN
  SELECT id INTO mp FROM materia_prima WHERE numero_parte = 'MP-800x400';
  SELECT id INTO prod FROM productos WHERE numero_parte = 'PR-RECT-200x100';

  -- Crear nueva pieza PZ-003 y su geometría igual (200x100)
  p3 := sp_alta_pieza(prod, mp, 'PZ-003');
  INSERT INTO geometrias(pieza_id, tipo, params, factor_area, orden)
  VALUES (p3, 'poligono', jsonb_build_object('vertices', jsonb_build_array(
            jsonb_build_object('x',0,'y',0),
            jsonb_build_object('x',200,'y',0),
            jsonb_build_object('x',200,'y',100),
            jsonb_build_object('x',0,'y',100)
        )), 1, 1);

  SELECT id INTO p1 FROM piezas WHERE etiqueta = 'PZ-001';

  BEGIN
    -- Intento que viola gap (10 mm). PZ-001 bbox aproximado: (50..250, 50..150)
    -- Colocar PZ-003 en x=255,y=50 (solo 5 mm de separación)
    PERFORM sp_rotar_posicionar_figuras(p3, 0, 255, 50, jsonb_build_object('tipo','rotar_posicionar','pieza_id',p3,'dx',255,'dy',50));
  EXCEPTION WHEN OTHERS THEN
    caught := TRUE;
  END;

  PERFORM test_assert('Separacion minima enforce', caught, 'Excepción esperada por gap');
END $$;

-- === Prueba de evento JSON (rotar 90° y mover) ===
DO $$
DECLARE p2 INT; mp INT; before_bbox TEXT; after_bbox TEXT; caught BOOLEAN := FALSE;
BEGIN
  SELECT id INTO p2 FROM piezas WHERE etiqueta = 'PZ-002';
  SELECT format('(%s,%s)-(%s,%s)', bbox_xmin, bbox_ymin, bbox_xmax, bbox_ymax) INTO before_bbox FROM piezas WHERE id = p2;

  PERFORM fn_aplicar_evento_json(jsonb_build_object(
    'tipo','rotar_posicionar','pieza_id',p2,'angulo_deg',90,'dx',0,'dy',0
  ));

  SELECT format('(%s,%s)-(%s,%s)', bbox_xmin, bbox_ymin, bbox_xmax, bbox_ymax) INTO after_bbox FROM piezas WHERE id = p2;

  PERFORM test_assert('Evento JSON aplicado', before_bbox <> after_bbox, 'bbox cambio de '||before_bbox||' a '||after_bbox);
END $$;

-- Reporte final

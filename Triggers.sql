CREATE OR REPLACE FUNCTION tr_validar_antes_de_corte()
RETURNS TRIGGER AS $$
DECLARE
    v_es_valido BOOLEAN;
BEGIN
    v_es_valido := fn_validar_colocacion_nativo(
        NEW.id_pieza,          
        NEW.geometria_final,   
        NEW.id_materia         
    );

    IF NOT v_es_valido THEN
        RAISE EXCEPTION 'ALERTA DE TRIGGER: El corte viola las reglas de colisión o límites de la materia prima.'
        USING HINT = 'Verifique que la pieza no se salga de la lámina ni se encime con otra.';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER t_validar_corte_insert
BEFORE INSERT ON cortes_planificados
FOR EACH ROW
EXECUTE FUNCTION tr_validar_antes_de_corte();

CREATE OR REPLACE FUNCTION tr_auditoria_cortes()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO evento (id_materiap, id_usuario, fecha_hora, tipo_evento, descripcion)
    VALUES (
        NEW.id_materia,
        1,
        NOW(),
        'Corte Planificado',
        jsonb_build_object('id_pieza', NEW.id_pieza, 'area_corte', fn_calcular_area_manual(NEW.geometria_final))
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER t_auditar_corte
AFTER INSERT ON cortes_planificados
FOR EACH ROW
EXECUTE FUNCTION tr_auditoria_cortes();

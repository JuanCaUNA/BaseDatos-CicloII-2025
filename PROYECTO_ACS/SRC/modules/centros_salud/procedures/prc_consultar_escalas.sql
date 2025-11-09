-- =============================================================
-- Procedimiento: PRC_Consultar_Escalas
-- Descripción: Consulta escalas mensuales y sus detalles para un centro, mes y año
-- Cumple con el enunciado: permite visualizar la asignación de médicos, turnos y estados
-- Parámetros: p_acm_id (centro), p_mes, p_anio
-- =============================================================
CREATE OR REPLACE PROCEDURE PRC_Consultar_Escalas(
	p_acm_id IN NUMBER,
	p_mes    IN NUMBER,
	p_anio   IN NUMBER
) AS
BEGIN
	-- Consulta encabezado de escala mensual
	FOR esc IN (
		SELECT AEM_ID, AEM_ESTADO
		  FROM ACS_ESCALA_MENSUAL
		 WHERE ACM_ID = p_acm_id AND AEM_MES = p_mes AND AEM_ANIO = p_anio
	) LOOP
		DBMS_OUTPUT.PUT_LINE('Escala Mensual ID: ' || esc.AEM_ID || ' Estado: ' || esc.AEM_ESTADO);

		-- Consulta detalles de la escala mensual
		FOR det IN (
			SELECT ADM_ID, ADM_FECHA, ADM_ESTADO_TURNO, AME_ID, APM_ID, ATU_ID
			  FROM ACS_DETALLE_MENSUAL
			 WHERE AEM_ID = esc.AEM_ID
			 ORDER BY ADM_FECHA, ATU_ID
		) LOOP
			DBMS_OUTPUT.PUT_LINE('  Detalle: ' || det.ADM_ID || ' Fecha: ' || TO_CHAR(det.ADM_FECHA,'DD-MM-YYYY') ||
				' Turno: ' || det.ATU_ID || ' Médico: ' || det.AME_ID || ' Puesto: ' || det.APM_ID || ' Estado: ' || det.ADM_ESTADO_TURNO);
		END LOOP;
	END LOOP;
END;
/ 

CREATE OR REPLACE PROCEDURE PRC_Escalas_Marcar_Lista_Pago(
  p_mes   IN NUMBER,
  p_anio  IN NUMBER,
  p_acm_id IN NUMBER DEFAULT NULL
) AS
BEGIN
  FOR r IN (
    SELECT AEM_ID
    FROM ACS_ESCALA_MENSUAL
    WHERE AEM_MES = p_mes
      AND AEM_ANIO = p_anio
      AND (p_acm_id IS NULL OR ACM_ID = p_acm_id)
      AND AEM_ESTADO IN ('VIGENTE','EN REVISION','CONSTRUCCION') -- candidatas
  ) LOOP
    PRC_Escala_Cambiar_Estado(r.AEM_ID, 'LISTA PARA PAGO');
  END LOOP;
END;
/

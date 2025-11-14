-- FUNCION AUXILIAR PARA EXTRAER CAMPOS DE UNA LINEA
CREATE OR REPLACE FUNCTION UTIL_GET_FIELD(P_LINE VARCHAR2, P_POS NUMBER) RETURN VARCHAR2 IS
    V_START NUMBER := 1;
    V_END NUMBER;
    V_COUNT NUMBER := 1;
BEGIN
    -- Si la posición es 1, buscamos hasta la primera coma
    IF P_POS = 1 THEN
        V_END := INSTR(P_LINE, ',', 1, 1);
        IF V_END = 0 THEN
            RETURN TRIM(P_LINE);
        ELSE
            RETURN TRIM(SUBSTR(P_LINE, 1, V_END - 1));
        END IF;
    END IF;

    -- Para posiciones > 1
    FOR I IN 1..LENGTH(P_LINE) LOOP
        IF SUBSTR(P_LINE, I, 1) = ',' THEN
            V_COUNT := V_COUNT + 1;
            IF V_COUNT = P_POS THEN
                V_START := I + 1;
            ELSIF V_COUNT = P_POS + 1 THEN
                V_END := I - 1;
                RETURN TRIM(SUBSTR(P_LINE, V_START, V_END - V_START + 1));
            END IF;
        END IF;
    END LOOP;

    -- Si es el último campo
    IF V_COUNT = P_POS THEN
        RETURN TRIM(SUBSTR(P_LINE, V_START));
    END IF;

    RETURN NULL;
END;
/

/*
-- FUNCION AUXILIAR PARA EXTRAER CAMPOS DE UNA LINEA CSV
CREATE OR REPLACE FUNCTION UTIL_GET_FIELD(P_LINE VARCHAR2, P_POS NUMBER) RETURN VARCHAR2 IS
    V_START NUMBER := 1;
    V_END NUMBER;
    V_COUNT NUMBER := 1;
    V_CHAR VARCHAR2(2); -- usa el 2 por posbles errores con el tamaño de caracteres
BEGIN
    -- Si la posición es 1, buscamos hasta la primera coma
    IF P_POS = 1 THEN
        V_END := INSTR(P_LINE, ',', 1, 1);
        IF V_END = 0 THEN
            RETURN P_LINE;
        ELSE
            RETURN SUBSTR(P_LINE, 1, V_END - 1);
        END IF;
    END IF;

    -- Para posiciones > 1
    FOR I IN 1..LENGTH(P_LINE) LOOP
        V_CHAR := SUBSTR(P_LINE, I, 1);
        IF V_CHAR = ',' THEN
            V_COUNT := V_COUNT + 1;
            IF V_COUNT = P_POS THEN
                V_START := I + 1;
            ELSIF V_COUNT = P_POS + 1 THEN
                V_END := I - 1;
                RETURN SUBSTR(P_LINE, V_START, V_END - V_START + 1);
            END IF;
        END IF;
    END LOOP;

    -- Si es el último campo
    IF V_COUNT = P_POS THEN
        RETURN SUBSTR(P_LINE, V_START);
    END IF;

    RETURN NULL;
END;
/
*/
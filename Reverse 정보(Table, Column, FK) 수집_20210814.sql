-- TABLE 목록
SELECT ROW_NUMBER() OVER(ORDER BY A.OWNER, A.TABLE_NAME) AS RNO
      ,'모델1' AS 모델명, '주제영역1' AS 주제영역명, '그룹1' AS 엔터티그룹명
      ,CASE
         WHEN INSTR(T.COMMENTS, CHR(10)) > 0 THEN A.TABLE_NAME -- COMMENT에 행분리 문자가 있는 경우 엔터티명 부적합하여 테이블명으로 사용
         WHEN T.COMMENTS IS NOT NULL THEN T.COMMENTS
         ELSE A.TABLE_NAME
       END AS 엔터티명
      ,A.TABLE_NAME AS 테이블명
      ,TRIM(TO_CHAR(A.NUM_ROWS, '9,999,999,999,999')) AS 동의어 -- 동의어에 총건수를 문자형으로 추출(comma 포함)
      ,A.TABLE_NAME AS 보조명
      ,A.OWNER AS DBOWNER
      ,NULL AS 분류, NULL AS "LEVEL", NULL AS 단계, NULL AS 유형, NULL AS 표준화, NULL AS 상태, NULL AS 발생주기, NULL AS 월간발생량, NULL AS "보존기한(월)"
      ,A.NUM_ROWS 총건수
      ,T.COMMENTS AS 정의
      ,NULL AS 데이터처리형태, NULL AS 특이사항, NULL AS Note, NULL AS TAG
      ,O.CREATED, O.LAST_DDL_TIME, A.LAST_ANALYZED, A.TEMPORARY
      ,'[COMMENT]: ' || T.COMMENTS || CHR(13) || CHR(10) ||
       '[NUM_ROWS]: ' || TRIM(TO_CHAR(A.NUM_ROWS, '9,999,999,999,999')) || CHR(13) || CHR(10) ||
       '[CREATED]: ' || TO_CHAR(O.CREATED, 'YYYY-MM-DD HH24:MI:SS') || CHR(13) || CHR(10) ||
       '[LAST_DDL_TIME]: ' || TO_CHAR(O.LAST_DDL_TIME, 'YYYY-MM-DD HH24:MI:SS') || CHR(13) || CHR(10) ||
       '[LAST_ANALYZED]: ' || TO_CHAR(A.LAST_ANALYZED, 'YYYY-MM-DD HH24:MI:SS') AS 정의2
  FROM DBA_TABLES A INNER JOIN DBA_OBJECTS O
         ON   ( A.OWNER = O.OWNER
            AND A.TABLE_NAME = O.OBJECT_NAME
            AND O.OBJECT_TYPE = 'TABLE')
       LEFT OUTER JOIN DBA_TAB_COMMENTS T
         ON   ( A.OWNER = T.OWNER
            AND A.TABLE_NAME = T.TABLE_NAME )
 WHERE 1=1
   AND A.TABLE_NAME NOT LIKE 'BIN$%'
   AND A.OWNER IN ('OWNER1', 'OWNER2')  -- 해당 OWNER 지정
--   AND A.TABLE_NAME = 'TABLE_NAME' -- 특정 TABLE만 포함 또는 제외
 ORDER  BY A.OWNER, A.TABLE_NAME
;

-- COLUMN 목록
WITH WC AS (
SELECT A.OWNER, A.TABLE_NAME, A.COLUMN_NAME, A.COLUMN_ID, A.DATA_TYPE
      ,CASE WHEN A.DATA_TYPE= 'NUMBER' AND A.DATA_SCALE > 0 THEN A.DATA_PRECISION||','||A.DATA_SCALE
            WHEN A.DATA_TYPE= 'NUMBER' AND A.DATA_SCALE = 0 THEN TO_CHAR(A.DATA_PRECISION)
            WHEN A.DATA_TYPE= 'NUMBER' AND A.DATA_SCALE IS NULL THEN ''
            WHEN A.DATA_TYPE IN ('DATE','TIMESTAMP','BLOB', 'CLOB')  THEN NULL
            WHEN A.DATA_TYPE LIKE 'TIMESTAMP%' THEN NULL
            ELSE TO_CHAR(A.DATA_LENGTH)
       END AS DATA_LENGTH
      ,A.DATA_PRECISION, A.DATA_SCALE
      ,DECODE(A.NULLABLE, 'Y','N','Y') AS NOT_NULL
      ,DECODE(B.COLUMN_NAME, NULL, 'N', 'Y') PRI_KEY
      ,B.POSITION PK_POSITION
      ,T.COMMENTS
      ,A.DEFAULT_LENGTH
--      ,A.DATA_DEFAULT
      ,CASE
         WHEN A.DEFAULT_LENGTH IS NULL THEN NULL
         ELSE EXTRACTVALUE
           ( DBMS_XMLGEN.GETXMLTYPE
             ( 'SELECT DATA_DEFAULT FROM DBA_TAB_COLUMNS WHERE OWNER = ''' || A.OWNER || ''' AND TABLE_NAME = ''' || A.TABLE_NAME || ''' AND COLUMN_NAME = ''' || A.COLUMN_NAME || '''' )
           , '//text()' )
       END AS DATA_DEFAULT
      ,A.LAST_ANALYZED, A.NUM_DISTINCT
--      ,A.LOW_VALUE
      ,DECODE(DATA_TYPE
              ,'NUMBER'       ,TO_CHAR(UTL_RAW.CAST_TO_NUMBER(LOW_VALUE))
              ,'VARCHAR2'     ,TO_SINGLE_BYTE(UTL_RAW.CAST_TO_VARCHAR2(LOW_VALUE))
              ,'CHAR'         ,TO_SINGLE_BYTE(UTL_RAW.CAST_TO_VARCHAR2(LOW_VALUE))
              ,'NVARCHAR2'    ,TO_CHAR(UTL_RAW.CAST_TO_NVARCHAR2(LOW_VALUE))
              ,'BINARY_DOUBLE',TO_CHAR(UTL_RAW.CAST_TO_BINARY_DOUBLE(LOW_VALUE))
              ,'BINARY_FLOAT' ,TO_CHAR(UTL_RAW.CAST_TO_BINARY_FLOAT(LOW_VALUE))
              ,'DATE',DECODE(LOW_VALUE, NULL, NULL, TO_CHAR(1780+TO_NUMBER(SUBSTR(LOW_VALUE,1,2),'XX')
                     +TO_NUMBER(SUBSTR(LOW_VALUE,3,2),'XX'))||'-'
                   ||TRIM(TO_CHAR(TO_NUMBER(SUBSTR(LOW_VALUE,5,2), 'XX'), '00'))||'-'
                   ||TRIM(TO_CHAR(TO_NUMBER(SUBSTR(LOW_VALUE,7,2), 'XX'), '00'))||' '
                   ||TRIM(TO_CHAR(TO_NUMBER(SUBSTR(LOW_VALUE,9,2),'XX')-1, '00'))||':'
                   ||TRIM(TO_CHAR(TO_NUMBER(SUBSTR(LOW_VALUE,11,2),'XX')-1, '00'))||':'
                   ||TRIM(TO_CHAR(TO_NUMBER(SUBSTR(LOW_VALUE,13,2),'XX')-1, '00')))
              ,LOW_VALUE
              ) LOW_VALUE
--      ,A.HIGH_VALUE
      ,DECODE(DATA_TYPE
              ,'NUMBER'       ,TO_CHAR(UTL_RAW.CAST_TO_NUMBER(HIGH_VALUE))
              ,'VARCHAR2'     ,TO_SINGLE_BYTE(UTL_RAW.CAST_TO_VARCHAR2(HIGH_VALUE))
              ,'CHAR'         ,TO_SINGLE_BYTE(UTL_RAW.CAST_TO_VARCHAR2(HIGH_VALUE))
              ,'NVARCHAR2'    ,TO_CHAR(UTL_RAW.CAST_TO_NVARCHAR2(HIGH_VALUE))
              ,'BINARY_DOUBLE',TO_CHAR(UTL_RAW.CAST_TO_BINARY_DOUBLE(HIGH_VALUE))
              ,'BINARY_FLOAT' ,TO_CHAR(UTL_RAW.CAST_TO_BINARY_FLOAT(HIGH_VALUE))
              ,'DATE',DECODE(HIGH_VALUE, NULL, NULL, TO_CHAR(1780+TO_NUMBER(SUBSTR(HIGH_VALUE,1,2),'XX')
                     +TO_NUMBER(SUBSTR(HIGH_VALUE,3,2),'XX'))||'-'
                   ||TRIM(TO_CHAR(TO_NUMBER(SUBSTR(HIGH_VALUE,5,2), 'XX'), '00'))||'-'
                   ||TRIM(TO_CHAR(TO_NUMBER(SUBSTR(HIGH_VALUE,7,2), 'XX'), '00'))||' '
                   ||TRIM(TO_CHAR(TO_NUMBER(SUBSTR(HIGH_VALUE,9,2),'XX')-1, '00'))||':'
                   ||TRIM(TO_CHAR(TO_NUMBER(SUBSTR(HIGH_VALUE,11,2),'XX')-1, '00'))||':'
                   ||TRIM(TO_CHAR(TO_NUMBER(SUBSTR(HIGH_VALUE,13,2),'XX')-1, '00')))
              ,HIGH_VALUE
               ) HIGH_VALUE
      ,TB.NUM_ROWS, A.NUM_NULLS, A.CHAR_USED, A.AVG_COL_LEN
  FROM DBA_TABLES TB LEFT OUTER JOIN DBA_TAB_COLUMNS A
         ON (TB.OWNER = A.OWNER
         AND TB.TABLE_NAME = A.TABLE_NAME)
       LEFT OUTER JOIN
       (SELECT C.OWNER, C.TABLE_NAME, C.COLUMN_NAME, C.POSITION
          FROM DBA_CONS_COLUMNS C INNER JOIN DBA_CONSTRAINTS S
                 ON  ( C.OWNER = S.OWNER
                   AND C.TABLE_NAME = S.TABLE_NAME
                   AND C.CONSTRAINT_NAME = S.CONSTRAINT_NAME )
         WHERE S.CONSTRAINT_TYPE = 'P'
       ) B
         ON  ( A.OWNER = B.OWNER
           AND A.TABLE_NAME = B.TABLE_NAME
           AND A.COLUMN_NAME = B.COLUMN_NAME )
       LEFT OUTER JOIN ALL_COL_COMMENTS T
         ON  ( T.OWNER = A.OWNER
           AND T.TABLE_NAME = A.TABLE_NAME
           AND T.COLUMN_NAME = A.COLUMN_NAME )
 WHERE 1=1
   AND A.OWNER IN ('OWNER1', 'OWNER2')  -- 해당 OWNER 지정
   AND A.TABLE_NAME NOT LIKE 'BIN$%'
   AND NOT EXISTS ( SELECT 'X'  -- View column 제외 조건
                      FROM DBA_VIEWS V
                     WHERE V.OWNER = A.OWNER
                       AND V.VIEW_NAME = A.TABLE_NAME )
   --AND A.TABLE_NAME = 'TABLE_NAME'
-- ORDER BY OWNER, TABLE_NAME, COLUMN_ID
)
SELECT ROW_NUMBER() OVER(ORDER BY OWNER, TABLE_NAME, COLUMN_ID) AS RNO
--      ,ROW_NUMBER() OVER(PARTITION BY OWNER, TABLE_NAME ORDER BY COLUMN_ID) AS COLNO
      ,'모델1' AS 모델명
      ,'' AS 엔터티명
      ,CASE
         WHEN INSTR(COMMENTS, CHR(10)) > 0 THEN COLUMN_NAME -- COMMENT에 행분리 문자가 있는 경우 속성명 부적합하여 컬럼명으로 사용
         WHEN COMMENTS IS NOT NULL THEN COMMENTS
         ELSE COLUMN_NAME
       END AS 속성명
      ,TABLE_NAME AS 테이블명
      ,COLUMN_NAME AS 컬럼명
      ,COMMENTS AS 정의
      ,COLUMN_NAME AS 보조명
      ,COLUMN_NAME AS 동의어
      ,TABLE_NAME AS Reverse테이블명
      ,COLUMN_NAME AS Reverse컬럼명
      ,DATA_TYPE AS ReverseType
      ,DATA_LENGTH AS ReverseLENGTH
      ,PRI_KEY AS PK
      ,NOT_NULL AS NOTNULL
      ,NULL AS 유형
      ,DATA_TYPE AS 데이터타입
      ,DATA_PRECISION AS 길이
      ,DATA_SCALE AS 소수점
      ,DATA_DEFAULT AS 기본값
      ,NULL AS 기본값, NULL AS 도메인, NULL AS "FK", NULL AS 핵심속성여부, NULL AS 본질식별자여부
      ,NULL AS 보조식별자여부, NULL AS 표준동기화여부, NULL AS 비상속여부, NULL AS 표준화
      ,NULL AS 정보보호여부, NULL AS 정보보호등급, NULL AS 암호화여부, NULL AS 스크램블
      ,'[COMMENT]: ' || COMMENTS || CHR(13) || CHR(10) ||
       '[NUM_ROWS]: ' || TRIM(TO_CHAR(NUM_ROWS, '9,999,999,999,999')) || CHR(13) || CHR(10) ||
       '[NUM_DISTINCT]: ' || TRIM(TO_CHAR(NUM_DISTINCT, '9,999,999,999,999')) || CHR(13) || CHR(10) ||
       '[NUM_NULLS]: ' || TRIM(TO_CHAR(NUM_NULLS, '9,999,999,999,999')) || CHR(13) || CHR(10) ||
       '[NULL%] : ' || DECODE(NVL(NUM_ROWS, 0), 0, 0, ROUND(NUM_NULLS / NUM_ROWS, 5) * 100) || '%' || CHR(13) || CHR(10) ||
       '[MIN_VALUE]: ' || LOW_VALUE || CHR(13) || CHR(10) ||
       '[MAX_VALUE]: ' || HIGH_VALUE  AS 정의2
--      ,WC.*
  FROM WC
 WHERE NUM_NULLS > 0
 ORDER BY OWNER, TABLE_NAME, COLUMN_ID
;

-- FK 목록
WITH WFK AS (
SELECT DISTINCT
       C2.OWNER AS P_OWNER
      ,C2.TABLE_NAME P_TABLE_NAME
      ,LISTAGG (C2.COLUMN_NAME, ',') WITHIN GROUP (ORDER BY C2.POSITION)
         OVER ( PARTITION BY C1.OWNER, C1.TABLE_NAME, C1.CONSTRAINT_NAME, C2.OWNER, C2.TABLE_NAME) AS P_COLUMN_LIST
      ,C1.OWNER AS C_OWNER
      ,C1.TABLE_NAME AS C_TABLE_NAME
      ,C1.CONSTRAINT_NAME AS C_CONSTRAINT_NAME
  FROM DBA_CONSTRAINTS C1 INNER JOIN DBA_CONS_COLUMNS C2
         ON (C1.R_CONSTRAINT_NAME = C2.CONSTRAINT_NAME
         AND C1.R_OWNER = C2.OWNER)
 WHERE C1.OWNER IN ('OWNER1', 'OWNER2')  -- 해당 DB의 테이블 OWNER 지정
   AND C1.CONSTRAINT_TYPE = 'R'
 ORDER BY C2.OWNER, C2.TABLE_NAME
)
SELECT '모델1' AS 모델명
      ,P_TABLE_NAME AS 부모엔터티명
      ,P_TABLE_NAME AS 부모테이블명
      ,C_TABLE_NAME AS 자식엔터티명
      ,C_TABLE_NAME AS 자식테이블명
      ,P_TABLE_NAME || '->' || C_TABLE_NAME AS 관계명
      ,NULL AS 정의, NULL AS 관계유형, NULL AS 기수성, NULL AS 선택성, NULL AS 식별성
      ,NULL AS 부모엔터티관계동사, NULL AS 자식엔터티관계동사
  FROM WFK
;

-- phpMyAdmin SQL Dump
-- version 5.1.0
-- https://www.phpmyadmin.net/
--
-- Servidor: localhost
-- Tiempo de generación: 27-03-2022 a las 08:44:37
-- Versión del servidor: 5.7.32-35-log
-- Versión de PHP: 7.4.28

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Base de datos: dbugotkgu8banw
--

DELIMITER $$
--
-- Procedimientos
--
CREATE  PROCEDURE MOV_UP_BUSCAR_EMPLEADO_PERMISOV2 (IN IN_per_documento VARCHAR(50), IN IN_id_sede INT)  BEGIN
    declare con varchar(100);
    set con=concat('%',IN_per_documento,'%');
     SELECT 
        DISTINCT
        pe.id_persona,
        pe.per_nombre,
        pe.per_apellido_paterno,
        pe.per_apellido_materno,
        pe.id_nacionalidad,
        pe.id_tpdocumento,
        pe.per_documento,
        CONCAT(per_nombre," ",per_apellido_paterno," ",per_apellido_materno) AS datos,
        ca.id_cargo,
        ca.ca_descripcion,
        se.id_sede,
        se.se_descripcion,
        se.se_lugar,
        1 id_sueldo
    FROM persona pe 
    INNER JOIN empleado em on pe.id_persona = em.id_persona 
    INNER JOIN sede_empleado she on she.id_persona = em.id_persona and she.sm_estado = 1
    INNER JOIN sede se on se.id_sede = she.id_sede
    INNER JOIN cargos_empleado ehc on ehc.id_persona = em.id_persona and ehc.ce_estado = 1
    INNER JOIN cargo ca on ca.id_cargo = ehc.id_cargo
    WHERE pe.per_documento like con and she.id_sede = IN_id_sede;

END$$

CREATE  PROCEDURE MOV_UP_BUSCAR_PERSONA_SUPLENTE_DOCUMENTO_TAREO (IN IN_per_documento VARCHAR(50))  BEGIN
    declare con varchar(100);
    set con=concat('%',IN_per_documento,'%');

    ## PERSONAS QUE SOLO SEAN EMPLEADO
 
    CREATE TEMPORARY TABLE TEMP_PERSONAS (
        id_persona int,
        id_nacionalidad int,
        id_tpdocumento varchar(50),
        per_nombre varchar(70),
        per_apellido_paterno varchar(70),
        per_apellido_materno varchar(70),
        per_documento varchar(70),
        datos  varchar(255),
        ca_descripcion varchar(255),
        se_descripcion varchar(255),
        banco  varchar(255),
        phb_cuenta varchar(255),
        phb_cci varchar(255),
        tpc_descripcion varchar(255) 
    );

    INSERT INTO TEMP_PERSONAS
    SELECT 
        pe.id_persona,
        pe.id_nacionalidad,
        pe.id_tpdocumento,
        pe.per_nombre,
        pe.per_apellido_paterno,
        pe.per_apellido_materno,
        pe.per_documento,
        CONCAT(per_nombre," ",per_apellido_paterno," ",per_apellido_materno) AS datos,
        ca.ca_descripcion,
        se.se_descripcion,
        CONCAT(ba_abreviatura," - ",ba_nombre) AS banco,
        phb.phb_cuenta,
        phb.phb_cci,
        tp.tpc_descripcion
    FROM persona pe 
    INNER JOIN empleado em on pe.id_persona = em.id_persona
    INNER JOIN sede_empleado she on she.id_persona = em.id_persona and she.sm_estado = 1 
    INNER JOIN sede se on se.id_sede = she.id_sede
    INNER JOIN cargos_empleado ce on ce.id_persona = em.id_persona and ce.ce_estado = 1
    INNER JOIN cargo ca on ca.id_cargo = ce.id_cargo
    INNER JOIN persona_has_banco phb on phb.id_persona = em.id_persona and phb.phb_estado = 1 
    INNER JOIN banco ba on ba.id_banco = phb.id_banco
    inner join tipo_cuenta tp on phb.id_tpcuenta = tp.id_tpcuenta
    WHERE pe.per_documento like con or CONCAT(per_nombre,per_apellido_paterno,per_apellido_materno) like con and pe.pe_estado <> 0;

    INSERT INTO TEMP_PERSONAS
    SELECT 
        pe.id_persona,
        pe.id_nacionalidad,
        pe.id_tpdocumento,
        pe.per_nombre,
        pe.per_apellido_paterno,
        pe.per_apellido_materno,
        pe.per_documento,
        CONCAT(per_nombre," ",per_apellido_paterno," ",per_apellido_materno) AS datos,
        '',
        '',
        CONCAT(ba_abreviatura," - ",ba_nombre) AS banco,
        phb.phb_cuenta,
        phb.phb_cci,
        tp.tpc_descripcion
    FROM persona pe 
    INNER JOIN persona_has_banco phb on phb.id_persona = pe.id_persona and phb.phb_estado = 1
    INNER JOIN banco ba on ba.id_banco = phb.id_banco
    inner join tipo_cuenta tp on phb.id_tpcuenta = tp.id_tpcuenta
    WHERE pe.per_documento like con or CONCAT(per_nombre,per_apellido_paterno,per_apellido_materno) like con and pe.pe_estado <> 0;

    SELECT DISTINCT 
        id_persona,
        id_nacionalidad,
        id_tpdocumento,
        per_nombre,
        per_apellido_paterno,
        per_apellido_materno,
        per_documento,
        datos,
        banco,
        phb_cuenta,
        phb_cci,
        tpc_descripcion
    FROM TEMP_PERSONAS;

END$$

CREATE  PROCEDURE MOV_UP_BUSCAR_TAREO_OPERADOR (IN IN_fechaInicio VARCHAR(50), IN IN_fechaFin VARCHAR(50), IN IN_documento VARCHAR(50), IN IN_idMarcador VARCHAR(50))  BEGIN 
    IF IN_idMarcador = 0 
    THEN
            SELECT  
            LPAD(ta.id_tareo,7,'0') as id_tareo, 
            pe.per_documento,
            CONCAT(pe.per_nombre," ",pe.per_apellido_paterno," ",pe.per_apellido_materno) AS datos,
            date(ta.ta_fecha_r) as ta_fecha_r,
            ta.ta_hora_r, 
            case ta.ta_etapa
                when 0 then ' - '
                when 1 then date(ta.ta_fecha_c)
            end as ta_fecha_c, 
            case ta.ta_etapa
                when 0 then ' - '
                when 1 then ta.ta_hora_c
            end as ta_hora_c,
            ta.ta_estado estado_nr,
            case
            when ta.ta_estado  = 1 
            then 
                 case 
                 when ta.ta_etapa = 0 AND ta.id_marcador  NOT IN (6,4,5)
                 then
                    'PENDIENTE POR CERRAR'
                 when ta.ta_etapa = 1 AND ta.id_marcador  NOT IN (6,4,5)
                 then 
                    'CERRADO'
                 else
                    'ACTIVO'
                 end
            when ta.ta_estado  =  0 
            then 
                'INACTIVO'
            end as estado,
            ca.id_cargo, 
            ca.ca_descripcion,
            ma.id_marcador,
            CONCAT(ma_abreviatura," - ",ma_descripcion) AS marcador,
            case 
            when ta.id_marcador  = 6 and ta.ta_remunerado = 0
            then 
                '0.00'
            when ta.id_marcador  = 6 and ta.ta_remunerado = 1 and ta.ta_estado = 1
            then 
                fun_getCostoPorDiaEmpleadoReporte(ta.id_persona, ta.ta_fecha_r)
            when ta.id_marcador  =  4 and ta.ta_estado = 1
            then 
                'POR DETERMINAR'
            when ta.id_marcador  =  3 and ta.ta_estado = 1
            then 
                ROUND(fun_getCostoPorDiaEmpleadoReporte(ta.id_persona, ta.ta_fecha_r) * 1.36, 2)
            when ta.id_marcador  =  2 and ta.ta_estado = 1
            then 
                fun_getCostoPorDiaEmpleadoReporte(ta.id_persona, ta.ta_fecha_r)
            when ta.id_marcador  =  1 and ta.ta_estado = 1
            then 
                fun_getCostoPorDiaEmpleadoReporte(ta.id_persona, ta.ta_fecha_r)
            when ta.id_marcador  =  5
            then 
                '0.00'
            else 
                '0.00' 
            end as pagoXEsteDia
            from tareo ta
            INNER JOIN persona pe ON pe.id_persona = ta.id_persona 
            INNER JOIN empleado em on em.id_persona = pe.id_persona  
            INNER JOIN sede se on ta.id_sede = se.id_sede 
            INNER JOIN cargo ca on ca.id_cargo = ta.id_cargo
            INNER JOIN marcador ma on ma.id_marcador = ta.id_marcador
            WHERE 
            pe.per_documento = IN_documento
            AND Date(ta.ta_fecha_r) BETWEEN Date(IN_fechaInicio) and Date(IN_fechaFin)
            AND ta.ta_estado = 1
            order by ta.ta_fecha_r ASC; 
    ELSE
        
        SELECT  
            LPAD(ta.id_tareo,7,'0') as id_tareo, 
            pe.per_documento,
            CONCAT(pe.per_nombre," ",pe.per_apellido_paterno," ",pe.per_apellido_materno) AS datos,
            date(ta.ta_fecha_r) as ta_fecha_r,
            ta.ta_hora_r, 
            case ta.ta_etapa
                when 0 then ' - '
                when 1 then date(ta.ta_fecha_c)
            end as ta_fecha_c, 
            case ta.ta_etapa
                when 0 then ' - '
                when 1 then ta.ta_hora_c
            end as ta_hora_c,
            ta.ta_estado estado_nr,
            case
            when ta.ta_estado  = 1 
            then 
                 case 
                 when ta.ta_etapa = 0 AND ta.id_marcador  NOT IN (6,4,5)
                 then
                    'PENDIENTE POR CERRAR'
                 when ta.ta_etapa = 1 AND ta.id_marcador  NOT IN (6,4,5)
                 then 
                    'CERRADO'
                 else
                    'ACTIVO'
                 end
            when ta.ta_estado  =  0 
            then 
                'INACTIVO'
            end as estado,
            ca.id_cargo, 
            ca.ca_descripcion,
            ma.id_marcador,
            CONCAT(ma_abreviatura," - ",ma_descripcion) AS marcador,
            case 
            when ta.id_marcador  = 6 and ta.ta_remunerado = 0
            then 
                '0.00'
            when ta.id_marcador  = 6 and ta.ta_remunerado = 1 and ta.ta_estado = 1
            then 
                fun_getCostoPorDiaEmpleadoReporte(ta.id_persona, ta.ta_fecha_r)
            when ta.id_marcador  =  4 and ta.ta_estado = 1
            then 
                'POR DETERMINAR'
            when ta.id_marcador  =  3 and ta.ta_estado = 1
            then 
                ROUND(fun_getCostoPorDiaEmpleadoReporte(ta.id_persona, ta.ta_fecha_r) * 1.36, 2)
            when ta.id_marcador  =  2 and ta.ta_estado = 1
            then 
                fun_getCostoPorDiaEmpleadoReporte(ta.id_persona, ta.ta_fecha_r)
            when ta.id_marcador  =  1 and ta.ta_estado = 1
            then 
                fun_getCostoPorDiaEmpleadoReporte(ta.id_persona, ta.ta_fecha_r)
            when ta.id_marcador  =  5
            then 
                '0.00'
            else 
                '0.00' 
            end as pagoXEsteDia
            from tareo ta
            INNER JOIN persona pe ON pe.id_persona = ta.id_persona 
            INNER JOIN empleado em on em.id_persona = pe.id_persona  
            INNER JOIN sede se on ta.id_sede = se.id_sede 
            INNER JOIN cargo ca on ca.id_cargo = ta.id_cargo
            INNER JOIN marcador ma on ma.id_marcador = ta.id_marcador
            WHERE ma.id_marcador = IN_idMarcador 
            AND pe.per_documento = IN_documento
            AND Date(ta.ta_fecha_r) BETWEEN Date(IN_fechaInicio) and Date(IN_fechaFin)
            AND ta.ta_estado = 1
            order by ta.ta_fecha_r ASC;   
    END IF;
END$$

CREATE  PROCEDURE MOV_UP_BUSCAR_TAREO_SUPERVISOR (IN IN_fechaInicio VARCHAR(50), IN IN_fechaFin VARCHAR(50), IN IN_documento VARCHAR(50), IN IN_idMarcador VARCHAR(50), IN IN_idSede INT)  BEGIN 

    IF IN_idMarcador = 0 
    THEN
            SELECT  
            LPAD(ta.id_tareo,7,'0') as id_tareo, 
            pe.per_documento,
            CONCAT(pe.per_nombre," ",pe.per_apellido_paterno," ",pe.per_apellido_materno) AS datos,
            date(ta.ta_fecha_r) as ta_fecha_r,
            ta.ta_hora_r, 
            case ta.ta_etapa
                when 0 then ' - '
                when 1 then date(ta.ta_fecha_c)
            end as ta_fecha_c, 
            case ta.ta_etapa
                when 0 then ' - '
                when 1 then ta.ta_hora_c
            end as ta_hora_c,
            ta.ta_estado estado_nr, 
            case
            when ta.ta_estado  = 1 
            then 
                 case 
                 when ta.ta_etapa = 0 AND ta.id_marcador  NOT IN (6,4,5)
                 then
                    'PENDIENTE POR CERRAR'
                 when ta.ta_etapa = 1 AND ta.id_marcador  NOT IN (6,4,5)
                 then 
                    'CERRADO'
                 else
                    'ACTIVO'
                 end
            when ta.ta_estado  =  0 
            then 
                'INACTIVO'
            end as estado, 
            ca.id_cargo, 
            ca.ca_descripcion,
            ma.id_marcador,
            CONCAT(ma_abreviatura," - ",ma_descripcion) AS marcador
             from tareo ta
            INNER JOIN persona pe ON pe.id_persona = ta.id_persona 
            INNER JOIN empleado em on em.id_persona = pe.id_persona  
            INNER JOIN sede se on ta.id_sede = se.id_sede 
            INNER JOIN cargo ca on ca.id_cargo = ta.id_cargo
            INNER JOIN marcador ma on ma.id_marcador = ta.id_marcador
            WHERE 
            pe.per_documento like concat('%',IN_documento,'%') 
            AND Date(ta.ta_fecha_r) BETWEEN Date(IN_fechaInicio) and Date(IN_fechaFin)
            AND ta.id_sede = IN_idSede 
            AND ta.ta_estado = 1
            order by UPPER (CONCAT(pe.per_nombre," ",pe.per_apellido_paterno," ",pe.per_apellido_materno)), ta.ta_fecha_r ASC; 
    ELSE
        
        SELECT  
            LPAD(ta.id_tareo,7,'0') as id_tareo, 
            pe.per_documento,
            CONCAT(pe.per_nombre," ",pe.per_apellido_paterno," ",pe.per_apellido_materno) AS datos,
            date(ta.ta_fecha_r) as ta_fecha_r,
            ta.ta_hora_r, 
            case ta.ta_etapa
                when 0 then ' - '
                when 1 then date(ta.ta_fecha_c)
            end as ta_fecha_c, 
            case ta.ta_etapa
                when 0 then ' - '
                when 1 then ta.ta_hora_c
            end as ta_hora_c,
            ta.ta_estado estado_nr,
            case
            when ta.ta_estado  = 1 
            then 
                 case 
                 when ta.ta_etapa = 0 AND ta.id_marcador  NOT IN (6,4,5)
                 then
                    'PENDIENTE POR CERRAR'
                 when ta.ta_etapa = 1 AND ta.id_marcador  NOT IN (6,4,5)
                 then 
                    'CERRADO'
                 else
                    'ACTIVO'
                 end
            when ta.ta_estado  =  0 
            then 
                'INACTIVO'
            end as estado,
            ca.id_cargo, 
            ca.ca_descripcion,
            ma.id_marcador,
            CONCAT(ma_abreviatura," - ",ma_descripcion) AS marcador
             from tareo ta
            INNER JOIN persona pe ON pe.id_persona = ta.id_persona 
            INNER JOIN empleado em on em.id_persona = pe.id_persona  
            INNER JOIN sede se on ta.id_sede = se.id_sede 
            INNER JOIN cargo ca on ca.id_cargo = ta.id_cargo
            INNER JOIN marcador ma on ma.id_marcador = ta.id_marcador
            WHERE ma.id_marcador = IN_idMarcador AND  
             pe.per_documento like concat('%',IN_documento,'%') 
             AND Date(ta.ta_fecha_r) BETWEEN Date(IN_fechaInicio) and Date(IN_fechaFin)
             AND ta.id_sede = IN_idSede 
             AND ta.ta_estado = 1
             order by UPPER (CONCAT(pe.per_nombre," ",pe.per_apellido_paterno," ",pe.per_apellido_materno)), ta.ta_fecha_r ASC;  
    END IF;

END$$

CREATE  PROCEDURE MOV_UP_LISTAR_CARGO ()  BEGIN

SELECT 
id_cargo,
ca_descripcion,
ca_abreviatura,
ca_estado,
IF(ca_estado = 0, 'INACTIVO', 'ACTIVO') as estado, 
CONCAT(ca_abreviatura," - ",ca_descripcion) AS datos
,userCreacion
,fechaCreacion
,userModificacion
,fechaModificacion
,flEliminado
FROM cargo where ca_estado = 1 and id_cargo in(1,3);

END$$

CREATE  PROCEDURE MOV_UP_LISTAR_NACIONALIDAD ()  BEGIN

SELECT 
id_nacionalidad,
na_descripcion,
na_abreviatura,
na_estado,
IF(na_estado = 0, 'INACTIVO', 'ACTIVO') as estado,
CONCAT(na_abreviatura," - ",na_descripcion) AS datos
FROM nacionalidad where na_estado = 1;

END$$

CREATE  PROCEDURE MOV_UP_LISTAR_PERMISO ()  BEGIN

SELECT 
id_permiso,
pe_descripcion,
pe_estado,
IF(pe_estado = 0, 'INACTIVO', 'ACTIVO') as estado,
pe_nombre
FROM permiso where pe_estado = 1;

END$$

CREATE  PROCEDURE MOV_UP_LISTAR_SEDE ()  begin
	
SELECT 
id_sede,
se_descripcion,
se_lugar,
se_cantidad,
se_estado,
IF(se_estado = 0, 'INACTIVO', 'ACTIVO') as estado,
CONCAT(se_lugar," - ",se_descripcion) AS datos
FROM sede WHERE se_estado = 1;

END$$

CREATE  PROCEDURE MOV_UP_LISTAR_TIPO_DOCUMENTO ()  BEGIN

SELECT 
id_tpdocumento,
tpd_estado,
IF(tpd_estado = 0, 'INACTIVO', 'ACTIVO') as estado,
tpd_descripcion,
tpd_abreviatura,
CONCAT(tpd_abreviatura," - ",tpd_descripcion) AS datos,
tpd_longitud
FROM tipo_documento WHERE tpd_estado = 1;

END$$

CREATE  PROCEDURE MOV_UP_REGISTRO_DESCANSO_FALTA_TAREO (IN IN_id_persona INT, IN IN_id_tpdocumento VARCHAR(50), IN IN_id_nacionalidad INT, IN IN_id_cargo INT, IN IN_id_sede INT, IN IN_trs_remunerado INT, IN IN_ta_estado INT, IN IN_trs_fecha_r DATETIME, IN IN_trs_fecha_c DATETIME, IN IN_trs_usuario INT, IN IN_id_sueldo INT, IN IN_id_marcador INT, IN IN_userCreacion VARCHAR(50))  BEGIN   
    DECLARE dec_pagado int;
    DECLARE dec_idMarcador int;  

    ## TRANSACCION
    DECLARE errno INT;
    DECLARE msg_errno TEXT;
    DECLARE msg TEXT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET CURRENT DIAGNOSTICS CONDITION 1 errno = MYSQL_ERRNO,msg_errno = MESSAGE_TEXT ; 
            ##SELECT msg_errno  AS MYSQL_ERROR;
            set msg = concat('- ', msg_errno);
            signal sqlstate '45000' set message_text = msg;
            #signal sqlstate MYSQL_ERROR set message_text = msg_errno;
        ROLLBACK;
    END;

START TRANSACTION;


if(IN_id_marcador = 4)
then
	if EXISTS(SELECT * FROM  tareo ta
	            INNER JOIN persona su
	            on ta.id_persona = su.id_persona
	            where su.id_persona = IN_id_persona  
	            and date(ta.ta_fecha_r) = date(IN_trs_fecha_r)
	            and ta.id_marcador  = 5
	            and ta.ta_estado = 1
	         	and su.pe_estado <> 0
	         ) 
	THEN
	    signal sqlstate '45000' set message_text = '¡Esta persona cuenta con una falta, no es posible registrar el descanso!';
	END IF;
end if;

if(IN_id_marcador = 5)
then
	if EXISTS(SELECT * FROM  tareo ta
	            INNER JOIN persona su
	            on ta.id_persona = su.id_persona
	            where su.id_persona = IN_id_persona  
	            and date(ta.ta_fecha_r) = date(IN_trs_fecha_r)
	            and ta.id_marcador  = 4
	            and ta.ta_estado = 1
	         	and su.pe_estado <> 0
	         ) 
	THEN
	    signal sqlstate '45000' set message_text = '¡Esta persona cuenta con un descanso, no es posible registrar la falta!';
	END IF; 
end if;
 


if IN_id_marcador = 4
        then
           IF EXISTS(
                SELECT * FROM  tareo ta
                    INNER JOIN persona su
                    on ta.id_persona = su.id_persona
                    where su.id_persona = IN_id_persona  
                    and date(ta.ta_fecha_r) = date(IN_trs_fecha_r)
                    and ta.id_marcador  = 4
                    and ta.ta_estado = 1
               		and su.pe_estado <> 0
            )
            THEN 
                signal sqlstate '45000' set message_text = '¡Esta persona ya cuenta con un descanso registrado el día de hoy!';
            else
                INSERT INTO tareo(
                  id_sede, id_cargo,id_persona, id_sueldo, id_marcador, 
                  ta_remunerado, ta_estado, ta_fecha_r, 
                  ta_fecha_c, ta_hora_r, ta_hora_c, 
                  ta_hrstrabajadas, ta_usuario, ta_permiso
                  ,userCreacion,userModificacion
                ) 
                VALUES 
                  (
                    IN_id_sede, IN_id_cargo,IN_id_persona, IN_id_sueldo,IN_id_marcador, 
                    1, 1, IN_trs_fecha_r, 
                    IN_trs_fecha_r, '00:00:00', '00:00:00', 
                    0, IN_trs_usuario, 0
                    ,IN_userCreacion
                    ,IN_userCreacion

                  );
            end if;  
elseif IN_id_marcador = 5
then
            IF EXISTS(
                SELECT * FROM  tareo ta
                    INNER JOIN persona su
                    on ta.id_persona = su.id_persona
                    where su.id_persona = IN_id_persona
                    and date(ta.ta_fecha_r) = date(IN_trs_fecha_r)
                    and ta.id_marcador  = 5
                    and ta.ta_estado = 1
                    and su.pe_estado <> 0
            )
            THEN 
                signal sqlstate '45000' set message_text = '¡Esta persona ya cuenta con una falta registrada el día de hoy!';
            else

                INSERT INTO tareo(
                      id_sede, id_cargo,id_persona, id_sueldo, id_marcador, 
                      ta_remunerado, ta_estado, ta_fecha_r, 
                      ta_fecha_c, ta_hora_r, ta_hora_c, 
                      ta_hrstrabajadas, ta_usuario, ta_permiso,userCreacion,userModificacion
                    ) 
                    VALUES 
                    (
                        IN_id_sede, IN_id_cargo,IN_id_persona, IN_id_sueldo,IN_id_marcador, 
                        0, 1, IN_trs_fecha_r, 
                        IN_trs_fecha_r, '00:00:00', '00:00:00', 
                        0, IN_trs_usuario, 0
                        ,IN_userCreacion
,IN_userCreacion

                    ); 
                
            end if; 
end if; 
 
## RETURN TO TABLES...
COMMIT WORK;

END$$

CREATE  PROCEDURE MOV_UP_REGISTRO_PERMISO_TAREO (IN IN_id_permiso INT, IN IN_id_persona INT, IN IN_id_tpdocumento VARCHAR(50), IN IN_id_nacionalidad INT, IN IN_id_cargo INT, IN IN_id_sede INT, IN IN_trs_remunerado INT, IN IN_ta_estado INT, IN IN_trs_fecha_r DATETIME, IN IN_trs_fecha_c DATETIME, IN IN_trs_usuario INT, IN IN_id_sueldo INT, IN IN_id_marcador INT, IN IN_userCreacion VARCHAR(50))  BEGIN   
    DECLARE dec_pagado int;
    DECLARE dec_idMarcador int; 
    DECLARE dec_idPermiso int; 

    ## TRANSACCION
    DECLARE errno INT;
    DECLARE msg_errno TEXT;
    DECLARE msg TEXT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET CURRENT DIAGNOSTICS CONDITION 1 errno = MYSQL_ERRNO,msg_errno = MESSAGE_TEXT ; 
            ##SELECT msg_errno  AS MYSQL_ERROR;
            set msg = concat('TRY: ', msg_errno);
            signal sqlstate '45000' set message_text = msg;
            #signal sqlstate MYSQL_ERROR set message_text = msg_errno;
        ROLLBACK;
    END;

START TRANSACTION;

IF IN_trs_remunerado = 1
then
    set dec_pagado = 1;
else
    set dec_pagado = 0;
end if;

IF IN_id_marcador = 6
then
    set dec_idPermiso = IN_id_permiso;
else
    set dec_idPermiso = 0;
end if;

if EXISTS(SELECT * FROM  tareo ta
            INNER JOIN persona su
            on ta.id_persona = su.id_persona
            where su.id_persona = IN_id_persona  
            and date(ta.ta_fecha_r) = date(IN_trs_fecha_r)
            and ta.id_marcador  = 5
            and ta.ta_estado = 1
         	and su.pe_estado <> 0
         ) 
THEN
    signal sqlstate '45000' set message_text = 'Esta persona tiene registrado una falta el dia de hoy!';
END IF; 

if EXISTS(SELECT * FROM  tareo ta
            INNER JOIN persona su
            on ta.id_persona = su.id_persona
            where su.id_persona = IN_id_persona  
            and date(ta.ta_fecha_r) = date(IN_trs_fecha_r)
            and ta.id_marcador  = 4
            and ta.ta_estado = 1
         	and su.pe_estado <> 0
         ) 
THEN
    signal sqlstate '45000' set message_text = 'Esta persona tiene registrado un descanso el dia de hoy!';
END IF; 

IF EXISTS(
    SELECT * FROM  tareo ta
            INNER JOIN persona su
            on ta.id_persona = su.id_persona
            where su.id_persona = IN_id_persona  
            and date(ta.ta_fecha_r) = date(IN_trs_fecha_r)
            and ta.id_marcador  = 6
            and ta.ta_estado = 1
    		and su.pe_estado <> 0
)
THEN 
    signal sqlstate '45000' set message_text = 'Esta persona ya cuenta con un permiso registrado el dia de hoy!';
ELSE 
    INSERT INTO tareo(
      id_sede, id_cargo,id_persona, id_sueldo, id_marcador, 
      ta_remunerado, ta_estado, ta_fecha_r, 
      ta_fecha_c, ta_hora_r, ta_hora_c, 
      ta_hrstrabajadas, ta_usuario, ta_permiso,userCreacion,userModificacion
    ) 
    VALUES 
      (
        IN_id_sede, IN_id_cargo,IN_id_persona, IN_id_sueldo, 
        IN_id_marcador, dec_pagado, 1, IN_trs_fecha_r, 
        IN_trs_fecha_r, '00:00:00', '00:00:00', 
        0, IN_trs_usuario, dec_idPermiso
        ,IN_userCreacion
        ,IN_userCreacion
    ); 
END IF;   

## RETURN TO TABLES...
COMMIT WORK;

END$$

CREATE  PROCEDURE MOV_UP_SUPERVISOR_REGISTRAR_EMPLEADOV (IN IN_id_tpdocumento VARCHAR(80), IN IN_id_nacionalidad INT, IN IN_per_nombre VARCHAR(80), IN IN_per_apellido_paterno VARCHAR(80), IN IN_per_apellido_materno VARCHAR(80), IN IN_per_documento VARCHAR(80), IN IN_per_fecha_nac DATE, IN IN_per_celular VARCHAR(80), IN IN_per_correo VARCHAR(80), IN IN_per_nacionalidad INT, IN IN_pe_fecha_ingreso DATE, IN IN_pe_titular INT, IN IN_pe_usuario INT, IN IN_pe_sexo VARCHAR(1), IN IN_pe_direccion VARCHAR(80), IN IN_pe_estado INT, IN IN_empleado JSON, IN IN_pago JSON)  BEGIN

## DECLARACIONES
DECLARE dec_ID_PERSONA INT;
DECLARE dec_id_tpdocumento VARCHAR(80);
DECLARE dec_id_nacionalidad INT; 
declare dec_id_tpUsuario int;
declare dec_id_usuario int;

declare dia_descanso date;
declare acumulador date;
declare two_week date;
DECLARE dec_id_sueldo INT; 


DECLARE dec_json_empleado_items BIGINT UNSIGNED DEFAULT JSON_LENGTH(IN_empleado);
DECLARE dec_json_empleado_index BIGINT UNSIGNED DEFAULT 0;

DECLARE dec_json_pago_items BIGINT UNSIGNED DEFAULT JSON_LENGTH(IN_pago);
DECLARE dec_json_pago_index BIGINT UNSIGNED DEFAULT 0;
## END DECLARACIONES

## TRANSACCION
DECLARE errno INT;
DECLARE msg_errno TEXT;
DECLARE msg TEXT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET CURRENT DIAGNOSTICS CONDITION 1 errno = MYSQL_ERRNO,msg_errno = MESSAGE_TEXT ; 
            ##SELECT msg_errno  AS MYSQL_ERROR;
            set msg = concat(' ', msg_errno);
            signal sqlstate '45000' set message_text = msg;
            #signal sqlstate MYSQL_ERROR set message_text = msg_errno;
        ROLLBACK;
    END;

    START TRANSACTION;
## END TRANSACCION


IF EXISTS(
    SELECT 1 FROM  persona_has_listanegra a WHERE a.id_persona = (select id_persona from persona where per_documento = IN_per_documento)  and a.flEliminado = 1
)
THEN
    signal sqlstate '45000' set message_text = 'Esta persona está en la lista negra, por favor anúlelo y vuelva a intentarlo';
end if;


IF  JSON_VALID(IN_empleado) = 0
THEN
    signal sqlstate '45000' set message_text = 'Error datos incorrectos en el empleado!';
END IF; 

IF  JSON_VALID(IN_pago) = 0
THEN
    signal sqlstate '45000' set message_text = 'Error datos incorrectos en el Pago!';
END IF; 


        IF NOT EXISTS(
            SELECT 1 FROM  persona WHERE per_documento = IN_per_documento
        )
        THEN
            INSERT INTO persona(
              id_tpdocumento, id_nacionalidad, 
              per_nombre, per_apellido_paterno, 
              per_apellido_materno, per_documento, 
              per_fecha_nac, per_celular, per_correo, 
              per_nacionalidad, pe_fecha_ingreso, 
              pe_fecha_cese, pe_titular, pe_usuario, 
              pe_sexo, pe_direccion, pe_estado
            ) 
            VALUES 
              (
                IN_id_tpdocumento, IN_id_nacionalidad, 
                IN_per_nombre, IN_per_apellido_paterno, 
                IN_per_apellido_materno, IN_per_documento, 
                IN_per_fecha_nac, IN_per_celular, 
                IN_per_correo, IN_per_nacionalidad, 
                IN_pe_fecha_ingreso, IN_pe_fecha_ingreso, 
                IN_pe_titular, IN_pe_usuario, IN_pe_sexo, 
                IN_pe_direccion, IN_pe_estado
              ); 

        SELECT LAST_INSERT_ID() INTO dec_ID_PERSONA; 

        WHILE dec_json_empleado_index < dec_json_empleado_items DO
                        INSERT INTO empleado(
                          id_persona, phc_estado, phc_fecha_r, 
                          phc_fecha_c, phc_codigo
                        ) 
                        VALUES 
                        (
                            dec_ID_PERSONA, 3, IN_pe_fecha_ingreso, 
                            IN_pe_fecha_ingreso, 'CODIGO'
                        );
                       
                       
                        select 
                			a.id_tipoUsuario into dec_id_tpUsuario 
            			from cargo a where a.id_cargo  = JSON_UNQUOTE(JSON_EXTRACT(IN_empleado, CONCAT('$[', dec_json_empleado_index, '].cargo')));
            		
            				INSERT INTO usuario(
			                  id_tpusuario, us_usuario, us_contrasenia, 
			                  us_estado, us_fecha_r, us_fecha_c, 
			                  us_empleado, us_persona
			               ) 
			               VALUES 
			               (
			                        dec_id_tpUsuario, IN_per_documento, IN_per_documento, 
			                        1, NOW(), NOW(), dec_ID_PERSONA, dec_ID_PERSONA
			               );
			              
			              
			                select id_usuario into dec_id_usuario  from usuario where us_persona = dec_ID_PERSONA;
              
			                insert into sis_usuario_modperm(id_mpermiso, id_usuario,userCreacion, fechaCreacion,userModificacion, fechaModificacion, flEliminado)
			                select 
			                id_mpermiso, 
			                dec_id_usuario,
			                'JVERGARA',
			                curdate(),
			                'JVERGARA',
			                curdate(),
			                1
			                from sis_perfil_modperm a where a.id_tpusuario = dec_id_tpUsuario and a.flEliminado = 1;
			               
			               
			               INSERT INTO cargos_empleado(
				                id_persona, 
				                id_cargo, 
				                ce_fecha_r, 
				                ce_fecha_c, 
				                ce_estado, 
				                ce_observacion
				            )
				            VALUES (
				                dec_ID_PERSONA,
				                JSON_UNQUOTE(JSON_EXTRACT(IN_empleado, CONCAT('$[', dec_json_empleado_index, '].cargo'))),
				                IN_pe_fecha_ingreso,
				                IN_pe_fecha_ingreso,
				                1,
				                'OBSERVACION'
				            );
				           
				           
				            INSERT INTO sede_empleado(id_persona, id_sede, sm_codigo, sm_fecha_r, sm_fecha_c, sm_observacion, sm_estado) 
				            VALUES 
				            (
				                dec_ID_PERSONA,
				                JSON_UNQUOTE(JSON_EXTRACT(IN_empleado, CONCAT('$[', dec_json_empleado_index, '].sede'))),
				                'CODIGO',
				                IN_pe_fecha_ingreso,
				                IN_pe_fecha_ingreso,
				                'OBSERVACION',
				                1
				            );

                         

                        IF JSON_UNQUOTE(JSON_EXTRACT(IN_empleado, CONCAT('$[', dec_json_empleado_index, '].descansoReferencia'))) <> 'NONE'
			            THEN
			
			            INSERT INTO descanso(
			                id_persona,   
			                de_fecha, 
			                de_observacion, 
			                de_estado,
			                de_referencia
			            )VALUES (
			                dec_ID_PERSONA, 
			                JSON_UNQUOTE(JSON_EXTRACT(IN_empleado, CONCAT('$[', dec_json_empleado_index, '].descanso'))),
			                '',
			                1,
			                JSON_UNQUOTE(JSON_EXTRACT(IN_empleado, CONCAT('$[', dec_json_empleado_index, '].descansoReferencia')))
			            ); 
			
			            end if;

                        /*INSERT INTO sueldo(
                          id_persona, ta_basico, ta_estado, 
                          ta_observacion, ta_fecha_r, ta_fecha_c, 
                          ta_csdia, ta_asignacion_familiar, 
                          ta_bonificacion, ta_movilidad, ta_alimentos, 
                          ta_total,
                          ta_vigenciaInicio,
                          ta_vigenciaFin
                        ) 
                        VALUES 
                        (
                            dec_ID_PERSONA, 0, 3, '', NOW(), NOW(), 
                            0, 0, 0, 0, 0, 0,
                             NOW(),'2100-01-01'
                        ); */
                    SET dec_json_empleado_index := dec_json_empleado_index + 1;
            END WHILE;

        WHILE dec_json_pago_index < dec_json_pago_items DO

            IF JSON_UNQUOTE(JSON_EXTRACT(IN_pago, CONCAT('$[', dec_json_pago_index, '].tipo'))) = 0 THEN
              IF NOT EXISTS(select id_persona from persona where per_documento = JSON_UNQUOTE(JSON_EXTRACT(IN_pago, CONCAT('$[', dec_json_pago_index, '].documento'))))
              THEN
                  signal sqlstate '45000' set message_text = 'La persona suplente no existe!';
              ELSE
                  INSERT INTO suplente_cobrar(
                        id_persona,   
                        suc_estado,
                        suc_origen,
                        suc_observacion
                    ) VALUES (
                        (select id_persona from persona where per_documento = JSON_UNQUOTE(JSON_EXTRACT(IN_pago, CONCAT('$[', dec_json_pago_index, '].documento')))), 
                        1,
                        dec_ID_PERSONA,
                        ''
                    );
                END if;
            END IF;
            SET dec_json_pago_index := dec_json_pago_index + 1;
        END WHILE;

ELSE
      signal sqlstate '45000' set message_text = 'Esta persona ya esta registrada en el sistema!';
END IF; 

## RETURN TO TABLES...
COMMIT WORK;

END$$

CREATE  PROCEDURE MOV_UP_SUPERVISOR_REGISTRAR_SUPLENTE (IN IN_id_tpdocumento VARCHAR(80), IN IN_id_nacionalidad INT, IN IN_per_nombre VARCHAR(80), IN IN_per_apellido_paterno VARCHAR(80), IN IN_per_apellido_materno VARCHAR(80), IN IN_per_documento VARCHAR(80), IN IN_per_fecha_nac DATE, IN IN_per_celular VARCHAR(80), IN IN_per_correo VARCHAR(80), IN IN_per_nacionalidad INT, IN IN_pe_fecha_ingreso DATE, IN IN_pe_titular INT, IN IN_pe_usuario INT, IN IN_pe_sexo VARCHAR(1), IN IN_pe_direccion VARCHAR(80), IN IN_pe_estado INT)  BEGIN

## DECLARACIONES
DECLARE dec_ID_PERSONA INT;
DECLARE dec_id_tpdocumento VARCHAR(80);
DECLARE dec_id_nacionalidad INT; 
## END DECLARACIONES

## TRANSACCION
    DECLARE errno INT;
    DECLARE msg_errno TEXT;
    DECLARE msg TEXT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET CURRENT DIAGNOSTICS CONDITION 1 errno = MYSQL_ERRNO,msg_errno = MESSAGE_TEXT ; 
            ##SELECT msg_errno  AS MYSQL_ERROR;
            set msg = concat('M: ', msg_errno);
            signal sqlstate '45000' set message_text = msg;
            #signal sqlstate MYSQL_ERROR set message_text = msg_errno;
        ROLLBACK;
    END;

    START TRANSACTION;
## END TRANSACCION
  

IF NOT EXISTS(
    SELECT 1 FROM  persona WHERE per_documento = IN_per_documento
)
THEN
    INSERT INTO persona(
            id_tpdocumento, 
            id_nacionalidad, 
            per_nombre, 
            per_apellido_paterno, 
            per_apellido_materno, 
            per_documento, 
            per_fecha_nac, 
            per_celular, 
            per_correo, 
            per_nacionalidad,
            pe_fecha_ingreso, 
            pe_fecha_cese, 
            pe_titular, 
            pe_usuario, 
            pe_sexo, 
            pe_direccion,
            pe_estado
        ) VALUES 
        (
            IN_id_tpdocumento, 
            IN_id_nacionalidad, 
            IN_per_nombre, 
            IN_per_apellido_paterno, 
            IN_per_apellido_materno, 
            IN_per_documento, 
            IN_per_fecha_nac, 
            IN_per_celular, 
            IN_per_correo, 
            IN_per_nacionalidad,  
            IN_pe_fecha_ingreso, 
            IN_pe_fecha_ingreso, 
            IN_pe_titular, 
            IN_pe_usuario, 
            IN_pe_sexo, 
            IN_pe_direccion,
            IN_pe_estado
        ); 
ELSE
      signal sqlstate '45000' set message_text = 'Esta persona ya esta registrada en el sistema!';
END IF; 

## RETURN TO TABLES...
COMMIT WORK;

END$$

CREATE  PROCEDURE MOV_UP_UP_BUSCAR_TAREO_CIERRE_REGISTRO (IN IN_per_documento VARCHAR(100), IN IN_id_sede INT)  BEGIN

DECLARE DEC_TAREO INT DEFAULT 0 ;
   
IF (EXISTS(SELECT 
            *
        FROM
        persona pe
        INNER JOIN tareo ta ON ta.id_persona = pe.id_persona
        WHERE
                ta.ta_estado = 1 
            and ta.ta_etapa = 0
            AND pe.per_documento = IN_per_documento
            AND ta.id_sede = IN_id_sede
            AND ta.id_marcador not IN (4,5,6)
           and pe.pe_estado <> 0
        LIMIT 1))
THEN

    SELECT 
            ta.id_tareo INTO DEC_TAREO 
        FROM
        persona pe 
        INNER JOIN tareo ta ON ta.id_persona = pe.id_persona
        WHERE
            ta.ta_estado = 1 
            and ta.ta_etapa = 0
            AND pe.per_documento = IN_per_documento
            AND ta.id_sede = IN_id_sede
            AND ta.id_marcador not IN (4,5,6)
            and pe.pe_estado <> 0
        LIMIT 1;

    SELECT
        ta.id_tareo,
        pe.per_documento,
        UPPER(
            CONCAT(
                per_nombre,
                " ",
                per_apellido_paterno,
                " ",
                per_apellido_materno
            )
        ) AS datos,
        ca.id_cargo,
        ca.ca_descripcion cargo,
        se.id_sede,
        se.se_descripcion,
        se.se_lugar,
        pe.id_persona,
        pe.id_nacionalidad,
        pe.id_tpdocumento,
        CONCAT(
            "HORA DE INGRESO: ",
            DATE_FORMAT(ta.ta_hora_r, '%h:%i %p'),
            #ta.ta_hora_r,
            " / ",
            DATE(ta.ta_fecha_r)
        ) AS registro,
        CONCAT('TURNO: ',ma.ma_abreviatura,' - ',ma.ma_descripcion) as sedeTurno,
        0 id_sueldo,
        sem.id_sede_em,
        pe.pe_estado 
        FROM
            persona pe
        INNER JOIN empleado em ON
            pe.id_persona = em.id_persona
        INNER JOIN sede_empleado sem on 
            em.id_persona = sem.id_persona and sem.sm_estado = 1 and sem.id_sede  = IN_id_sede
        INNER JOIN tareo ta ON
            ta.id_persona = pe.id_persona
        INNER JOIN sede se ON
            ta.id_sede = se.id_sede
        INNER JOIN cargo ca ON
            ca.id_cargo = ta.id_cargo
        LEFT JOIN marcador ma on ta.id_marcador = ma.id_marcador
        WHERE
            ta.ta_estado = 1 
            AND ta.ta_etapa = 0  
            AND pe.per_documento = IN_per_documento 
            AND ta.id_tareo = DEC_TAREO
            AND ta.id_marcador not IN (4,5,6)
            and pe.pe_estado <> 0
            ;  

ELSE
            SELECT
                0 AS id_tareo,
                pe.per_documento,
                UPPER(
                    CONCAT(
                        per_nombre,
                        " ",
                        per_apellido_paterno,
                        " ",
                        per_apellido_materno
                    )
                ) AS datos,
                ca.id_cargo,
                ca.ca_descripcion cargo,
                se.id_sede,
                se.se_descripcion,
                se.se_lugar,
                pe.id_persona,
                pe.id_nacionalidad,
                pe.id_tpdocumento,
                '' AS registro,
                ''  AS sedeTurno,
                0 as id_sueldo, #su.id_sueldo,
                she.id_sede_em,
                pe.pe_estado 
            FROM
                persona pe
            INNER JOIN empleado em ON
                pe.id_persona = em.id_persona
            #INNER JOIN sueldo su on em.id_persona = su.id_persona
            INNER JOIN sede_empleado she ON
                em.id_persona = she.id_persona  and she.sm_estado = 1 and she.id_sede  = IN_id_sede
            INNER JOIN sede se ON
                she.id_sede = se.id_sede
            INNER JOIN cargos_empleado ehc ON
                em.id_persona = ehc.id_persona and ehc.ce_estado = 1
            INNER JOIN cargo ca ON
                ca.id_cargo = ehc.id_cargo
            WHERE
                pe.per_documento = IN_per_documento 
               	and pe.pe_estado <> 0
                ; 
  END IF ;

END$$

CREATE  PROCEDURE MOV_UP_UP_CERRAR_TAREO (IN IN_id_tareo INT, IN IN_ta_estado INT, IN IN_ta_etapa INT, IN IN_ta_fecha_c DATETIME, IN IN_ta_hora_c TIME)  BEGIN 

    ## DECLARES
    DECLARE dec_horasTrabajadas varchar(50);
    DECLARE dec_FechaInicial datetime;

    ## TRANSACCION
    DECLARE errno INT;
    DECLARE msg_errno TEXT;
    DECLARE msg TEXT;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION

    BEGIN
        GET CURRENT DIAGNOSTICS CONDITION 1 errno = MYSQL_ERRNO,msg_errno = MESSAGE_TEXT ; 
            ##SELECT msg_errno  AS MYSQL_ERROR;
            set msg = concat('TRY: ', msg_errno);
            signal sqlstate '45000' set message_text = msg;
            #signal sqlstate MYSQL_ERROR set message_text = msg_errno;
        ROLLBACK;
    END;

    START TRANSACTION;
    IF EXISTS(
        SELECT
            id_tareo
        FROM
            tareo
        WHERE  
            id_tareo = IN_id_tareo AND ta_estado <> 1 AND ta_etapa <> 0
    )
    THEN
        signal sqlstate '45000' set message_text = 'Este tareo ya esta cerrado!';
    ELSE 
            ## OBTENIENDO LA FECHA INICIAL
            select ta_fecha_r into dec_FechaInicial from tareo WHERE id_tareo = IN_id_tareo;
           
            ## CALCULANDO LA HORAS TRABAJADAS
            set dec_horasTrabajadas = timestampdiff(second,dec_FechaInicial, concat(date(IN_ta_fecha_c)," ",IN_ta_hora_c))/3600;
 			#select dec_horasTrabajadas;
            IF dec_FechaInicial > concat(IN_ta_fecha_c," ",IN_ta_hora_c)
            THEN
                signal sqlstate '45000' set message_text = 'La hora ingresada tiene que ser mayor que la hora registrada!';
            else
                ## ACTUALIZANDO
                UPDATE tareo
                    SET 
                    ta_estado   =   IN_ta_estado, 
                    ta_etapa    =   IN_ta_etapa,
                    ta_fecha_c  =   IN_ta_fecha_c, 
                    ta_hora_c   =   IN_ta_hora_c,
                    ta_hrstrabajadas = dec_horasTrabajadas
                WHERE 
                id_tareo = IN_id_tareo;
            END IF;
    END IF;
## RETURN TO TABLES...
COMMIT WORK;
END$$

CREATE  PROCEDURE MOV_UP_UP_LISTAR_MARCADOR (IN IN_TIPO_MARCADOR INT)  BEGIN
if IN_TIPO_MARCADOR = 3
then
    SELECT 
    id_marcador,
    ma_estado,
    IF(ma_estado = 0, 'INACTIVO', 'ACTIVO') as estado, 
    ma_descripcion,
    ma_abreviatura,
    CONCAT(ma_abreviatura," - ",ma_descripcion) AS datos
    FROM marcador
    where id_marcador = 6;
elseif IN_TIPO_MARCADOR = 4
then
    SELECT 
    id_marcador,
    ma_estado,
    IF(ma_estado = 0, 'INACTIVO', 'ACTIVO') as estado, 
    ma_descripcion,
    ma_abreviatura,
    CONCAT(ma_abreviatura," - ",ma_descripcion) AS datos
    FROM marcador
    where id_marcador = 4 or id_marcador = 5;
else 
    SELECT 
    id_marcador,
    ma_estado,
    IF(ma_estado = 0, 'INACTIVO', 'ACTIVO') as estado, 
    ma_descripcion,
    ma_abreviatura,
    CONCAT(ma_abreviatura," - ",ma_descripcion) AS datos
    FROM marcador
    where ma_tipo = IN_TIPO_MARCADOR;
end if;

END$$

CREATE  PROCEDURE MOV_UP_UP_REGISTRO_TAREO (IN IN_id_marcador INT, IN IN_id_persona INT, IN IN_id_tpdocumento VARCHAR(50), IN IN_id_nacionalidad INT, IN IN_id_cargo INT, IN IN_id_sede INT, IN IN_ta_estado INT, IN IN_ta_fecha_r DATETIME, IN IN_ta_fecha_c DATETIME, IN IN_ta_hora_r TIME, IN IN_ta_hora_c TIME, IN IN_ta_usuario INT, IN IN_id_sede_em INT, IN IN_id_sueldo INT, IN IN_ta_remunerado INT, IN IN_userCreacion VARCHAR(50))  BEGIN 

    DECLARE dec_permiso varchar(50);

    ## TRANSACCION
    DECLARE errno INT;
    DECLARE msg_errno TEXT;
    DECLARE msg TEXT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET CURRENT DIAGNOSTICS CONDITION 1 errno = MYSQL_ERRNO,msg_errno = MESSAGE_TEXT ; 
            set msg = concat('TRY: ', msg_errno);
            signal sqlstate '45000' set message_text = msg;
        ROLLBACK;
    END;

    START TRANSACTION;


    IF EXISTS(  
            select 
                * 
            from tareo t
            INNER JOIN persona s
            on t.id_persona = s.id_persona
            where t.id_marcador = 6
            and s.id_persona = IN_id_persona
            and date(t.ta_fecha_r) = date(IN_ta_fecha_r)
            and t.ta_estado = 1
    )
    THEN
        select 
            p.pe_nombre  into dec_permiso 
        from tareo t
        INNER JOIN persona s
        on t.id_persona = s.id_persona
        INNER JOIN permiso p on t.ta_permiso = p.id_permiso
        where t.id_marcador = 6
        and s.id_persona = IN_id_persona
        and date(t.ta_fecha_r) = date(IN_ta_fecha_r)
        and t.ta_estado = 1; 

        set msg = concat('Esta persona tiene un permiso : ', dec_permiso);
        signal sqlstate '45000' set message_text = msg;

    END IF;

    IF EXISTS(  
            select 
                * 
            from tareo t
            INNER JOIN persona s
            on t.id_persona = s.id_persona
            where t.id_marcador = 5
            and s.id_persona = IN_id_persona
            and date(t.ta_fecha_r) = date(IN_ta_fecha_r) 
            and t.ta_estado = 1
    )
    THEN
        signal sqlstate '45000' set message_text = 'Esta persona tiene una falta registrado hoy! :';
    END IF;


    IF EXISTS(
           SELECT 
            id_tareo 
            from tareo ta
            INNER JOIN persona su
            on ta.id_persona = su.id_persona
            INNER JOIN empleado em on em.id_persona = su.id_persona
            WHERE em.id_persona = IN_id_persona 
            and (Date(ta.ta_fecha_r) BETWEEN Date(IN_ta_fecha_r) and date(IN_ta_fecha_r))
            and ta.id_sede = IN_id_sede
            AND ta.id_marcador = IN_id_marcador
            and ta.id_marcador NOT IN (6,4,5)
            and ta.ta_etapa = 1
            and ta.ta_estado = 1
        )
        THEN
            signal sqlstate '45000' set message_text = 'Esta persona tiene un tareo en este turno!';
        ELSE 
            INSERT INTO tareo(
              id_sede_em, id_sede, id_cargo, id_sueldo, 
              id_marcador, ta_estado, ta_fecha_r, 
              ta_fecha_c, ta_hora_r, ta_hora_c, 
              ta_hrstrabajadas, ta_usuario, ta_remunerado,
              ta_etapa,id_persona
              ,userCreacion
              ,userModificacion
            ) 
            VALUES 
            (
                IN_id_sede_em, IN_id_sede, IN_id_cargo, 
                IN_id_sueldo, IN_id_marcador, IN_ta_estado, 
                IN_ta_fecha_r, IN_ta_fecha_c, IN_ta_hora_r, 
                IN_ta_hora_c, 0, IN_ta_usuario, IN_ta_remunerado,
                0, IN_id_persona,
                IN_userCreacion,
                IN_userCreacion
            ); 
    END IF;


## RETURN TO TABLES...
COMMIT WORK;

END$$

CREATE  PROCEDURE test_test (IN IN_opcion INT, IN IN_nombre VARCHAR(50), IN IN_sede INT, IN IN_documento VARCHAR(50), IN IN_opcionFecha INT, IN IN_inicio DATE, IN IN_fin DATE)  begin 
	
	drop table  if exists documentoEmpleado;
	create temporary  table documentoEmpleado(
		id_docemp int
	);
	
	insert into documentoEmpleado
	select 
		a.id_docemp 
	from documentos_has_empleado a
	where 
		a.flEliminado  = 1 and
		(date(a.emd_emision) <> '2100-01-01' and  date(a.emd_vigencia) <> '2100-01-01')
	;


	select 
		p.per_documento as nr_identidad,
		CONCAT(p.per_nombre," ",p.per_apellido_paterno," ",p.per_apellido_materno) AS datos,
		se.se_descripcion as sede,
		ca.ca_descripcion as cargo,
		de.de_descripcion as documento,
		b.emd_vigencia as fecha_vigencia
	from documentoEmpleado a
	inner join  documentos_has_empleado b on a.id_docemp = b.id_docemp 
	inner join documentos_empleado de on b.id_emdocumento = de.id_emdocumento 
	inner join  persona p on b.id_persona  = p.id_persona 
	INNER JOIN sede_empleado she on she.id_persona = p.id_persona and she.sm_estado = 1
	INNER JOIN sede se on se.id_sede = she.id_sede
	INNER JOIN cargos_empleado ce on ce.id_persona = p.id_persona and ce.ce_estado  = 1
	INNER JOIN cargo ca on ca.id_cargo = ce.id_cargo
	where 
		CASE WHEN IN_opcion = 1 THEN  
	        p.per_documento = IN_documento
	    WHEN IN_opcion = 2 THEN  
	        CONCAT(p.per_nombre," ",p.per_apellido_paterno," ",p.per_apellido_materno) LIKE CONCAT('%',IN_nombre,'%')  
	    WHEN IN_opcion = 3 THEN  
	        she.id_sede = IN_sede
	    ELSE 
	        TRUE  
	    end
    
    and  
	    CASE WHEN IN_opcionFecha = 1 THEN  
	        date(b.emd_vigencia) < IN_inicio
	    WHEN IN_opcionFecha = 2 THEN  
	        date(b.emd_vigencia) between date(IN_inicio)  and date(IN_fin) 
	    ELSE 
	        TRUE  
	    end
	order by b.emd_vigencia asc;
	 

end$$

CREATE  PROCEDURE UPM_BUSCAR_PERSONA_SUPLENTE_DOCUMENTO_TAREO_MOVIL (IN IN_per_documento VARCHAR(70))  BEGIN
## PERSONAS QUE SOLO SEAN EMPLEADO
CREATE TEMPORARY TABLE TEMP_PERSONAS (
    id_persona int,
    id_nacionalidad int,
    id_tpdocumento varchar(50),
    per_nombre varchar(70),
    per_apellido_paterno varchar(70),
    per_apellido_materno varchar(70),
    per_documento varchar(70),
    datos  varchar(255),
    ca_descripcion varchar(255),
    se_descripcion varchar(255),
    banco  varchar(255),
    phb_cuenta varchar(255),
    phb_cci varchar(255)
);

INSERT INTO TEMP_PERSONAS
SELECT 
    pe.id_persona,
    pe.id_nacionalidad,
    pe.id_tpdocumento,
    pe.per_nombre,
    pe.per_apellido_paterno,
    pe.per_apellido_materno,
    pe.per_documento,
    CONCAT(per_nombre," ",per_apellido_paterno," ",per_apellido_materno) AS datos,
    ca.ca_descripcion,
    se.se_descripcion,
    CONCAT(ba_abreviatura," - ",ba_nombre) AS banco,
    CASE when phb.phb_cuenta != '' then
          CONCAT("Cuenta: ",sp_CENSURING_DNI(phb.phb_cuenta))
        ELSE
          CONCAT("CI: ",sp_CENSURING_DNI(phb.phb_cci))
    end as phb_cuenta,
    CONCAT("CI: ",phb.phb_cci) phb_cci
FROM persona pe 
INNER JOIN empleado em on pe.id_persona = em.id_persona and pe.pe_estado <> 0
INNER JOIN sede_empleado she on she.id_persona = em.id_persona
INNER JOIN sede se on se.id_sede = she.id_sede
INNER JOIN cargos_empleado ce on ce.id_persona = em.id_persona
INNER JOIN cargo ca on ca.id_cargo = ce.id_cargo
INNER JOIN persona_has_banco phb on phb.id_persona = em.id_persona 
INNER JOIN banco ba on ba.id_banco = phb.id_banco
WHERE pe.per_documento = IN_per_documento limit 10;

INSERT INTO TEMP_PERSONAS
SELECT 
    pe.id_persona,
    pe.id_nacionalidad,
    pe.id_tpdocumento,
    pe.per_nombre,
    pe.per_apellido_paterno,
    pe.per_apellido_materno,
    pe.per_documento,
    CONCAT(per_nombre," ",per_apellido_paterno," ",per_apellido_materno) AS datos,
    '',
    '',
    COALESCE(CONCAT(ba_abreviatura," - ",ba_nombre), '-')  AS banco,
     CASE when phb.phb_cuenta != '' then
          CONCAT("Cuenta: ",sp_CENSURING_DNI(phb.phb_cuenta))
        ELSE
          CONCAT("CI: ",sp_CENSURING_DNI(phb.phb_cci))
    end as phb_cuenta,
    COALESCE(CONCAT("CI: ",phb.phb_cci), 'CI: -') AS phb_cci 
FROM persona pe 
LEFT JOIN persona_has_banco phb on phb.id_persona = pe.id_persona and pe.pe_estado <> 0
LEFT JOIN banco ba on ba.id_banco = phb.id_banco
WHERE pe.per_documento  = IN_per_documento limit 10;

SELECT DISTINCT 
    id_persona,
    id_nacionalidad,
    id_tpdocumento,
    per_nombre,
    per_apellido_paterno,
    per_apellido_materno,
    per_documento,
    datos,
    banco,
    if(phb_cuenta = 'null', '', phb_cuenta) as phb_cuenta,
	if(phb_cci = 'null', '', phb_cci) as phb_cci 
FROM TEMP_PERSONAS;

END$$

CREATE  PROCEDURE UPM_COMPROBAR_VERSION (IN IN_version VARCHAR(6))  BEGIN

declare dec_version decimal(9,2);

SELECT max(cast(ve_version as DECIMAL(9,2))) into dec_version FROM  app_version;

if IN_version != dec_version
then
	select REPLACE(dec_version, '.', '') as version, 0 as estado;
else
	select REPLACE(dec_version, '.', '') as version, 1 as estado;
end if;

END$$

CREATE  PROCEDURE UPM_LISTAR_BANCO ()  BEGIN

SELECT 
id_banco,
ba_descripcion,
ba_abreviatura,
ba_nombre,
ba_estado,
IF(ba_estado = 0, 'INACTIVO', 'ACTIVO') as estado,
CONCAT(ba_abreviatura," - ",ba_nombre) AS datos
FROM banco WHERE ba_estado = 1;

END$$

CREATE  PROCEDURE UPM_LISTAR_CARGO ()  BEGIN

SELECT 
id_cargo,
ca_descripcion,
ca_abreviatura,
ca_estado,
IF(ca_estado = 0, 'INACTIVO', 'ACTIVO') as estado, 
CONCAT(ca_abreviatura," - ",ca_descripcion) AS datos
FROM cargo where ca_estado = 1;

END$$

CREATE  PROCEDURE UPM_LISTAR_EMPLEADO_SEDES_DESCANSO_MOBIL (IN IN_id_sede INT)  BEGIN

SELECT 
    pe.id_persona,
    pe.id_tpdocumento,
    pe.id_nacionalidad,
    pe.per_nombre,
    pe.per_apellido_paterno,
    pe.per_apellido_materno,
    pe.per_documento,
    CONCAT(per_nombre," ",per_apellido_paterno," ",per_apellido_materno) AS datos,
    ca.id_cargo,
    ca.ca_descripcion,
    na.id_nacionalidad,
    na.na_descripcion,
    td.id_tpdocumento,
    td.tpd_descripcion,
    DATE(pe.pe_fecha_ingreso) pe_fecha_ingreso,
    IF(DATE(pe.pe_fecha_ingreso) = DATE(pe.pe_fecha_cese), '-', DATE(pe.pe_fecha_cese)) as cese,
    IF(pe.pe_estado = 1, 'ACTIVO','INACTIVO') as estado 
FROM empleado em
INNER JOIN persona pe on em.id_persona = pe.id_persona and pe.pe_estado <> 0 
INNER JOIN tipo_documento td on td.id_tpdocumento = pe.id_tpdocumento
INNER JOIN nacionalidad na on na.id_nacionalidad = pe.id_nacionalidad
INNER JOIN sede_empleado sem on sem.id_persona = em.id_persona
INNER JOIN sede se on sem.id_sede = se.id_sede
INNER JOIN cargos_empleado ce on ce.id_persona = em.id_persona
INNER JOIN cargo ca on ca.id_cargo = ce.id_cargo 
WHERE sem.id_sede = IN_id_sede ;  

END$$

CREATE  PROCEDURE UPM_LISTAR_NACIONALIDAD ()  BEGIN

SELECT 
id_nacionalidad,
na_descripcion,
na_abreviatura,
na_estado,
IF(na_estado = 0, 'INACTIVO', 'ACTIVO') as estado,
CONCAT(na_abreviatura," - ",na_descripcion) AS datos
FROM nacionalidad where na_estado = 1;

END$$

CREATE  PROCEDURE UPM_LISTAR_PERMISO ()  BEGIN

SELECT 
id_permiso,
pe_descripcion,
pe_estado,
IF(pe_estado = 0, 'INACTIVO', 'ACTIVO') as estado,
pe_nombre
FROM permiso where pe_estado = 1;

END$$

CREATE  PROCEDURE UPM_LISTAR_SEDE ()  BEGIN

SELECT 
id_sede,
se_descripcion,
se_lugar,
se_cantidad,
se_estado,
IF(se_estado = 0, 'INACTIVO', 'ACTIVO') as estado,
CONCAT(se_lugar," - ",se_descripcion) AS datos
FROM sede WHERE se_estado = 1;

END$$

CREATE  PROCEDURE UPM_LISTAR_TIPO_CUENTA ()  BEGIN

SELECT 
id_tpcuenta,
tpc_descripcion,
tpc_abreviatura,
CONCAT(tpc_abreviatura," - ",tpc_descripcion) AS datos
FROM tipo_cuenta where tpc_estado = 1;

END$$

CREATE  PROCEDURE UPM_LISTAR_TIPO_DOCUMENTO ()  BEGIN

SELECT 
id_tpdocumento,
tpd_estado,
IF(tpd_estado = 0, 'INACTIVO', 'ACTIVO') as estado,
tpd_descripcion,
tpd_abreviatura,
CONCAT(tpd_abreviatura," - ",tpd_descripcion) AS datos,
tpd_longitud
FROM tipo_documento WHERE tpd_estado = 1;

END$$

CREATE  PROCEDURE up_actualizar_fecha_documentos (IN IN_id_docemp INT, IN IN_opcion INT, IN IN_fecha_emision VARCHAR(50), IN IN_fecha_vigencia VARCHAR(50), IN IN_userCreacion VARCHAR(50))  begin 
	
	if(IN_opcion = 0)
	then 
		UPDATE documentos_has_empleado 
		SET 
			emd_emision = IN_fecha_emision
			,userModificacion	= IN_userCreacion
			,fechaModificacion	= now()
		WHERE id_docemp = IN_id_docemp;
	else 
		UPDATE documentos_has_empleado 
		SET 
			emd_vigencia = IN_fecha_vigencia
			,userModificacion	= IN_userCreacion
			,fechaModificacion	= now()
		WHERE id_docemp = IN_id_docemp;
	end if;
	
end$$

CREATE  PROCEDURE UP_ACTUALIZAR_FOTO_PERFIL (IN IN_documento VARCHAR(50), IN IN_foto VARCHAR(50), IN IN_userCreacion VARCHAR(50))  BEGIN

UPDATE empleado
SET 
	phc_foto_perfil		=IN_foto 
	,userModificacion	= IN_userCreacion
	,fechaModificacion	= now()
WHERE id_persona in (select id_persona from persona pe where pe.per_documento = IN_documento);

END$$

CREATE  PROCEDURE UP_ACTUALIZAR_SUELDO_PERSONAWEB (IN IN_id_sueldo INT, IN IN_id_persona INT, IN IN_ta_basico VARCHAR(25), IN IN_ta_estado VARCHAR(25), IN IN_ta_observacion VARCHAR(25), IN IN_ta_csdia VARCHAR(25), IN IN_ta_asignacion_familiar VARCHAR(25), IN IN_ta_bonificacion VARCHAR(25), IN IN_ta_movilidad VARCHAR(25), IN IN_ta_alimentos VARCHAR(25), IN IN_ta_total VARCHAR(25), IN IN_ta_vigenciaInicio DATE, IN IN_ta_vigenciaFin DATE, IN IN_userCreacion VARCHAR(50))  BEGIN 
    declare dec_estado int;

 
    select phc_estado into dec_estado from empleado e where e.id_persona = IN_id_persona;
    
    if dec_estado = 3
    then
    
        signal sqlstate '45000' set message_text = '¡Esta persona todavía no ha sido aprobado, por favor aprobarlo!';
        
    else

            UPDATE sueldo 
            SET 
            ta_basico=IN_ta_basico,
            ta_estado=IN_ta_estado,
            ta_observacion=IN_ta_observacion, 
            ta_csdia=IN_ta_csdia,
            ta_asignacion_familiar=IN_ta_asignacion_familiar,
            ta_bonificacion=IN_ta_bonificacion,
            ta_movilidad=IN_ta_movilidad,
            ta_alimentos=IN_ta_alimentos,
            ta_total=IN_ta_total,
            ta_vigenciaInicio=IN_ta_vigenciaInicio,
            ta_vigenciaFin=if(IN_ta_vigenciaFin = '0000-00-00','2100-01-01', IN_ta_vigenciaFin)
            ,userModificacion	= IN_userCreacion
			,fechaModificacion= now()
            WHERE 
            id_sueldo = IN_id_sueldo;
         
    end if;
    
END$$

CREATE  PROCEDURE UP_ACTUALIZAR_USUARIO_PERSONA_ID (IN IN_id_usuario INT, IN IN_us_usuario VARCHAR(50), IN IN_us_contrasenia VARCHAR(50), IN IN_us_estado INT, IN IN_opcion INT, IN IN_userCreacion VARCHAR(50))  BEGIN  

 if(IN_opcion = 1)
 then
    UPDATE usuario SET  
     us_usuario=IN_us_usuario,
     us_contrasenia=IN_us_contrasenia,
     us_estado=IN_us_estado
     ,userModificacion	= IN_userCreacion
	 ,fechaModificacion= now()
     WHERE id_usuario = IN_id_usuario;
 else
    UPDATE usuario SET  
     us_usuario=IN_us_usuario, 
     us_estado=IN_us_estado
     ,userModificacion	= IN_userCreacion
	 ,fechaModificacion= now()
     WHERE id_usuario = IN_id_usuario;
 end if;
      
END$$

CREATE  PROCEDURE UP_ACTUALZIAR_CUENTA_TITULAR_PERSONAWEB (IN IN_id_persona INT, IN IN_id_phbanco INT, IN IN_id_banco VARCHAR(25), IN IN_id_tpcuenta VARCHAR(25), IN IN_phb_cuenta VARCHAR(25), IN IN_phb_cci VARCHAR(25), IN IN_userCreacion VARCHAR(50))  BEGIN 

    UPDATE persona 
    SET pe_titular = 1
    ,userModificacion	= IN_userCreacion
	,fechaModificacion= now()
    WHERE id_persona = IN_id_persona;

    UPDATE suplente_cobrar SET
     suc_estado=0
     ,userModificacion	= IN_userCreacion
	,fechaModificacion= now()
    WHERE suc_origen = IN_id_persona and suc_estado = 1;

    UPDATE persona_has_banco SET
     phb_estado=0
     ,userModificacion	= IN_userCreacion
	,fechaModificacion= now()
    WHERE id_persona = IN_id_persona and phb_estado = 1; 

    UPDATE persona_has_banco SET
     phb_estado=1,
     id_banco = IN_id_banco,
     id_tpcuenta = IN_id_tpcuenta,
     phb_cuenta = IN_phb_cuenta,
     phb_cci = IN_phb_cci
     ,userModificacion	= IN_userCreacion
	,fechaModificacion= now()
    WHERE id_phbanco = IN_id_phbanco; 

END$$

CREATE  PROCEDURE UP_ADMINISTRADOR_REGISTRAR_EMPLEADO (IN IN_id_tpdocumento VARCHAR(80), IN IN_id_nacionalidad INT, IN IN_per_nombre VARCHAR(80), IN IN_per_apellido_paterno VARCHAR(80), IN IN_per_apellido_materno VARCHAR(80), IN IN_per_documento VARCHAR(80), IN IN_per_fecha_nac DATE, IN IN_per_celular VARCHAR(80), IN IN_per_correo VARCHAR(80), IN IN_per_nacionalidad INT, IN IN_pe_fecha_ingreso DATETIME, IN IN_pe_titular INT, IN IN_pe_usuario INT, IN IN_pe_sexo VARCHAR(1), IN IN_pe_direccion VARCHAR(80), IN IN_pe_estado INT, IN IN_empleado JSON, IN IN_pago JSON, IN IN_userCreacion VARCHAR(50))  BEGIN
    
## DECLARACIONES
DECLARE dec_ID_PERSONA INT;
DECLARE dec_id_tpdocumento VARCHAR(80);
DECLARE dec_id_nacionalidad INT; 
declare dec_id_tpUsuario int;
declare dec_id_usuario int;

declare dia_descanso date;
declare acumulador date;
declare two_week date;
DECLARE dec_id_sueldo INT; 

DECLARE dec_json_empleado_items BIGINT UNSIGNED DEFAULT JSON_LENGTH(IN_empleado);
DECLARE dec_json_empleado_index BIGINT UNSIGNED DEFAULT 0;

DECLARE dec_json_pago_items BIGINT UNSIGNED DEFAULT JSON_LENGTH(IN_pago);
DECLARE dec_json_pago_index BIGINT UNSIGNED DEFAULT 0;
## TRANSACCION
DECLARE errno INT;
DECLARE msg_errno TEXT;
DECLARE msg TEXT;

DECLARE EXIT HANDLER FOR SQLEXCEPTION
BEGIN
    GET CURRENT DIAGNOSTICS CONDITION 1 errno = MYSQL_ERRNO,msg_errno = MESSAGE_TEXT ; 
        ##SELECT msg_errno  AS MYSQL_ERROR;
        set msg = concat('* ', msg_errno);
        signal sqlstate '45000' set message_text = msg;
        #signal sqlstate MYSQL_ERROR set message_text = msg_errno;
    ROLLBACK;
END;

START TRANSACTION;
## END TRANSACCION

IF  JSON_VALID(IN_empleado) = 0
THEN
    signal sqlstate '45000' set message_text = 'Error datos incorrectos en el empleado!';
END IF; 

IF EXISTS(
    SELECT 1 FROM  persona_has_listanegra a WHERE a.id_persona = (select id_persona from persona where per_documento = IN_per_documento)  and a.flEliminado = 1
)
THEN
    signal sqlstate '45000' set message_text = 'Esta persona está en la lista negra, por favor anúlelo y vuelva a intentarlo';
end if;


IF NOT EXISTS(
    SELECT 1 FROM  persona WHERE per_documento = IN_per_documento
)
THEN
        INSERT INTO persona(
          id_tpdocumento, id_nacionalidad, 
          per_nombre, per_apellido_paterno, 
          per_apellido_materno, per_documento, 
          per_fecha_nac, per_celular, per_correo, 
          per_nacionalidad, pe_fecha_ingreso, 
          pe_fecha_cese, pe_titular, pe_usuario, 
          pe_sexo, pe_direccion, pe_estado
          ,userCreacion,userModificacion
        ) 
        VALUES 
        (
            IN_id_tpdocumento, IN_id_nacionalidad, 
            IN_per_nombre, IN_per_apellido_paterno, 
            IN_per_apellido_materno, IN_per_documento, 
            IN_per_fecha_nac, IN_per_celular, 
            IN_per_correo, IN_per_nacionalidad, 
            IN_pe_fecha_ingreso, IN_pe_fecha_ingreso, 
            IN_pe_titular, IN_pe_usuario, IN_pe_sexo, 
            IN_pe_direccion, IN_pe_estado
            ,IN_userCreacion
			,IN_userCreacion
        );   

        SELECT LAST_INSERT_ID() INTO dec_ID_PERSONA; 

        WHILE dec_json_empleado_index < dec_json_empleado_items DO

            INSERT INTO empleado(
              id_persona, phc_estado, phc_fecha_r, 
              phc_fecha_c, phc_codigo
              ,userCreacion,userModificacion
            ) 
            VALUES 
            (
                dec_ID_PERSONA, 1, IN_pe_fecha_ingreso, 
                IN_pe_fecha_ingreso, 'CODIGO'
                ,IN_userCreacion
				,IN_userCreacion
            );
           
            select 
                a.id_tipoUsuario into dec_id_tpUsuario 
            from cargo a where a.id_cargo  = JSON_UNQUOTE(JSON_EXTRACT(IN_empleado, CONCAT('$[', dec_json_empleado_index, '].cargo')));

             
             INSERT INTO usuario(
                  id_tpusuario, us_usuario, us_contrasenia, 
                  us_estado, us_fecha_r, us_fecha_c, 
                  us_empleado, us_persona
                  ,userCreacion,userModificacion
               ) 
               VALUES 
               (
                        dec_id_tpUsuario, IN_per_documento, IN_per_documento, 
                        1, NOW(), NOW(), dec_ID_PERSONA, dec_ID_PERSONA
                        ,IN_userCreacion
						,IN_userCreacion
               );
              
                select id_usuario into dec_id_usuario  from usuario where us_persona = dec_ID_PERSONA;
              
                insert into sis_usuario_modperm(id_mpermiso, id_usuario,userCreacion,userModificacion)
                select 
                id_mpermiso, 
                dec_id_usuario
                ,IN_userCreacion
				,IN_userCreacion
                from sis_perfil_modperm a where a.id_tpusuario = dec_id_tpUsuario and a.flEliminado = 1;
              

            INSERT INTO cargos_empleado(

                id_persona, 
                id_cargo, 
                ce_fecha_r, 
                ce_fecha_c, 
                ce_estado, 
                ce_observacion
                ,userCreacion,userModificacion
            )
            VALUES (
                dec_ID_PERSONA,
                JSON_UNQUOTE(JSON_EXTRACT(IN_empleado, CONCAT('$[', dec_json_empleado_index, '].cargo'))),
                IN_pe_fecha_ingreso,
                IN_pe_fecha_ingreso,
                1,
                'OBSERVACION'
                ,IN_userCreacion
				,IN_userCreacion
            );

            INSERT INTO sede_empleado(id_persona, id_sede, sm_codigo, sm_fecha_r, sm_fecha_c, sm_observacion, sm_estado
            	,userCreacion,userModificacion
            ) 
            VALUES 
            (
                dec_ID_PERSONA,
                JSON_UNQUOTE(JSON_EXTRACT(IN_empleado, CONCAT('$[', dec_json_empleado_index, '].sede'))),
                'CODIGO',
                IN_pe_fecha_ingreso,
                IN_pe_fecha_ingreso,
                'OBSERVACION',
                1
                ,IN_userCreacion
				,IN_userCreacion
            );


            IF JSON_UNQUOTE(JSON_EXTRACT(IN_empleado, CONCAT('$[', dec_json_empleado_index, '].descansoReferencia'))) <> 'NONE'
            THEN

            INSERT INTO descanso(
                id_persona,   
                de_fecha, 
                de_observacion, 
                de_estado,
                de_referencia
                ,userCreacion,userModificacion
            )VALUES (
                dec_ID_PERSONA, 
                JSON_UNQUOTE(JSON_EXTRACT(IN_empleado, CONCAT('$[', dec_json_empleado_index, '].descanso'))),
                '',
                1,
                JSON_UNQUOTE(JSON_EXTRACT(IN_empleado, CONCAT('$[', dec_json_empleado_index, '].descansoReferencia')))
                ,IN_userCreacion
				,IN_userCreacion
            ); 

            end if;
                

                IF JSON_UNQUOTE(JSON_EXTRACT(IN_empleado, CONCAT('$[', dec_json_empleado_index, '].sueldo_basico'))) <> 0
                THEN
                    INSERT INTO sueldo(
                          id_persona, ta_basico, ta_estado, 
                          ta_observacion, ta_fecha_r, ta_fecha_c, 
                          ta_csdia, ta_asignacion_familiar, 
                          ta_bonificacion, ta_movilidad, ta_alimentos, 
                          ta_total,ta_vigenciaInicio,ta_vigenciaFin
                          ,userCreacion,userModificacion
                    ) VALUES (
                        dec_ID_PERSONA,  
                        JSON_UNQUOTE(JSON_EXTRACT(IN_empleado, CONCAT('$[', dec_json_empleado_index, '].sueldo_basico'))),
                        1,
                        '',
                        NOW(),
                        NOW(),
                        JSON_UNQUOTE(JSON_EXTRACT(IN_empleado, CONCAT('$[', dec_json_empleado_index, '].costo_dia'))),
                        JSON_UNQUOTE(JSON_EXTRACT(IN_empleado, CONCAT('$[', dec_json_empleado_index, '].asignacion_familiar'))),
                        JSON_UNQUOTE(JSON_EXTRACT(IN_empleado, CONCAT('$[', dec_json_empleado_index, '].bonificacion'))),
                        JSON_UNQUOTE(JSON_EXTRACT(IN_empleado, CONCAT('$[', dec_json_empleado_index, '].movilidad'))),
                        JSON_UNQUOTE(JSON_EXTRACT(IN_empleado, CONCAT('$[', dec_json_empleado_index, '].alimentos'))),
                        JSON_UNQUOTE(JSON_EXTRACT(IN_empleado, CONCAT('$[', dec_json_empleado_index, '].sueldo_total'))),
                        JSON_UNQUOTE(JSON_EXTRACT(IN_empleado, CONCAT('$[', dec_json_empleado_index, '].ta_vigenciaInicio'))),
                        JSON_UNQUOTE(JSON_EXTRACT(IN_empleado, CONCAT('$[', dec_json_empleado_index, '].ta_vigenciaFin')))
                        ,IN_userCreacion
						,IN_userCreacion

                    ); 
                END IF;

            SET dec_json_empleado_index := dec_json_empleado_index + 1;
        END WHILE;

        WHILE dec_json_pago_index < dec_json_pago_items DO

            IF JSON_EXTRACT(IN_pago, CONCAT('$[', dec_json_pago_index, '].tipo')) = 1 THEN
                
                IF JSON_UNQUOTE(JSON_EXTRACT(IN_pago, CONCAT('$[', dec_json_pago_index, '].banco'))) <> '0' THEN
                
                    INSERT INTO persona_has_banco(
                        id_persona, 
                        id_banco, 
                        id_tpcuenta, 
                        phb_cuenta, 
                        phb_cci
                        ,userCreacion,userModificacion
                    ) VALUES (
                        dec_ID_PERSONA, 
                        JSON_UNQUOTE(JSON_EXTRACT(IN_pago, CONCAT('$[', dec_json_pago_index, '].banco'))),
                        JSON_UNQUOTE(JSON_EXTRACT(IN_pago, CONCAT('$[', dec_json_pago_index, '].tipo_cuenta'))),
                        JSON_UNQUOTE(JSON_EXTRACT(IN_pago, CONCAT('$[', dec_json_pago_index, '].cuenta'))),
                        JSON_UNQUOTE(JSON_EXTRACT(IN_pago, CONCAT('$[', dec_json_pago_index, '].cci')))
                        ,IN_userCreacion
						,IN_userCreacion
                    );

                END IF;

            ELSE

                IF NOT EXISTS(select id_persona from persona where per_documento = JSON_UNQUOTE(JSON_EXTRACT(IN_pago, CONCAT('$[', dec_json_pago_index, '].documento'))))
                THEN
                    signal sqlstate '45000' set message_text = 'La persona suplente no existe!';
                ELSE
                    INSERT INTO suplente_cobrar(
                        id_persona,   
                        suc_estado,
                        suc_origen,
                        suc_observacion
                        ,userCreacion,userModificacion
                    ) VALUES (
                        (select id_persona from persona where per_documento = JSON_UNQUOTE(JSON_EXTRACT(IN_pago, CONCAT('$[', dec_json_pago_index, '].documento')))), 
                        1,
                        dec_ID_PERSONA,
                        ''
                        ,IN_userCreacion
						,IN_userCreacion
                    );
                END if;
            END IF;

            SET dec_json_pago_index := dec_json_pago_index + 1;
        END WHILE;

ELSE
      signal sqlstate '45000' set message_text = 'Esta persona ya esta registrada en el sistema!';
END IF; 

## RETURN TO TABLES...
COMMIT WORK;

END$$

CREATE  PROCEDURE UP_ANULAR_CESE_EMPLEADO (IN IN_id_cese INT, IN IN_userCreacion VARCHAR(50))  BEGIN
  DECLARE dec_id_persona int;
  declare dec_id_lista int;
  
  UPDATE empleado_has_cese 
  	SET flEliminado = '0'
  	,userModificacion	= IN_userCreacion
	,fechaModificacion= now()
  WHERE id_cese = IN_id_cese;
 
  select a.id_lista, a.id_persona into dec_id_lista, dec_id_persona from empleado_has_cese a where a.id_cese = IN_id_cese;
  
  UPDATE persona_has_listanegra 
  	set flEliminado = '0' 
  	,userModificacion	= IN_userCreacion
	,fechaModificacion= now()
 	where id_lista = dec_id_lista;
 
  UPDATE persona 
  	set pe_estado = 1 
  	,userModificacion	= IN_userCreacion
	,fechaModificacion= now()
  where id_persona = dec_id_persona;

  update usuario 
  	set us_estado = 1 
  	,userModificacion	= IN_userCreacion
	,fechaModificacion= now()
 	where us_persona = dec_id_persona;

END$$

CREATE  PROCEDURE UP_APROBAR_REGISTRA_SUELDO_ADM (IN IN_id_sueldo INT, IN IN_id_persona INT, IN IN_ta_basico VARCHAR(50), IN IN_ta_asignacion_familiar VARCHAR(50), IN IN_ta_bonificacion VARCHAR(50), IN IN_ta_movilidad VARCHAR(50), IN IN_ta_alimentos VARCHAR(50), IN IN_ta_total VARCHAR(50))  BEGIN

DECLARE dec_id_sueldo int;

UPDATE empleado SET
    phc_estado = 1
WHERE 
id_persona = IN_id_persona;


if EXISTS(
    SELECT 
    id_sueldo 
    FROM sueldo
    WHERE id_sueldo = IN_id_sueldo 
    #and ta_estado = 3
) THEN

    SELECT 
    id_sueldo into dec_id_sueldo
    FROM sueldo
    WHERE id_persona = IN_id_persona; 
    #and ta_estado = 3;

    UPDATE sueldo SET
    ta_basico = IN_ta_basico,
    ta_estado = 1,
    ta_observacion = 'DATA INICIAL',
    ta_fecha_r = NOW(),
    ta_fecha_c = NOW(),
    ta_csdia = '0',
    ta_asignacion_familiar = IN_ta_asignacion_familiar,
    ta_bonificacion = IN_ta_bonificacion,
    ta_movilidad = IN_ta_movilidad,
    ta_alimentos = IN_ta_alimentos,
    ta_total = IN_ta_total
    WHERE 
    id_sueldo = IN_id_sueldo;

ELSE
    INSERT INTO sueldo(
                    id_persona,   
                    ta_basico, 
                    ta_estado, 
                    ta_observacion, 
                    ta_fecha_r, 
                    ta_fecha_c, 
                    ta_csdia, 
                    ta_asignacion_familiar, 
                    ta_bonificacion, 
                    ta_movilidad, 
                    ta_alimentos,
                    ta_total
                ) VALUES (
                    IN_id_persona,  
                    IN_ta_basico,
                    1,
                    'DATA INICIAL', 
                    NOW(),
                    NOW(),
                    '0',
                    IN_ta_asignacion_familiar,
                    IN_ta_bonificacion,
                    IN_ta_movilidad,
                    IN_ta_alimentos,
                    IN_ta_total
                );
 
END IF;

END$$

CREATE  PROCEDURE UP_BUSCAR_DIAS_TAREADO (IN IN_id_persona INT, IN IN_fecha_inicio DATE, IN IN_fecha_fin DATE)  BEGIN

 SELECT date(ta.ta_fecha_r) as fecha, GROUP_CONCAT(CONCAT_WS(':', ma.ma_abreviatura) SEPARATOR ',') AS Result 
 FROM tareo ta INNER JOIN marcador ma on ta.id_marcador = ma.id_marcador 
 INNER JOIN persona su on ta.id_persona = su.id_persona 
 where 
 su.id_persona = IN_id_persona and
 date(ta.ta_fecha_r) between date(IN_fecha_inicio) and date(IN_fecha_fin)
 and ta.ta_estado = 1
 GROUP BY ta.ta_fecha_r;

END$$

CREATE  PROCEDURE up_buscar_documentos_x_documento (IN IN_documentoNro VARCHAR(50), IN IN_documentos VARCHAR(50), IN IN_conSin INT)  begin 
    
    declare delimiterString varchar(1);
    declare inputstr varchar(50);
    declare conSin varchar(3);

    ##CURSOR
    DECLARE findelbucle INTEGER DEFAULT 0;
   
   # CURSOR LOOP
    declare id_documento int;
   
    
   #cursor para las personas
    DECLARE documentos_sistema CURSOR for
    select 
        item
    from Items; 

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET findelbucle=1;

    drop table if exists Items;

    CREATE TEMPORARY TABLE Items(
        item NVARCHAR(50)
    );

    set delimiterString = ',';
    set inputstr = IN_documentos;
 
    WHILE LOCATE(delimiterString,inputstr) > 1 DO
        INSERT INTO Items SELECT SUBSTRING_INDEX(inputstr,delimiterString,1);
        SET inputstr = REPLACE (inputstr, (SELECT LEFT(inputstr,LOCATE(delimiterString,inputstr))),'');
    END WHILE;


    drop table if exists empleados_sel;
    CREATE TEMPORARY TABLE empleados_sel(
        id_sel int primary key auto_increment,
        id_persona int,
        id_documento int
    );


    #star cursor
    OPEN documentos_sistema;
        loop1: loop
          
        FETCH documentos_sistema INTO id_documento; 
        IF findelbucle = 1 THEN
           LEAVE loop1;
        END IF;
         
         
        insert into empleados_sel 
        select 
        null,
        p.id_persona,
        id_documento
        from persona p  
        where p.per_documento like concat('%',IN_documentoNro,'%');
        
       END LOOP loop1;
    CLOSE documentos_sistema; 

	
   	 select 
        sel.*,
        concat(p.per_nombre,' ',p.per_apellido_paterno,' ',p.per_apellido_materno) as datos,
        p.per_documento,
        if(dhe.id_docemp is null, 0, dhe.id_docemp) as id_docemp,
        if(dhe.id_docemp is null, 'No', 'Si') as isPossesihng,
        dhe.emd_nombrefile
    from empleados_sel sel
    inner join persona p on sel.id_persona = p.id_persona 
    left join documentos_has_empleado dhe on sel.id_persona = dhe.id_persona  and sel.id_documento = dhe.id_emdocumento 
    and dhe.flEliminado = 1
    #where sel.isPossesihng  = conSin
    ;

    
end$$

CREATE  PROCEDURE up_buscar_documentos_x_nombres (IN IN_datosPersona VARCHAR(50), IN IN_documentos VARCHAR(50), IN IN_conSin INT, IN IN_estadoEmpleado VARCHAR(1), IN in_opcionSede INT)  begin 
    
    declare delimiterString varchar(1);
    declare inputstr varchar(50);
    declare conSin varchar(3);

    ##CURSOR
    DECLARE findelbucle INTEGER DEFAULT 0;
   
   # CURSOR LOOP
    declare id_documento int;
   
    
   #cursor para las personas
    DECLARE documentos_sistema CURSOR for
    select 
        item
    from Items; 

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET findelbucle=1;

    drop table if exists Items;

    CREATE TEMPORARY TABLE Items(
        item NVARCHAR(50)
    );

    set delimiterString = ',';
    set inputstr = IN_documentos;
 
    if IN_documentos = 'T'
    THEN 
    	set inputstr = CONCAT((SELECT 
		 group_concat(ac.id_emdocumento)
		FROM (
			SELECT id_emdocumento FROM documentos_empleado a where a.flEliminado = 1
		) as ac),',');
    end if;
   
    WHILE LOCATE(delimiterString,inputstr) > 1 DO
    	INSERT INTO Items SELECT SUBSTRING_INDEX(inputstr,delimiterString,1);
    	SET inputstr = REPLACE (inputstr, (SELECT LEFT(inputstr,LOCATE(delimiterString,inputstr))),'');
	END WHILE;


    drop table if exists empleados_sel;
    CREATE TEMPORARY TABLE empleados_sel(
        id_sel int primary key auto_increment,
        id_persona int,
        id_documento int
    );
   
   if IN_conSin = 1
   	then
   		set conSin = 'Si';
   	else
   		set conSin = 'No';
   	end if;


    #star cursor
    OPEN documentos_sistema;
        loop1: loop
          
        FETCH documentos_sistema INTO id_documento; 
        IF findelbucle = 1 THEN
           LEAVE loop1;
        END IF;
         
         
        insert into empleados_sel 
        select 
        null,
        p.id_persona,
        id_documento
        from persona p  
        where concat(p.per_nombre,' ',p.per_apellido_paterno,' ',p.per_apellido_materno) like concat('%',IN_datosPersona,'%');
        
       END LOOP loop1;
    CLOSE documentos_sistema; 

	
   	 select 
  		DISTINCT
	    codigo,
	    id_persona,
	    datos,
	    if(in_opcionSede = 1, sede, '') as sede,
	    posicion,
	    documento,
	    isPossesihng,
	    per_documento,
	    emd_nombrefile,
	    id_tpdocumento
	  from 
	  (
		  	SELECT 
		   		LPAD(pe.id_persona, 8, '0') 	as codigo,
		   		pe.id_persona					as id_persona,
		   		CONCAT(per_nombre," ",per_apellido_paterno," ",per_apellido_materno) AS datos,
		   		se.se_descripcion 				as sede,
		   		ca.ca_descripcion				as posicion,
		   		de.de_nombre					as documento,
		   		if(dhe.id_docemp is null, 'No', 'Si') as isPossesihng,
		   		per_documento,
   				emd_nombrefile,
   				pe.id_tpdocumento
			FROM empleado em
			INNER JOIN empleados_sel p on em.id_persona = p.id_persona 
			inner JOIN persona pe on pe.id_persona  = p.id_persona  and pe.pe_estado = 
			case 
			when IN_estadoEmpleado = '1' then
					1
			when IN_estadoEmpleado = '0' then
					0
			when IN_estadoEmpleado = 'T' then
					pe.pe_estado
			end 
			INNER JOIN tipo_documento td on td.id_tpdocumento = pe.id_tpdocumento
			INNER JOIN nacionalidad na on na.id_nacionalidad = pe.id_nacionalidad
			INNER JOIN sede_empleado sem on sem.id_persona = em.id_persona and sem.sm_estado = 1
			INNER JOIN sede se on sem.id_sede = se.id_sede
			INNER JOIN cargos_empleado ce on ce.id_persona = em.id_persona and ce.ce_estado = 1
			INNER JOIN cargo ca on ca.id_cargo = ce.id_cargo 
			left join documentos_has_empleado dhe on p.id_persona = dhe.id_persona  and p.id_documento = dhe.id_emdocumento and dhe.flEliminado = 1
			left join  documentos_empleado de on p.id_documento  = de.id_emdocumento 
	  ) as res
	 	where isPossesihng = conSin
	 	order by sede, datos asc;
	 
end$$

CREATE  PROCEDURE up_buscar_documentos_x_sede (IN IN_sede INT, IN IN_documentos VARCHAR(50), IN IN_conSin INT, IN IN_estadoEmpleado VARCHAR(1), IN in_opcionSede INT)  begin 
    
    declare delimiterString varchar(1);
    declare inputstr varchar(50);
    declare conSin varchar(3);

    ##CURSOR
    DECLARE findelbucle INTEGER DEFAULT 0;
   
   # CURSOR LOOP
    declare id_documento int;
   
    
   #cursor para las personas
    DECLARE documentos_sistema CURSOR for
    select 
        item
    from Items; 

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET findelbucle=1;

    drop table if exists Items;

    CREATE TEMPORARY TABLE Items(
        item NVARCHAR(50)
    );

    set delimiterString = ',';
    set inputstr = IN_documentos;
 
    if IN_documentos = 'T'
    THEN 
    	set inputstr = CONCAT((SELECT 
		 group_concat(ac.id_emdocumento)
		FROM (
			SELECT id_emdocumento FROM documentos_empleado a where a.flEliminado = 1
		) as ac),',');
    end if;
   
   WHILE LOCATE(delimiterString,inputstr) > 1 DO
    	INSERT INTO Items SELECT SUBSTRING_INDEX(inputstr,delimiterString,1);
    	SET inputstr = REPLACE (inputstr, (SELECT LEFT(inputstr,LOCATE(delimiterString,inputstr))),'');
	END WHILE;


    drop table if exists empleados_sel;
    CREATE TEMPORARY TABLE empleados_sel(
        id_sel int primary key auto_increment,
        id_persona int,
        id_documento int
    );


    #star cursor
    OPEN documentos_sistema;
        loop1: loop
          
        FETCH documentos_sistema INTO id_documento; 
        IF findelbucle = 1 THEN
           LEAVE loop1;
        END IF;
         
         
        insert into empleados_sel 
        select 
        null,
        p.id_persona,
        id_documento
        from persona p 
        inner join 
        sede_empleado se on p.id_persona  = se.id_persona
        where se.id_sede  = IN_sede;
        
       END LOOP loop1;
    CLOSE documentos_sistema; 

	
   	if IN_conSin = 1
   	then
   		set conSin = 'Si';
   	else
   		set conSin = 'No';
   	end if;
   
     

  select 
  	DISTINCT
    codigo,
    id_persona,
    datos,
    if(in_opcionSede = 1, sede, '') as sede,
    posicion,
    documento,
    isPossesihng,
    per_documento,
    emd_nombrefile,
    id_tpdocumento
  from 
  (
  	SELECT 
   		LPAD(pe.id_persona, 8, '0') 	as codigo,
   		pe.id_persona					as id_persona,
   		CONCAT(per_nombre," ",per_apellido_paterno," ",per_apellido_materno) AS datos,
   		se.se_descripcion 				as sede,
   		ca.ca_descripcion				as posicion,
   		de.de_nombre					as documento,
   		if(dhe.id_docemp is null, 'No', 'Si') as isPossesihng,
   		per_documento,
   		emd_nombrefile,
   		pe.id_tpdocumento
	FROM empleado em
	INNER JOIN empleados_sel p on em.id_persona = p.id_persona 
	inner JOIN persona pe on pe.id_persona  = p.id_persona  and pe.pe_estado = 
	case 
		when IN_estadoEmpleado = '1' then
				1
		when IN_estadoEmpleado = '0' then
				0
		when IN_estadoEmpleado = 'T' then
				pe.pe_estado
		end
	INNER JOIN tipo_documento td on td.id_tpdocumento = pe.id_tpdocumento
	INNER JOIN nacionalidad na on na.id_nacionalidad = pe.id_nacionalidad
	INNER JOIN sede_empleado sem on sem.id_persona = em.id_persona and sem.sm_estado = 1
	INNER JOIN sede se on sem.id_sede = se.id_sede
	INNER JOIN cargos_empleado ce on ce.id_persona = em.id_persona and ce.ce_estado = 1
	INNER JOIN cargo ca on ca.id_cargo = ce.id_cargo 
	left join documentos_has_empleado dhe on p.id_persona = dhe.id_persona  and p.id_documento = dhe.id_emdocumento and dhe.flEliminado = 1
	left join  documentos_empleado de on p.id_documento  = de.id_emdocumento
	WHERE sem.id_sede = IN_sede
  ) as res
 	where isPossesihng = conSin
 	order by sede, datos asc
  ;

    
end$$

CREATE  PROCEDURE up_buscar_documentos_x_todos (IN IN_Todos VARCHAR(50), IN IN_documentos VARCHAR(50), IN IN_conSin INT, IN IN_estadoEmpleado VARCHAR(1), IN in_opcionSede INT)  begin 
    
    declare delimiterString varchar(1);
    declare inputstr varchar(50);
    declare conSin varchar(3);

    ##CURSOR
    DECLARE findelbucle INTEGER DEFAULT 0;
   
   # CURSOR LOOP
    declare id_documento int;
   
    
   #cursor para las personas
    DECLARE documentos_sistema CURSOR for
    select 
        item
    from Items; 

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET findelbucle=1;

    drop table if exists Items;

    CREATE TEMPORARY TABLE Items(
        item NVARCHAR(50)
    );

    set delimiterString = ',';
    set inputstr = IN_documentos;
 
    if IN_documentos = 'T'
    THEN 
        set inputstr = CONCAT((SELECT 
         group_concat(ac.id_emdocumento)
        FROM (
            SELECT id_emdocumento FROM documentos_empleado a where a.flEliminado = 1
        ) as ac),',');
    end if;
   
    WHILE LOCATE(delimiterString,inputstr) > 1 DO
        INSERT INTO Items SELECT SUBSTRING_INDEX(inputstr,delimiterString,1);
        SET inputstr = REPLACE (inputstr, (SELECT LEFT(inputstr,LOCATE(delimiterString,inputstr))),'');
    END WHILE;


    drop table if exists empleados_sel;
    CREATE TEMPORARY TABLE empleados_sel(
        id_sel int primary key auto_increment,
        id_persona int,
        id_documento int
    );
   
    if IN_conSin = 1
    then
        set conSin = 'Si';
    else
        set conSin = 'No';
    end if;


    #star cursor
    OPEN documentos_sistema;
        loop1: loop
          
        FETCH documentos_sistema INTO id_documento; 
        IF findelbucle = 1 THEN
           LEAVE loop1;
        END IF;
         
         
        insert into empleados_sel 
        select 
        null,
        p.id_persona,
        id_documento
        from persona p;
        
       END LOOP loop1;
    CLOSE documentos_sistema; 

     #select * from empleados_sel;
    
     select 
        DISTINCT
	    codigo,
	    id_persona,
	    datos,
	    if(in_opcionSede = 1, sede, '') as sede,
	    posicion,
	    documento,
	    isPossesihng,
	    per_documento,
	    emd_nombrefile,
	    id_tpdocumento
      from 
      (
            SELECT 
                LPAD(pe.id_persona, 8, '0')     as codigo,
                pe.id_persona                   as id_persona,
                CONCAT(per_nombre," ",per_apellido_paterno," ",per_apellido_materno) AS datos,
                se.se_descripcion               as sede,
                ca.ca_descripcion               as posicion,
                de.de_nombre                    as documento,
                if(dhe.id_docemp is null, 'No', 'Si') as isPossesihng,
                per_documento,
                emd_nombrefile,
                pe.id_tpdocumento 
            FROM empleado em
            INNER JOIN empleados_sel p on em.id_persona = p.id_persona 
            inner JOIN persona pe on pe.id_persona  = p.id_persona  and pe.pe_estado = 
			case 
			when IN_estadoEmpleado = '1' then
					1
			when IN_estadoEmpleado = '0' then
					0
			when IN_estadoEmpleado = 'T' then
					pe.pe_estado
			end  
            INNER JOIN tipo_documento td on td.id_tpdocumento = pe.id_tpdocumento
            INNER JOIN nacionalidad na on na.id_nacionalidad = pe.id_nacionalidad
            INNER JOIN sede_empleado sem on sem.id_persona = em.id_persona and sem.sm_estado = 1
            INNER JOIN sede se on sem.id_sede = se.id_sede
            INNER JOIN cargos_empleado ce on ce.id_persona = em.id_persona and ce.ce_estado = 1
            INNER JOIN cargo ca on ca.id_cargo = ce.id_cargo 
            left join documentos_has_empleado dhe on p.id_persona = dhe.id_persona  and p.id_documento = dhe.id_emdocumento and dhe.flEliminado = 1
            left join  documentos_empleado de on p.id_documento  = de.id_emdocumento 
      ) as res
        where isPossesihng = conSin
       order by sede, datos asc
       ;
    
end$$

CREATE  PROCEDURE UP_BUSCAR_EMPLEADO_ADM (IN IN_opcion INT, IN IN_per_nombres VARCHAR(50), IN IN_per_documento VARCHAR(50), IN IN_id_sede INT, IN IN_id_cargo INT)  BEGIN
    
    SELECT 
    	DISTINCT
        pe.id_persona,
        pe.id_tpdocumento,
        pe.id_nacionalidad,
        pe.per_nombre,
        pe.per_apellido_paterno,
        pe.per_apellido_materno,
        pe.per_documento,
        CONCAT(per_nombre," ",per_apellido_paterno," ",per_apellido_materno) AS datos,
        na.id_nacionalidad,
        na.na_descripcion,
        td.id_tpdocumento,
        td.tpd_descripcion,
        ca.ca_descripcion,
        em.phc_estado,
        pe.pe_estado,
        fun_getBanco_planilla(pe.id_persona) banco,
        fun_getCuentas_planilla(pe.id_persona) cuenta,
        fun_getTipoCuentas_planilla(pe.id_persona) tpCuenta,
        fun_getCci_planilla(pe.id_persona) cci,
        fun_getDatosSuplente_planilla(pe.id_persona) suplente
        ,pe.userCreacion
		,pe.fechaCreacion
		,pe.userModificacion
		,pe.fechaModificacion
		,pe.flEliminado
FROM persona pe
INNER JOIN empleado em on em.id_persona = pe.id_persona 
INNER JOIN tipo_documento td on td.id_tpdocumento = pe.id_tpdocumento
INNER JOIN nacionalidad na on na.id_nacionalidad = pe.id_nacionalidad
INNER JOIN cargos_empleado ce on ce.id_persona = pe.id_persona and ce.ce_estado = 1
INNER JOIN cargo ca on ce.id_cargo = ca.id_cargo
LEFT JOIN sede_empleado sem on sem.id_persona = em.id_persona and sem.sm_estado = 1
LEFT JOIN sede se on sem.id_sede = se.id_sede
     WHERE 
    CASE WHEN IN_opcion = 1 THEN  
        pe.per_documento = IN_per_documento
    WHEN IN_opcion = 2 THEN  
        CONCAT(per_nombre," ",per_apellido_paterno," ",per_apellido_materno) LIKE CONCAT('%',IN_per_nombres,'%')  
    WHEN IN_opcion = 3 THEN  
        sem.id_sede = IN_id_sede
    WHEN IN_opcion = 4 THEN  
        ca.id_cargo = IN_id_cargo
    ELSE 
        TRUE  
    end;
   
END$$

CREATE  PROCEDURE UP_BUSCAR_EMPLEADO_ADM_WEB (IN IN_opcion INT, IN IN_per_nombres VARCHAR(50), IN IN_per_documento VARCHAR(50), IN IN_id_sede INT, IN IN_id_cargo INT, IN in_opcionSede INT)  BEGIN 
    
    select
    	distinct
    	LPAD(pe.id_persona, 8, '0') as codigo,
        pe.id_persona,
        pe.id_tpdocumento,
        pe.id_nacionalidad,
        pe.per_nombre,
        pe.per_apellido_paterno,
        pe.per_apellido_materno,
        pe.per_documento,
        CONCAT(per_nombre," ",per_apellido_paterno," ",per_apellido_materno) AS datos,
        na.id_nacionalidad,
        na.na_descripcion,
        td.id_tpdocumento,
        td.tpd_descripcion,
        ca.ca_descripcion,
        em.phc_estado,
        pe.pe_estado, 
        if(in_opcionSede = 1, se.se_descripcion, '') as sede
FROM persona pe
INNER JOIN empleado em on em.id_persona = pe.id_persona 
INNER JOIN tipo_documento td on td.id_tpdocumento = pe.id_tpdocumento
INNER JOIN nacionalidad na on na.id_nacionalidad = pe.id_nacionalidad
INNER JOIN cargos_empleado ce on ce.id_persona = pe.id_persona
INNER JOIN cargo ca on ce.id_cargo = ca.id_cargo
INNER JOIN sede_empleado sem on sem.id_persona = em.id_persona
INNER JOIN sede se on sem.id_sede = se.id_sede
     WHERE 
    CASE WHEN IN_opcion = 1 THEN  
        pe.per_documento = IN_per_documento
    WHEN IN_opcion = 2 THEN  
        CONCAT(per_nombre," ",per_apellido_paterno," ",per_apellido_materno) LIKE CONCAT('%',IN_per_nombres,'%')  
    WHEN IN_opcion = 3 THEN  
        sem.id_sede = IN_id_sede
    WHEN IN_opcion = 4 THEN  
        ca.id_cargo = IN_id_cargo
    ELSE 
        TRUE  
    end
   order by se.se_descripcion, per_nombre  asc
    ; 
END$$

CREATE  PROCEDURE UP_BUSCAR_EMPLEADO_CESE_ADM (IN IN_opcion INT, IN IN_per_nombres VARCHAR(50), IN IN_per_documento VARCHAR(50), IN IN_id_sede INT, IN IN_id_cargo INT)  begin

	SELECT 
        DISTINCT
        date(ec.ce_fecha_cese) as ce_fecha_cese,
        ec.id_cese,
        case when ec.id_cese is null
        then
            1
        else 
            0
        end as ce_estado,
        ec.ce_motivo,
        date(ls.userCreacion) as lis_fecha_lista,
        ls.id_lista,
        case when ls.id_lista is null
        then
            0
        else 
            1
        end as ls_estado,
        ls.lis_motivo,
        pe.id_persona,
        pe.id_tpdocumento,
        pe.id_nacionalidad,
        pe.per_nombre,
        pe.per_apellido_paterno,
        pe.per_apellido_materno,
        pe.per_documento,
        CONCAT(per_nombre," ",per_apellido_paterno," ",per_apellido_materno) AS datos,
        na.na_descripcion,
        td.tpd_descripcion,
        ca.ca_descripcion,
        em.phc_estado,
        pe.pe_estado,
        mc.mo_nombre,
        if(mc.id_motivo is null, 0 ,mc.id_motivo) id_motivo
        ,coalesce((select count(*) from empleado_has_cese where id_persona  = pe.id_persona and flEliminado != 0), null) as ce_cantidad
        ,fun_getCeseAuditoria(pe.id_persona, 1) as userCreacion
        ,fun_getCeseAuditoria(pe.id_persona, 2) as fechaCreacion
        ,fun_getCeseAuditoria(pe.id_persona, 3) as userModificacion
        ,fun_getCeseAuditoria(pe.id_persona, 4) as fechaModificacion
FROM persona pe
INNER JOIN empleado em on em.id_persona = pe.id_persona 
INNER JOIN tipo_documento td on td.id_tpdocumento = pe.id_tpdocumento
INNER JOIN nacionalidad na on na.id_nacionalidad = pe.id_nacionalidad
INNER JOIN cargos_empleado ce on ce.id_persona = pe.id_persona and ce.ce_estado = 1
INNER JOIN cargo ca on ce.id_cargo = ca.id_cargo
LEFT JOIN sede_empleado sem on sem.id_persona = em.id_persona and sem.sm_estado = 1
LEFT JOIN sede se on sem.id_sede = se.id_sede
LEFT JOIN empleado_has_cese ec on ec.id_persona = pe.id_persona and ec.flEliminado != 0
left join motivos_cese mc on mc.id_motivo  = ec.id_motivo 
LEFT JOIN persona_has_listanegra ls on ls.id_persona = pe.id_persona and ls.flEliminado != 0
     WHERE 
    CASE WHEN IN_opcion = 1 THEN  
        pe.per_documento = IN_per_documento
    WHEN IN_opcion = 2 THEN  
        CONCAT(per_nombre," ",per_apellido_paterno," ",per_apellido_materno) LIKE CONCAT('%',IN_per_nombres,'%')  
    WHEN IN_opcion = 3 THEN  
        sem.id_sede = IN_id_sede
    WHEN IN_opcion = 4 THEN  
        ca.id_cargo = IN_id_cargo
    ELSE 
        TRUE  
    end;
 
  
END$$

CREATE  PROCEDURE UP_BUSCAR_EMPLEADO_PERMISO (IN IN_per_documento VARCHAR(50))  BEGIN
    declare con varchar(100);
    set con=concat('%',IN_per_documento,'%');
     SELECT 
        DISTINCT
        pe.id_persona,
        pe.per_nombre,
        pe.per_apellido_paterno,
        pe.per_apellido_materno,
        pe.id_nacionalidad,
        pe.id_tpdocumento,
        pe.per_documento,
        CONCAT(per_nombre," ",per_apellido_paterno," ",per_apellido_materno) AS datos,
        ca.id_cargo,
        ca.ca_descripcion,
        se.id_sede,
        se.se_descripcion,
        se.se_lugar,
        su.id_sueldo
    FROM persona pe 
    INNER JOIN empleado em on pe.id_persona = em.id_persona
    INNER JOIN sueldo su on pe.id_persona = su.id_persona
    INNER JOIN sede_empleado she on she.id_persona = em.id_persona
    INNER JOIN sede se on se.id_sede = she.id_sede
    INNER JOIN cargos_empleado ehc on ehc.id_persona = em.id_persona
    INNER JOIN cargo ca on ca.id_cargo = ehc.id_cargo
    WHERE pe.per_documento like con;

END$$

CREATE  PROCEDURE UP_BUSCAR_EMPLEADO_PERMISOV2 (IN IN_per_documento VARCHAR(50), IN IN_id_sede INT)  BEGIN
    declare con varchar(100);
    set con=concat('%',IN_per_documento,'%');
     SELECT 
        DISTINCT
        pe.id_persona,
        pe.per_nombre,
        pe.per_apellido_paterno,
        pe.per_apellido_materno,
        pe.id_nacionalidad,
        pe.id_tpdocumento,
        pe.per_documento,
        CONCAT(per_nombre," ",per_apellido_paterno," ",per_apellido_materno) AS datos,
        ca.id_cargo,
        ca.ca_descripcion,
        se.id_sede,
        se.se_descripcion,
        se.se_lugar,
        su.id_sueldo
    FROM persona pe 
    INNER JOIN empleado em on pe.id_persona = em.id_persona
    INNER JOIN sueldo su on pe.id_persona = su.id_persona
    INNER JOIN sede_empleado she on she.id_persona = em.id_persona
    INNER JOIN sede se on se.id_sede = she.id_sede
    INNER JOIN cargos_empleado ehc on ehc.id_persona = em.id_persona
    INNER JOIN cargo ca on ca.id_cargo = ehc.id_cargo
    WHERE pe.per_documento like con and she.id_sede = IN_id_sede;

END$$

CREATE  PROCEDURE UP_BUSCAR_PERSONA_DOCUMENTO (IN IN_per_documento VARCHAR(50))  BEGIN
    declare con varchar(100);
    set con=concat('%',IN_per_documento,'%');

SELECT 
    pe.id_persona,
    pe.per_nombre,
    pe.per_apellido_paterno,
    pe.per_apellido_materno,
    pe.id_nacionalidad,
    pe.id_tpdocumento,
    pe.per_documento,
    CONCAT(per_nombre," ",per_apellido_paterno," ",per_apellido_materno) AS datos,
    ba.id_banco,
    ba.ba_abreviatura,
    phb.phb_cuenta,
    phb.phb_cci
FROM persona pe 
INNER JOIN persona_has_banco phb on 
pe.id_persona = phb.id_persona and 
pe.id_tpdocumento = phb.id_tpdocumento and 
pe.id_nacionalidad = phb.id_nacionalidad
INNER JOIN banco ba on phb.id_banco = ba.id_banco  
WHERE pe.per_documento like con or pe.per_nombre like con;

END$$

CREATE  PROCEDURE UP_BUSCAR_PERSONA_ID (IN IN_id_persona INT)  BEGIN

SELECT
    su.ta_csdia,
    pe.id_persona,
    pe.pe_titular,
    CONCAT(pe.per_apellido_paterno," ",pe.per_apellido_materno," ",pe.per_nombre) apellidos,
    td.tpd_abreviatura,
    CASE when pe.id_nacionalidad = 1 then
         'L'
        ELSE
         'E'
    end as nacionalidad,
    pe.per_documento,
    ca.ca_descripcion,
    su.ta_basico,
    su.ta_asignacion_familiar,
    pe.pe_fecha_ingreso
FROM  persona pe
INNER JOIN tipo_documento td on pe.id_tpdocumento = td.id_tpdocumento
INNER JOIN cargos_empleado ce on pe.id_persona = ce.id_persona and ce.ce_estado = 1
INNER JOIN cargo ca on ca.id_cargo = ce.id_cargo
INNER JOIN sueldo su on pe.id_persona = su.id_persona
where pe.id_persona = IN_id_persona;

END$$

CREATE  PROCEDURE UP_BUSCAR_PERSONA_SUPLENTE_DOCUMENTO_TAREO_ADMN (IN IN_per_documento VARCHAR(50))  BEGIN
    declare con varchar(100);
    set con=concat('%',IN_per_documento,'%');

    ## PERSONAS QUE SOLO SEAN EMPLEADO
 
    CREATE TEMPORARY TABLE TEMP_PERSONAS (
        id_persona int,
        id_nacionalidad int,
        id_tpdocumento varchar(50),
        per_nombre varchar(70),
        per_apellido_paterno varchar(70),
        per_apellido_materno varchar(70),
        per_documento varchar(70),
        datos  varchar(255),
        ca_descripcion varchar(255),
        se_descripcion varchar(255),
        banco  varchar(255),
        phb_cuenta varchar(255),
        phb_cci varchar(255),
        tpc_descripcion varchar(255) 
    );

    INSERT INTO TEMP_PERSONAS
    SELECT 
        pe.id_persona,
        pe.id_nacionalidad,
        pe.id_tpdocumento,
        pe.per_nombre,
        pe.per_apellido_paterno,
        pe.per_apellido_materno,
        pe.per_documento,
        CONCAT(per_nombre," ",per_apellido_paterno," ",per_apellido_materno) AS datos,
        ca.ca_descripcion,
        se.se_descripcion,
        CONCAT(ba_abreviatura," - ",ba_nombre) AS banco,
        phb.phb_cuenta,
        phb.phb_cci,
        tp.tpc_descripcion
    FROM persona pe 
    INNER JOIN empleado em on pe.id_persona = em.id_persona
    INNER JOIN sede_empleado she on she.id_persona = em.id_persona
    INNER JOIN sede se on se.id_sede = she.id_sede
    INNER JOIN cargos_empleado ce on ce.id_persona = em.id_persona
    INNER JOIN cargo ca on ca.id_cargo = ce.id_cargo
    INNER JOIN persona_has_banco phb on phb.id_persona = em.id_persona and phb.phb_estado = 1 
    INNER JOIN banco ba on ba.id_banco = phb.id_banco
    inner join tipo_cuenta tp on phb.id_tpcuenta = tp.id_tpcuenta
    WHERE pe.per_documento like con or CONCAT(per_nombre,per_apellido_paterno,per_apellido_materno) like con;

    INSERT INTO TEMP_PERSONAS
    SELECT 
        pe.id_persona,
        pe.id_nacionalidad,
        pe.id_tpdocumento,
        pe.per_nombre,
        pe.per_apellido_paterno,
        pe.per_apellido_materno,
        pe.per_documento,
        CONCAT(per_nombre," ",per_apellido_paterno," ",per_apellido_materno) AS datos,
        '',
        '',
        CONCAT(ba_abreviatura," - ",ba_nombre) AS banco,
        phb.phb_cuenta,
        phb.phb_cci,
        tp.tpc_descripcion
    FROM persona pe 
    INNER JOIN persona_has_banco phb on phb.id_persona = pe.id_persona and phb.phb_estado = 1
    INNER JOIN banco ba on ba.id_banco = phb.id_banco
    inner join tipo_cuenta tp on phb.id_tpcuenta = tp.id_tpcuenta
    WHERE pe.per_documento like con or CONCAT(per_nombre,per_apellido_paterno,per_apellido_materno) like con;

    SELECT DISTINCT 
        id_persona,
        id_nacionalidad,
        id_tpdocumento,
        per_nombre,
        per_apellido_paterno,
        per_apellido_materno,
        per_documento,
        datos,
        banco,
        phb_cuenta,
        phb_cci,
        tpc_descripcion
    FROM TEMP_PERSONAS;

END$$

CREATE  PROCEDURE UP_BUSCAR_PERSONA_SUPLENTE_DOCUMENTO_TAREO_ADMN2 (IN IN_per_documento VARCHAR(50))  BEGIN
    declare con varchar(100);
    set con=concat('%',IN_per_documento,'%');

    ## PERSONAS QUE SOLO SEAN EMPLEADO
 
    CREATE TEMPORARY TABLE TEMP_PERSONAS (
        id_persona int,
        id_nacionalidad int,
        id_tpdocumento varchar(50),
        per_nombre varchar(70),
        per_apellido_paterno varchar(70),
        per_apellido_materno varchar(70),
        per_documento varchar(70),
        datos  varchar(255),
        ca_descripcion varchar(255),
        se_descripcion varchar(255),
        banco  varchar(255),
        phb_cuenta varchar(255)
    );

    INSERT INTO TEMP_PERSONAS
    SELECT 
        pe.id_persona,
        pe.id_nacionalidad,
        pe.id_tpdocumento,
        pe.per_nombre,
        pe.per_apellido_paterno,
        pe.per_apellido_materno,
        pe.per_documento,
        CONCAT(per_nombre," ",per_apellido_paterno," ",per_apellido_materno) AS datos,
        ca.ca_descripcion,
        se.se_descripcion,
        CONCAT(ba_abreviatura," - ",ba_nombre) AS banco,
        phb.phb_cuenta
    FROM persona pe 
    INNER JOIN empleado em on pe.id_persona = em.id_persona
    INNER JOIN sede_empleado she on she.id_persona = em.id_persona
    INNER JOIN sede se on se.id_sede = she.id_sede
    INNER JOIN cargos_empleado ce on ce.id_persona = em.id_persona
    INNER JOIN cargo ca on ca.id_cargo = ce.id_cargo
    INNER JOIN persona_has_banco phb on phb.id_persona = em.id_persona and phb.phb_estado = 1 
    INNER JOIN banco ba on ba.id_banco = phb.id_banco
    WHERE pe.per_documento like con or CONCAT(per_nombre,per_apellido_paterno,per_apellido_materno) like con;

    INSERT INTO TEMP_PERSONAS
    SELECT 
        pe.id_persona,
        pe.id_nacionalidad,
        pe.id_tpdocumento,
        pe.per_nombre,
        pe.per_apellido_paterno,
        pe.per_apellido_materno,
        pe.per_documento,
        CONCAT(per_nombre," ",per_apellido_paterno," ",per_apellido_materno) AS datos,
        '',
        '',
        CONCAT(ba_abreviatura," - ",ba_nombre) AS banco,
        phb.phb_cuenta
    FROM persona pe 
    INNER JOIN persona_has_banco phb on phb.id_persona = pe.id_persona and phb.phb_estado = 1
    INNER JOIN banco ba on ba.id_banco = phb.id_banco
    WHERE pe.per_documento like con or CONCAT(per_nombre,per_apellido_paterno,per_apellido_materno) like con;

    SELECT DISTINCT 
        id_persona,
        id_nacionalidad,
        id_tpdocumento,
        per_nombre,
        per_apellido_paterno,
        per_apellido_materno,
        per_documento,
        datos,
        banco,
        phb_cuenta
    FROM TEMP_PERSONAS;

END$$

CREATE  PROCEDURE UP_BUSCAR_PERSONA_SUPLENTE_DOCUMENTO_TAREO_MOVIL (IN IN_per_documento VARCHAR(50))  BEGIN
    declare con varchar(100);
    set con=concat('%',IN_per_documento,'%');

## PERSONAS QUE SOLO SEAN EMPLEADO

CREATE TEMPORARY TABLE TEMP_PERSONAS (
    id_persona int,
    id_nacionalidad int,
    id_tpdocumento varchar(50),
    per_nombre varchar(70),
    per_apellido_paterno varchar(70),
    per_apellido_materno varchar(70),
    per_documento varchar(70),
    datos  varchar(255),
    ca_descripcion varchar(255),
    se_descripcion varchar(255),
    banco  varchar(255),
    phb_cuenta varchar(255),
    phb_cci varchar(255)
);

INSERT INTO TEMP_PERSONAS
SELECT 
    pe.id_persona,
    pe.id_nacionalidad,
    pe.id_tpdocumento,
    pe.per_nombre,
    pe.per_apellido_paterno,
    pe.per_apellido_materno,
    pe.per_documento,
    CONCAT(per_nombre," ",per_apellido_paterno," ",per_apellido_materno) AS datos,
    ca.ca_descripcion,
    se.se_descripcion,
    CONCAT(ba_abreviatura," - ",ba_nombre) AS banco,
    CONCAT("Cuenta: ",phb.phb_cuenta) AS phb_cuenta,
    CONCAT("CI: ",phb.phb_cuenta) AS phb_cci 
FROM persona pe 
INNER JOIN empleado em on pe.id_persona = em.id_persona and pe.pe_estado <> 0
INNER JOIN sede_empleado she on she.id_persona = em.id_persona
INNER JOIN sede se on se.id_sede = she.id_sede
INNER JOIN cargos_empleado ce on ce.id_persona = em.id_persona
INNER JOIN cargo ca on ca.id_cargo = ce.id_cargo
INNER JOIN persona_has_banco phb on phb.id_persona = em.id_persona 
INNER JOIN banco ba on ba.id_banco = phb.id_banco
WHERE pe.per_documento like con limit 10;

INSERT INTO TEMP_PERSONAS
SELECT 
    pe.id_persona,
    pe.id_nacionalidad,
    pe.id_tpdocumento,
    pe.per_nombre,
    pe.per_apellido_paterno,
    pe.per_apellido_materno,
    pe.per_documento,
    CONCAT(per_nombre," ",per_apellido_paterno," ",per_apellido_materno) AS datos,
    '',
    '',
    CONCAT(ba_abreviatura," - ",ba_nombre) AS banco,
    CONCAT("Cuenta: ",phb.phb_cuenta) AS phb_cuenta,
    CONCAT("CI: ",phb.phb_cuenta) AS phb_cci 
FROM persona pe 
INNER JOIN persona_has_banco phb on phb.id_persona = pe.id_persona and pe.pe_estado <> 0
INNER JOIN banco ba on ba.id_banco = phb.id_banco
WHERE pe.per_documento like con limit 10;

SELECT DISTINCT 
    id_persona,
    id_nacionalidad,
    id_tpdocumento,
    per_nombre,
    per_apellido_paterno,
    per_apellido_materno,
    per_documento,
    datos,
    banco,
    phb_cuenta,
    phb_cci
FROM TEMP_PERSONAS;

END$$

CREATE  PROCEDURE UP_BUSCAR_PERSONA_WEB_ADM (IN IN_opcion INT, IN IN_per_nombres VARCHAR(50), IN IN_per_documento VARCHAR(50))  BEGIN
     SELECT 
        pe.id_persona,
        pe.id_tpdocumento,
        pe.id_nacionalidad,
        pe.per_nombre,
        pe.per_apellido_paterno,
        pe.per_apellido_materno,
        pe.per_documento,
        CONCAT(per_nombre," ",per_apellido_paterno," ",per_apellido_materno) AS datos,
        na.id_nacionalidad,
        na.na_descripcion,
        td.id_tpdocumento,
        td.tpd_descripcion, 
        pe.pe_estado
        ,pe.userCreacion
		,pe.fechaCreacion
		,pe.userModificacion
		,pe.fechaModificacion
		,pe.flEliminado
FROM persona pe
INNER JOIN tipo_documento td on td.id_tpdocumento = pe.id_tpdocumento
INNER JOIN nacionalidad na on na.id_nacionalidad = pe.id_nacionalidad
where not exists (SELECT * from empleado where id_persona = pe.id_persona) AND
CASE WHEN IN_opcion = 1 THEN  
    pe.per_documento = IN_per_documento
WHEN IN_opcion = 2 THEN  
    CONCAT(pe.per_nombre," ",pe.per_apellido_paterno," ",pe.per_apellido_materno) LIKE CONCAT('%',IN_per_nombres,'%')  
ELSE 
    TRUE  
end;
  
END$$

CREATE  PROCEDURE UP_BUSCAR_TAREO_CIERRE (IN IN_per_documento VARCHAR(50))  BEGIN

    declare con varchar(100);
    set con=concat('%',IN_per_documento,'%');

    SELECT 
    ta.id_tareo, 
    CONCAT("HORA DE INGRESO: ",ta.ta_hora_r," ",date(ta.ta_fecha_r)) as tareo,
     pe.per_documento,
      CONCAT(per_nombre," ",per_apellido_paterno," ",per_apellido_materno) AS datos,
       ca.id_cargo, 
       ca.ca_descripcion,
        se.id_sede,
         se.se_descripcion 
    from tareo ta 
    INNER JOIN persona pe ON pe.id_persona = ta.id_persona and pe.id_tpdocumento = ta.id_tpdocumento and pe.id_nacionalidad = ta.id_nacionalidad 
    INNER JOIN empleado em on em.id_persona = pe.id_persona and em.id_tpdocumento = pe.id_tpdocumento and em.id_nacionalidad = pe.id_nacionalidad 
    INNER JOIN sede se on em.id_sede = se.id_sede 
    INNER JOIN cargo ca on ca.id_cargo = em.id_cargo 
    WHERE 
    pe.per_documento like con
    and ta.ta_estado = 0;

END$$

CREATE  PROCEDURE UP_BUSCAR_TAREO_CIERRE_REGISTRO (IN IN_per_documento VARCHAR(50))  BEGIN
    DECLARE
        DEC_TAREO INT DEFAULT 0 ;
  
        SELECT
                 1
            INTO DEC_TAREO 
        FROM
        persona pe
        INNER JOIN empleado em ON pe.id_persona = em.id_persona 
        INNER JOIN sueldo su ON su.id_persona = em.id_persona
        INNER JOIN tareo ta ON ta.id_sueldo = su.id_sueldo
        WHERE
            ta.ta_estado = 0 AND(
                DATE(ta.ta_fecha_r) BETWEEN DATE(
                    DATE_ADD(NOW(), INTERVAL -1 DAY)) AND DATE(NOW())) AND pe.per_documento = IN_per_documento
                LIMIT 1;


IF DEC_TAREO = 1 THEN
    SELECT
        ta.id_tareo,
        pe.per_documento,
        CONCAT(
            per_nombre,
            " ",
            per_apellido_paterno,
            " ",
            per_apellido_materno
        ) AS datos,
        ca.id_cargo,
        ca.ca_descripcion cargo,
        se.id_sede,
        se.se_descripcion,
        se.se_lugar,
        pe.id_persona,
        pe.id_nacionalidad,
        pe.id_tpdocumento,
        CONCAT(
            "HORA DE INGRESO: ",
            ta.ta_hora_r,
            " - ",
            DATE(ta.ta_fecha_r)
        ) AS registro,
        CONCAT('SEDE ',se.se_lugar,' TURNO: ',ma.ma_abreviatura,' - ',ma.ma_descripcion) as sedeTurno,
        su.id_sueldo
        FROM
            persona pe
        INNER JOIN empleado em ON
            pe.id_persona = em.id_persona
        INNER JOIN sueldo su ON
            su.id_persona = em.id_persona
        INNER JOIN tareo ta ON
            ta.id_sueldo = su.id_sueldo  
        INNER JOIN sede se ON
            ta.id_sede = se.id_sede
        INNER JOIN cargo ca ON
            ca.id_cargo = ta.id_cargo
        LEFT JOIN marcador ma on ta.id_marcador = ma.id_marcador
        WHERE
            ta.ta_estado = 0 AND(
                DATE(ta.ta_fecha_r) BETWEEN DATE(
                    DATE_ADD(NOW(), INTERVAL -1 DAY)) AND DATE(NOW())) AND pe.per_documento = IN_per_documento ; 
ELSE
            SELECT
                0 AS id_tareo,
                pe.per_documento,
                CONCAT(
                    per_nombre,
                    " ",
                    per_apellido_paterno,
                    " ",
                    per_apellido_materno
                ) AS datos,
                ca.id_cargo,
                ca.ca_descripcion cargo,
                se.id_sede,
                se.se_descripcion,
                se.se_lugar,
                pe.id_persona,
                pe.id_nacionalidad,
                pe.id_tpdocumento,
                '' AS registro,
                CONCAT('SEDE: ',se.se_lugar,' ',se.se_descripcion)  AS sedeTurno,
                su.id_sueldo
            FROM
                persona pe
            INNER JOIN empleado em ON
                pe.id_persona = em.id_persona
            INNER JOIN sueldo su on em.id_persona = su.id_persona  
            INNER JOIN sede_empleado she ON
                em.id_persona = she.id_persona
            INNER JOIN sede se ON
                she.id_sede = se.id_sede
            INNER JOIN cargos_empleado ehc ON
                em.id_persona = ehc.id_persona
            INNER JOIN cargo ca ON
                ca.id_cargo = ehc.id_cargo
            WHERE
                pe.per_documento LIKE CONCAT('%', IN_per_documento, '%') ;

END IF ; 
END$$

CREATE  PROCEDURE UP_BUSCAR_TAREO_CIERRE_REGISTRO_OLD (IN IN_per_documento VARCHAR(50))  BEGIN

    declare con varchar(100);
    set con=concat('%',IN_per_documento,'%');

    SELECT 
        CASE WHEN (ta.id_tareo IS NULL) THEN 
            0
        ELSE 
            ta.id_tareo
        END AS id_tareo,
        pe.per_documento,
        CONCAT(
            per_nombre,
            " ",
            per_apellido_paterno,
            " ",
            per_apellido_materno
        ) AS datos,
        IFNULL(ca.id_cargo, 0) id_cargo,
        IFNULL(ca.ca_descripcion, "") cargo, 
        se.id_sede,
        se.se_descripcion,
        se.se_lugar,
        CASE WHEN (se1.id_sede IS NULL) THEN 
            '-' 
        ELSE 
            CONCAT(
                "HORA DE INGRESO: ",
                ta.ta_hora_r,
                " - ",
                DATE(ta.ta_fecha_r)
            )
        END AS registro 
    FROM
        persona pe
    INNER JOIN empleado em ON
        em.id_persona = pe.id_persona AND em.id_tpdocumento = pe.id_tpdocumento AND em.id_nacionalidad = pe.id_nacionalidad
    INNER JOIN sede_has_empleado she on em.id_persona = she.id_persona and she.id_tpdocumento = em.id_tpdocumento and she.id_nacionalidad = em.id_nacionalidad
    INNER JOIN sede se on se.id_sede = she.id_sede
    LEFT JOIN tareo ta ON
        pe.id_persona = ta.id_persona AND pe.id_tpdocumento = ta.id_tpdocumento AND pe.id_nacionalidad = ta.id_nacionalidad
    LEFT JOIN sede se1 ON
        ta.id_sede = se1.id_sede
    LEFT JOIN cargo ca ON
        ca.id_cargo = ta.id_cargo
    WHERE 
    pe.per_documento like con
    AND CASE WHEN (ta.id_tareo IS NULL) THEN 
         1 = 1  
    ELSE 
        ta.ta_estado = 0  
    END;

END$$

CREATE  PROCEDURE UP_BUSCAR_TAREO_CIERRE_REGISTRO_V2 (IN IN_per_documento VARCHAR(100), IN IN_id_sede INT)  BEGIN

DECLARE DEC_TAREO INT DEFAULT 0 ;
   
IF (EXISTS(SELECT 
            *
        FROM
        persona pe
        #INNER JOIN empleado em ON pe.id_persona = em.id_persona 
        #INNER JOIN sueldo su ON su.id_persona = em.id_persona
        INNER JOIN tareo ta ON ta.id_persona = pe.id_persona
        WHERE
            ta.ta_estado = 1 
            and ta.ta_etapa = 0
            AND pe.per_documento = IN_per_documento
            AND ta.id_sede = IN_id_sede
            AND ta.id_marcador not IN (4,5,6)
        LIMIT 1))
THEN

    SELECT 
            ta.id_tareo INTO DEC_TAREO 
        FROM
        persona pe
        #INNER JOIN empleado em ON pe.id_persona = em.id_persona 
        #INNER JOIN sueldo su ON su.id_persona = em.id_persona
        INNER JOIN tareo ta ON ta.id_persona = pe.id_persona
        WHERE
            ta.ta_estado = 1 
            and ta.ta_etapa = 0
            AND pe.per_documento = IN_per_documento
            AND ta.id_sede = IN_id_sede
            AND ta.id_marcador not IN (4,5,6)
        LIMIT 1;

    SELECT
        ta.id_tareo,
        pe.per_documento,
        UPPER(
            CONCAT(
                per_nombre,
                " ",
                per_apellido_paterno,
                " ",
                per_apellido_materno
            )
        ) AS datos,
        ca.id_cargo,
        ca.ca_descripcion cargo,
        se.id_sede,
        se.se_descripcion,
        se.se_lugar,
        pe.id_persona,
        pe.id_nacionalidad,
        pe.id_tpdocumento,
        CONCAT(
            "HORA DE INGRESO: ",
            DATE_FORMAT(ta.ta_hora_r, '%h:%i %p'),
            #ta.ta_hora_r,
            " / ",
            DATE(ta.ta_fecha_r)
        ) AS registro,
        CONCAT('TURNO: ',ma.ma_abreviatura,' - ',ma.ma_descripcion) as sedeTurno,
        0 id_sueldo,
        sem.id_sede_em
        FROM
            persona pe
        INNER JOIN empleado em ON
            pe.id_persona = em.id_persona
        INNER JOIN sede_empleado sem on 
            em.id_persona = sem.id_persona and sem.sm_estado = 1
        INNER JOIN tareo ta ON
            ta.id_persona = pe.id_persona
        INNER JOIN sede se ON
            ta.id_sede = se.id_sede
        INNER JOIN cargo ca ON
            ca.id_cargo = ta.id_cargo
        LEFT JOIN marcador ma on ta.id_marcador = ma.id_marcador
        WHERE
            ta.ta_estado = 1 
            AND ta.ta_etapa = 0  
            AND pe.per_documento = IN_per_documento
            AND ta.id_sede = IN_id_sede
            AND ta.id_tareo = DEC_TAREO
            AND ta.id_marcador not IN (4,5,6);  

ELSE
            SELECT
                0 AS id_tareo,
                pe.per_documento,
                UPPER(
                    CONCAT(
                        per_nombre,
                        " ",
                        per_apellido_paterno,
                        " ",
                        per_apellido_materno
                    )
                ) AS datos,
                ca.id_cargo,
                ca.ca_descripcion cargo,
                se.id_sede,
                se.se_descripcion,
                se.se_lugar,
                pe.id_persona,
                pe.id_nacionalidad,
                pe.id_tpdocumento,
                '' AS registro,
                ''  AS sedeTurno,
                0 as id_sueldo, #su.id_sueldo,
                she.id_sede_em
            FROM
                persona pe
            INNER JOIN empleado em ON
                pe.id_persona = em.id_persona
            #INNER JOIN sueldo su on em.id_persona = su.id_persona
            INNER JOIN sede_empleado she ON
                em.id_persona = she.id_persona  and she.sm_estado = 1
            INNER JOIN sede se ON
                she.id_sede = se.id_sede
            INNER JOIN cargos_empleado ehc ON
                em.id_persona = ehc.id_persona
            INNER JOIN cargo ca ON
                ca.id_cargo = ehc.id_cargo
            WHERE
                pe.per_documento = IN_per_documento
                AND she.id_sede = IN_id_sede ; 
  END IF ;

END$$

CREATE  PROCEDURE UP_BUSCAR_TAREO_OPERADOR_hosting (IN IN_fechaInicio VARCHAR(50), IN IN_fechaFin VARCHAR(50), IN IN_documento VARCHAR(50), IN IN_idMarcador VARCHAR(50))  BEGIN 
    IF IN_idMarcador = 0 
    THEN
            SELECT  
            LPAD(ta.id_tareo,7,'0') as id_tareo, 
            pe.per_documento,
            CONCAT(pe.per_nombre," ",pe.per_apellido_paterno," ",pe.per_apellido_materno) AS datos,
            date(ta.ta_fecha_r) as ta_fecha_r,
            ta.ta_hora_r, 
            case ta.ta_etapa
                when 0 then ' - '
                when 1 then date(ta.ta_fecha_c)
            end as ta_fecha_c, 
            case ta.ta_etapa
                when 0 then ' - '
                when 1 then ta.ta_hora_c
            end as ta_hora_c,
            ta.ta_estado estado_nr,
            case
            when ta.ta_estado  = 1 
            then 
                 case 
                 when ta.ta_etapa = 0 AND ta.id_marcador  NOT IN (6,4,5)
                 then
                    'PENDIENTE POR CERRAR'
                 when ta.ta_etapa = 1 AND ta.id_marcador  NOT IN (6,4,5)
                 then 
                    'CERRADO'
                 else
                    'ACTIVO'
                 end
            when ta.ta_estado  =  0 
            then 
                'INACTIVO'
            end as estado,
            ca.id_cargo, 
            ca.ca_descripcion,
            ma.id_marcador,
            CONCAT(ma_abreviatura," - ",ma_descripcion) AS marcador,
            case 
            when ta.id_marcador  = 6 and ta.ta_remunerado = 0
            then 
                '0.00'
            when ta.id_marcador  = 6 and ta.ta_remunerado = 1 and ta.ta_estado = 1
            then 
                fun_getCostoPorDiaEmpleadoReporte(ta.id_persona, ta.ta_fecha_r)
            when ta.id_marcador  =  4 and ta.ta_estado = 1
            then 
                'POR DETERMINAR'
            when ta.id_marcador  =  3 and ta.ta_estado = 1
            then 
                ROUND(fun_getCostoPorDiaEmpleadoReporte(ta.id_persona, ta.ta_fecha_r) * 1.36, 2)
            when ta.id_marcador  =  2 and ta.ta_estado = 1
            then 
                fun_getCostoPorDiaEmpleadoReporte(ta.id_persona, ta.ta_fecha_r)
            when ta.id_marcador  =  1 and ta.ta_estado = 1
            then 
                fun_getCostoPorDiaEmpleadoReporte(ta.id_persona, ta.ta_fecha_r)
            when ta.id_marcador  =  5
            then 
                '0.00'
            else 
                '0.00' 
            end as pagoXEsteDia
            from tareo ta
            INNER JOIN persona pe ON pe.id_persona = ta.id_persona 
            INNER JOIN empleado em on em.id_persona = pe.id_persona  
            INNER JOIN sede se on ta.id_sede = se.id_sede 
            INNER JOIN cargo ca on ca.id_cargo = ta.id_cargo
            INNER JOIN marcador ma on ma.id_marcador = ta.id_marcador
            WHERE 
            pe.per_documento = IN_documento
            AND Date(ta.ta_fecha_r) BETWEEN Date(IN_fechaInicio) and Date(IN_fechaFin)
            AND ta.ta_estado = 1
            order by ta.ta_fecha_r ASC; 
    ELSE
        
        SELECT  
            LPAD(ta.id_tareo,7,'0') as id_tareo, 
            pe.per_documento,
            CONCAT(pe.per_nombre," ",pe.per_apellido_paterno," ",pe.per_apellido_materno) AS datos,
            date(ta.ta_fecha_r) as ta_fecha_r,
            ta.ta_hora_r, 
            case ta.ta_etapa
                when 0 then ' - '
                when 1 then date(ta.ta_fecha_c)
            end as ta_fecha_c, 
            case ta.ta_etapa
                when 0 then ' - '
                when 1 then ta.ta_hora_c
            end as ta_hora_c,
            ta.ta_estado estado_nr,
            case
            when ta.ta_estado  = 1 
            then 
                 case 
                 when ta.ta_etapa = 0 AND ta.id_marcador  NOT IN (6,4,5)
                 then
                    'PENDIENTE POR CERRAR'
                 when ta.ta_etapa = 1 AND ta.id_marcador  NOT IN (6,4,5)
                 then 
                    'CERRADO'
                 else
                    'ACTIVO'
                 end
            when ta.ta_estado  =  0 
            then 
                'INACTIVO'
            end as estado,
            ca.id_cargo, 
            ca.ca_descripcion,
            ma.id_marcador,
            CONCAT(ma_abreviatura," - ",ma_descripcion) AS marcador,
            case 
            when ta.id_marcador  = 6 and ta.ta_remunerado = 0
            then 
                '0.00'
            when ta.id_marcador  = 6 and ta.ta_remunerado = 1 and ta.ta_estado = 1
            then 
                fun_getCostoPorDiaEmpleadoReporte(ta.id_persona, ta.ta_fecha_r)
            when ta.id_marcador  =  4 and ta.ta_estado = 1
            then 
                'POR DETERMINAR'
            when ta.id_marcador  =  3 and ta.ta_estado = 1
            then 
                ROUND(fun_getCostoPorDiaEmpleadoReporte(ta.id_persona, ta.ta_fecha_r) * 1.36, 2)
            when ta.id_marcador  =  2 and ta.ta_estado = 1
            then 
                fun_getCostoPorDiaEmpleadoReporte(ta.id_persona, ta.ta_fecha_r)
            when ta.id_marcador  =  1 and ta.ta_estado = 1
            then 
                fun_getCostoPorDiaEmpleadoReporte(ta.id_persona, ta.ta_fecha_r)
            when ta.id_marcador  =  5
            then 
                '0.00'
            else 
                '0.00' 
            end as pagoXEsteDia
            from tareo ta
            INNER JOIN persona pe ON pe.id_persona = ta.id_persona 
            INNER JOIN empleado em on em.id_persona = pe.id_persona  
            INNER JOIN sede se on ta.id_sede = se.id_sede 
            INNER JOIN cargo ca on ca.id_cargo = ta.id_cargo
            INNER JOIN marcador ma on ma.id_marcador = ta.id_marcador
            WHERE ma.id_marcador = IN_idMarcador 
            AND pe.per_documento = IN_documento
            AND Date(ta.ta_fecha_r) BETWEEN Date(IN_fechaInicio) and Date(IN_fechaFin)
            AND ta.ta_estado = 1
            order by ta.ta_fecha_r ASC;   
    END IF;
END$$

CREATE  PROCEDURE UP_BUSCAR_TAREO_SUPERVISOR_hosting (IN IN_fechaInicio VARCHAR(50), IN IN_fechaFin VARCHAR(50), IN IN_documento VARCHAR(50), IN IN_idMarcador VARCHAR(50), IN IN_idSede INT)  BEGIN 

    IF IN_idMarcador = 0 
    THEN
            SELECT  
            LPAD(ta.id_tareo,7,'0') as id_tareo, 
            pe.per_documento,
            CONCAT(pe.per_nombre," ",pe.per_apellido_paterno," ",pe.per_apellido_materno) AS datos,
            date(ta.ta_fecha_r) as ta_fecha_r,
            ta.ta_hora_r, 
            case ta.ta_etapa
                when 0 then ' - '
                when 1 then date(ta.ta_fecha_c)
            end as ta_fecha_c, 
            case ta.ta_etapa
                when 0 then ' - '
                when 1 then ta.ta_hora_c
            end as ta_hora_c,
            ta.ta_estado estado_nr, 
            case
            when ta.ta_estado  = 1 
            then 
                 case 
                 when ta.ta_etapa = 0 AND ta.id_marcador  NOT IN (6,4,5)
                 then
                    'PENDIENTE POR CERRAR'
                 when ta.ta_etapa = 1 AND ta.id_marcador  NOT IN (6,4,5)
                 then 
                    'CERRADO'
                 else
                    'ACTIVO'
                 end
            when ta.ta_estado  =  0 
            then 
                'INACTIVO'
            end as estado, 
            ca.id_cargo, 
            ca.ca_descripcion,
            ma.id_marcador,
            CONCAT(ma_abreviatura," - ",ma_descripcion) AS marcador
             from tareo ta
            INNER JOIN persona pe ON pe.id_persona = ta.id_persona 
            INNER JOIN empleado em on em.id_persona = pe.id_persona  
            INNER JOIN sede se on ta.id_sede = se.id_sede 
            INNER JOIN cargo ca on ca.id_cargo = ta.id_cargo
            INNER JOIN marcador ma on ma.id_marcador = ta.id_marcador
            WHERE 
            pe.per_documento like concat('%',IN_documento,'%') 
            AND Date(ta.ta_fecha_r) BETWEEN Date(IN_fechaInicio) and Date(IN_fechaFin)
            AND ta.id_sede = IN_idSede 
            AND ta.ta_estado = 1
            order by UPPER (CONCAT(pe.per_nombre," ",pe.per_apellido_paterno," ",pe.per_apellido_materno)), ta.ta_fecha_r ASC; 
    ELSE
        
        SELECT  
            LPAD(ta.id_tareo,7,'0') as id_tareo, 
            pe.per_documento,
            CONCAT(pe.per_nombre," ",pe.per_apellido_paterno," ",pe.per_apellido_materno) AS datos,
            date(ta.ta_fecha_r) as ta_fecha_r,
            ta.ta_hora_r, 
            case ta.ta_etapa
                when 0 then ' - '
                when 1 then date(ta.ta_fecha_c)
            end as ta_fecha_c, 
            case ta.ta_etapa
                when 0 then ' - '
                when 1 then ta.ta_hora_c
            end as ta_hora_c,
            ta.ta_estado estado_nr,
            case
            when ta.ta_estado  = 1 
            then 
                 case 
                 when ta.ta_etapa = 0 AND ta.id_marcador  NOT IN (6,4,5)
                 then
                    'PENDIENTE POR CERRAR'
                 when ta.ta_etapa = 1 AND ta.id_marcador  NOT IN (6,4,5)
                 then 
                    'CERRADO'
                 else
                    'ACTIVO'
                 end
            when ta.ta_estado  =  0 
            then 
                'INACTIVO'
            end as estado,
            ca.id_cargo, 
            ca.ca_descripcion,
            ma.id_marcador,
            CONCAT(ma_abreviatura," - ",ma_descripcion) AS marcador
             from tareo ta
            INNER JOIN persona pe ON pe.id_persona = ta.id_persona 
            INNER JOIN empleado em on em.id_persona = pe.id_persona  
            INNER JOIN sede se on ta.id_sede = se.id_sede 
            INNER JOIN cargo ca on ca.id_cargo = ta.id_cargo
            INNER JOIN marcador ma on ma.id_marcador = ta.id_marcador
            WHERE ma.id_marcador = IN_idMarcador AND  
             pe.per_documento like concat('%',IN_documento,'%') 
             AND Date(ta.ta_fecha_r) BETWEEN Date(IN_fechaInicio) and Date(IN_fechaFin)
             AND ta.id_sede = IN_idSede 
             AND ta.ta_estado = 1
             order by UPPER (CONCAT(pe.per_nombre," ",pe.per_apellido_paterno," ",pe.per_apellido_materno)), ta.ta_fecha_r ASC;  
    END IF;

END$$

CREATE  PROCEDURE up_cambiar_contrasenia_usuario (IN IN_usuario INT, IN IN_contrasenia_actual VARCHAR(50), IN IN_contrasenia_nueva INT, IN IN_userCreacion VARCHAR(50))  begin 
	
	declare dec_idUsuario int default 0;
	
	select 
		id_usuario into dec_idUsuario 
	from usuario u where us_usuario  = IN_usuario and us_contrasenia = IN_contrasenia_actual;

	if(dec_idUsuario = 0)
	then
		signal sqlstate '45000' set message_text = '¡La contraseña actual, ingresada es incorrecta!';
	end if;

	
	update usuario 
	set 
		us_contrasenia = IN_contrasenia_nueva
		,userModificacion = IN_userCreacion
	    ,fechaModificacion= now()
	where us_usuario  = IN_usuario and us_contrasenia = IN_contrasenia_actual; 


end$$

CREATE  PROCEDURE UP_CAMBIO_CONTRASENIA_PERSONA_ID (IN IN_id_persona INT, IN IN_contrasenia VARCHAR(50))  BEGIN

 UPDATE  usuario  
 SET  us_contrasenia=IN_contrasenia 
 WHERE us_persona = IN_id_persona;
 
END$$

CREATE  PROCEDURE UP_CAMBIO_ESTADO_SEDE_PERSONAWEB (IN IN_id_sede_em INT, IN IN_sm_estado INT, IN IN_userCreacion VARCHAR(50))  BEGIN 

	declare dec_id_persona int;

	IF IN_sm_estado = 1
    then
    	select  id_persona into dec_id_persona from sede_empleado se where se.id_sede_em = IN_id_sede_em;
        update sede_empleado SET
             sm_estado = 0
            ,userModificacion	= IN_userCreacion
			,fechaModificacion	= now()
        WHERE 
        id_persona  	= dec_id_persona
        and sm_estado 	= 1 ;
    END IF;
   
    UPDATE sede_empleado 
    SET sm_estado = IN_sm_estado
    ,userModificacion	= IN_userCreacion
	,fechaModificacion= now()
    WHERE id_sede_em = IN_id_sede_em;
 
END$$

CREATE  PROCEDURE up_cambio_masivo_sueldo (IN IN_SEDE VARCHAR(8), IN IN_FECHA VARCHAR(15))  begin 
    
    ##CURSOR
    DECLARE findelbucle INTEGER DEFAULT 0; 
    
    # CURSOR LOOP
    declare id_persona int;

    #cursor para las personas
    DECLARE personas_tareo CURSOR for
    select distinct p.id_persona from persona p inner join sede_empleado se on p.id_persona  = se.id_persona and se.sm_estado  = 1 where se.id_sede  = IN_SEDE and p.pe_estado  = 1; 

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET findelbucle=1;
     
    #star cursor
    OPEN personas_tareo;
        loop1: loop
          
        FETCH personas_tareo INTO id_persona; 
        IF findelbucle = 1 THEN
           LEAVE loop1;
        END IF;
        
        UPDATE sueldo SET ta_vigenciaFin=IN_FECHA WHERE id_sueldo = (SELECT
        MAX(s.id_sueldo) 
        FROM sueldo s where s.id_persona = id_persona and s.ta_estado  = 1 limit 1);
        
       
       END LOOP loop1;
    CLOSE personas_tareo; 
    
    
END$$

CREATE  PROCEDURE up_cantidad_empleados ()  begin 
    
select 
count(e.id_persona) as CANTIDAD
from persona p inner join empleado e on p.id_persona  = e.id_persona 
where p.id_persona != 1
;
    
END$$

CREATE  PROCEDURE up_cantidad_personas_aprobar ()  begin 
    
select 
    count(*) as CANTIDAD
from empleado em where em.phc_estado = 3;
    
END$$

CREATE  PROCEDURE up_cantidad_tareo_registrado ()  begin 
    
select 
    count(*) as CANTIDAD
from tareo t where t.ta_estado = 1;
    
END$$

CREATE  PROCEDURE UP_CERRAR_TAREO (IN IN_id_tareo INT, IN IN_ta_estado INT, IN IN_ta_etapa INT, IN IN_ta_fecha_c DATETIME, IN IN_ta_hora_c TIME)  BEGIN 

    ## DECLARES
    DECLARE dec_horasTrabajadas varchar(40);
    DECLARE dec_FechaInicial datetime;

    ## TRANSACCION
    DECLARE errno INT;
    DECLARE msg_errno TEXT;
    DECLARE msg TEXT;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION

    BEGIN
        GET CURRENT DIAGNOSTICS CONDITION 1 errno = MYSQL_ERRNO,msg_errno = MESSAGE_TEXT ; 
            ##SELECT msg_errno  AS MYSQL_ERROR;
            set msg = concat('TRY: ', msg_errno);
            signal sqlstate '45000' set message_text = msg;
            #signal sqlstate MYSQL_ERROR set message_text = msg_errno;
        ROLLBACK;
    END;

    START TRANSACTION;
    IF EXISTS(
        SELECT
            id_tareo
        FROM
            tareo
        WHERE  
            id_tareo = IN_id_tareo AND ta_estado <> 1 AND ta_etapa <> 0
    )
    THEN
        signal sqlstate '45000' set message_text = 'Este tareo ya esta cerrado!';
    ELSE 
            ## OBTENIENDO LA FECHA INICIAL
            select ta_fecha_r into dec_FechaInicial from tareo WHERE id_tareo = IN_id_tareo;
            ## CALCULANDO LA HORAS TRABAJADAS
            set dec_horasTrabajadas = timestampdiff(second,dec_FechaInicial, concat(IN_ta_fecha_c," ",IN_ta_hora_c))/3600;

            IF dec_FechaInicial > concat(IN_ta_fecha_c," ",IN_ta_hora_c)
            THEN
                signal sqlstate '45000' set message_text = 'La hora ingresada tiene que ser mayor que la hora registrada!';
            ELSE
                ## ACTUALIZANDO
                UPDATE tareo
                    SET 
                    ta_estado   =   IN_ta_estado, 
                    ta_etapa    =   IN_ta_etapa,
                    ta_fecha_c  =   IN_ta_fecha_c, 
                    ta_hora_c   =   IN_ta_hora_c,
                    ta_hrstrabajadas = dec_horasTrabajadas
                WHERE 
                id_tareo = IN_id_tareo; 
            END IF;

            
    END IF;
## RETURN TO TABLES...
COMMIT WORK;
END$$

CREATE  PROCEDURE UP_CONTAR_DATA_ABREVIATURA (IN IN_cap_codigo VARCHAR(40), IN IN_fecha VARCHAR(40))  BEGIN

SELECT  
    COALESCE(SUM(t.id_marcador = 1),0) as maniana,
    COALESCE(SUM(t.id_marcador = 2),0) as tarde,
    COALESCE(SUM(t.id_marcador = 3),0) as noche
FROM tareo t 
INNER JOIN persona s on s.id_persona = t.id_persona
WHERE s.id_persona in(
    select d.id_persona from ca_planilla c INNER JOIN de_planilla d on c.id_planilla = d.id_planilla
    and c.cap_codigo = IN_cap_codigo
)
and date(t.ta_fecha_r) = date(IN_fecha);

END$$

CREATE  PROCEDURE UP_DESHABILITAR_CARGO_PERSONAWEB (IN IN_id_caempleado INT, IN IN_userCreacion VARCHAR(50))  BEGIN 

    UPDATE cargos_empleado 
    SET ce_estado = 0
    ,userModificacion	= IN_userCreacion
	,fechaModificacion= now()
    WHERE id_caempleado = IN_id_caempleado;
 
END$$

CREATE  PROCEDURE UP_DESHABILITAR_DESCANSO_PERSONAWEB (IN IN_id_descanso INT, IN IN_userCreacion VARCHAR(50))  BEGIN  

    update descanso set de_estado = 0 
    ,userModificacion	= IN_userCreacion
	,fechaModificacion= now()
    WHERE id_descanso = IN_id_descanso; 
 
END$$

CREATE  PROCEDURE UP_DESHABILITAR_PERSONA_PERSONAWEB (IN IN_id_persona INT, IN IN_userCreacion VARCHAR(50))  BEGIN 
    
    UPDATE persona_has_banco 
    SET phb_estado=0
    ,userModificacion	= IN_userCreacion
	,fechaModificacion= now()
    WHERE id_persona  = IN_id_persona ;

    UPDATE persona 
    SET pe_estado = 0
    ,userModificacion	= IN_userCreacion
	,fechaModificacion= now()
    WHERE id_persona  = IN_id_persona ;
 
END$$

CREATE  PROCEDURE UP_DESHABILITAR_SUELDO_PERSONAWEB (IN IN_id_sueldo INT, IN IN_userCreacion VARCHAR(50))  BEGIN 

    UPDATE sueldo 
    SET ta_estado = 0,
    ta_vigenciaFin = now()
    ,userModificacion	= IN_userCreacion
	,fechaModificacion= now()
    WHERE id_sueldo = IN_id_sueldo;
 
END$$

CREATE  PROCEDURE UP_DESICION_ESTADO_EMPLEADO (IN IN_id_persona INT, IN IN_opcion INT, IN IN_userCreacion VARCHAR(50))  BEGIN

if(IN_opcion = 1)
then
	UPDATE empleado SET
	    phc_estado 			= 1
	    ,userModificacion	= IN_userCreacion
		,fechaModificacion	= now()
	WHERE 
	id_persona = IN_id_persona;

	UPDATE persona  SET 
	     userModificacion	= IN_userCreacion
		,fechaModificacion	= now()
	WHERE 
	id_persona = IN_id_persona;

else 
	DELETE FROM suplente_cobrar WHERE id_persona = IN_id_persona;
	DELETE FROM sueldo WHERE id_persona = IN_id_persona;
	DELETE FROM sede_empleado WHERE id_persona = IN_id_persona; 
	DELETE FROM descanso WHERE id_persona = IN_id_persona;
	DELETE FROM empleado WHERE id_persona = IN_id_persona;
	DELETE FROM persona WHERE id_persona = IN_id_persona;
	delete from persona_has_banco WHERE id_persona = IN_id_persona;
	delete from cargos_empleado WHERE id_persona = IN_id_persona;
	DELETE FROM usuario WHERE us_persona = IN_id_persona;
	DELETE FROM sis_usuario_modperm WHERE id_usuario = (select id_usuario FROM usuario WHERE us_persona = IN_id_persona);

end if;

END$$

CREATE  PROCEDURE up_editar_configuraciones_planilla (IN IN_pc_modo_descanso VARCHAR(8), IN IN_id_configuracion INT)  begin 
    UPDATE 
    pla_configuraciones SET 
    pc_modo_descanso = IN_pc_modo_descanso  WHERE id_configuracion = IN_id_configuracion;

END$$

CREATE  PROCEDURE up_eliminar_documentos_empleado (IN IN_id_docemp INT)  begin 

	UPDATE documentos_has_empleado 
	SET 
		flEliminado=0
	WHERE id_docemp = IN_id_docemp;
	
end$$

CREATE  PROCEDURE up_eliminar_documentos_s (IN IN_id_docemp INT)  begin 

	UPDATE documentos_has_empleado 
	SET 
		flEliminado=0
	WHERE id_docemp = IN_id_docemp;
	
end$$

CREATE  PROCEDURE UP_ELIMINAR_TAREO_WEB (IN IN_id_tareo INT)  BEGIN  
   DELETE FROM tareo WHERE id_tareo = IN_id_tareo; 
END$$

CREATE  PROCEDURE up_generar_planilla_15CNA (IN IN_MES VARCHAR(8), IN IN_ANIO VARCHAR(8), IN IN_SEDE INT)  begin 
    declare mismo_inicio date;
    declare inicio_dia date;
    declare final_quincena date; 
    declare perido_interno varchar(80);
    declare dias_x_mes int;
    declare dec_porcNoche decimal(9,2);

    DECLARE findelbucle INTEGER DEFAULT 0; 

    # CURSOR LOOP
    declare documento varchar(50);
    declare id_persona int;

    #cursor para las personas
    DECLARE personas_tareo CURSOR for
    select distinct p.per_documento, p.id_persona  from tareo t 
    inner join sueldo s  
    on t.id_sueldo  = s.id_sueldo 
    inner join persona p
    on p.id_persona  = s.id_persona
    and t.id_sede  = IN_SEDE
    and date(t.ta_fecha_r) between  date(inicio_dia) and date(final_quincena); 

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET findelbucle=1;
 
    DROP TABLE IF EXISTS persona_tareo;
    CREATE TEMPORARY TABLE persona_tareo(
        id_tareo int,
        id_marcador int,
        remunerado int,
        ta_estado int,
        documento varchar(50),
        id_persona int,
        fecha date,
        id_sueldo int,
        cst_dia decimal(9,2),
        ta_remunerado int
    ); 
     
    set inicio_dia := concat(IN_ANIO,'-',IN_MES,'-01');
    set final_quincena := concat(IN_ANIO,'-',IN_MES,'-15');
    set mismo_inicio := concat(IN_ANIO,'-',IN_MES,'-01');
    set perido_interno := concat(IN_ANIO,'-',IN_MES,'-15'); 
    select EXTRACT(DAY from LAST_DAY(mismo_inicio)) into dias_x_mes;
    set dec_porcNoche := 1.35;
    
    
 #star cursor
 OPEN personas_tareo;
    loop1: LOOP
            FETCH personas_tareo INTO documento, id_persona; 
            IF findelbucle = 1 THEN
               LEAVE loop1;
            END IF;
           
            WHILE inicio_dia <= final_quincena DO 
            
                if exists(select * from tareo t inner join sueldo s 
                        on t.id_sueldo  = s.id_sueldo 
                        inner join  persona p on s.id_persona  = p.id_persona 
                        where date(t.ta_fecha_r) = date(inicio_dia) and p.per_documento = documento
                        and t.ta_estado = 1
                        )
                then 
                
                    insert into persona_tareo
                    select 
                        t.id_tareo,
                        t.id_marcador,
                        t.ta_remunerado,
                        t.ta_estado,
                        p.per_documento,
                        id_persona,
                        t.ta_fecha_r,
                        t.id_sueldo,
                        #s.ta_csdia
                        ROUND(cast(((s.ta_basico+s.ta_asignacion_familiar) / dias_x_mes)  as decimal(9,2)), 2)  cst_dia,
                        t.ta_remunerado
                    from tareo t inner join sueldo s 
                            on t.id_sueldo  = s.id_sueldo 
                    inner join  persona p 
                            on s.id_persona  = p.id_persona 
                    where date(t.ta_fecha_r) = date(inicio_dia) and p.per_documento = documento
                    and t.ta_estado = 1
                    ;
                else
                
                    insert into persona_tareo
                    select 0,0, 0, 0, documento,id_persona,inicio_dia,0,0,0;
                
                end if;
            
            SET inicio_dia = ADDDATE(inicio_dia, INTERVAL 1 DAY);
            END WHILE;
        SET inicio_dia = mismo_inicio;
    END LOOP loop1;
CLOSE personas_tareo; 
#end cursor 

    DROP TABLE IF EXISTS pre_planilla_;
    create temporary table pre_planilla_(
    select 
    v.id_persona,
    v.fecha, 
    v.id_marcador,
    v.cst_dia,
    concat(year(v.fecha), 
        (
            Case when DAY(v.fecha) <= 8
            THEN 
                '-7'
            when DAY(v.fecha) > 8 and DAY(v.fecha) < 16
            THEN 
                '-15' 
            END
        )
    ) periodo,
    dayofweek(v.fecha)-1 num_dia_sem
    ,(case when v.id_tareo <> 0 and v.ta_estado=1 and v.id_marcador=1   then 1 else 0 end) manana_cumple
    ,(case when v.id_tareo <> 0 and v.ta_estado<>1 and v.id_marcador=1   then 1 else 0 end) manana_no_cumple
    ,(case when v.id_tareo <> 0 and v.ta_estado=1 and v.id_marcador=2   then 1 else 0 end) tarde_cumple
    ,(case when v.id_tareo <> 0 and v.ta_estado<>1 and v.id_marcador=2   then 1 else 0 end) tarde_no_cumple
    ,(case when v.id_tareo <> 0 and v.ta_estado=1 and v.id_marcador=3   then 1 else 0 end) noche_cumple
    ,(case when v.id_tareo <> 0 and v.ta_estado<>1 and v.id_marcador=3   then 1 else 0 end) noche_no_cumple
    ,(case when v.id_marcador = 4  and v.ta_estado = 1  then 1 else 0 end) descanso
    ,(case when v.id_marcador = 5 then 1 else 0 end) faltas
    ,(CASE WHEN EXISTS (
              SELECT * FROM  feriado  WHERE fe_dia = v.fecha
          ) 
            THEN
                1
            ELSE 
                0 
     end) as feriado 
    ,(case when v.id_tareo <> 0 and v.ta_estado = 1  and v.id_marcador = 6 and v.ta_remunerado = 1 then 1 else 0 end) permiso_pago
    ,(case when v.id_tareo <> 0 and v.ta_estado = 1  and v.id_marcador = 6 and v.ta_remunerado = 0 then 1 else 0 end) permiso_no_pago
    from persona_tareo v 
    group by v.id_persona,v.fecha,v.id_marcador  
    );


    DROP TABLE IF EXISTS pre_planilla_2;
    create temporary table pre_planilla_2(
    select 
        p.id_persona,
        p.periodo,
        p.fecha,
        p.cst_dia,
        min(p.fecha) inicio_sem,
        max(p.fecha) fin_sem,
        sum(p.manana_cumple) t_manana_v,
        sum(p.manana_no_cumple) t_manana_no,
        sum(p.tarde_cumple) t_tarde_v,
        sum(p.tarde_no_cumple) t_tarde_no,
        sum(p.noche_cumple) t_noche_v,
        sum(p.noche_no_cumple) t_noche_no,
        sum(p.descanso) descanso,
        sum(p.faltas) faltas,
        sum(p.permiso_pago) permiso_pago,
        sum(p.permiso_no_pago) permiso_no_pago,
        sum(p.manana_cumple*p.cst_dia) total_pago_maniana,
        sum(p.tarde_cumple*p.cst_dia) total_pago_tarde, 
        sum(p.noche_cumple* ROUND(CAST(p.cst_dia*dec_porcNoche AS DECIMAL(9,2)), 2)) total_pago_noche, 
        sum(p.feriado) as feriado,
        ((sum(p.manana_cumple)+sum(p.tarde_cumple))*p.cst_dia)+sum(p.noche_cumple)* ROUND(CAST(p.cst_dia*dec_porcNoche AS DECIMAL(9,2)), 2) subtotal,
        ((sum(p.manana_cumple)+sum(p.tarde_cumple))*p.cst_dia)+sum(p.noche_cumple)* ROUND(CAST(p.cst_dia*dec_porcNoche AS DECIMAL(9,2)), 2)+
        if(sum(p.descanso)=0,0,
            (case 
                when sum(p.faltas)=0 then p.cst_dia
                when sum(p.faltas)=1 then ROUND(CAST(((p.cst_dia/6)*5) AS DECIMAL(9,2)), 2)
                when sum(p.faltas)=2 then ROUND(CAST(((p.cst_dia/6)*4) AS DECIMAL(9,2)), 2)
                when sum(p.faltas)=3 then ROUND(CAST(((p.cst_dia/6)*3) AS DECIMAL(9,2)), 2)
                when sum(p.faltas)=4 then ROUND(CAST(((p.cst_dia/6)*2) AS DECIMAL(9,2)), 2)
                when sum(p.faltas)=5 then ROUND(CAST(((p.cst_dia/6)*1) AS DECIMAL(9,2)), 2)
                else 0 end)
        )+
        if(sum(p.permiso_pago) = 0, 0, p.cst_dia)
        TOTAL_SF, 
        (CASE WHEN EXISTS (
              SELECT * FROM  feriado  WHERE fe_dia = p.fecha
          ) 
            THEN
                ((((sum(p.manana_cumple)+sum(p.tarde_cumple))*p.cst_dia)+sum(p.noche_cumple)* ROUND(CAST(p.cst_dia*dec_porcNoche AS DECIMAL(9,2)), 2))*2)+
                if(sum(p.descanso)=0,0,
                    (case 
                        when sum(p.faltas)=0 then p.cst_dia
                        when sum(p.faltas)=1 then ROUND(CAST(((p.cst_dia/6)*5) AS DECIMAL(9,2)), 2)
                        when sum(p.faltas)=2 then ROUND(CAST(((p.cst_dia/6)*4) AS DECIMAL(9,2)), 2)
                        when sum(p.faltas)=3 then ROUND(CAST(((p.cst_dia/6)*3) AS DECIMAL(9,2)), 2)
                        when sum(p.faltas)=4 then ROUND(CAST(((p.cst_dia/6)*2) AS DECIMAL(9,2)), 2)
                        when sum(p.faltas)=5 then ROUND(CAST(((p.cst_dia/6)*1) AS DECIMAL(9,2)), 2)
                        else 0 end)
                )+
                if(sum(p.permiso_pago) = 0, 0, p.cst_dia)
            ELSE 
                ((sum(p.manana_cumple)+sum(p.tarde_cumple))*p.cst_dia)+sum(p.noche_cumple)* ROUND(CAST(p.cst_dia*dec_porcNoche AS DECIMAL(9,2)), 2)+
                if(sum(p.descanso)=0,0,
                    (case 
                        when sum(p.faltas)=0 then p.cst_dia
                        when sum(p.faltas)=1 then ROUND(CAST(((p.cst_dia/6)*5) AS DECIMAL(9,2)), 2)
                        when sum(p.faltas)=2 then ROUND(CAST(((p.cst_dia/6)*4) AS DECIMAL(9,2)), 2)
                        when sum(p.faltas)=3 then ROUND(CAST(((p.cst_dia/6)*3) AS DECIMAL(9,2)), 2)
                        when sum(p.faltas)=4 then ROUND(CAST(((p.cst_dia/6)*2) AS DECIMAL(9,2)), 2)
                        when sum(p.faltas)=5 then ROUND(CAST(((p.cst_dia/6)*1) AS DECIMAL(9,2)), 2)
                        else 0 end)
                )+
                if(sum(p.permiso_pago) = 0, 0, p.cst_dia)
            END  
        ) TOTAL_CF 
        from pre_planilla_ p 
        #inner join sueldo su on p.id_persona=su.id_persona
        group by 
        p.id_persona,
        p.fecha
    );

select * from pre_planilla_2;
     
     
END$$

CREATE  PROCEDURE up_generar_planilla_15CNA_2 (IN IN_MES VARCHAR(8), IN IN_ANIO VARCHAR(8), IN IN_SEDE INT)  begin 
    declare mismo_inicio date;
    declare inicio_dia date;
    declare final_quincena date; 
    declare perido_interno varchar(80);
    declare dias_x_mes int;
    declare dec_porcNoche decimal(9,2);

    DECLARE findelbucle INTEGER DEFAULT 0; 

    # CURSOR LOOP
    declare documento varchar(50);
    declare id_persona int;

    #cursor para las personas
    DECLARE personas_tareo CURSOR for
    select distinct p.per_documento, p.id_persona  from tareo t 
    inner join sueldo s  
    on t.id_sueldo  = s.id_sueldo 
    inner join persona p
    on p.id_persona  = s.id_persona
    and t.id_sede  = IN_SEDE
    and date(t.ta_fecha_r) between  date(inicio_dia) and date(final_quincena);

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET findelbucle=1;
 
    DROP TABLE IF EXISTS persona_tareo;
    CREATE TEMPORARY TABLE persona_tareo(
        id_tareo int,
        id_marcador int,
        remunerado int,
        ta_estado int,
        documento varchar(50),
        id_persona int,
        fecha date,
        id_sueldo int,
        cst_dia decimal(9,2),
        ta_remunerado int
    ); 
     
    set inicio_dia := concat(IN_ANIO,'-',IN_MES,'-16');
    set final_quincena := last_day(inicio_dia); 
    set mismo_inicio := concat(IN_ANIO,'-',IN_MES,'-16');
    set perido_interno := last_day(inicio_dia); 
    select EXTRACT(DAY from LAST_DAY(mismo_inicio)) into dias_x_mes;
    set dec_porcNoche := 1.35;
    
    
 #star cursor
 OPEN personas_tareo;
    loop1: LOOP
            FETCH personas_tareo INTO documento, id_persona; 
            IF findelbucle = 1 THEN
               LEAVE loop1;
            END IF;
           
            WHILE inicio_dia <= final_quincena DO 
            
                if exists(select * from tareo t inner join sueldo s 
                        on t.id_sueldo  = s.id_sueldo 
                        inner join  persona p on s.id_persona  = p.id_persona 
                        where date(t.ta_fecha_r) = date(inicio_dia) and p.per_documento = documento
                        and t.ta_estado = 1
                        )
                then 
                
                    insert into persona_tareo
                    select 
                        t.id_tareo,
                        t.id_marcador,
                        t.ta_remunerado,
                        t.ta_estado,
                        p.per_documento,
                        id_persona,
                        t.ta_fecha_r,
                        t.id_sueldo,
                        #s.ta_csdia
                        ROUND(cast(((s.ta_basico+s.ta_asignacion_familiar) / dias_x_mes)  as decimal(9,2)), 2)  cst_dia,
                        t.ta_remunerado
                    from tareo t inner join sueldo s 
                            on t.id_sueldo  = s.id_sueldo 
                    inner join  persona p 
                            on s.id_persona  = p.id_persona 
                    where date(t.ta_fecha_r) = date(inicio_dia) and p.per_documento = documento and t.ta_estado = 1;
                else
                
                    insert into persona_tareo
                    select 0,0, 0, 0, documento,id_persona,inicio_dia,0,0,0;
                
                end if;
            
            SET inicio_dia = ADDDATE(inicio_dia, INTERVAL 1 DAY);
            END WHILE;
        SET inicio_dia = mismo_inicio;
    END LOOP loop1;
CLOSE personas_tareo; 
#end cursor 

    DROP TABLE IF EXISTS pre_planilla_;
    create temporary table pre_planilla_(
    select 
    v.id_persona,
    v.fecha, 
    v.id_marcador,
    v.cst_dia,
    concat(year(v.fecha), 
        (
            Case when DAY(v.fecha) > 15 and DAY(v.fecha) <= 22
            THEN 
                '-22'
            when DAY(v.fecha) > 22 and DAY(v.fecha) <= DAY(LAST_DAY(mismo_inicio))
            THEN 
                '-30'
            END
        )
    ) periodo,
    dayofweek(v.fecha)-1 num_dia_sem
    ,(case when v.id_tareo <> 0 and v.ta_estado=1 and v.id_marcador=1   then 1 else 0 end) manana_cumple
    ,(case when v.id_tareo <> 0 and v.ta_estado<>1 and v.id_marcador=1   then 1 else 0 end) manana_no_cumple
    ,(case when v.id_tareo <> 0 and v.ta_estado=1 and v.id_marcador=2   then 1 else 0 end) tarde_cumple
    ,(case when v.id_tareo <> 0 and v.ta_estado<>1 and v.id_marcador=2   then 1 else 0 end) tarde_no_cumple
    ,(case when v.id_tareo <> 0 and v.ta_estado=1 and v.id_marcador=3   then 1 else 0 end) noche_cumple
    ,(case when v.id_tareo <> 0 and v.ta_estado<>1 and v.id_marcador=3   then 1 else 0 end) noche_no_cumple
    ,(case when v.id_marcador = 4  and v.ta_estado = 1  then 1 else 0 end) descanso
    ,(case when v.id_marcador = 5 then 1 else 0 end) faltas
    ,(CASE WHEN EXISTS (
              SELECT * FROM  feriado  WHERE fe_dia = v.fecha
          ) 
            THEN
                1
            ELSE 
                0 
     end) as feriado 
    ,(case when v.id_tareo <> 0 and v.ta_estado = 1  and v.id_marcador = 6 and v.ta_remunerado = 1 then 1 else 0 end) permiso_pago
    ,(case when v.id_tareo <> 0 and v.ta_estado = 1  and v.id_marcador = 6 and v.ta_remunerado = 0 then 1 else 0 end) permiso_no_pago
    from persona_tareo v 
    group by v.id_persona,v.fecha,v.id_marcador  
    );
   
    DROP TABLE IF EXISTS pre_planilla_2;
    create temporary table pre_planilla_2(
    select 
        p.id_persona,
        p.periodo,
        p.fecha,
        p.cst_dia,
        min(p.fecha) inicio_sem,
        max(p.fecha) fin_sem,
        sum(p.manana_cumple) t_manana_v,
        sum(p.manana_no_cumple) t_manana_no,
        sum(p.tarde_cumple) t_tarde_v,
        sum(p.tarde_no_cumple) t_tarde_no,
        sum(p.noche_cumple) t_noche_v,
        sum(p.noche_no_cumple) t_noche_no,
        sum(p.descanso) descanso,
        sum(p.faltas) faltas,
        sum(p.permiso_pago) permiso_pago,
        sum(p.permiso_no_pago) permiso_no_pago,
        sum(p.manana_cumple*p.cst_dia) total_pago_maniana,
        sum(p.tarde_cumple*p.cst_dia) total_pago_tarde, 
        sum(p.noche_cumple* ROUND(CAST(p.cst_dia*dec_porcNoche AS DECIMAL(9,2)), 2)) total_pago_noche, 
        sum(p.feriado) as feriado,
        ((sum(p.manana_cumple)+sum(p.tarde_cumple))*p.cst_dia)+sum(p.noche_cumple)* ROUND(CAST(p.cst_dia*dec_porcNoche AS DECIMAL(9,2)), 2) subtotal,
        ((sum(p.manana_cumple)+sum(p.tarde_cumple))*p.cst_dia)+sum(p.noche_cumple)* ROUND(CAST(p.cst_dia*dec_porcNoche AS DECIMAL(9,2)), 2)+
        if(sum(p.descanso)=0,0,
            (case 
                when sum(p.faltas)=0 then p.cst_dia
                when sum(p.faltas)=1 then ROUND(CAST(((p.cst_dia/6)*5) AS DECIMAL(9,2)), 2)
                when sum(p.faltas)=2 then ROUND(CAST(((p.cst_dia/6)*4) AS DECIMAL(9,2)), 2)
                when sum(p.faltas)=3 then ROUND(CAST(((p.cst_dia/6)*3) AS DECIMAL(9,2)), 2)
                when sum(p.faltas)=4 then ROUND(CAST(((p.cst_dia/6)*2) AS DECIMAL(9,2)), 2)
                when sum(p.faltas)=5 then ROUND(CAST(((p.cst_dia/6)*1) AS DECIMAL(9,2)), 2)
                else 0 end)
        )+
        if(sum(p.permiso_pago) = 0, 0, p.cst_dia)
        TOTAL_SF, 
        (CASE WHEN EXISTS (
              SELECT * FROM  feriado  WHERE fe_dia = p.fecha
          ) 
            THEN
                ((((sum(p.manana_cumple)+sum(p.tarde_cumple))*p.cst_dia)+sum(p.noche_cumple)* ROUND(CAST(p.cst_dia*dec_porcNoche AS DECIMAL(9,2)), 2))*2)+
                if(sum(p.descanso)=0,0,
                    (case 
                        when sum(p.faltas)=0 then p.cst_dia
                        when sum(p.faltas)=1 then ROUND(CAST(((p.cst_dia/6)*5) AS DECIMAL(9,2)), 2)
                        when sum(p.faltas)=2 then ROUND(CAST(((p.cst_dia/6)*4) AS DECIMAL(9,2)), 2)
                        when sum(p.faltas)=3 then ROUND(CAST(((p.cst_dia/6)*3) AS DECIMAL(9,2)), 2)
                        when sum(p.faltas)=4 then ROUND(CAST(((p.cst_dia/6)*2) AS DECIMAL(9,2)), 2)
                        when sum(p.faltas)=5 then ROUND(CAST(((p.cst_dia/6)*1) AS DECIMAL(9,2)), 2)
                        else 0 end)
                )+
                if(sum(p.permiso_pago) = 0, 0, p.cst_dia)
            ELSE 
                ((sum(p.manana_cumple)+sum(p.tarde_cumple))*p.cst_dia)+sum(p.noche_cumple)* ROUND(CAST(p.cst_dia*dec_porcNoche AS DECIMAL(9,2)), 2)+
                if(sum(p.descanso)=0,0,
                    (case 
                        when sum(p.faltas)=0 then p.cst_dia
                        when sum(p.faltas)=1 then ROUND(CAST(((p.cst_dia/6)*5) AS DECIMAL(9,2)), 2)
                        when sum(p.faltas)=2 then ROUND(CAST(((p.cst_dia/6)*4) AS DECIMAL(9,2)), 2)
                        when sum(p.faltas)=3 then ROUND(CAST(((p.cst_dia/6)*3) AS DECIMAL(9,2)), 2)
                        when sum(p.faltas)=4 then ROUND(CAST(((p.cst_dia/6)*2) AS DECIMAL(9,2)), 2)
                        when sum(p.faltas)=5 then ROUND(CAST(((p.cst_dia/6)*1) AS DECIMAL(9,2)), 2)
                        else 0 end)
                )+
                if(sum(p.permiso_pago) = 0, 0, p.cst_dia)
            END  
        ) TOTAL_CF 
        from pre_planilla_ p 
        #inner join sueldo su on p.id_persona=su.id_persona
        group by 
        p.id_persona,
        p.fecha
    );

   
select * from pre_planilla_2;
      
END$$

CREATE  PROCEDURE up_generar_planilla_30AL (IN IN_MES VARCHAR(8), IN IN_ANIO VARCHAR(8), IN IN_SEDE INT)  begin 
    declare mismo_inicio date;
    declare inicio_dia date;
    declare final_mensual date; 
    declare perido_interno varchar(80);
    declare dias_x_mes int;

    DECLARE findelbucle INTEGER DEFAULT 0; 

    # CURSOR LOOP
    declare documento varchar(50);
    declare id_persona int;

    #cursor para las personas
    DECLARE personas_tareo CURSOR for
    select distinct p.per_documento, p.id_persona  from tareo t 
    inner join sueldo s  
    on t.id_sueldo  = s.id_sueldo 
    inner join persona p
    on p.id_persona  = s.id_persona
    and t.id_sede  = IN_SEDE;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET findelbucle=1;
 
    DROP TABLE IF EXISTS persona_tareo;
    CREATE TEMPORARY TABLE persona_tareo(
        id_tareo int,
        id_marcador int,
        remunerado int,
        ta_estado int,
        documento varchar(50),
        id_persona int,
        fecha date,
        id_sueldo int,
        cst_dia decimal(9,2),
        ta_remunerado int
    ); 
 
     
    set inicio_dia := concat(IN_ANIO,'-',IN_MES,'-01');
    set final_mensual := last_day(inicio_dia);
    set mismo_inicio := concat(IN_ANIO,'-',IN_MES,'-01');
    set perido_interno := last_day(inicio_dia);
    select EXTRACT(DAY from LAST_DAY(mismo_inicio)) into dias_x_mes;
    
 #star cursor
 OPEN personas_tareo;
    loop1: LOOP
            FETCH personas_tareo INTO documento, id_persona; 
            IF findelbucle = 1 THEN
               LEAVE loop1;
            END IF;
        
            WHILE inicio_dia <= final_mensual DO 
            
                if exists(select * from tareo t inner join sueldo s 
                        on t.id_sueldo  = s.id_sueldo 
                        inner join  persona p on s.id_persona  = p.id_persona 
                        where date(t.ta_fecha_r) = date(inicio_dia) and p.per_documento = documento)
                then 
                
                    insert into persona_tareo
                    select 
                        t.id_tareo,
                        t.id_marcador,
                        t.ta_remunerado,
                        t.ta_estado,
                        p.per_documento,
                        id_persona,
                        t.ta_fecha_r,
                        t.id_sueldo,
                        #s.ta_csdia
                        cast(((s.ta_basico+s.ta_asignacion_familiar) / dias_x_mes)  as decimal(9,2))  cst_dia,
                        t.ta_remunerado
                    from tareo t inner join sueldo s 
                            on t.id_sueldo  = s.id_sueldo 
                    inner join  persona p 
                            on s.id_persona  = p.id_persona 
                    where date(t.ta_fecha_r) = date(inicio_dia) and p.per_documento = documento;
                else
                
                    insert into persona_tareo
                    select 0,0, 0, 0, documento,id_persona,inicio_dia,0,0,0;
                
                end if;
            
            SET inicio_dia = ADDDATE(inicio_dia, INTERVAL 1 DAY);
            END WHILE;
        SET inicio_dia = mismo_inicio;
    END LOOP loop1;
CLOSE personas_tareo; 
#end cursor 
   
    DROP TABLE IF EXISTS pre_planilla_;
    create temporary table pre_planilla_(
    select 
    v.id_persona,
    v.fecha, 
    v.id_marcador,
    v.cst_dia,
    concat(year(v.fecha), 
        (
            Case when DAY(v.fecha) >= 1  and DAY(v.fecha) <= 8
            THEN 
                '-7'
            when DAY(v.fecha) > 8 and DAY(v.fecha) < 16
            THEN 
                '-15' 
            when DAY(v.fecha) > 15 and DAY(v.fecha) <= 22
            THEN 
                '-22'
            when DAY(v.fecha) > 22 and DAY(v.fecha) <= DAY(LAST_DAY(mismo_inicio))
            THEN 
                '-30'
            END
        )
    ) periodo,
    dayofweek(v.fecha)-1 num_dia_sem
    ,(case when v.id_tareo <> 0 and v.ta_estado=1 and v.id_marcador=1   then 1 else 0 end) manana_cumple
    ,(case when v.id_tareo <> 0 and v.ta_estado<>1 and v.id_marcador=1   then 1 else 0 end) manana_no_cumple
    ,(case when v.id_tareo <> 0 and v.ta_estado=1 and v.id_marcador=2   then 1 else 0 end) tarde_cumple
    ,(case when v.id_tareo <> 0 and v.ta_estado<>1 and v.id_marcador=2   then 1 else 0 end) tarde_no_cumple
    ,(case when v.id_tareo <> 0 and v.ta_estado=1 and v.id_marcador=3   then 1 else 0 end) noche_cumple
    ,(case when v.id_tareo <> 0 and v.ta_estado<>1 and v.id_marcador=3   then 1 else 0 end) noche_no_cumple
    ,(case when v.id_marcador = 4  and v.ta_estado = 1  then 1 else 0 end) descanso
    ,(case when v.id_marcador = 5 then 1 else 0 end) faltas
    ,(case when v.id_tareo <> 0 and v.ta_estado = 1  and v.id_marcador = 6 and v.ta_remunerado = 1 then 1 else 0 end) permiso_pago
    ,(case when v.id_tareo <> 0 and v.ta_estado = 1  and v.id_marcador = 6 and v.ta_remunerado = 0 then 1 else 0 end) permiso_no_pago
    from persona_tareo v 
    group by v.id_persona,v.fecha,v.id_marcador  
    );


    DROP TABLE IF EXISTS pre_planilla_2;
    create temporary table pre_planilla_2(
    select 
        p.id_persona,
        p.periodo,
        p.fecha,
        p.cst_dia,
        min(p.fecha) inicio_sem,
        max(p.fecha) fin_sem,
        sum(p.manana_cumple) t_manana_v,
        sum(p.manana_no_cumple) t_manana_no,
        sum(p.tarde_cumple) t_tarde_v,
        sum(p.tarde_no_cumple) t_tarde_no,
        sum(p.noche_cumple) t_noche_v,
        sum(p.noche_no_cumple) t_noche_no,
        sum(p.descanso) descanso,
        sum(p.faltas) faltas,
        sum(p.permiso_pago) permiso_pago,
        sum(p.permiso_no_pago) permiso_no_pago,
        sum(p.manana_cumple*p.cst_dia) total_pago_maniana,
        sum(p.tarde_cumple*p.cst_dia) total_pago_tarde, 
        sum(p.noche_cumple* ROUND(CAST(p.cst_dia+(p.cst_dia*0.35) AS DECIMAL(9,2)))) total_pago_noche, 
        ((sum(p.manana_cumple)+sum(p.tarde_cumple))*p.cst_dia)+sum(p.noche_cumple)* ROUND(CAST(p.cst_dia+(p.cst_dia*0.35) AS DECIMAL(9,2))) subtotal,
        ((sum(p.manana_cumple)+sum(p.tarde_cumple))*p.cst_dia)+sum(p.noche_cumple)* ROUND(CAST(p.cst_dia+(p.cst_dia*0.35) AS DECIMAL(9,2)))+
        if(sum(p.descanso)=0,0,
            (case 
                when sum(p.faltas)=0 then p.cst_dia
                when sum(p.faltas)=1 then ROUND(CAST(((p.cst_dia/6)*5) AS DECIMAL(9,2)))
                when sum(p.faltas)=2 then ROUND(CAST(((p.cst_dia/6)*4) AS DECIMAL(9,2)))
                when sum(p.faltas)=3 then ROUND(CAST(((p.cst_dia/6)*3) AS DECIMAL(9,2)))
                when sum(p.faltas)=4 then ROUND(CAST(((p.cst_dia/6)*2) AS DECIMAL(9,2)))
                when sum(p.faltas)=5 then ROUND(CAST(((p.cst_dia/6)*1) AS DECIMAL(9,2)))
                else 0 end)
        )+
        if(sum(p.permiso_pago) = 0, 0, p.cst_dia)
        TOTAL_SF, 
        (CASE WHEN EXISTS (
              SELECT * FROM  feriado  WHERE fe_dia = p.fecha
          ) 
            THEN
                ((((sum(p.manana_cumple)+sum(p.tarde_cumple))*p.cst_dia)+sum(p.noche_cumple)* ROUND(CAST(p.cst_dia+(p.cst_dia*0.35) AS DECIMAL(9,2))))*2)+
                if(sum(p.descanso)=0,0,
                    (case 
                        when sum(p.faltas)=0 then p.cst_dia
                        when sum(p.faltas)=1 then ROUND(CAST(((p.cst_dia/6)*5) AS DECIMAL(9,2)))
                        when sum(p.faltas)=2 then ROUND(CAST(((p.cst_dia/6)*4) AS DECIMAL(9,2)))
                        when sum(p.faltas)=3 then ROUND(CAST(((p.cst_dia/6)*3) AS DECIMAL(9,2)))
                        when sum(p.faltas)=4 then ROUND(CAST(((p.cst_dia/6)*2) AS DECIMAL(9,2)))
                        when sum(p.faltas)=5 then ROUND(CAST(((p.cst_dia/6)*1) AS DECIMAL(9,2)))
                        else 0 end)
                )+
                if(sum(p.permiso_pago) = 0, 0, p.cst_dia)
            ELSE 
                ((sum(p.manana_cumple)+sum(p.tarde_cumple))*p.cst_dia)+sum(p.noche_cumple)* ROUND(CAST(p.cst_dia+(p.cst_dia*0.35) AS DECIMAL(9,2)))+
                if(sum(p.descanso)=0,0,
                    (case 
                        when sum(p.faltas)=0 then p.cst_dia
                        when sum(p.faltas)=1 then ROUND(CAST(((p.cst_dia/6)*5) AS DECIMAL(9,2)))
                        when sum(p.faltas)=2 then ROUND(CAST(((p.cst_dia/6)*4) AS DECIMAL(9,2)))
                        when sum(p.faltas)=3 then ROUND(CAST(((p.cst_dia/6)*3) AS DECIMAL(9,2)))
                        when sum(p.faltas)=4 then ROUND(CAST(((p.cst_dia/6)*2) AS DECIMAL(9,2)))
                        when sum(p.faltas)=5 then ROUND(CAST(((p.cst_dia/6)*1) AS DECIMAL(9,2)))
                        else 0 end)
                )+
                if(sum(p.permiso_pago) = 0, 0, p.cst_dia)
            END  
        ) TOTAL_CF 
        from pre_planilla_ p inner join sueldo su on p.id_persona=su.id_persona
        group by 
        p.id_persona,
        p.fecha
    );

select * from pre_planilla_2;
     
END$$

CREATE  PROCEDURE up_generar_planilla_30ALv2 (IN IN_MES VARCHAR(8), IN IN_ANIO VARCHAR(8), IN IN_SEDE INT)  begin 
      
    DROP TABLE IF EXISTS persona_tareo_1Qna;
    CREATE TEMPORARY TABLE persona_tareo_1Qna(
        id_tareo int,
        id_marcador int,
        remunerado int,
        ta_estado int,
        documento varchar(50),
        id_persona int,
        fecha date,
        id_sueldo int,
        cst_dia decimal(9,2),
        ta_remunerado int
    );
   
    DROP TABLE IF EXISTS persona_tareo_2Qna;
    CREATE TEMPORARY TABLE persona_tareo_2Qna(
        id_tareo int,
        id_marcador int,
        remunerado int,
        ta_estado int,
        documento varchar(50),
        id_persona int,
        fecha date,
        id_sueldo int,
        cst_dia decimal(9,2),
        ta_remunerado int
    );
   
   # CALCULO1
   begin
	   	declare mismo_inicio date;
	    declare inicio_dia date;
	    declare final_quincena date;
	    declare inicia_quincena date;
	    declare final_mensual date; 
	    declare perido_interno varchar(80);
	    declare dias_x_mes int;
	    declare dec_porcNoche decimal(9,2);
	   	declare documento1 varchar(50);
    	declare id_persona1 int; 
        DECLARE findelbucle1Qna INTEGER DEFAULT 0; 
    
	   	DECLARE c_personas_tareo_1Qna CURSOR for
	    select distinct p.per_documento, p.id_persona  from tareo t 
	    inner join sueldo s  
	    on t.id_sueldo  = s.id_sueldo 
	    inner join persona p
	    on p.id_persona  = s.id_persona
	    and t.id_sede  = IN_SEDE
	    and date(t.ta_fecha_r) between  date(inicio_dia) and date(final_quincena);
	     DECLARE CONTINUE HANDLER FOR NOT FOUND SET findelbucle1Qna=1;
	   
	   	set inicio_dia := concat(IN_ANIO,'-',IN_MES,'-01');
	    set final_quincena := concat(IN_ANIO,'-',IN_MES,'-15');
	    set inicia_quincena := concat(IN_ANIO,'-',IN_MES,'-15');
	    set mismo_inicio := concat(IN_ANIO,'-',IN_MES,'-01');
	    set perido_interno := concat(IN_ANIO,'-',IN_MES,'-15'); 
	    select EXTRACT(DAY from LAST_DAY(mismo_inicio)) into dias_x_mes;
	    set dec_porcNoche := 1.35;
	    set final_mensual := last_day(inicio_dia);
   
	   
	   	OPEN c_personas_tareo_1Qna;
	    loop1: LOOP
	            FETCH c_personas_tareo_1Qna INTO documento1, id_persona1; 
	            IF findelbucle1Qna = 1 THEN
	               LEAVE loop1;
	            END IF;
	           
	            WHILE inicio_dia <= final_quincena DO 
	            
		                if exists(select * from tareo t inner join sueldo s 
		                        on t.id_sueldo  = s.id_sueldo 
		                        inner join  persona p on s.id_persona  = p.id_persona 
		                        where date(t.ta_fecha_r) = date(inicio_dia) and p.per_documento = documento1
		                        and t.ta_estado = 1
		                        )
		                then 
		                
		                    insert into persona_tareo_1Qna
		                    select 
		                        t.id_tareo,
		                        t.id_marcador,
		                        t.ta_remunerado,
		                        t.ta_estado,
		                        p.per_documento,
		                        id_persona1,
		                        t.ta_fecha_r,
		                        t.id_sueldo,
		                        #s.ta_csdia
		                        ROUND(cast(((s.ta_basico+s.ta_asignacion_familiar) / dias_x_mes)  as decimal(9,2)), 2)  cst_dia,
		                        t.ta_remunerado
		                    from tareo t inner join sueldo s 
		                            on t.id_sueldo  = s.id_sueldo 
		                    inner join  persona p 
		                            on s.id_persona  = p.id_persona 
		                    where date(t.ta_fecha_r) = date(inicio_dia) and p.per_documento = documento1
		                    and t.ta_estado = 1
		                    ;
		                else
		                
		                    insert into persona_tareo_1Qna
		                    select 0,0, 0, 0, documento1,id_persona1,inicio_dia,0,0,0;
		                
		                end if;
	            
	            		SET inicio_dia = ADDDATE(inicio_dia, INTERVAL 1 DAY);
	            	END WHILE;
	        	SET inicio_dia = mismo_inicio;
	    	END LOOP loop1;
		CLOSE c_personas_tareo_1Qna;
	
		
	DROP TABLE IF EXISTS pre_planilla_1Qna;
    create temporary table pre_planilla_1Qna(
    select 
    v.id_persona,
    v.fecha, 
    v.id_marcador,
    v.cst_dia,
    concat(year(v.fecha), 
        (
            Case when DAY(v.fecha) <= 8
            THEN 
                '-7'
            when DAY(v.fecha) > 8 and DAY(v.fecha) < 16
            THEN 
                '-15' 
            END
        )
    ) periodo,
    dayofweek(v.fecha)-1 num_dia_sem
    ,(case when v.id_tareo <> 0 and v.ta_estado=1 and v.id_marcador=1   then 1 else 0 end) manana_cumple
    ,(case when v.id_tareo <> 0 and v.ta_estado<>1 and v.id_marcador=1   then 1 else 0 end) manana_no_cumple
    ,(case when v.id_tareo <> 0 and v.ta_estado=1 and v.id_marcador=2   then 1 else 0 end) tarde_cumple
    ,(case when v.id_tareo <> 0 and v.ta_estado<>1 and v.id_marcador=2   then 1 else 0 end) tarde_no_cumple
    ,(case when v.id_tareo <> 0 and v.ta_estado=1 and v.id_marcador=3   then 1 else 0 end) noche_cumple
    ,(case when v.id_tareo <> 0 and v.ta_estado<>1 and v.id_marcador=3   then 1 else 0 end) noche_no_cumple
    ,(case when v.id_marcador = 4  and v.ta_estado = 1  then 1 else 0 end) descanso
    ,(case when v.id_marcador = 5 then 1 else 0 end) faltas
    ,(CASE WHEN EXISTS (
              SELECT * FROM  feriado  WHERE fe_dia = v.fecha
          ) 
            THEN
                1
            ELSE 
                0 
     end) as feriado 
    ,(case when v.id_tareo <> 0 and v.ta_estado = 1  and v.id_marcador = 6 and v.ta_remunerado = 1 then 1 else 0 end) permiso_pago
    ,(case when v.id_tareo <> 0 and v.ta_estado = 1  and v.id_marcador = 6 and v.ta_remunerado = 0 then 1 else 0 end) permiso_no_pago
    from persona_tareo_1Qna v 
    group by v.id_persona,v.fecha,v.id_marcador  
    );


    DROP TABLE IF EXISTS pre_planilla_1Qna_2;
    create temporary table pre_planilla_1Qna_2(
    select 
        p.id_persona,
        p.periodo,
        p.fecha,
        p.cst_dia,
        min(p.fecha) inicio_sem,
        max(p.fecha) fin_sem,
        sum(p.manana_cumple) t_manana_v,
        sum(p.manana_no_cumple) t_manana_no,
        sum(p.tarde_cumple) t_tarde_v,
        sum(p.tarde_no_cumple) t_tarde_no,
        sum(p.noche_cumple) t_noche_v,
        sum(p.noche_no_cumple) t_noche_no,
        sum(p.descanso) descanso,
        sum(p.faltas) faltas,
        sum(p.permiso_pago) permiso_pago,
        sum(p.permiso_no_pago) permiso_no_pago,
        sum(p.manana_cumple*p.cst_dia) total_pago_maniana,
        sum(p.tarde_cumple*p.cst_dia) total_pago_tarde, 
        sum(p.noche_cumple* ROUND(CAST(p.cst_dia*dec_porcNoche AS DECIMAL(9,2)), 2)) total_pago_noche, 
        sum(p.feriado) as feriado,
        ((sum(p.manana_cumple)+sum(p.tarde_cumple))*p.cst_dia)+sum(p.noche_cumple)* ROUND(CAST(p.cst_dia*dec_porcNoche AS DECIMAL(9,2)), 2) subtotal,
        ((sum(p.manana_cumple)+sum(p.tarde_cumple))*p.cst_dia)+sum(p.noche_cumple)* ROUND(CAST(p.cst_dia*dec_porcNoche AS DECIMAL(9,2)), 2)+
        if(sum(p.descanso)=0,0,
            (case 
                when sum(p.faltas)=0 then p.cst_dia
                when sum(p.faltas)=1 then ROUND(CAST(((p.cst_dia/6)*5) AS DECIMAL(9,2)), 2)
                when sum(p.faltas)=2 then ROUND(CAST(((p.cst_dia/6)*4) AS DECIMAL(9,2)), 2)
                when sum(p.faltas)=3 then ROUND(CAST(((p.cst_dia/6)*3) AS DECIMAL(9,2)), 2)
                when sum(p.faltas)=4 then ROUND(CAST(((p.cst_dia/6)*2) AS DECIMAL(9,2)), 2)
                when sum(p.faltas)=5 then ROUND(CAST(((p.cst_dia/6)*1) AS DECIMAL(9,2)), 2)
                else 0 end)
        )+
        if(sum(p.permiso_pago) = 0, 0, p.cst_dia)
        TOTAL_SF, 
        (CASE WHEN EXISTS (
              SELECT * FROM  feriado  WHERE fe_dia = p.fecha
          ) 
            THEN
                ((((sum(p.manana_cumple)+sum(p.tarde_cumple))*p.cst_dia)+sum(p.noche_cumple)* ROUND(CAST(p.cst_dia*dec_porcNoche AS DECIMAL(9,2)), 2))*2)+
                if(sum(p.descanso)=0,0,
                    (case 
                        when sum(p.faltas)=0 then p.cst_dia
                        when sum(p.faltas)=1 then ROUND(CAST(((p.cst_dia/6)*5) AS DECIMAL(9,2)), 2)
                        when sum(p.faltas)=2 then ROUND(CAST(((p.cst_dia/6)*4) AS DECIMAL(9,2)), 2)
                        when sum(p.faltas)=3 then ROUND(CAST(((p.cst_dia/6)*3) AS DECIMAL(9,2)), 2)
                        when sum(p.faltas)=4 then ROUND(CAST(((p.cst_dia/6)*2) AS DECIMAL(9,2)), 2)
                        when sum(p.faltas)=5 then ROUND(CAST(((p.cst_dia/6)*1) AS DECIMAL(9,2)), 2)
                        else 0 end)
                )+
                if(sum(p.permiso_pago) = 0, 0, p.cst_dia)
            ELSE 
                ((sum(p.manana_cumple)+sum(p.tarde_cumple))*p.cst_dia)+sum(p.noche_cumple)* ROUND(CAST(p.cst_dia*dec_porcNoche AS DECIMAL(9,2)), 2)+
                if(sum(p.descanso)=0,0,
                    (case 
                        when sum(p.faltas)=0 then p.cst_dia
                        when sum(p.faltas)=1 then ROUND(CAST(((p.cst_dia/6)*5) AS DECIMAL(9,2)), 2)
                        when sum(p.faltas)=2 then ROUND(CAST(((p.cst_dia/6)*4) AS DECIMAL(9,2)), 2)
                        when sum(p.faltas)=3 then ROUND(CAST(((p.cst_dia/6)*3) AS DECIMAL(9,2)), 2)
                        when sum(p.faltas)=4 then ROUND(CAST(((p.cst_dia/6)*2) AS DECIMAL(9,2)), 2)
                        when sum(p.faltas)=5 then ROUND(CAST(((p.cst_dia/6)*1) AS DECIMAL(9,2)), 2)
                        else 0 end)
                )+
                if(sum(p.permiso_pago) = 0, 0, p.cst_dia)
            END  
        ) TOTAL_CF 
        from pre_planilla_1Qna p 
        #inner join sueldo su on p.id_persona=su.id_persona
        group by 
        p.id_persona,
        p.fecha
    );
	
   	end;
   # CALCULO1
   
   # CALCULO2
   begin
	   	declare mismo_inicio date;
	    declare inicio_dia date;
	    declare final_quincena date;
	    declare inicia_quincena date;
	    declare final_mensual date; 
	    declare perido_interno varchar(80);
	    declare dias_x_mes int;
	    declare dec_porcNoche decimal(9,2);
	   	declare documento2 varchar(50);
    	declare id_persona2 int; 
        DECLARE findelbucle2Qna INTEGER DEFAULT 0; 
    
	   	DECLARE c_personas_tareo_2Qna CURSOR for
	    select distinct p.per_documento, p.id_persona  from tareo t 
	    inner join sueldo s  
	    on t.id_sueldo  = s.id_sueldo 
	    inner join persona p
	    on p.id_persona  = s.id_persona
	    and t.id_sede  = IN_SEDE
	    and date(t.ta_fecha_r) between  date(inicia_quincena) and date(final_mensual);
	     DECLARE CONTINUE HANDLER FOR NOT FOUND SET findelbucle2Qna=1;
	   
	   	set inicio_dia := concat(IN_ANIO,'-',IN_MES,'-01');
	    set final_quincena := concat(IN_ANIO,'-',IN_MES,'-16');
	    set inicia_quincena := concat(IN_ANIO,'-',IN_MES,'-16');
	    set mismo_inicio := concat(IN_ANIO,'-',IN_MES,'-16');
	    set perido_interno := last_day(inicio_dia);
	    select EXTRACT(DAY from LAST_DAY(mismo_inicio)) into dias_x_mes;
	    set dec_porcNoche := 1.35;
	    set final_mensual := last_day(inicio_dia);
   
	   
	   	OPEN c_personas_tareo_2Qna;
	    loop1: LOOP
	            FETCH c_personas_tareo_2Qna INTO documento2, id_persona2; 
	            IF findelbucle2Qna = 1 THEN
	               LEAVE loop1;
	            END IF;
	           
	            WHILE inicia_quincena <= final_mensual DO 
	            
		                if exists(select * from tareo t inner join sueldo s 
		                        on t.id_sueldo  = s.id_sueldo 
		                        inner join  persona p on s.id_persona  = p.id_persona 
		                        where date(t.ta_fecha_r) = date(inicia_quincena) and p.per_documento = documento2
		                        and t.ta_estado = 1
		                        )
		                then 
		                
		                    insert into persona_tareo_2Qna
		                    select 
		                        t.id_tareo,
		                        t.id_marcador,
		                        t.ta_remunerado,
		                        t.ta_estado,
		                        p.per_documento,
		                        id_persona2,
		                        t.ta_fecha_r,
		                        t.id_sueldo,
		                        #s.ta_csdia
		                        ROUND(cast(((s.ta_basico+s.ta_asignacion_familiar) / dias_x_mes)  as decimal(9,2)), 2)  cst_dia,
		                        t.ta_remunerado
		                    from tareo t inner join sueldo s 
		                            on t.id_sueldo  = s.id_sueldo 
		                    inner join  persona p 
		                            on s.id_persona  = p.id_persona 
		                    where date(t.ta_fecha_r) = date(inicia_quincena) and p.per_documento = documento2
		                    and t.ta_estado = 1
		                    ;
		                else
		                
		                    insert into persona_tareo_2Qna
		                    select 0,0, 0, 0, documento2,id_persona2,inicia_quincena,0,0,0;
		                
		                end if;
	            
	            		SET inicia_quincena = ADDDATE(inicia_quincena, INTERVAL 1 DAY);
	            	END WHILE;
	        	SET inicia_quincena = mismo_inicio;
	    	END LOOP loop1;
		CLOSE c_personas_tareo_2Qna;
	
	#select * from persona_tareo_2Qna;
	
		
	DROP TABLE IF EXISTS pre_planilla_2Qna;
    create temporary table pre_planilla_2Qna(
    select 
    v.id_persona,
    v.fecha, 
    v.id_marcador,
    v.cst_dia,
    concat(year(v.fecha), 
        (
            Case when DAY(v.fecha) > 15 and DAY(v.fecha) <= 22
            THEN 
                '-22'
            when DAY(v.fecha) > 22 and DAY(v.fecha) <= DAY(LAST_DAY(mismo_inicio))
            THEN 
                '-30'
            END
        )
    ) periodo,
    dayofweek(v.fecha)-1 num_dia_sem
    ,(case when v.id_tareo <> 0 and v.ta_estado=1 and v.id_marcador=1   then 1 else 0 end) manana_cumple
    ,(case when v.id_tareo <> 0 and v.ta_estado<>1 and v.id_marcador=1   then 1 else 0 end) manana_no_cumple
    ,(case when v.id_tareo <> 0 and v.ta_estado=1 and v.id_marcador=2   then 1 else 0 end) tarde_cumple
    ,(case when v.id_tareo <> 0 and v.ta_estado<>1 and v.id_marcador=2   then 1 else 0 end) tarde_no_cumple
    ,(case when v.id_tareo <> 0 and v.ta_estado=1 and v.id_marcador=3   then 1 else 0 end) noche_cumple
    ,(case when v.id_tareo <> 0 and v.ta_estado<>1 and v.id_marcador=3   then 1 else 0 end) noche_no_cumple
    ,(case when v.id_marcador = 4  and v.ta_estado = 1  then 1 else 0 end) descanso
    ,(case when v.id_marcador = 5 then 1 else 0 end) faltas
    ,(CASE WHEN EXISTS (
              SELECT * FROM  feriado  WHERE fe_dia = v.fecha
          ) 
            THEN
                1
            ELSE 
                0 
     end) as feriado 
    ,(case when v.id_tareo <> 0 and v.ta_estado = 1  and v.id_marcador = 6 and v.ta_remunerado = 1 then 1 else 0 end) permiso_pago
    ,(case when v.id_tareo <> 0 and v.ta_estado = 1  and v.id_marcador = 6 and v.ta_remunerado = 0 then 1 else 0 end) permiso_no_pago
    from persona_tareo_2Qna v 
    group by v.id_persona,v.fecha,v.id_marcador  
    );


    DROP TABLE IF EXISTS pre_planilla_2Qna_2;
    create temporary table pre_planilla_2Qna_2(
    select 
        p.id_persona,
        p.periodo,
        p.fecha,
        p.cst_dia,
        min(p.fecha) inicio_sem,
        max(p.fecha) fin_sem,
        sum(p.manana_cumple) t_manana_v,
        sum(p.manana_no_cumple) t_manana_no,
        sum(p.tarde_cumple) t_tarde_v,
        sum(p.tarde_no_cumple) t_tarde_no,
        sum(p.noche_cumple) t_noche_v,
        sum(p.noche_no_cumple) t_noche_no,
        sum(p.descanso) descanso,
        sum(p.faltas) faltas,
        sum(p.permiso_pago) permiso_pago,
        sum(p.permiso_no_pago) permiso_no_pago,
        sum(p.manana_cumple*p.cst_dia) total_pago_maniana,
        sum(p.tarde_cumple*p.cst_dia) total_pago_tarde, 
        sum(p.noche_cumple* ROUND(CAST(p.cst_dia*dec_porcNoche AS DECIMAL(9,2)), 2)) total_pago_noche, 
        sum(p.feriado) as feriado,
        ((sum(p.manana_cumple)+sum(p.tarde_cumple))*p.cst_dia)+sum(p.noche_cumple)* ROUND(CAST(p.cst_dia*dec_porcNoche AS DECIMAL(9,2)), 2) subtotal,
        ((sum(p.manana_cumple)+sum(p.tarde_cumple))*p.cst_dia)+sum(p.noche_cumple)* ROUND(CAST(p.cst_dia*dec_porcNoche AS DECIMAL(9,2)), 2)+
        if(sum(p.descanso)=0,0,
            (case 
                when sum(p.faltas)=0 then p.cst_dia
                when sum(p.faltas)=1 then ROUND(CAST(((p.cst_dia/6)*5) AS DECIMAL(9,2)), 2)
                when sum(p.faltas)=2 then ROUND(CAST(((p.cst_dia/6)*4) AS DECIMAL(9,2)), 2)
                when sum(p.faltas)=3 then ROUND(CAST(((p.cst_dia/6)*3) AS DECIMAL(9,2)), 2)
                when sum(p.faltas)=4 then ROUND(CAST(((p.cst_dia/6)*2) AS DECIMAL(9,2)), 2)
                when sum(p.faltas)=5 then ROUND(CAST(((p.cst_dia/6)*1) AS DECIMAL(9,2)), 2)
                else 0 end)
        )+
        if(sum(p.permiso_pago) = 0, 0, p.cst_dia)
        TOTAL_SF, 
        (CASE WHEN EXISTS (
              SELECT * FROM  feriado  WHERE fe_dia = p.fecha
          ) 
            THEN
                ((((sum(p.manana_cumple)+sum(p.tarde_cumple))*p.cst_dia)+sum(p.noche_cumple)* ROUND(CAST(p.cst_dia*dec_porcNoche AS DECIMAL(9,2)), 2))*2)+
                if(sum(p.descanso)=0,0,
                    (case 
                        when sum(p.faltas)=0 then p.cst_dia
                        when sum(p.faltas)=1 then ROUND(CAST(((p.cst_dia/6)*5) AS DECIMAL(9,2)), 2)
                        when sum(p.faltas)=2 then ROUND(CAST(((p.cst_dia/6)*4) AS DECIMAL(9,2)), 2)
                        when sum(p.faltas)=3 then ROUND(CAST(((p.cst_dia/6)*3) AS DECIMAL(9,2)), 2)
                        when sum(p.faltas)=4 then ROUND(CAST(((p.cst_dia/6)*2) AS DECIMAL(9,2)), 2)
                        when sum(p.faltas)=5 then ROUND(CAST(((p.cst_dia/6)*1) AS DECIMAL(9,2)), 2)
                        else 0 end)
                )+
                if(sum(p.permiso_pago) = 0, 0, p.cst_dia)
            ELSE 
                ((sum(p.manana_cumple)+sum(p.tarde_cumple))*p.cst_dia)+sum(p.noche_cumple)* ROUND(CAST(p.cst_dia*dec_porcNoche AS DECIMAL(9,2)), 2)+
                if(sum(p.descanso)=0,0,
                    (case 
                        when sum(p.faltas)=0 then p.cst_dia
                        when sum(p.faltas)=1 then ROUND(CAST(((p.cst_dia/6)*5) AS DECIMAL(9,2)), 2)
                        when sum(p.faltas)=2 then ROUND(CAST(((p.cst_dia/6)*4) AS DECIMAL(9,2)), 2)
                        when sum(p.faltas)=3 then ROUND(CAST(((p.cst_dia/6)*3) AS DECIMAL(9,2)), 2)
                        when sum(p.faltas)=4 then ROUND(CAST(((p.cst_dia/6)*2) AS DECIMAL(9,2)), 2)
                        when sum(p.faltas)=5 then ROUND(CAST(((p.cst_dia/6)*1) AS DECIMAL(9,2)), 2)
                        else 0 end)
                )+
                if(sum(p.permiso_pago) = 0, 0, p.cst_dia)
            END  
        ) TOTAL_CF
        from pre_planilla_2Qna p 
        #inner join sueldo su on p.id_persona=su.id_persona
        group by 
        p.id_persona,
        p.fecha
    );
	
   	end;
    # CALCULO2 
    select * from pre_planilla_1Qna_2
   	union all
   	select * from pre_planilla_2Qna_2; 
     
END$$

CREATE  PROCEDURE UP_GENERAR_REPORTE_PERMISO (IN IN_id_sede INT, IN IN_id_permiso INT, IN IN_pago INT, IN IN_inicio DATE, IN IN_fin DATE)  BEGIN   
select 
    ta.id_tareo,
    IF(ta.ta_estado = 0, 'INACTIVO', 'ACTIVO') as estado,
    LPAD(ta.id_tareo,7,'0') as codigo, 
    UPPER (CONCAT(pe.per_nombre," ",pe.per_apellido_paterno," ",pe.per_apellido_materno)) AS datos,
    CONCAT(se.se_lugar," - ",se.se_descripcion) AS sede_datos,
    date(ta.ta_fecha_r) as fecha_ingreso, 
    CONCAT(ma_abreviatura," - ",ma_descripcion) AS marcador_datos,
    (select pe_nombre from permiso where id_permiso =  ta.ta_permiso limit 1) as permiso, 
    CASE ta.ta_remunerado
      WHEN 1 THEN 'PAGADO'
      WHEN 0 THEN 'NO PAGADO'
      ELSE NULL
    END as tipo_permiso,
    ta.ta_remunerado,
    ta.ta_estado 
    FROM
    tareo ta
    INNER JOIN marcador ma on ta.id_marcador = ma.id_marcador
    INNER JOIN sede se on ta.id_sede = se.id_sede
    INNER JOIN empleado em on em.id_persona = ta.id_persona
    INNER JOIN persona pe on pe.id_persona = em.id_persona
    where 
    date(ta.ta_fecha_r) between date(IN_inicio) 
    AND date(IN_fin) 
    AND ta.id_sede = IN_id_sede
    and ta.id_marcador = 6
    and
    CASE WHEN IN_pago = 1 THEN  ta.ta_remunerado = 1
    WHEN IN_pago = 0 THEN  ta.ta_remunerado = 0         
    WHEN IN_pago = 3 THEN   TRUE
    ELSE TRUE  END 
    AND
    CASE WHEN IN_id_permiso <> 0 THEN ta.ta_permiso = IN_id_permiso
    WHEN IN_id_permiso = 0 THEN   TRUE 
    ELSE  TRUE END 
    # /aaa
    order by UPPER (CONCAT(pe.per_nombre," ",pe.per_apellido_paterno," ",pe.per_apellido_materno)), ta.ta_fecha_r asc;

END$$

CREATE  PROCEDURE UP_GENERAR_REPORTE_TAREO (IN IN_id_sede INT, IN IN_documento VARCHAR(50), IN IN_inicio DATE, IN IN_fin DATE, IN IN_marcador VARCHAR(5))  BEGIN 
    select 
    ta.id_tareo,
    
    case
    when ta.ta_estado = 1
    then
    	'ACTIVO'
    when ta.ta_estado = 0
    then
    	'INACTIVO'
    end as estado,
    case
    when ta.ta_estado  = 1 
    then 
        'ACTIVO' 	
    else 
        'INACTIVO'
    end as estado2,
    LPAD(ta.id_tareo,7,'0') as codigo, 
    UPPER (CONCAT(pe.per_nombre," ",pe.per_apellido_paterno," ",pe.per_apellido_materno)) AS datos,
    CONCAT(se.se_lugar," - ",se.se_descripcion) AS sede_datos,
    date(ta.ta_fecha_r) as fecha_ingreso,
    ta.ta_hora_r as hora_ingreso, 
    case 
    when ta.id_marcador  = 6
    then 
        date(ta.ta_fecha_c)
    when ta.id_marcador  =  4
    then 
        date(ta.ta_fecha_c)
    when ta.id_marcador  =  5
    then 
        date(ta.ta_fecha_c)
    else 
        case 
        when ta.ta_etapa  = 1
        then 
             date(ta.ta_fecha_c) 
        else
            ''
        end
    end as fecha_cierre,
    case 
    when ta.id_marcador  = 6
    then 
        ta.ta_hora_c 
    when ta.id_marcador  =  4
    then 
        ta.ta_hora_c 
    when ta.id_marcador  =  5
    then 
        ta.ta_hora_c 
    else 
        case 
        when ta.ta_etapa  = 1
        then 
             ta.ta_hora_c 
        else
            ''
        end
    end as hora_cierre,
    CONCAT(ma_abreviatura," - ",ma_descripcion) AS marcador_datos,
    ta.ta_estado,
    case 
    	when ta.id_marcador in(1,2,3)  and ta.ta_etapa = 0
    	then
    		'PENDIENTE POR CERRAR'
    	when ta.id_marcador in(1,2,3)  and ta.ta_etapa = 1
    	then
    		'CERRADO'
    	when ta.id_marcador in(4,5,6)  and ta.ta_etapa = 1
    	then
    		ma.ma_descripcion
        else
        	ma.ma_descripcion
    	end as etapa
    ,ta.userCreacion
	,ta.fechaCreacion
	,ta.userModificacion
	,ta.fechaModificacion
	,ta.flEliminado
    FROM
    tareo ta
    INNER JOIN marcador ma on ta.id_marcador = ma.id_marcador
    INNER JOIN sede se on ta.id_sede = se.id_sede
    INNER JOIN empleado em on em.id_persona = ta.id_persona
    INNER JOIN persona pe on pe.id_persona = em.id_persona
    where 
    date(ta.ta_fecha_r) between date(IN_inicio) and date(IN_fin) 
    AND ta.id_sede = IN_id_sede 
    AND CASE WHEN IN_documento != '' THEN 
        (pe.per_documento = IN_documento or CONCAT(pe.per_nombre," ",pe.per_apellido_paterno," ",pe.per_apellido_materno) like concat('%',IN_documento,'%'))  
    ELSE 
        TRUE 
    end
    and 
     ta.id_marcador  = IN_marcador
    order by UPPER (CONCAT(pe.per_nombre," ",pe.per_apellido_paterno," ",pe.per_apellido_materno)),CONCAT(se.se_lugar," - ",se.se_descripcion), ta.ta_fecha_r asc;

END$$

CREATE  PROCEDURE up_get_configuraciones_planilla ()  begin 
    SELECT * FROM pla_configuraciones limit 1; 
END$$

CREATE  PROCEDURE UP_GET_DATA_PERSONA (IN IN_id_persona INT)  BEGIN 

    SELECT 
        a.id_persona,
        a.id_tpdocumento,
        a.id_nacionalidad,
        a.per_nombre,
        a.per_apellido_paterno,
        a.per_apellido_materno,
        a.per_documento,
        a.per_fecha_nac,
        a.per_celular,
        a.per_celular,
        a.per_celular,
        a.per_correo,
        a.pe_estado,
        /*case
	    when a.pe_estado  = 1 
	    then 
	         case 
	         when e.phc_estado = 3
	         then
	            3
	         else
	            1
	         end
	    when a.pe_estado  =  0 
	    then 
	        0
	    end as pe_estado,*/
        date(a.pe_fecha_ingreso) pe_fecha_ingreso,
        date(a.pe_fecha_cese) pe_fecha_cese,
        a.pe_titular,
        a.pe_usuario,
        a.pe_sexo,
        a.pe_direccion,
        (select phc_foto_perfil from empleado c where c.id_persona = IN_id_persona limit 1) as em_foto
    FROM persona a
   	inner join empleado e on e.id_persona = a.id_persona 
     where a.id_persona = IN_id_persona ;

END$$

CREATE  PROCEDURE UP_GET_DATA_PERSONA_SUPLENTE (IN IN_id_persona INT)  BEGIN 

    SELECT 
        * 
    FROM persona where id_persona = IN_id_persona;

END$$

CREATE  PROCEDURE UP_GET_DIA_ABREVIATURA_TAREADO (IN IN_id_persona INT, IN IN_fecha DATE)  BEGIN

declare dec_modoDescanso int;
declare personaEstado int;
declare fechaSece varchar(50);

select pc_modo_descanso into dec_modoDescanso from pla_configuraciones limit 1;

DROP TABLE IF EXISTS dias_xPersona;
CREATE TEMPORARY TABLE dias_xPersona(
        fecha date,
        resultado varchar(80)
); 


select p.pe_estado,p.pe_fecha_cese  into personaEstado,fechaSece from persona p where p.id_persona  = IN_id_persona;

if exists(select * from feriado f where date(f.fe_dia) = date(IN_fecha) and f.fe_estado = 1)
then 
    if personaEstado = 0 
       then
            if date(fechaSece) >= IN_fecha
            then
                 insert into dias_xPersona
                 select IN_fecha, 'FE';
            end if;
        else
            insert into dias_xPersona 
            select IN_fecha,  'FE';
    end if;
end if; 

if exists(select * from persona p where p.id_persona = IN_id_persona and date(p.pe_fecha_ingreso) > date(IN_fecha))
then 
    insert into dias_xPersona
    select IN_fecha,
    '-';
end if;

if dec_modoDescanso = 1 
then 
     if personaEstado = 0 
       then
            if date(fechaSece) >= IN_fecha
            then
                 insert into dias_xPersona
                 select d.de_fecha,'D'
                 from descanso d 
                 where 
                 d.id_persona = IN_id_persona 
                 and date(d.de_fecha) = date(IN_fecha)
                 and d.de_estado = 1;
                
                 insert into dias_xPersona
                 SELECT 
                 date(ta.ta_fecha_r) as fecha, 
                 #GROUP_CONCAT(CONCAT_WS(':', ma.ma_abreviatura) SEPARATOR ',') AS Result 
                 ma.ma_abreviatura  AS Result 
                 FROM tareo ta 
                 INNER JOIN marcador ma on ta.id_marcador = ma.id_marcador 
                 INNER JOIN persona su on ta.id_persona = su.id_persona 
                 where 
                 su.id_persona = IN_id_persona 
                 and date(ta.ta_fecha_r) = date(IN_fecha)
                 and ta.ta_estado = 1
                 and ta.id_marcador  <> 4 and ta.id_marcador  <> 6;

                insert into dias_xPersona
                 SELECT 
                 date(ta.ta_fecha_r) as fecha, 
                 #GROUP_CONCAT(CONCAT_WS(':', ma.ma_abreviatura) SEPARATOR ',') AS Result 
                 #ma.ma_abreviatura  AS Result 
                 case when ta.id_marcador = 6 and ta.ta_remunerado = 1 then ma.ma_abreviatura else 'FAL' end as Result
                 FROM tareo ta 
                 INNER JOIN marcador ma on ta.id_marcador = ma.id_marcador 
                 INNER JOIN persona su on ta.id_persona = su.id_persona 
                 where 
                 su.id_persona = IN_id_persona 
                 and date(ta.ta_fecha_r) = date(IN_fecha)
                 and ta.ta_estado = 1 
                 and ta.id_marcador = 6;

            end if;
         else
                 insert into dias_xPersona
                 select 
                    d.de_fecha,
                    'D'
                 from descanso d 
                 where 
                 d.id_persona = IN_id_persona 
                 and date(d.de_fecha) = date(IN_fecha)
                 and d.de_estado = 1;
                
                 insert into dias_xPersona
                 SELECT 
                 date(ta.ta_fecha_r) as fecha, 
                 #GROUP_CONCAT(CONCAT_WS(':', ma.ma_abreviatura) SEPARATOR ',') AS Result 
                 ma.ma_abreviatura  AS Result 
                 FROM tareo ta 
                 INNER JOIN marcador ma on ta.id_marcador = ma.id_marcador 
                 INNER JOIN persona su on ta.id_persona = su.id_persona 
                 where 
                 su.id_persona = IN_id_persona 
                 and date(ta.ta_fecha_r) = date(IN_fecha)
                 and ta.ta_estado = 1
                 and ta.id_marcador  <> 4;
        end if;    
else 
     if personaEstado = 0 
       then
            if date(fechaSece) >= IN_fecha
            then
                 insert into dias_xPersona
                 SELECT 
                 date(ta.ta_fecha_r) as fecha, 
                 #GROUP_CONCAT(CONCAT_WS(':', ma.ma_abreviatura) SEPARATOR ',') AS Result 
                 ma.ma_abreviatura  AS Result 
                 FROM tareo ta 
                 INNER JOIN marcador ma on ta.id_marcador = ma.id_marcador 
                 INNER JOIN persona su on ta.id_persona = su.id_persona 
                 where 
                 su.id_persona = IN_id_persona 
                 and date(ta.ta_fecha_r) = date(IN_fecha)
                 and ta.ta_estado = 1 and ta.id_marcador <> 6;

                 insert into dias_xPersona
                 SELECT 
                 date(ta.ta_fecha_r) as fecha, 
                 #GROUP_CONCAT(CONCAT_WS(':', ma.ma_abreviatura) SEPARATOR ',') AS Result 
                 #ma.ma_abreviatura  AS Result 
                 case when ta.id_marcador = 6 and ta.ta_remunerado = 1 then ma.ma_abreviatura else 'FAL' end as Result
                 FROM tareo ta 
                 INNER JOIN marcador ma on ta.id_marcador = ma.id_marcador 
                 INNER JOIN persona su on ta.id_persona = su.id_persona 
                 where 
                 su.id_persona = IN_id_persona 
                 and date(ta.ta_fecha_r) = date(IN_fecha)
                 and ta.ta_estado = 1 and ta.id_marcador = 6;

            end if;
         else
                 # mañana, tarde, noche
                 insert into dias_xPersona
                 SELECT 
                 date(ta.ta_fecha_r) as fecha, 
                 #GROUP_CONCAT(CONCAT_WS(':', ma.ma_abreviatura) SEPARATOR ',') AS Result 
                 ma.ma_abreviatura  AS Result 
                 FROM tareo ta 
                 INNER JOIN marcador ma on ta.id_marcador = ma.id_marcador 
                 INNER JOIN persona su on ta.id_persona = su.id_persona 
                 where 
                 su.id_persona = IN_id_persona 
                 and date(ta.ta_fecha_r) = date(IN_fecha)
                 and ta.ta_estado = 1 
                 and ta.ta_etapa = 1
                 and ta.id_marcador in(1,2,3)
                 and ta.id_marcador not in(4,5,6);

                 insert into dias_xPersona
                 SELECT 
                 date(ta.ta_fecha_r) as fecha, 
                 #GROUP_CONCAT(CONCAT_WS(':', ma.ma_abreviatura) SEPARATOR ',') AS Result 
                 ma.ma_abreviatura  AS Result 
                 FROM tareo ta 
                 INNER JOIN marcador ma on ta.id_marcador = ma.id_marcador 
                 INNER JOIN persona su on ta.id_persona = su.id_persona 
                 where 
                 su.id_persona = IN_id_persona 
                 and date(ta.ta_fecha_r) = date(IN_fecha)
                 and ta.ta_estado = 1 
                 and ta.id_marcador not in(1,2,3)
                 and ta.id_marcador in(4,5);
  
                 insert into dias_xPersona
                 SELECT 
                 date(ta.ta_fecha_r) as fecha, 
                 #GROUP_CONCAT(CONCAT_WS(':', ma.ma_abreviatura) SEPARATOR ',') AS Result 
                 #ma.ma_abreviatura  AS Result 
                 case when ta.id_marcador = 6 and ta.ta_remunerado = 1 then ma.ma_abreviatura else 'FAL' end as Result
                 FROM tareo ta 
                 INNER JOIN marcador ma on ta.id_marcador = ma.id_marcador 
                 INNER JOIN persona su on ta.id_persona = su.id_persona 
                 where 
                 su.id_persona = IN_id_persona 
                 and date(ta.ta_fecha_r) = date(IN_fecha)
                 and ta.ta_estado = 1 and ta.id_marcador = 6;


        end if; 
end if; 

select 
date(fecha) as fecha, 
GROUP_CONCAT(CONCAT_WS(':', resultado) SEPARATOR ',') AS Result 
from dias_xPersona a  GROUP by a.fecha;

END$$

CREATE  PROCEDURE UP_GET_DOCUMENTOS_EDIT_EMPLEADO ()  BEGIN

select * from documentos_empleado a where a.flEliminado  = 1;

END$$

CREATE  PROCEDURE UP_GET_DOCUMENTOS_EMPLEADO ()  BEGIN

select * from documentos_empleado a where a.flEliminado  = 1;

END$$

CREATE  PROCEDURE UP_GET_SEDES_EMPLEADOS_BY_IDPERSONA (IN IN_id_persona INT)  BEGIN 
 
 select 
    she.id_sede_em,
    se.id_sede,
    se.se_descripcion,
    se.se_lugar
from sede_empleado she 
INNER JOIN empleado em on em.id_persona = she.id_persona
INNER JOIN sede se on she.id_sede = se.id_sede
where she.sm_estado = 1 and em.id_persona = IN_id_persona;

END$$

CREATE  PROCEDURE UP_HABILITARS_DESCANSO_PERSONAWEB (IN IN_id_descanso INT, IN IN_userCreacion VARCHAR(50))  BEGIN  
	
	declare dec_id_persona int;

	select 
	 d.id_persona  into dec_id_persona
	from descanso d where id_descanso  = IN_id_descanso limit 1;
	
	update descanso set de_estado = 0 ,
    	userModificacion	= IN_userCreacion
		,fechaModificacion= now()
	WHERE id_persona = dec_id_persona and de_estado = 1;
	
    update descanso set de_estado = 1 ,
    	userModificacion	= IN_userCreacion
	,fechaModificacion= now()
	WHERE id_descanso = IN_id_descanso; 
 
END$$

CREATE  PROCEDURE UP_HABILITAR_DESHABILITAR_CUENTA_TERCERO_PERSONAWEB (IN IN_id_persona INT, IN IN_id_sucobrar INT, IN IN_OPCION INT)  BEGIN 
    
    if IN_OPCION = 1
    then 
            UPDATE persona 
            SET pe_titular = 0
            WHERE id_persona = IN_id_persona;
            
            UPDATE persona_has_banco SET
            phb_estado=0
            WHERE id_persona = IN_id_persona;

            UPDATE suplente_cobrar SET suc_estado = 0
            WHERE suc_origen = IN_id_persona;

            UPDATE suplente_cobrar SET suc_estado = 1
            WHERE id_sucobrar = IN_id_sucobrar;
           
    else
        UPDATE persona 
            SET pe_titular = 0
            WHERE id_persona = IN_id_persona;
           
        UPDATE suplente_cobrar SET suc_estado=0
            WHERE id_sucobrar = IN_id_sucobrar; 
    end if; 
END$$

CREATE  PROCEDURE UP_HABILITAR_DESHABILITAR_CUENTA_TITULAR_PERSONAWEB (IN IN_id_persona INT, IN IN_id_phbanco INT, IN IN_OPCION INT, IN IN_userCreacion VARCHAR(50))  BEGIN 
    
    if IN_OPCION = 1
    then
        UPDATE persona 
        SET pe_titular = 1 
		,userModificacion	= IN_userCreacion
		,fechaModificacion	= now()
        WHERE id_persona 	= IN_id_persona;
    
        UPDATE suplente_cobrar SET
        suc_estado=0
		,userModificacion	= IN_userCreacion
		,fechaModificacion	= now()
        WHERE suc_origen 	= IN_id_persona and suc_estado = 1;
    
        UPDATE persona_has_banco SET
        phb_estado			= 0 
		,userModificacion	= IN_userCreacion
		,fechaModificacion	= now()
        WHERE id_persona 	= IN_id_persona  and phb_estado = 1; 
   
        UPDATE persona_has_banco SET
        phb_estado			= 1 
		,userModificacion	= IN_userCreacion
		,fechaModificacion	= now()
        WHERE id_phbanco 	= IN_id_phbanco;  
       
    else
        UPDATE persona_has_banco SET
             phb_estado			= 0 
			,userModificacion	= IN_userCreacion
			,fechaModificacion	= now()
            WHERE id_phbanco 	= IN_id_phbanco; 
    end if; 
   
END$$

CREATE  PROCEDURE UP_INHABILITAR_LISTA_NEGRA (IN IN_id_lista INT, IN IN_opcion INT)  BEGIN

UPDATE persona_has_listanegra
SET flEliminado = case when IN_opcion = 0 then 0 else 1 end
WHERE id_lista = IN_id_lista;

END$$

CREATE  PROCEDURE up_linea_tiempo_tareo (IN_fechaInicio VARCHAR(40), IN_fechaFin VARCHAR(40), IN_Sede VARCHAR(40))  begin 


select 
count(t.id_tareo) CANTIDAD, 
date(t.ta_fecha_r) FECHA 
from tareo t where date(t.ta_fecha_r) 
BETWEEN 
CASE WHEN IN_fechaInicio = 'T' THEN 
concat(year(curdate()),'-',month(curdate()-1),'-',if(day(curdate())<=15, '01', '15')) 
ELSE
IN_fechaInicio
END
and 
CASE WHEN IN_fechaFin = 'T' THEN 
concat(year(curdate()),'-',month(curdate()-1),'-',if(day(curdate())>15, day(last_day(curdate())), '15')) 
ELSE
IN_fechaFin
END
AND CASE WHEN IN_Sede != 'T' THEN 
    t.id_sede = IN_Sede
ELSE 
    TRUE 
END
GROUP by date(t.ta_fecha_r)
order by date(t.ta_fecha_r);

    
END$$

CREATE  PROCEDURE up_listar_asistencia_empleado (IN IN_opcion INT, IN IN_nombre VARCHAR(50), IN IN_sede INT, IN IN_documento VARCHAR(50), IN IN_inicio DATE, IN IN_fin DATE, IN IN_turno VARCHAR(5), IN IN_opcionTareo VARCHAR(5))  begin 
	
	declare dec_countTareo int default 0;
	
	drop table if exists empleados;
	create temporary  table empleados(
		id_persona int,
		documento varchar(20),
		nombres varchar(70),
		cargo varchar(20),
		sede varchar(20)
	);
	
	drop table if exists dates;
	create temporary  table dates(
		dia date
	);
	
	select 
		count(*) into dec_countTareo
	from tareo t 
	inner join persona p 
	on t.id_persona  = p.id_persona 
	where date(t.ta_fecha_r) between date(IN_inicio) and date(IN_fin)
	and
	(
							t.id_marcador not IN (4,6) and 
							t.id_marcador = 
							case 
							when IN_turno <> 'T' then
									IN_turno 
							when IN_turno = 'T' then
									t.id_marcador
							end
						)
	and
	CASE WHEN IN_opcion = 1 THEN  
        p.per_documento = IN_documento
    WHEN IN_opcion = 2 THEN  
        CONCAT(p.per_nombre," ",p.per_apellido_paterno," ",p.per_apellido_materno) LIKE CONCAT('%',IN_nombre,'%')  
    WHEN IN_opcion = 3 THEN  
        t.id_sede = IN_sede
    ELSE 
        TRUE  
    end
   	and t.ta_estado = 1
    ; 
 

	if(dec_countTareo <= 0)
	then
		 signal sqlstate '45000' set message_text = 'No hay tareos que mostrar';
	end if;
	
	
	insert into dates
	select * from 
	(select adddate('1970-01-01',t4.i*10000 + t3.i*1000 + t2.i*100 + t1.i*10 + t0.i) selected_date from
	 (select 0 i union select 1 union select 2 union select 3 union select 4 union select 5 union select 6 union select 7 union select 8 union select 9) t0,
	 (select 0 i union select 1 union select 2 union select 3 union select 4 union select 5 union select 6 union select 7 union select 8 union select 9) t1,
	 (select 0 i union select 1 union select 2 union select 3 union select 4 union select 5 union select 6 union select 7 union select 8 union select 9) t2,
	 (select 0 i union select 1 union select 2 union select 3 union select 4 union select 5 union select 6 union select 7 union select 8 union select 9) t3,
	 (select 0 i union select 1 union select 2 union select 3 union select 4 union select 5 union select 6 union select 7 union select 8 union select 9) t4) v
	where selected_date between date(IN_inicio) and date(IN_fin);

	insert into empleados
	SELECT 
	    pe.id_persona,
	    pe.per_documento,
	    CONCAT(per_nombre," ",per_apellido_paterno," ",per_apellido_materno) AS datos,
	    ca.ca_descripcion,
	    se.se_descripcion
	FROM persona pe 
	INNER JOIN empleado em on pe.id_persona = em.id_persona and pe.pe_estado <> 0
	INNER JOIN sede_empleado she on she.id_persona = em.id_persona and she.sm_estado = 1
	INNER JOIN sede se on se.id_sede = she.id_sede
	INNER JOIN cargos_empleado ce on ce.id_persona = em.id_persona and ce.ce_estado  = 1
	INNER JOIN cargo ca on ca.id_cargo = ce.id_cargo
	WHERE 
    CASE WHEN IN_opcion = 1 THEN  
        pe.per_documento = IN_documento
    WHEN IN_opcion = 2 THEN  
        CONCAT(pe.per_nombre," ",pe.per_apellido_paterno," ",pe.per_apellido_materno) LIKE CONCAT('%',IN_nombre,'%')  
    WHEN IN_opcion = 3 THEN  
        she.id_sede = IN_sede
    ELSE 
        TRUE  
    end;
   
   insert into empleados
   SELECT 
		pe.id_persona,
		pe.per_documento,
		CONCAT(per_nombre," ",per_apellido_paterno," ",per_apellido_materno) AS datos,
	    ca.ca_descripcion,
	    se.se_descripcion
	FROM persona pe 
	INNER JOIN empleado em on pe.id_persona = em.id_persona and pe.pe_estado = 0
	INNER JOIN sede_empleado she on she.id_persona = em.id_persona and she.sm_estado = 1
	INNER JOIN sede se on se.id_sede = she.id_sede
	INNER JOIN cargos_empleado ce on ce.id_persona = em.id_persona and ce.ce_estado  = 1
	INNER JOIN cargo ca on ca.id_cargo = ce.id_cargo
	left join empleado_has_cese ehc on ehc.id_persona = pe.id_persona and ehc.flEliminado = 1
	WHERE 
	CASE WHEN IN_opcion = 1 THEN  
	    pe.per_documento = IN_documento
	WHEN IN_opcion = 2 THEN  
	    CONCAT(pe.per_nombre," ",pe.per_apellido_paterno," ",pe.per_apellido_materno) LIKE CONCAT('%',IN_nombre,'%')  
	WHEN IN_opcion = 3 THEN  
	    she.id_sede = IN_sede
	ELSE 
	    TRUE  
	end
	and  
	CASE WHEN ehc.id_cese is not null THEN  
	    date(ehc.ce_fecha_cese) between date(IN_inicio) and date(IN_fin) 
	ELSE 
	    false  
	end;
	

	if(IN_opcionTareo = 1)
	then
		select 
		c.*,
		b.*,
		fun_get_asistencia_by_day(c.id_persona, b.dia, IN_turno) as asistencia
		from(
			select 
				distinct
				id_persona,
				documento,
				nombres,
				cargo,
				sede
			from empleados a where EXISTS(SELECT * FROM tareo t WHERE t.id_persona = a.id_persona) 
		) as c cross join dates b;
	else 
		select 
			a.*,
			b.*,
			fun_get_asistencia_by_day(a.id_persona, b.dia, IN_turno) as asistencia
		from empleados a cross join dates b;
	end if;
 

end$$

CREATE  PROCEDURE up_listar_auditoria_empleados (IN IN_idTablas INT, IN IN_fechaInicio DATETIME, IN IN_fechaFin DATETIME, IN IN_usaurio VARCHAR(50), IN IN_tpAuditoria VARCHAR(50))  BEGIN 
	select 
		td.tbs_mostrar,
		a.fecha,
		a.usuario, 
		case
            when a.tipo_auditoria  = 1 
            then 
                 'REGISTRO'
            when a.tipo_auditoria  = 2 
            then 
                'EDICION'
            when a.tipo_auditoria  = 3 
            then 
                'ANULACION'
            when a.tipo_auditoria  =  4 
            then 
                'ELIMINACION'
        end as tipo_auditoria,
		a.old_value,
		a.new_value,
        a.usuario
	from auditoria a inner join tablas_dba td on a.id_tablas  = td.id_tablas
	where 
	a.id_tablas  = IN_idTablas and 
	date(a.fecha) between date(IN_fechaInicio) and date(IN_fechaFin) and 
		CASE 
		WHEN IN_usaurio <> 'T' 
		THEN  
	        a.usuario = IN_usaurio
	    ELSE 
	       TRUE
	    end
	 and 
	 	CASE 
		WHEN IN_tpAuditoria <> 'T' 
		THEN  
	        a.tipo_auditoria  = IN_tpAuditoria
	    ELSE 
	        TRUE
	    end;
END$$

CREATE  PROCEDURE UP_LISTAR_BANCO ()  BEGIN

SELECT 
id_banco,
ba_descripcion,
ba_abreviatura,
ba_nombre,
ba_estado,
IF(ba_estado = 0, 'INACTIVO', 'ACTIVO') as estado,
CONCAT(ba_abreviatura," - ",ba_nombre) AS datos
,userCreacion
,fechaCreacion
,userModificacion
,fechaModificacion
,flEliminado
FROM banco;

END$$

CREATE  PROCEDURE UP_LISTAR_BANCOS_PERSONA_TITULAR (IN IN_id_persona INT)  BEGIN
 
SELECT 
    phb.id_phbanco, 
    phb.phb_fecha_r, 
    phb.id_tpcuenta,
    ba.id_banco,
    concat(ba.ba_abreviatura," ",ba.ba_nombre) banco,  
    IF(phb.phb_estado = 1, 'ACTIVO','INACTIVO') estado,
    phb.phb_estado,
    phb.phb_cuenta,
    phb.phb_cci 
    ,phb.userCreacion
	,phb.fechaCreacion
	,phb.userModificacion
	,phb.fechaModificacion
	,phb.flEliminado
FROM persona pe
INNER JOIN persona_has_banco phb on phb.id_persona = pe.id_persona 
INNER JOIN banco ba on phb.id_banco = ba.id_banco 
 where pe.id_persona = IN_id_persona;

END$$

CREATE  PROCEDURE UP_LISTAR_BANCOS_SUPLENTE_EMPLEADO (IN IN_id_persona INT)  BEGIN
 
SELECT
    phb_estado id_enti,
    IF(pe.pe_titular = 1, 1, 0) pe_titular,
    phb.phb_fecha_r, 
    concat(ba.ba_abreviatura," ",ba.ba_nombre) banco,  
    IF(pe.pe_titular = 1, 'ACTIVO','INACTIVO') estado,
    phb.phb_estado,
    phb.phb_cuenta,
    phb.phb_cci, 
    IF(pe.pe_titular = 1, 'TITULAR','TERCERO') tipo,
    '' tercero
FROM persona pe
INNER JOIN persona_has_banco phb on phb.id_persona = pe.id_persona 
INNER JOIN banco ba on phb.id_banco = ba.id_banco 
 where pe.id_persona = IN_id_persona 
union all 
SELECT
    sc.id_sucobrar id_enti,
    IF(pe.pe_titular = 0, 1, 0) pe_titular,
    sc.suc_fecha_r, 
    concat(ba.ba_abreviatura," ",ba.ba_nombre) banco,  
    IF(pe.pe_titular = 0, 'ACTIVO','INACTIVO') estado,
    phb.phb_estado,
    phb.phb_cuenta,
    phb.phb_cci, 
    'TERCERO' tipo,
    concat(pe.per_nombre," ",pe.per_apellido_paterno," ",pe.per_apellido_materno) tercero
FROM suplente_cobrar sc 
INNER JOIN persona pe on pe.id_persona = sc.id_persona
INNER JOIN persona_has_banco phb on sc.id_persona = phb.id_persona
INNER JOIN banco ba on phb.id_banco = ba.id_banco
where sc.suc_origen = IN_id_persona;

END$$

CREATE  PROCEDURE UP_LISTAR_BANCOS_SUPLENTE_PLANILLA (IN IN_id_persona INT)  BEGIN
 
 select 
    concat(pe2.per_apellido_paterno," ",pe2.per_apellido_materno," ",pe2.per_nombre) as datos,
    concat(ba.ba_abreviatura," ",ba.ba_nombre) banco,
    phb.phb_cuenta,
    phb.phb_cci 
    from suplente_cobrar sc 
    INNER JOIN persona pe 
    on sc.suc_origen = pe.id_persona
    INNER JOIN persona pe2 on 
    sc.id_persona = pe2.id_persona
    INNER JOIN persona_has_banco phb on phb.id_persona = pe2.id_persona and phb.phb_estado = 1
    INNER JOIN banco ba on phb.id_banco = ba.id_banco
    WHERE pe.pe_titular = 0
    and sc.suc_origen = IN_id_persona
     limit 1;

END$$

CREATE  PROCEDURE UP_LISTAR_BANCOS_TITULAR_PLANILLA (IN IN_id_persona INT)  BEGIN
 
 SELECT
    concat(ba.ba_abreviatura," ",ba.ba_nombre) banco,
    phb.phb_cuenta,
    phb.phb_cci
FROM persona pe
INNER JOIN persona_has_banco phb on phb.id_persona = pe.id_persona and phb.phb_estado = 1
INNER JOIN banco ba on phb.id_banco = ba.id_banco 
 where pe.id_persona = IN_id_persona and pe.pe_titular = 1 limit 1;

END$$

CREATE  PROCEDURE UP_LISTAR_BANCOS_X_EMPLEADO (IN IN_id_persona INT)  BEGIN
 
 select
    phb.id_phbanco,
    phb.id_banco,
    phb.id_tpcuenta,
    phb.phb_estado,
    b.ba_nombre,
    if(phb.phb_cuenta is null or phb.phb_cuenta = 'null', '', phb.phb_cuenta) as phb_cuenta,
    if(phb.phb_cci is null or phb.phb_cci = 'null', '', phb.phb_cci) as phb_cci,
    IF(phb.phb_estado = 0, 'INACTIVO', 'ACTIVO') as estado,
    c.tpc_descripcion,
    c.tpc_abreviatura
    ,phb.userCreacion
	,phb.fechaCreacion
	,phb.userModificacion
	,phb.fechaModificacion
	,phb.flEliminado
from persona_has_banco phb
inner join banco b on b.id_banco  = phb.id_banco
inner JOIN tipo_cuenta c on phb.id_tpcuenta = c.id_tpcuenta
where phb.id_persona  = IN_id_persona;

END$$

CREATE  PROCEDURE UP_LISTAR_CARGO ()  BEGIN

SELECT 
id_cargo,
ca_descripcion,
ca_abreviatura,
ca_estado,
IF(ca_estado = 0, 'INACTIVO', 'ACTIVO') as estado, 
CONCAT(ca_abreviatura," - ",ca_descripcion) AS datos,
id_tipoUsuario as id_tpusuario,
tp.tpu_descripcion
,c.userCreacion
,c.fechaCreacion
,c.userModificacion
,c.fechaModificacion
,c.flEliminado
FROM cargo c
inner JOIN tipo_usuario tp 
on c.id_tipoUsuario = tp.id_tpusuario
;

END$$

CREATE  PROCEDURE UP_LISTAR_CARGOS_EMPLEADO (IN IN_id_persona INT)  BEGIN
SELECT 
    ce.id_caempleado, 
    date(ce.ce_fecha_r) as ce_fecha_r,
    IF(ce.ce_estado = 0, 'INACTIVO', 'ACTIVO') as estado,
    ce.ce_estado,
    ce.ce_observacion,
    ca.ca_descripcion,
    ca.id_cargo,
    pe.id_persona,
    pe.id_tpdocumento,
    pe.id_nacionalidad
    ,ce.userCreacion
	,ce.fechaCreacion
	,ce.userModificacion
	,ce.fechaModificacion
	,ce.flEliminado
FROM persona pe
INNER JOIN empleado em on pe.id_persona = em.id_persona
INNER JOIN cargos_empleado ce on pe.id_persona = ce.id_persona
INNER JOIN cargo ca on ce.id_cargo = ca.id_cargo
where pe.id_persona = IN_id_persona
ORDER by ce.id_caempleado DESC;

END$$

CREATE  PROCEDURE UP_LISTAR_CESE_EMPLEADO (IN IN_id_persona INT)  BEGIN


SELECT * FROM  empleado_has_cese a 
inner JOIN persona b
on a.id_persona = b.id_persona
INNER JOIN cargo c  on a.id_cargo = c.id_cargo
where b.id_persona = IN_id_persona;

END$$

CREATE  PROCEDURE UP_LISTAR_DESCANSO_EMPLEADO (IN IN_id_persona INT)  BEGIN

 SELECT 
    de.id_descanso,
    de.de_referencia,
    IF(de.de_estado = 0, 'INACTIVO', 'ACTIVO') as estado,
    case when DAYNAME(de.de_fecha)  = 'Monday' then 'Lunes'
    when  DAYNAME(de.de_fecha) = 'Tuesday' then 'Martes'
    when  DAYNAME(de.de_fecha) = 'Wednesday' then 'Miércoles'
    when  DAYNAME(de.de_fecha) = 'Thursday' then 'Jueves'
    when  DAYNAME(de.de_fecha) = 'Friday' then 'Viernes'
    when  DAYNAME(de.de_fecha) = 'Saturday' then 'Sabado'
    when  DAYNAME(de.de_fecha) = 'Sunday' then 'Domingo'
    else null end as dia,
    de.de_fecha,
    de.de_estado,
    de.de_observacion,
    pe.id_persona,
    pe.id_tpdocumento,
    pe.id_nacionalidad
    ,de.userCreacion
	,de.fechaCreacion
	,de.userModificacion
	,de.fechaModificacion
	,de.flEliminado
FROM persona pe
INNER JOIN empleado em on pe.id_persona = em.id_persona
INNER JOIN descanso de on em.id_persona = de.id_persona
where pe.id_persona = IN_id_persona
ORDER by de.id_descanso DESC;

END$$

CREATE  PROCEDURE UP_LISTAR_DOCUMENTOS_EMPLEADOS ()  BEGIN

SELECT 
    id_emdocumento,
    de_nombre,
    de_descripcion,
    userCreacion,
    flEliminado,
    IF(flEliminado = 0, 'INACTIVO', 'ACTIVO') as estado,
    CONCAT(de_nombre," - ",de_descripcion) AS datos
    ,userCreacion
	,fechaCreacion
	,userModificacion
	,fechaModificacion
	,flEliminado
FROM  documentos_empleado ;
#WHERE flEliminado = 1;

END$$

CREATE  PROCEDURE UP_LISTAR_EMPLEADO ()  BEGIN

SELECT 
    em.id_persona,
    em.id_tpdocumento,
    em.id_nacionalidad,
    pe.per_nombre,
    pe.per_apellido_paterno,
    pe.per_apellido_materno,
    pe.per_documento,
    CONCAT(per_nombre," ",per_apellido_paterno," ",per_apellido_materno) AS datos,
    ca.id_cargo,
    ca.ca_descripcion,
    na.id_nacionalidad,
    na.na_descripcion,
    td.id_tpdocumento,
    td.tpd_descripcion 
FROM empleado em
INNER JOIN persona pe on em.id_persona = pe.id_persona and em.id_tpdocumento = pe.id_tpdocumento and em.id_nacionalidad = pe.id_nacionalidad
INNER JOIN tipo_documento td on td.id_tpdocumento = em.id_tpdocumento
INNER JOIN nacionalidad na on na.id_nacionalidad = em.id_nacionalidad
INNER JOIN cargo ca on ca.id_cargo = pe.id_nacionalidad; 

END$$

CREATE  PROCEDURE UP_LISTAR_EMPLEADOS_SIN_APROBAR ()  BEGIN

SELECT 
        pe.id_persona,
        pe.id_tpdocumento,
        pe.id_nacionalidad,
        pe.per_nombre,
        pe.per_apellido_paterno,
        pe.per_apellido_materno,
        pe.per_documento,
        CONCAT(per_nombre," ",per_apellido_paterno," ",per_apellido_materno) AS datos,
        CONCAT(se_lugar," ",se_descripcion) AS sede,
        ca.id_cargo,
        ca.ca_descripcion,
        se.id_sede,
        se.se_lugar,
        se.se_descripcion,
        na.id_nacionalidad,
        na.na_descripcion,
        td.id_tpdocumento,
        td.tpd_descripcion
    FROM empleado em
    INNER JOIN persona pe on em.id_persona = pe.id_persona
    INNER JOIN tipo_documento td on td.id_tpdocumento = pe.id_tpdocumento
    INNER JOIN nacionalidad na on na.id_nacionalidad = pe.id_nacionalidad
    INNER JOIN cargos_empleado ce on ce.id_persona = pe.id_persona
    INNER JOIN cargo ca ON ca.id_cargo = ce.id_cargo
    INNER JOIN sede_empleado she ON em.id_persona = she.id_persona
    INNER JOIN sede se ON she.id_sede = se.id_sede 
    where em.phc_estado = 3;

END$$

CREATE  PROCEDURE UP_LISTAR_EMPLEADOS_SIN_APROBAR_V (IN IN_opcion INT, IN IN_dato VARCHAR(70))  BEGIN
	SELECT 
	        pe.id_persona,
	        pe.id_tpdocumento,
	        pe.id_nacionalidad,
	        pe.per_nombre,
	        pe.per_apellido_paterno,
	        pe.per_apellido_materno,
	        pe.per_documento,
	        CONCAT(per_nombre," ",per_apellido_paterno," ",per_apellido_materno) AS datos,
	        CONCAT(se_lugar," ",se_descripcion) AS sede,
	        ca.id_cargo,
	        ca.ca_descripcion,
	        se.id_sede,
	        se.se_lugar,
	        se.se_descripcion,
	        na.id_nacionalidad,
	        na.na_descripcion,
	        td.id_tpdocumento,
	        td.tpd_descripcion,
	        coalesce ((SELECT id_sueldo FROM sueldo WHERE id_persona = pe.id_persona and ta_estado = 3), 0) id_sueldo,
	        date(em.phc_fecha_r) phc_fecha_r
	        ,pe.userCreacion
			,pe.fechaCreacion
			,pe.userModificacion
			,pe.fechaModificacion
			,pe.flEliminado
	    FROM empleado em
	    INNER JOIN persona pe on em.id_persona = pe.id_persona
	    INNER JOIN tipo_documento td on td.id_tpdocumento = pe.id_tpdocumento
	    INNER JOIN nacionalidad na on na.id_nacionalidad = pe.id_nacionalidad
	    INNER JOIN cargos_empleado ce on ce.id_persona = pe.id_persona and ce.ce_estado  = 1
	    INNER JOIN cargo ca ON ca.id_cargo = ce.id_cargo
	    INNER JOIN sede_empleado she ON em.id_persona = she.id_persona and she.sm_estado = 1
	    INNER JOIN sede se ON she.id_sede = se.id_sede 
	    where em.phc_estado = 3
	    and
	        CASE WHEN IN_opcion = 1 THEN 
	            se.id_sede = IN_dato
	        WHEN IN_opcion = 2 THEN 
	             pe.per_documento like concat('%',IN_dato,'%')
	        WHEN IN_opcion = 3 THEN 
	             concat(pe.per_nombre,' ',pe.per_apellido_paterno,' ',pe.per_apellido_materno) like concat('%',IN_dato,'%')
	        ELSE 
	            TRUE 
	        END;  

END$$

CREATE  PROCEDURE UP_LISTAR_EMPLEADO_SEDES_DESCANSO_MOBIL (IN IN_id_sede INT)  BEGIN

SELECT 
    pe.id_persona,
    pe.id_tpdocumento,
    pe.id_nacionalidad,
    pe.per_nombre,
    pe.per_apellido_paterno,
    pe.per_apellido_materno,
    pe.per_documento,
    CONCAT(per_nombre," ",per_apellido_paterno," ",per_apellido_materno) AS datos,
    ca.id_cargo,
    ca.ca_descripcion,
    na.id_nacionalidad,
    na.na_descripcion,
    td.id_tpdocumento,
    td.tpd_descripcion,
    DATE(pe.pe_fecha_ingreso) pe_fecha_ingreso,
    IF(DATE(pe.pe_fecha_ingreso) = DATE(pe.pe_fecha_cese), '-', DATE(pe.pe_fecha_cese)) as cese,
    IF(pe.pe_estado = 1, 'ACTIVO','INACTIVO') as estado 
FROM empleado em
INNER JOIN persona pe on em.id_persona = pe.id_persona  
INNER JOIN tipo_documento td on td.id_tpdocumento = pe.id_tpdocumento
INNER JOIN nacionalidad na on na.id_nacionalidad = pe.id_nacionalidad
INNER JOIN sede_empleado sem on sem.id_persona = em.id_persona
INNER JOIN sede se on sem.id_sede = se.id_sede
INNER JOIN cargos_empleado ce on ce.id_persona = em.id_persona
INNER JOIN cargo ca on ca.id_cargo = ce.id_cargo 
WHERE sem.id_sede = IN_id_sede ;  

END$$

CREATE  PROCEDURE UP_LISTAR_EMPLEADO_SEDES_MOBIL (IN IN_id_sede INT, IN IN_estado VARCHAR(50))  BEGIN
  
SET lc_time_names = 'es_ES';

SELECT
    DISTINCT
    UPPER(SUBSTR(MONTHNAME(pe.pe_fecha_ingreso),1 ,4)) MES,
    day(pe.pe_fecha_ingreso) DIA,
    year(pe.pe_fecha_ingreso) ANIO,
    pe.id_persona,
    pe.id_tpdocumento,
    pe.id_nacionalidad,
    pe.per_nombre,
    pe.per_apellido_paterno,
    pe.per_apellido_materno,
    pe.per_documento,
    UPPER(CONCAT(per_nombre," ",per_apellido_paterno," ",per_apellido_materno)) AS datos,
    ca.id_cargo,
    ca.ca_descripcion,
    na.id_nacionalidad,
    UPPER(na.na_descripcion) na_descripcion,
    td.id_tpdocumento,
    td.tpd_descripcion,
    DATE(pe.pe_fecha_ingreso) pe_fecha_ingreso,
    IF(DATE(pe.pe_fecha_ingreso) = DATE(pe.pe_fecha_cese), '-', DATE(pe.pe_fecha_cese)) as cese,
    IF(pe.pe_estado <> 0, 'ACTIVO','INACTIVO') as estado,
    '' as descanso,
    fun_getBanco_Mobil(pe.id_persona) banco,
    sp_CENSURING_DNI(fun_getCuentas_Mobil(pe.id_persona)) cuenta,
    sp_CENSURING_DNI(fun_getCci_Mobil(pe.id_persona)) cci,
    IF(pe.pe_titular = 1, 'CUENTA TITULAR','CUENTA EXTERNO') as titular
FROM empleado em
INNER JOIN persona pe on em.id_persona = pe.id_persona  
INNER JOIN tipo_documento td on td.id_tpdocumento = pe.id_tpdocumento
INNER JOIN nacionalidad na on na.id_nacionalidad = pe.id_nacionalidad 
INNER JOIN cargos_empleado ce on ce.id_persona = em.id_persona and ce.ce_estado = 1
INNER JOIN cargo ca on ca.id_cargo = ce.id_cargo
inner JOIN sede_empleado sem on sem.id_persona = pe.id_persona and sem.sm_estado  = 1
WHERE sem.id_sede = IN_id_sede and 
pe.pe_estado = 
case when IN_estado = 'T'
then
pe.pe_estado
when IN_estado = '1'
then
1
when IN_estado = '0'
then
0
end
;  

END$$

CREATE  PROCEDURE UP_LISTAR_EMPLEADO_SUELDOS_MOBIL (IN IN_id_persona INT)  BEGIN
  
select 
    s.ta_total,
    s.ta_vigenciaInicio,
    if(s.ta_vigenciaFin = '2100-01-01', ' - ',s.ta_vigenciaFin) ta_vigenciaFin,
    s.ta_estado,
    IF(s.ta_estado = 1, 'ACTIVO','INACTIVO') as estado
from sueldo s where s.id_persona = IN_id_persona
order by s.ta_vigenciaFin desc;  

END$$

CREATE  PROCEDURE UP_LISTAR_FERIADO ()  BEGIN

SELECT 
id_feriado,
fe_descripcion,
fe_estado,
IF(fe_estado = 0, 'INACTIVO', 'ACTIVO') as estado,
fe_dia 
FROM feriado;

END$$

CREATE  PROCEDURE UP_LISTAR_HISTORY_CESE (IN IN_id_persona INT)  begin

	select  
		date(ce_fecha_cese) as ce_fecha_cese,
		mc.mo_nombre,
		ce_motivo,
		if(phl.id_lista is null, 'NO','SI') as ls_negra
	from empleado_has_cese ehc
	inner join motivos_cese mc on ehc.id_motivo  = mc.id_motivo 
	left join persona_has_listanegra phl  on ehc.id_lista = phl.id_lista
	where ehc.id_persona = IN_id_persona;

END$$

CREATE  PROCEDURE UP_LISTAR_HISTORY_LIST_BLACK (IN IN_id_persona INT)  begin
	select  
		date(phl.fechaCreacion ) as fechaCreacion,
		phl.lis_motivo 
	from persona_has_listanegra phl 
	where phl.id_persona = IN_id_persona order by fechaCreacion desc;
	
END$$

CREATE  PROCEDURE UP_LISTAR_LISTA_NEGRA_PERSONA (IN IN_opcion INT, IN IN_data VARCHAR(50), IN IN_estado INT)  BEGIN

    SELECT 
        distinct
         b.id_persona
        ,if(IN_estado = 1, a.id_lista , b.id_persona) as id_lista
        ,if(IN_estado = 1, a.lis_motivo , b.id_persona) as lis_motivo 
        ,concat(b.per_nombre,' ',b.per_apellido_paterno,' ',b.per_apellido_materno) as datos
        ,na.na_descripcion
        ,c.tpd_descripcion
        ,b.per_documento
        ,0 as se_descripcion
        ,0 as id_sede
        ,d.ca_descripcion 
        ,if(IN_estado = 1, a.fechaCreacion , 0) as fechaCreacion
    FROM  persona_has_listanegra a 
    inner JOIN persona b on a.id_persona = b.id_persona
    INNER JOIN nacionalidad na on b.id_nacionalidad = na.id_nacionalidad
    inner join tipo_documento c on b.id_tpdocumento = c.id_tpdocumento
    left JOIN cargos_empleado ce on ce.id_persona = b.id_persona and ce.ce_estado = 1
    left JOIN cargo d on d.id_cargo = ce.id_cargo
    inner join sede_empleado se on se.id_persona = b.id_persona and se.sm_estado = 1
    left join sede e on e.id_sede = se.id_sede
    WHERE 
    case when IN_opcion = 1
    THEN
      CONCAT(b.per_nombre," ",b.per_apellido_paterno," ",b.per_apellido_materno) like concat('%',IN_data,'%')
    when IN_opcion = 2
    THEN
      se.id_sede = IN_data
    when IN_opcion = 3
    THEN
      d.id_cargo = IN_data
    end
    and a.flEliminado = IN_estado;

END$$

CREATE  PROCEDURE UP_LISTAR_MARCADOR (IN IN_TIPO_MARCADOR INT)  BEGIN
if IN_TIPO_MARCADOR = 3
then
    SELECT 
    id_marcador,
    ma_estado,
    IF(ma_estado = 0, 'INACTIVO', 'ACTIVO') as estado, 
    ma_descripcion,
    ma_abreviatura,
    CONCAT(ma_abreviatura," - ",ma_descripcion) AS datos
    FROM marcador
    where id_marcador = 6;
elseif IN_TIPO_MARCADOR = 4
then
    SELECT 
    id_marcador,
    ma_estado,
    IF(ma_estado = 0, 'INACTIVO', 'ACTIVO') as estado, 
    ma_descripcion,
    ma_abreviatura,
    CONCAT(ma_abreviatura," - ",ma_descripcion) AS datos
    FROM marcador
    where id_marcador = 4 or id_marcador = 5;
else 
    SELECT 
    id_marcador,
    ma_estado,
    IF(ma_estado = 0, 'INACTIVO', 'ACTIVO') as estado, 
    ma_descripcion,
    ma_abreviatura,
    CONCAT(ma_abreviatura," - ",ma_descripcion) AS datos
    FROM marcador
    where ma_tipo = IN_TIPO_MARCADOR;
end if;

END$$

CREATE  PROCEDURE UP_LISTAR_MARCADOR_WEB_ADM ()  BEGIN 
SELECT 
    id_marcador,
    ma_estado,
    IF(ma_estado = 0, 'INACTIVO', 'ACTIVO') as estado, 
    ma_descripcion,
    ma_abreviatura,
    CONCAT(ma_abreviatura," - ",ma_descripcion) AS datos
    FROM marcador
    where id_marcador in(1,2,3,4,5,6);
end$$

CREATE  PROCEDURE up_listar_modulos_perfiles_sistema (IN IN_id_tpusuario INT)  begin 
    
    ##CURSOR
    DECLARE findelbucle INTEGER DEFAULT 0;
   
   # CURSOR LOOP
    declare cur_id_mpermiso int;
    declare cur_id_smodulo int;
    declare cur_id_spermiso int;
   
   #cursor para las personas
    DECLARE cur_modulos_sistema CURSOR for
    SELECT 
        b.id_mpermiso,
        a.id_smodulo,
        c.id_spermiso  
    FROM  sis_modulo a 
    INNER JOIN sis_modulo_permiso b on a.id_smodulo = b.id_smodulo and b.flEliminado = 1
    INNER JOIN sis_permiso c on b.id_spermiso = c.id_spermiso and c.flEliminado = 1
    where a.flEliminado = 1; 

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET findelbucle=1;
    
    drop table if exists modulos_sistema;
    CREATE TEMPORARY TABLE modulos_sistema(
        id_mpermiso int,
        id_smodulo  int,
        id_spermiso int,
        id_perfil  int,
        hasPermission int
    );
   
   
   #star cursor
    OPEN cur_modulos_sistema;
        loop1: loop
          
        FETCH cur_modulos_sistema INTO cur_id_mpermiso,cur_id_smodulo,cur_id_spermiso; 
        IF findelbucle = 1 THEN
           LEAVE loop1;
        END IF;
         
         
        insert into modulos_sistema 
        select
        cur_id_mpermiso, 
        cur_id_smodulo,
        cur_id_spermiso,
        IN_id_tpusuario,
        (
            select 
                a.id_mpermiso 
            from sis_perfil_modperm a 
                where a.id_mpermiso = cur_id_mpermiso 
                    and a.id_tpusuario = IN_id_tpusuario 
                    and a.flEliminado = 1
        );
        
       END LOOP loop1;
    CLOSE cur_modulos_sistema; 
    #end cursor
   
   select 
    a.id_smodulo,
    sm.sm_nombre,
    a.id_spermiso,
    sp.sp_nombre,
    a.id_mpermiso,
    if(a.hasPermission is null, 0, 1) as hasPermission
   from modulos_sistema a
   left join sis_modulo sm on a.id_smodulo = sm.id_smodulo 
   left join sis_permiso sp on a.id_spermiso = sp.id_spermiso ;

end$$

CREATE  PROCEDURE up_listar_modulos_usuarios_sistema (IN IN_id_usuario INT)  begin 
    
    ##CURSOR
    DECLARE findelbucle INTEGER DEFAULT 0;
   
   # CURSOR LOOP
    declare cur_id_mpermiso int;
    declare cur_id_smodulo int;
    declare cur_id_spermiso int;
   
    
   #cursor para las personas
    DECLARE cur_modulos_sistema CURSOR for
    SELECT 
        b.id_mpermiso,
        a.id_smodulo,
        c.id_spermiso  
    FROM  sis_modulo a 
    INNER JOIN sis_modulo_permiso b on a.id_smodulo = b.id_smodulo and b.flEliminado = 1
    INNER JOIN sis_permiso c on b.id_spermiso = c.id_spermiso and c.flEliminado = 1
    where a.flEliminado = 1; 

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET findelbucle=1;
    
    drop table if exists modulos_sistema;
    CREATE TEMPORARY TABLE modulos_sistema(
        id_mpermiso int,
        id_smodulo  int,
        id_spermiso int,
        id_usuario  int,
        hasPermission int
    );
   
   
   #star cursor
    OPEN cur_modulos_sistema;
        loop1: loop
          
        FETCH cur_modulos_sistema INTO cur_id_mpermiso,cur_id_smodulo,cur_id_spermiso; 
        IF findelbucle = 1 THEN
           LEAVE loop1;
        END IF;
         
         
        insert into modulos_sistema 
        select
        cur_id_mpermiso, 
        cur_id_smodulo,
        cur_id_spermiso,
        IN_id_usuario,
        (select a.id_mpermiso from sis_usuario_modperm a where a.id_mpermiso = cur_id_mpermiso and a.id_usuario = IN_id_usuario and a.flEliminado = 1);
        
       END LOOP loop1;
    CLOSE cur_modulos_sistema; 
    #end cursor
   
   select 
    a.id_smodulo,
    sm.sm_nombre,
    a.id_spermiso,
    sp.sp_nombre,
    a.id_mpermiso,
    if(a.hasPermission is null, 0, 1) as hasPermission
   from modulos_sistema a
   left join sis_modulo sm on a.id_smodulo = sm.id_smodulo 
   left join sis_permiso sp on a.id_spermiso = sp.id_spermiso 
   ;

    
end$$

CREATE  PROCEDURE UP_LISTAR_MOTIVOS_CESE ()  BEGIN

SELECT 
id_motivo,
mo_nombre,
flEliminado,
IF(flEliminado = 0, 'INACTIVO', 'ACTIVO') as estado,
CONCAT(mo_nombre) AS datos
FROM motivos_cese where flEliminado = 1;

END$$

CREATE  PROCEDURE UP_LISTAR_NACIONALIDAD ()  BEGIN

SELECT 
id_nacionalidad,
na_descripcion,
na_abreviatura,
na_estado,
IF(na_estado = 0, 'INACTIVO', 'ACTIVO') as estado,
CONCAT(na_abreviatura," - ",na_descripcion) AS datos
,userCreacion
,fechaCreacion
,userModificacion
,fechaModificacion
,flEliminado
FROM nacionalidad;

END$$

CREATE  PROCEDURE UP_LISTAR_PERMISO ()  BEGIN

SELECT 
id_permiso,
pe_descripcion,
pe_estado,
IF(pe_estado = 0, 'INACTIVO', 'ACTIVO') as estado,
pe_nombre
FROM permiso;

END$$

CREATE  PROCEDURE UP_LISTAR_PERMISO_WEB ()  BEGIN

SELECT 
id_permiso,
pe_descripcion,
pe_estado,
IF(pe_estado = 0, 'INACTIVO', 'ACTIVO') as estado,
pe_nombre
FROM permiso;

END$$

CREATE  PROCEDURE UP_LISTAR_PERSONAS ()  BEGIN

SELECT 
* 
FROM persona pe;

END$$

CREATE  PROCEDURE UP_LISTAR_SEDE ()  BEGIN

SELECT 
id_sede,
se_descripcion,
se_lugar,
se_cantidad,
se_estado,
IF(se_estado = 0, 'INACTIVO', 'ACTIVO') as estado,
CONCAT(se_lugar," - ",se_descripcion) AS datos
,userCreacion
,fechaCreacion
,userModificacion
,fechaModificacion
,flEliminado
FROM sede;

END$$

CREATE  PROCEDURE UP_LISTAR_SEDE_EMPLEADO (IN IN_id_persona INT)  BEGIN
 
SELECT 
    sem.id_sede_em,
    se.id_sede,
    pe.id_persona,
    date(sem.sm_fecha_r) as ta_fecha_r,
    IF(sem.sm_estado = 0, 'INACTIVO', 'ACTIVO') as estado,
    sem.sm_estado,
    sem.sm_observacion,
    concat(se.se_lugar," - ",se.se_descripcion) sede
    ,sem.userCreacion
	,sem.fechaCreacion
	,sem.userModificacion
	,sem.fechaModificacion
	,sem.flEliminado
FROM persona pe
INNER JOIN empleado em on pe.id_persona = em.id_persona 
INNER JOIN sede_empleado sem on em.id_persona = sem.id_persona
INNER JOIN sede se on se.id_sede = sem.id_sede
 where pe.id_persona = IN_id_persona
ORDER by sem.id_sede_em DESC
;

END$$

CREATE  PROCEDURE UP_LISTAR_SUELDO_EMPLEADO (IN IN_id_persona INT)  BEGIN
 
SELECT 
    su.id_sueldo,
    pe.id_persona,
    date(su.ta_fecha_r) as ta_fecha_r,
    su.ta_basico,
    su.ta_asignacion_familiar,
    su.ta_movilidad,
    su.ta_alimentos,
    su.ta_bonificacion,
    su.ta_total,
    su.ta_csdia,
    su.ta_estado,
    if(su.ta_vigenciaInicio = '2100-01-01', '',su.ta_vigenciaInicio) as ta_vigenciaInicio,
    if(su.ta_vigenciaFin = '2100-01-01', '',su.ta_vigenciaFin) as ta_vigenciaFin 
    ,su.userCreacion
	,su.fechaCreacion
	,su.userModificacion
	,su.fechaModificacion
	,su.flEliminado
FROM persona pe
INNER JOIN empleado em on pe.id_persona = em.id_persona 
INNER JOIN sueldo su on su.id_persona = em.id_persona
where pe.id_persona = IN_id_persona
ORDER by su.id_sueldo DESC
;

END$$

CREATE  PROCEDURE UP_LISTAR_SUPLENTE_DOCUMENTO (IN IN_id_persona INT)  BEGIN 
    select 
    sc.id_sucobrar,
    CONCAT(pe.per_nombre," ",pe.per_apellido_paterno," ",pe.per_apellido_materno) AS datos,
    coalesce(CONCAT(ba.ba_abreviatura," - ",ba.ba_nombre), 'No ingresado') AS banco,
    coalesce(phb.phb_cuenta, 'No ingresado') phb_cuenta,
    coalesce(phb.phb_cci, 'No ingresado') phb_cci, 
    IF(sc.suc_estado = 0, 'INACTIVO', 'ACTIVO') as estado,
    sc.suc_estado,
    c.tpc_abreviatura,
    c.tpc_descripcion,
     pe.per_documento
from suplente_cobrar sc 
INNER JOIN persona pe on sc.id_persona = pe.id_persona
LEFT JOIN persona_has_banco phb on phb.id_persona = pe.id_persona  and phb.phb_estado = 1
LEFT JOIN banco ba on ba.id_banco = phb.id_banco
LEFT JOIN tipo_cuenta c on phb.id_tpcuenta = c.id_tpcuenta
where sc.suc_origen  =  IN_id_persona;
#and sc.suc_estado = 1;

END$$

CREATE  PROCEDURE UP_LISTAR_TABLAS_DBA ()  BEGIN
  
select 
    *
from tablas_dba td where td.flEliminado  = 1;  

END$$

CREATE  PROCEDURE UP_LISTAR_TIPO_CUENTA ()  BEGIN

SELECT 
id_tpcuenta,
tpc_descripcion,
tpc_abreviatura,
CONCAT(tpc_abreviatura," - ",tpc_descripcion) AS datos
FROM tipo_cuenta;

END$$

CREATE  PROCEDURE UP_LISTAR_TIPO_DOCUMENTO ()  BEGIN

SELECT 
id_tpdocumento,
tpd_estado,
IF(tpd_estado = 0, 'INACTIVO', 'ACTIVO') as estado,
tpd_descripcion,
tpd_abreviatura,
CONCAT(tpd_abreviatura," - ",tpd_descripcion) AS datos,
tpd_longitud
,userCreacion
,fechaCreacion
,userModificacion
,fechaModificacion
,flEliminado
FROM tipo_documento;

END$$

CREATE  PROCEDURE UP_LISTAR_TPUSUARIO ()  BEGIN

SELECT 
tp.id_tpusuario,
tp.tpu_descripcion,
tp.tpu_estado,
tp.tpu_abreviatura, 
IF(tp.tpu_estado = 0, 'INACTIVO', 'ACTIVO') as estado,
CONCAT(tpu_abreviatura," - ",tpu_descripcion) AS datos 
,tp.userCreacion
,tp.fechaCreacion
,tp.userModificacion
,tp.fechaModificacion
,tp.flEliminado
FROM tipo_usuario tp;

END$$

CREATE  PROCEDURE UP_LISTAR_USUARIOS_SISTEMA ()  BEGIN

 select 
    pe.id_persona,
    u.id_usuario,
    u.id_tpusuario,
    CONCAT(pe.per_nombre," ",pe.per_apellido_paterno," ",pe.per_apellido_materno) AS datos,
    u.us_usuario,
    u.us_contrasenia,
    u.us_estado,
    IF(u.us_estado = 0, 'INACTIVO', 'ACTIVO') as estado,
    tp.tpu_descripcion as pe_perfil
    ,u.userCreacion
	,u.fechaCreacion
	,u.userModificacion
	,u.fechaModificacion
	,u.flEliminado
from usuario u 
INNER JOIN persona pe on u.us_persona = pe.id_persona
inner join tipo_usuario tp on tp.id_tpusuario = u.id_tpusuario
where EXISTS(
    select * from empleado where id_persona = u.us_persona
) order by u.id_usuario desc;

END$$

CREATE  PROCEDURE UP_LISTAR_VIGENCIA_SUELDO (IN IN_id_sueldo INT)  BEGIN

select 
s.ta_vigenciaInicio,
s.ta_vigenciaFin
from sueldo s where s.id_sueldo  = IN_id_sueldo;

END$$

CREATE  PROCEDURE up_list_all_documents (IN in_persona INT)  begin 
	
	##CURSOR
    DECLARE findelbucle INTEGER DEFAULT 0;
   
   # CURSOR LOOP
    declare id_documento int;
   
   #cursor para las personas
    DECLARE documentos_sistema CURSOR for
    select 
		id_emdocumento
	from documentos_empleado de where de.flEliminado = 1; 

	DECLARE CONTINUE HANDLER FOR NOT FOUND SET findelbucle=1;

	drop table if EXISTS temp_documento;
	create TEMPORARY table temp_documento(
		id_docemp	int,
	    id_documento int,
	    id_persona int,
	    per_documento varchar(50),
	    do_descripcion varchar(50),
	    do_peso decimal(15,4),
	    do_ruta varchar(250),
	    do_emision date,
	    do_vigencia date
	);
	 

	insert into temp_documento
	select
		0,
		id_emdocumento, 
		in_persona,
		(select pe.per_documento from persona pe where pe.id_persona = in_persona limit 1),
		de_nombre,
		0,
		'',
		curdate(),
		curdate()
	from documentos_empleado de where de.flEliminado = 1;
	 

    #star cursor
    OPEN documentos_sistema;
        loop1: loop
          
        FETCH documentos_sistema INTO id_documento; 
        IF findelbucle = 1 THEN
           LEAVE loop1;
        END IF;
         
       	UPDATE temp_documento a
		LEFT JOIN documentos_has_empleado b 
			on a.id_documento = b.id_emdocumento
		    and a.id_persona = b.id_persona 
		    and b.flEliminado = 1
		set
			a.id_docemp 	= b.id_docemp,
		    a.do_ruta  		= b.emd_nombrefile,
		    a.do_peso 		= b.emd_pesofile, 
		    a.do_emision 	= b.emd_emision , 
		    a.do_vigencia 	= b.emd_vigencia;
        
       
       END LOOP loop1;
    CLOSE documentos_sistema; 
	
	
   select * from temp_documento;
	
end$$

CREATE  PROCEDURE up_list_profile_users ()  BEGIN 
select 
    tu.id_tpusuario,
    tpu_descripcion,
    tpu_estado,
    if(tpu_estado = 0, 'INACTIVO','ACTIVO') estado,
    tpu_abreviatura,
    concat(tpu_abreviatura,' - ',tpu_descripcion) as datos,
    coalesce((select count(*) from sis_perfil_modperm a where a.id_tpusuario = tu.id_tpusuario and a.flEliminado = 1),0) as cantidad
    ,tu.userCreacion
	,tu.fechaCreacion
	,tu.userModificacion
	,tu.fechaModificacion
	,tu.flEliminado
from tipo_usuario tu;
END$$

CREATE  PROCEDURE UP_LOGIN_USUARIO (IN IN_us_usuario VARCHAR(50), IN IN_us_contrasenia VARCHAR(50))  BEGIN 
 
IF EXISTS( SELECT * FROM usuario WHERE us_usuario = IN_us_usuario AND us_contrasenia = IN_us_contrasenia)
THEN
    SELECT 
        pe.id_persona,
        pe.id_tpdocumento,
        pe.id_nacionalidad,
        CONCAT(pe.per_nombre," ",pe.per_apellido_paterno," ",pe.per_apellido_materno) AS datos,
        us.id_usuario,
        us.id_tpusuario,
        us.us_usuario,
        tu.tpu_descripcion,
        pe.per_documento,
        us.us_contrasenia
     FROM usuario us
     INNER JOIN tipo_usuario tu on us.id_tpusuario = tu.id_tpusuario
     INNER JOIN persona pe on pe.id_persona = us.us_persona
     LEFT JOIN empleado em on pe.id_persona = us.us_persona
     WHERE us_usuario=IN_us_usuario AND us_contrasenia= IN_us_contrasenia;
ELSE
    signal sqlstate '45000' set message_text = 'Usuario o contraseña incorrecta!';
END IF;

END$$

CREATE  PROCEDURE UP_LOGIN_USUARIO_MOBIL (IN IN_us_usuario VARCHAR(50), IN IN_us_contrasenia VARCHAR(50))  BEGIN 
 

IF EXISTS( SELECT * FROM usuario WHERE us_usuario = IN_us_usuario AND us_contrasenia = IN_us_contrasenia)
THEN
    SELECT 
        pe.id_persona,
        pe.id_tpdocumento,
        pe.id_nacionalidad,
        CONCAT(pe.per_nombre," ",pe.per_apellido_paterno," ",pe.per_apellido_materno) AS datos,
        us.id_usuario,
        us.id_tpusuario,
        us.us_usuario,
        tu.tpu_descripcion,
        pe.per_documento,
        us.us_contrasenia
     FROM usuario us
     INNER JOIN tipo_usuario tu on us.id_tpusuario = tu.id_tpusuario
     INNER JOIN persona pe on pe.id_persona = us.us_persona
     LEFT JOIN empleado em on pe.id_persona = us.us_persona
     WHERE us_usuario=IN_us_usuario AND us_contrasenia= IN_us_contrasenia;
ELSE
    signal sqlstate '45000' set message_text = 'Usuario o contraseña incorrecta!';
END IF;

END$$

CREATE  PROCEDURE UP_LOGIN_USUARIO_WEB (IN IN_us_usuario VARCHAR(50), IN IN_us_contrasenia VARCHAR(50))  BEGIN 

declare dec_id_persona int;
declare dec_id_usuario int;
declare dec_us_estado int;
declare dec_us_persmisos int;
declare dec_pe_estado int;

SELECT 
us_persona, us_estado , id_usuario 
into  
dec_id_persona, dec_us_estado, dec_id_usuario
FROM usuario WHERE us_usuario = IN_us_usuario AND us_contrasenia = IN_us_contrasenia;

select pe_estado into  dec_pe_estado from persona p where p.id_persona  = dec_id_persona;

select count(sum2.id_mpermiso)  into  dec_us_persmisos from sis_usuario_modperm sum2 where sum2.id_usuario  = dec_id_usuario and sum2.flEliminado = 1;

if(dec_id_persona is null)
then
  signal sqlstate '45000' set message_text = 'Usuario o contraseña incorrecta!';
end if;

if(dec_pe_estado = 0)
then
  signal sqlstate '45000' set message_text = 'El empleado esta inactivo!';
end if;

if(dec_us_estado = 0)
then
  signal sqlstate '45000' set message_text = 'El usuario esta inactivo!';
end if;

if(dec_us_persmisos <= 0)
then
  signal sqlstate '45000' set message_text = 'Este empleado no cuenta con ningun permiso!';
end if;

  
IF EXISTS(SELECT * FROM usuario WHERE us_usuario = IN_us_usuario AND us_contrasenia = IN_us_contrasenia and us_estado = 1)
THEN
    SELECT 
        p.id_persona AS id_persona, 
        if(ee.id_persona = 1, 'ADMINISTRADOR', concat(ee.per_apellido_paterno," ",ee.per_apellido_materno," ",ee.per_nombre)) as datos,
        us.id_usuario,
        us.id_tpusuario,
        us.us_usuario,
        tu.tpu_descripcion, 
        us.us_contrasenia,
        p.phc_foto_perfil
     FROM usuario us
     INNER JOIN tipo_usuario tu on us.id_tpusuario = tu.id_tpusuario
     inner join empleado p on us.us_persona = p.id_persona
     inner join persona ee on ee.id_persona = p.id_persona
     WHERE us_usuario=IN_us_usuario AND us_contrasenia= IN_us_contrasenia and us_estado = 1;
ELSE
    signal sqlstate '45000' set message_text = 'Usuario o contraseña incorrecta!';
END IF;
END$$

CREATE  PROCEDURE UP_MERGE_BANCO (IN IN_id_banco INT, IN IN_ba_nombre VARCHAR(50), IN IN_ba_abreviatura VARCHAR(50), IN IN_ba_descripcion TEXT, IN IN_ba_estado INT, IN IN_userCreacion VARCHAR(50))  BEGIN


if(IN_id_banco = '' or IN_id_banco = 0 or IN_id_banco is null)
then

	INSERT INTO banco
    (
        id_banco,
        ba_nombre,
        ba_abreviatura,
        ba_descripcion,
        ba_estado,
        userCreacion,
        userModificacion
    )
	VALUES
    (
        IN_id_banco,
        IN_ba_nombre,
        IN_ba_abreviatura,
        IN_ba_descripcion,
        IN_ba_estado,
        IN_userCreacion,
        IN_userCreacion
    );

else

	UPDATE banco
	SET ba_nombre = IN_ba_nombre,
	    ba_abreviatura = IN_ba_abreviatura,
	    ba_descripcion = IN_ba_descripcion,
	    ba_estado = IN_ba_estado ,
	    userModificacion = IN_userCreacion ,
	    fechaModificacion= now()
	WHERE id_banco = IN_id_banco;

end if;


END$$

CREATE  PROCEDURE UP_MERGE_CARGO (IN IN_id_cargo INT, IN IN_id_tipoUsuario INT, IN IN_ca_descripcion TEXT, IN IN_ca_abreviatura VARCHAR(50), IN IN_ca_estado INT, IN IN_userCreacion VARCHAR(50))  BEGIN
         
	if(IN_id_cargo = '' or IN_id_cargo = 0 or IN_id_cargo is null)
	then
	
		INSERT INTO cargo
	    (
	        id_cargo,
	        ca_descripcion,
	        ca_abreviatura,
	        ca_estado,
	        id_tipoUsuario,
	        userCreacion,
	        userModificacion
	    )
		VALUES
	    (
	        IN_id_cargo,
	        IN_ca_descripcion,
	        IN_ca_abreviatura,
	        IN_ca_estado,
	        IN_id_tipoUsuario,
	        IN_userCreacion,
	        IN_userCreacion
	    ); 
	
	else
	
		UPDATE cargo
		SET ca_descripcion   = IN_ca_descripcion,
	       ca_abreviatura   = IN_ca_abreviatura,
	       ca_estado        = IN_ca_estado,
	       id_tipoUsuario   = IN_id_tipoUsuario,
	       userModificacion	= IN_userCreacion,
	       fechaModificacion= now()
		WHERE id_cargo = IN_id_cargo;
	
	end if;

END$$

CREATE  PROCEDURE UP_MERGE_CUENTA_TITULAR (IN IN_id_phbanco INT, IN IN_id_persona INT, IN IN_id_banco INT, IN IN_id_tpcuenta INT, IN IN_phb_cuenta VARCHAR(50), IN IN_phb_cci VARCHAR(50), IN IN_phb_estado INT, IN IN_userCreacion VARCHAR(50))  BEGIN
    
    IF IN_phb_estado = 1
    THEN
        UPDATE 
        	persona_has_banco 
        	SET
            phb_estado = 0
            ,userModificacion	= IN_userCreacion
			,fechaModificacion= now()
        WHERE 
        id_persona = IN_id_persona
        and phb_estado = 1;
    END IF;

   	
	if(IN_id_phbanco = '' or IN_id_phbanco = 0 or IN_id_phbanco is null)
	then
	
		INSERT INTO persona_has_banco (
	        id_phbanco,
	        id_persona,
	        id_banco,
	        id_tpcuenta,
	        phb_cuenta,
	        phb_cci,
	        phb_estado
	        ,userCreacion,userModificacion
	    ) VALUES (
	        IN_id_phbanco,
	        IN_id_persona,
	        IN_id_banco,
	        IN_id_tpcuenta,
	        IN_phb_cuenta,
	        IN_phb_cci,
	        IN_phb_estado 
	        ,IN_userCreacion
			,IN_userCreacion
	    );
	
	else
	
		UPDATE persona_has_banco
		SET 
			id_banco = IN_id_banco,
		    id_persona = IN_id_persona,
		    id_tpcuenta = IN_id_tpcuenta,
		    phb_cuenta = IN_phb_cuenta,
		    phb_cci = IN_phb_cci,
		    phb_estado = IN_phb_estado
		   	,userModificacion	= IN_userCreacion
			,fechaModificacion= now()
		WHERE id_phbanco = IN_id_phbanco;
	
	end if;
    
END$$

CREATE  PROCEDURE UP_MERGE_DOCUMENTO_EMPLEADO (IN IN_id_emdocumento INT, IN IN_de_nombre VARCHAR(50), IN IN_de_descripcion VARCHAR(50), IN IN_userCreacion VARCHAR(50), IN IN_flEliminado INT)  BEGIN
  
if(IN_id_emdocumento = '' or IN_id_emdocumento = 0 or IN_id_emdocumento is null)
then

	INSERT INTO documentos_empleado
    (
        id_emdocumento,
        de_nombre,
        de_descripcion,
        de_obligatirio,
        de_fecha,
        userCreacion,
        fechaCreacion,
        userModificacion,
        fechaModificacion,
        flEliminado
    )
	VALUES
    (
        IN_id_emdocumento,
        IN_de_nombre,
        IN_de_descripcion,
        0,
        now(),
        IN_userCreacion,
        now(),
        IN_userCreacion,
        now(),
        IN_flEliminado
    );

else

	UPDATE documentos_empleado
	SET  de_nombre = IN_de_nombre
	   	,de_descripcion = IN_de_descripcion
	   	,flEliminado = IN_flEliminado
	   	,userModificacion = IN_userCreacion
	  	,fechaModificacion= now()
	WHERE id_emdocumento = IN_id_emdocumento;

end if;
  
END$$

CREATE  PROCEDURE UP_MERGE_FERIADO (IN IN_id_feriado INT, IN IN_fe_dia TEXT, IN IN_fe_descripcion VARCHAR(50), IN IN_fe_estado INT)  BEGIN
    
    declare dec_fecha date;

    IF EXISTS(SELECT * FROM feriado where id_feriado = IN_id_feriado) 
    THEN 

        select fe_dia into dec_fecha from feriado where id_feriado = IN_id_feriado;


        IF dec_fecha <> IN_fe_dia
        THEN

             IF EXISTS(SELECT * FROM feriado where date(fe_dia) = date(IN_fe_dia)) 
            THEN
                 signal sqlstate '45000' set message_text = 'El feriado que tratas de actualizar ya existe!';
            ELSE
                 UPDATE feriado SET  
               fe_dia =   IN_fe_dia,
               fe_descripcion=IN_fe_descripcion,
               fe_estado=IN_fe_estado where id_feriado = IN_id_feriado;
            END IF;

        ELSE
            UPDATE feriado SET  
           fe_dia =   IN_fe_dia,
           fe_descripcion=IN_fe_descripcion,
           fe_estado=IN_fe_estado where id_feriado = IN_id_feriado;
        END IF;
 
    ELSE
        INSERT INTO feriado (fe_dia, fe_descripcion, fe_estado)  
        VALUES (
            IN_fe_dia,
            IN_fe_descripcion,
            IN_fe_estado 
        );

    END IF; 

END$$

CREATE  PROCEDURE UP_MERGE_MARCADOR (IN IN_id_marcador VARCHAR(50), IN IN_ma_descripcion VARCHAR(50), IN IN_ma_abreviatura VARCHAR(50), IN IN_ma_estado INT)  BEGIN
 
INSERT INTO marcador (id_marcador,ma_descripcion,ma_abreviatura,ma_estado)  
    VALUES (
        IN_id_marcador,
        IN_ma_descripcion,
        IN_ma_abreviatura,
        IN_ma_estado 
    )   
ON DUPLICATE KEY UPDATE  
   ma_descripcion = IN_ma_descripcion,
   ma_abreviatura = IN_ma_abreviatura, 
   ma_estado = IN_ma_estado;

END$$

CREATE  PROCEDURE UP_MERGE_NACIONALIDAD (IN IN_id_nacionalidad INT, IN IN_na_descripcion VARCHAR(50), IN IN_na_abreviatura VARCHAR(50), IN IN_na_estado INT, IN IN_userCreacion VARCHAR(50))  begin
	
	
if(IN_id_nacionalidad = '' or IN_id_nacionalidad = 0 or IN_id_nacionalidad is null)
then

	 INSERT INTO nacionalidad
    (
        id_nacionalidad,
        na_descripcion,
        na_abreviatura,
        na_estado,
        userCreacion,
        userModificacion
    )
	VALUES
    (
        IN_id_nacionalidad, 
        IN_na_descripcion, 
        IN_na_abreviatura, 
        IN_na_estado, 
        IN_userCreacion, 
        IN_userCreacion
    );

else

 	UPDATE
    nacionalidad
	SET
	    na_descripcion = IN_na_descripcion,
	    na_abreviatura = IN_na_abreviatura,
	    na_estado = IN_na_estado,
	    userModificacion = IN_userCreacion,
	    fechaModificacion = now()
	WHERE
	    id_nacionalidad = IN_id_nacionalidad;

end if;
  

END$$

CREATE  PROCEDURE UP_MERGE_PERFIL_USUARIO (IN IN_id_tpusuario INT, IN IN_tpu_descripcion VARCHAR(50), IN IN_tpu_estado INT, IN IN_tpu_abreviatura VARCHAR(50), IN IN_userCreacion VARCHAR(50))  BEGIN
  
INSERT INTO tipo_usuario (id_tpusuario, tpu_descripcion, tpu_estado, tpu_abreviatura,userCreacion,userModificacion)   
    VALUES (
        IN_id_tpusuario,
        IN_tpu_descripcion,
        IN_tpu_estado,
        IN_tpu_abreviatura
        ,IN_userCreacion
,IN_userCreacion
    )   
ON DUPLICATE KEY UPDATE  
   tpu_descripcion = IN_tpu_descripcion,
   tpu_estado = IN_tpu_estado,
   tpu_abreviatura = IN_tpu_abreviatura
  	,userModificacion	= IN_userCreacion
	,fechaModificacion= now()
   ;

END$$

CREATE  PROCEDURE UP_MERGE_PERMISO (IN IN_id_permiso INT, IN IN_pe_descripcion TEXT, IN IN_pe_nombre VARCHAR(50), IN IN_pe_estado INT)  BEGIN

    INSERT INTO permiso (id_permiso, pe_descripcion, pe_estado, pe_nombre)  
        VALUES (
            IN_id_permiso,
            IN_pe_descripcion,
            IN_pe_estado,
            IN_pe_nombre 
        )   
    ON DUPLICATE KEY UPDATE  
       pe_descripcion   = IN_pe_descripcion,
       pe_estado        = IN_pe_estado,
       pe_nombre        = IN_pe_nombre ;

END$$

CREATE  PROCEDURE UP_MERGE_PERSONA (IN IN_id_persona INT, IN IN_id_tpdocumento VARCHAR(80), IN IN_id_nacionalidad INT, IN IN_per_nombre VARCHAR(80), IN IN_per_apellido_paterno VARCHAR(80), IN IN_per_apellido_materno VARCHAR(80), IN IN_per_documento VARCHAR(80), IN IN_per_fecha_nac DATE, IN IN_per_celular VARCHAR(80), IN IN_per_correo VARCHAR(80), IN IN_per_nacionalidad INT, IN IN_pe_fecha_ingreso DATE, IN IN_pe_titular INT, IN IN_pe_usuario INT, IN IN_pe_sexo VARCHAR(1), IN IN_pe_direccion VARCHAR(80), IN IN_pe_estado INT, IN IN_userCreacion VARCHAR(50))  BEGIN
   
    declare dec_documento varchar(80);
    select p.per_documento into dec_documento from persona p where p.id_persona = IN_id_persona;
   
   
   	IF EXISTS(
    	SELECT 1 FROM  persona_has_listanegra a WHERE a.id_persona  = IN_id_persona and a.flEliminado = 1
	)
	THEN
	    signal sqlstate '45000' set message_text = 'Esta persona está en la lista negra, por favor anúlelo y vuelva a intentarlo';
	end if;
	
	IF EXISTS(
	    SELECT 1 FROM  empleado_has_cese a WHERE 
	    a.id_persona = IN_id_persona
	    and a.flEliminado = 1
	)
	then
		if IN_pe_estado = 1
		then 
			update empleado_has_cese set flEliminado = 0 
				,userModificacion	= IN_userCreacion
				,fechaModificacion= now()
			where id_persona = IN_id_persona ;
		end if; 
	end if;


    if dec_documento <> IN_per_documento
    then 
        if exists(select id_persona from persona p where p.per_documento = IN_per_documento)
        then
            signal sqlstate '45000' set message_text = 'Este documento ya se ecuentra registrado en el sistema!';
        else 
            UPDATE persona SET 
            id_tpdocumento=IN_id_tpdocumento,
            id_nacionalidad=IN_id_nacionalidad,
            per_nombre=IN_per_nombre,
            per_apellido_paterno=IN_per_apellido_paterno,
            per_apellido_materno=IN_per_apellido_materno,
            per_documento=IN_per_documento,
            per_fecha_nac=IN_per_fecha_nac,
            per_celular=IN_per_celular,
            per_correo=IN_per_correo,
            per_nacionalidad=IN_per_nacionalidad,
            pe_estado=IN_pe_estado,
            pe_fecha_ingreso=IN_pe_fecha_ingreso,
            pe_titular=IN_pe_titular,
            pe_usuario=IN_pe_usuario,
            pe_sexo=IN_pe_sexo,
            pe_direccion=IN_pe_direccion 
            ,userModificacion	= IN_userCreacion
			,fechaModificacion= now()
            WHERE 
            id_persona = IN_id_persona
            ;

        end if;
    else
        UPDATE persona SET 
            id_tpdocumento=IN_id_tpdocumento,
            id_nacionalidad=IN_id_nacionalidad,
            per_nombre=IN_per_nombre,
            per_apellido_paterno=IN_per_apellido_paterno,
            per_apellido_materno=IN_per_apellido_materno,
            per_documento=IN_per_documento,
            per_fecha_nac=IN_per_fecha_nac,
            per_celular=IN_per_celular,
            per_correo=IN_per_correo,
            per_nacionalidad=IN_per_nacionalidad,
            pe_estado=IN_pe_estado,
            pe_fecha_ingreso=IN_pe_fecha_ingreso,
            pe_titular=IN_pe_titular,
            pe_usuario=IN_pe_usuario,
            pe_sexo=IN_pe_sexo,
            pe_direccion=IN_pe_direccion 
             ,userModificacion	= IN_userCreacion
			,fechaModificacion= now()
            WHERE 
            id_persona = IN_id_persona
            ;
    end if;

END$$

CREATE  PROCEDURE UP_MERGE_PERSONA_EMPLEADO (IN IN_id_persona INT, IN IN_id_tpdocumento VARCHAR(80), IN IN_id_nacionalidad INT, IN IN_per_nombre VARCHAR(80), IN IN_per_apellido_paterno VARCHAR(80), IN IN_per_apellido_materno VARCHAR(80), IN IN_per_documento VARCHAR(80), IN IN_per_fecha_nac DATE, IN IN_per_celular VARCHAR(80), IN IN_per_correo VARCHAR(80), IN IN_per_nacionalidad INT, IN IN_pe_fecha_ingreso DATE, IN IN_pe_fecha_cese DATE, IN IN_pe_titular INT, IN IN_pe_usuario INT, IN IN_pe_sexo VARCHAR(1), IN IN_pe_direccion VARCHAR(80), IN IN_pe_estado INT)  BEGIN


declare dec_documento varchar(80);
    select p.per_documento into dec_documento from persona p where p.id_persona = IN_id_persona;

    if dec_documento <> IN_per_documento
    then 
        if exists(select id_persona from persona p where p.per_documento = IN_per_documento)
        then
            signal sqlstate '45000' set message_text = 'Este documento ya se ecuentra registrado en el sistema!';
        else 
            UPDATE persona SET 
            id_tpdocumento=IN_id_tpdocumento,
            id_nacionalidad=IN_id_nacionalidad,
            per_nombre=IN_per_nombre,
            per_apellido_paterno=IN_per_apellido_paterno,
            per_apellido_materno=IN_per_apellido_materno,
            per_documento=IN_per_documento,
            per_fecha_nac=IN_per_fecha_nac,
            per_celular=IN_per_celular,
            per_correo=IN_per_correo,
            per_nacionalidad=IN_per_nacionalidad,
            pe_estado=IN_pe_estado,
            pe_fecha_ingreso=IN_pe_fecha_ingreso,
            pe_fecha_cese =IN_pe_fecha_cese,
            pe_usuario=IN_pe_usuario,
            pe_sexo=IN_pe_sexo,
            pe_direccion=IN_pe_direccion WHERE 
            id_persona = IN_id_persona;

        end if;
    else
        UPDATE persona SET 
            id_tpdocumento=IN_id_tpdocumento,
            id_nacionalidad=IN_id_nacionalidad,
            per_nombre=IN_per_nombre,
            per_apellido_paterno=IN_per_apellido_paterno,
            per_apellido_materno=IN_per_apellido_materno,
            per_documento=IN_per_documento,
            per_fecha_nac=IN_per_fecha_nac,
            per_celular=IN_per_celular,
            per_correo=IN_per_correo,
            per_nacionalidad=IN_per_nacionalidad,
            pe_estado=IN_pe_estado,
            pe_fecha_ingreso=IN_pe_fecha_ingreso,
            pe_fecha_cese =IN_pe_fecha_cese,
            pe_usuario=IN_pe_usuario,
            pe_sexo=IN_pe_sexo,
            pe_direccion=IN_pe_direccion WHERE 
            id_persona = IN_id_persona;
    end if;
   

END$$

CREATE  PROCEDURE UP_MERGE_SEDE (IN IN_id_sede INT, IN IN_se_descripcion TEXT, IN IN_se_lugar VARCHAR(50), IN IN_se_cantidad INT, IN IN_se_estado INT, IN IN_userCreacion VARCHAR(50))  BEGIN

if(IN_id_sede = '' or IN_id_sede = 0 or IN_id_sede is null)
then
 
	INSERT INTO sede
    (
        id_sede,
        se_descripcion,
        se_lugar,
        se_cantidad,
        se_estado,
        userCreacion,
        userModificacion
    )
	VALUES
    (
        IN_id_sede, 
        IN_se_descripcion, 
        IN_se_lugar, 
        IN_se_cantidad, 
        IN_se_estado, 
        IN_userCreacion, 
        IN_userCreacion
    );
	
else

	UPDATE sede
	SET 
	se_descripcion = IN_se_descripcion,
   	se_lugar = IN_se_lugar,
   	se_cantidad = IN_se_cantidad,
   	se_estado = IN_se_estado
  	,userModificacion	= IN_userCreacion
	,fechaModificacion= now()
	WHERE id_sede = IN_id_sede;

end if;
  
END$$

CREATE  PROCEDURE UP_MERGE_TIPO_DOCUMENTO (IN IN_id_tpdocumento VARCHAR(50), IN IN_tpd_descripcion VARCHAR(50), IN IN_tpd_abreviatura VARCHAR(50), IN IN_tpd_longitud INT, IN IN_tpd_estado INT, IN IN_userCreacion VARCHAR(50))  begin
	 
INSERT INTO tipo_documento (id_tpdocumento,tpd_descripcion,tpd_abreviatura,tpd_longitud,tpd_estado,userCreacion,userModificacion)  
    VALUES (
        IN_id_tpdocumento,
        IN_tpd_descripcion,
        IN_tpd_abreviatura,
        IN_tpd_longitud,
        IN_tpd_estado 
        ,IN_userCreacion
,IN_userCreacion
    )   
ON DUPLICATE KEY UPDATE  
   tpd_descripcion = IN_tpd_descripcion,
   tpd_abreviatura = IN_tpd_abreviatura, 
   tpd_longitud = IN_tpd_longitud,
   tpd_estado = IN_tpd_estado 
,userModificacion	= IN_userCreacion
,fechaModificacion= now();

END$$

CREATE  PROCEDURE UP_MIGRAR_SUPLENTE_EMPLEADO (IN IN_id_persona INT)  BEGIN

declare dec_documento varchar(50);

select per_documento into dec_documento from persona where id_persona = IN_id_persona;

/*
* EMPLEADO
**/
INSERT INTO  empleado (id_persona, phc_estado, phc_fecha_r, phc_fecha_c, phc_auditoria, phc_codigo) VALUES 
(
    IN_id_persona,
    1,
    NOW(),
    NOW(),
    NOW(),
    'CODIGO'
);

/*
* USUARIO
*/
INSERT INTO usuario(id_tpusuario, us_usuario, us_contrasenia, us_estado, us_fecha_r, us_fecha_c, us_empleado, us_persona) 
VALUES 
(
    3,
    dec_documento,
    dec_documento,
    0,
    NOW(),
    NOW(),
    IN_id_persona,
    IN_id_persona
);

END$$

CREATE  PROCEDURE UP_MODIFICAR_TAREO_WEB (IN IN_id_tareo INT, IN IN_ta_estado INT, IN IN_userCreacion VARCHAR(50))  BEGIN 

    IF NOT EXISTS(
        SELECT id_tareo FROM tareo
        WHERE
        id_tareo = IN_id_tareo
    ) 
    THEN
        signal sqlstate '45000' set message_text = 'Este tareo no existe!!';
    ELSE
        UPDATE tareo SET 
        ta_estado=IN_ta_estado  
       	,userModificacion	= IN_userCreacion
		,fechaModificacion= now()
        WHERE id_tareo = IN_id_tareo;
    END IF;
       
END$$

CREATE  PROCEDURE up_procesar_planilla_15CNA (IN IN_MES VARCHAR(8), IN IN_ANIO VARCHAR(8), IN IN_SEDE INT, IN IN_REPROCESO INT)  begin 
    
    
    declare mismo_inicio date;
    declare inicio_dia date;
    declare final_quincena date; 
    declare perido_interno varchar(80);
    declare dias_x_mes int;
    declare dec_porcNoche decimal(9,2);
    declare dec_modoDescanso int;
    declare dec_codPlanilla int;
    declare dec_codPlanillaBorrado int;
   
   
    # CURSOR LOOP
    declare nombres varchar(50);
    declare tPdocumento varchar(50);
    declare nacionalidad varchar(50);
    declare cargo varchar(50);
    declare ingreso varchar(50); 
    declare banco varchar(50);
    declare cuenta varchar(50);
    declare tpCuenta varchar(50);
    declare cci varchar(50); 
    declare suplente varchar(50); 
    declare id_persona int;
    declare documento varchar(50);
    declare fechaSece varchar(50);
    declare personaEstado int;
   
    # SUELDO
    declare dec_SueldoXdiaVigencia decimal(9,2) default 0;
    declare dec_SueldoCodigoVigencia  int default 0;
    declare dec_RemuneracionTotal decimal(9,2) default 0;

    DECLARE findelbucle INTEGER DEFAULT 0; 
   
    #cursor para las personas
    DECLARE personas_tareo CURSOR for
    select distinct 
        fun_getNamePersona_planilla(p.id_persona) as nombres,
        fun_getTpDocumento_planilla(p.id_persona) as tPdocumento,
        fun_getNacionalidad_planilla(p.id_persona) as nacionalidad,
        fun_getCargo_planilla(p.id_persona) cargo,
        fun_getFechaIngreso_planilla(p.id_persona) ingreso, 
        fun_getBanco_planilla(p.id_persona) banco,
        fun_getCuentas_planilla(p.id_persona) cuenta,
        fun_getTipoCuentas_planilla(p.id_persona) tpCuenta,
        fun_getCci_planilla(p.id_persona) cci,
        fun_getDatosSuplente_planilla(p.id_persona) suplente,
        p.per_documento, 
        p.id_persona,
        p.pe_estado,
        date(p.pe_fecha_cese)
        from tareo t 
        inner join persona p
        on p.id_persona  = t.id_persona
        and t.id_sede  = IN_SEDE
        and date(t.ta_fecha_r) between  date(inicio_dia) and date(final_quincena)
        and t.ta_estado = 1
        and  
        CASE WHEN IN_REPROCESO = 1 THEN 
            NOT EXISTS
            (
            SELECT  null 
            FROM    de_planilla d 
                INNER JOIN ca_planilla ca 
                on d.id_planilla = ca.id_planilla
            WHERE   d.id_persona = t.id_persona
                and date(inicio_sem) between date(inicio_dia) and date(final_quincena)
                and ca.cap_anio = IN_ANIO and ca.cap_mes = IN_MES and ca.cap_periodo = 1
            )
         WHEN IN_REPROCESO = 2 THEN 
            NOT EXISTS
            (
            SELECT  null 
            FROM    de_planilla d 
                INNER JOIN ca_planilla ca 
                on d.id_planilla = ca.id_planilla
            WHERE   d.id_persona = t.id_persona

                and date(inicio_sem) between date(inicio_dia) and date(final_quincena)
                and ca.cap_anio = IN_ANIO and ca.cap_mes = IN_MES and ca.cap_periodo = 1 and ca.cap_sede <> IN_SEDE
            )
        ELSE 
            TRUE 
        END; 

        DECLARE CONTINUE HANDLER FOR NOT FOUND SET findelbucle=1;
   
        DROP TABLE IF EXISTS persona_tareo;
        CREATE TEMPORARY TABLE persona_tareo(
            id_tareo int,
            id_marcador int,
            remunerado int,
            ta_estado int,
            documento varchar(50),
            id_persona int,
            fecha date,
            id_sueldo int,
            cst_dia decimal(9,2),
            ta_remunerado int,
            nombres varchar(50),
            tPdocumento varchar(50),
            nacionalidad varchar(50),
            cargo varchar(50),
            ingreso varchar(50),
            remuneracion_Total decimal(9,2),
            banco varchar(50),
            cuenta varchar(50),
            tpCuenta varchar(50),
            cci varchar(50),
            suplente varchar(50),
            fechaSece varchar(50),
            personaEstado int
        );  
       
        set inicio_dia := concat(IN_ANIO,'-',IN_MES,'-01');
        set final_quincena := concat(IN_ANIO,'-',IN_MES,'-15');
        set mismo_inicio := concat(IN_ANIO,'-',IN_MES,'-01');
        set perido_interno := concat(IN_ANIO,'-',IN_MES,'-15'); 
        select EXTRACT(DAY from LAST_DAY(mismo_inicio)) into dias_x_mes;
        set dec_porcNoche := 1.35;
        # 1 = maestro descanso, 0 = tareo marcador
        #set dec_modoDescanso := 1;
        select pc_modo_descanso into dec_modoDescanso from pla_configuraciones limit 1;
       
       if EXISTS(select * from  ca_planilla where cap_codigo = concat(IN_ANIO,IN_MES,IN_SEDE,1)) and IN_REPROCESO = 1
       then
            signal sqlstate '45000' set message_text = 'Esta sede ya tiene generado una planilla en este periodo';
       elseif EXISTS(select * from  ca_planilla where cap_codigo = concat(IN_ANIO,IN_MES,IN_SEDE,1)) and IN_REPROCESO = 2
       then
            select id_planilla into dec_codPlanillaBorrado from  ca_planilla where cap_codigo = concat(IN_ANIO,IN_MES,IN_SEDE,1); 
            DELETE FROM ca_planilla WHERE cap_codigo = concat(IN_ANIO,IN_MES,IN_SEDE,1);
            DELETE FROM de_planilla WHERE id_planilla = dec_codPlanillaBorrado; 
       end if;
       
       if(
            select count(p.id_persona)  from tareo t 
            inner join persona p
            on p.id_persona  = t.id_persona
            and t.id_sede  = IN_SEDE
            and date(t.ta_fecha_r) between  date(inicio_dia) and date(final_quincena) 
            and t.ta_estado  = 1
            AND
            CASE WHEN IN_REPROCESO = 1 THEN 
                NOT EXISTS
                (
                SELECT  null 
                FROM    de_planilla d 
                    INNER JOIN ca_planilla ca 
                    on d.id_planilla = ca.id_planilla
                WHERE   d.id_persona = t.id_persona
                    and date(inicio_sem) between date(inicio_dia) and date(final_quincena)
                    and ca.cap_anio = IN_ANIO and ca.cap_mes = IN_MES and ca.cap_periodo = 1
                )
             WHEN IN_REPROCESO = 2 THEN 
                NOT EXISTS
                (
                SELECT  null 
                FROM    de_planilla d 
                    INNER JOIN ca_planilla ca 
                    on d.id_planilla = ca.id_planilla
                WHERE   d.id_persona = t.id_persona
                    and date(inicio_sem) between date(inicio_dia) and date(final_quincena)
                    and ca.cap_anio = IN_ANIO and ca.cap_mes = IN_MES and ca.cap_periodo = 1 and ca.cap_sede <> IN_SEDE
                )
            ELSE 
                TRUE 
            END
        ) <= 0
       then
            signal sqlstate '45000' set message_text = 'No hay tareos que procesar en este mes!';
       end if;
      
      
       #star cursor
OPEN personas_tareo;
    loop1: loop
      
    FETCH personas_tareo INTO nombres,tPdocumento,nacionalidad,cargo,ingreso,banco,cuenta,tpCuenta,cci,suplente,documento, id_persona,personaEstado, fechaSece; 
    IF findelbucle = 1 THEN
       LEAVE loop1;
    END IF;
   
    # CREAR UN BUCLE DESDE LA FECHA DE INICIO HASTA LA QUINCENA
    WHILE inicio_dia <= final_quincena DO
    
    # OBTENER EL SUELDO QUE TUVO EN ESE PERIODO
    select 
        ROUND(cast((fun_getRemuneracionBruta_planillav2(s.id_sueldo) / dias_x_mes) as decimal(9,2)), 2),
        id_sueldo,
        s.ta_total
        into 
        dec_SueldoXdiaVigencia,
        dec_SueldoCodigoVigencia,
        dec_RemuneracionTotal
    from sueldo s where
    s.id_persona = id_persona
    and s.ta_vigenciaInicio between  s.ta_vigenciaInicio and inicio_dia
    and s.ta_vigenciaFin  between inicio_dia and s.ta_vigenciaFin;
    #END SUELDO

    # 80 = REGISTRANDO LA RENUNCIA
    if personaEstado = 0
    then
        if date(fechaSece) <= inicio_dia
        then 
            insert into persona_tareo 
            select 
            80, 80, 1, 1, documento, id_persona, inicio_dia, dec_SueldoCodigoVigencia, dec_SueldoXdiaVigencia, 1
            ,nombres,tPdocumento,nacionalidad,cargo,ingreso,dec_RemuneracionTotal,banco,cuenta,tpCuenta,cci,suplente,fechaSece,personaEstado;
        end if;
    end if;
    # END RENUNCIA
   
    # 70 = REGISTRANDO INGRESO NUEVO
    if date(ingreso) > inicio_dia
    then 
        # 70 = ingreso nuevo xd
        insert into persona_tareo 
        select 
        70, 70, 1, 1, documento, id_persona, inicio_dia, dec_SueldoCodigoVigencia, dec_SueldoXdiaVigencia, 1
        ,nombres,tPdocumento,nacionalidad,cargo,ingreso,dec_RemuneracionTotal,banco,cuenta,tpCuenta,cci,suplente,fechaSece,personaEstado;
    end if;
    #END INGRESO NUEVO

    #MODO 1
    if dec_modoDescanso = 1 
    then
        # 50 = GENERAR LOS DESCANSOS MODO 1
            if exists(select * from descanso d where d.id_persona = id_persona and date(d.de_fecha) = date(inicio_dia) and d.de_estado = 1)
            then
                if personaEstado = 0 
                then
                    if date(fechaSece) >= inicio_dia
                    then
                        insert into persona_tareo 
                        select 
                        50, 4, 1, 1, documento, id_persona, inicio_dia, dec_SueldoCodigoVigencia, dec_SueldoXdiaVigencia, 1
                        ,nombres,tPdocumento,nacionalidad,cargo,ingreso,dec_RemuneracionTotal,banco,cuenta,tpCuenta,cci,suplente,fechaSece,personaEstado;
                    end if;
               else
                    insert into persona_tareo 
                    select 
                        50, 4, 1, 1, documento, id_persona, inicio_dia, dec_SueldoCodigoVigencia, dec_SueldoXdiaVigencia, 1
                        ,nombres,tPdocumento,nacionalidad,cargo,ingreso,dec_RemuneracionTotal,banco,cuenta,tpCuenta,cci,suplente,fechaSece,personaEstado;
               end if;
            end if;
       #END GENERAR LOS DESCANSOS MODO 1
    else
        #GENERAR LOS DESCANSOS MODO 2
        if exists(select * from tareo t inner join sueldo s 
                on t.id_sueldo  = s.id_sueldo 
                inner join  persona p on s.id_persona  = p.id_persona 
                where date(t.ta_fecha_r) = date(inicio_dia) and p.per_documento = documento
                and t.ta_estado = 1
                and t.id_marcador  = 4
            )
            then
                insert into persona_tareo
                select 
                    t.id_tareo,
                    t.id_marcador,
                    t.ta_remunerado,
                    t.ta_estado,
                    p.per_documento,
                    id_persona,
                    t.ta_fecha_r,
                    dec_SueldoCodigoVigencia,
                    #s.ta_csdia
                    dec_SueldoXdiaVigencia,
                    t.ta_remunerado
                    ,nombres,tPdocumento,nacionalidad,cargo,ingreso,dec_RemuneracionTotal,banco,cuenta,tpCuenta,cci,suplente,fechaSece,personaEstado
                from tareo t  
                inner join  persona p 
                on t.id_persona  = p.id_persona 
                where date(t.ta_fecha_r) = date(inicio_dia) and p.per_documento = documento and t.ta_estado = 1 and t.id_marcador  = 4;
           end if;
         #GENERAR LOS DESCANSOS MODO 2
    end if; 
    #END MODO 1
   
    # FERIADO 60
    if exists(select * from feriado f where date(f.fe_dia) = date(inicio_dia) and f.fe_estado = 1)
    then 
            if personaEstado = 0 
                then
                    if date(fechaSece) >= inicio_dia
                    then
                        insert into persona_tareo 
                        select 
                        60, 60, 1, 1, documento, id_persona, inicio_dia, dec_SueldoCodigoVigencia, dec_SueldoXdiaVigencia, 1 
                        ,nombres,tPdocumento,nacionalidad,cargo,ingreso,dec_RemuneracionTotal,banco,cuenta,tpCuenta,cci,suplente,fechaSece,personaEstado;
                    end if;
               else
                    insert into persona_tareo 
                    select 
                    60, 60, 1, 1, documento, id_persona, inicio_dia, dec_SueldoCodigoVigencia, dec_SueldoXdiaVigencia, 1 
                    ,nombres,tPdocumento,nacionalidad,cargo,ingreso,dec_RemuneracionTotal,banco,cuenta,tpCuenta,cci,suplente,fechaSece,personaEstado;
             end if;
    end if;
    # END FERIADO
   
    #MODO 2 - INFO DEL TAREO != DESCANSO
    if exists(select * from tareo t  
            inner join  persona p on t.id_persona  = p.id_persona 
            where date(t.ta_fecha_r) = date(inicio_dia) and p.per_documento = documento
            and t.ta_estado = 1
            and t.ta_etapa  = 1
            and t.id_marcador  <> 4 and t.id_marcador  <> 6
    )
    then
    insert into persona_tareo
    select 
        t.id_tareo,
        t.id_marcador,
        t.ta_remunerado,
        t.ta_estado,
        p.per_documento,
        id_persona,
        t.ta_fecha_r,
        dec_SueldoCodigoVigencia, 
        dec_SueldoXdiaVigencia,
        t.ta_remunerado
        ,nombres,tPdocumento,nacionalidad,cargo,ingreso,dec_RemuneracionTotal,banco,cuenta,tpCuenta,cci,suplente,fechaSece,personaEstado
        from tareo t  
        inner join  persona p 
                on t.id_persona  = p.id_persona 
        where date(t.ta_fecha_r) = date(inicio_dia) 
        and p.per_documento = documento 
        and t.ta_estado = 1 
        and t.ta_etapa  = 1
        and t.id_marcador  <> 4 
        and t.id_marcador  <> 6;
    else  
        # COMPOBAR SI ESA PERSONA TIENE UN PERMISO
    if exists(select * from tareo t  
        inner join  persona p on t.id_persona  = p.id_persona 
        where date(t.ta_fecha_r) = date(inicio_dia) and p.per_documento = documento
        and t.ta_estado = 1
        and t.id_marcador = 6 and t.ta_remunerado = 1
        )
    then
         insert into persona_tareo 
            select 
            90, 6, 1, 1, documento, id_persona, inicio_dia, dec_SueldoCodigoVigencia, dec_SueldoXdiaVigencia, 1 
            ,nombres,tPdocumento,nacionalidad,cargo,ingreso,dec_RemuneracionTotal,banco,cuenta,tpCuenta,cci,suplente,fechaSece,personaEstado;
    else
        if exists(select * from tareo t
            inner join  persona p on t.id_persona  = p.id_persona 
            where date(t.ta_fecha_r) = date(inicio_dia) and p.per_documento = documento
            and t.ta_estado = 1
            and t.id_marcador = 6 and t.ta_remunerado = 0
            )
        then
            insert into persona_tareo 
            select 
            0, 5, 1, 1, documento, id_persona, inicio_dia, dec_SueldoCodigoVigencia, dec_SueldoXdiaVigencia, 1 
            ,nombres,tPdocumento,nacionalidad,cargo,ingreso,dec_RemuneracionTotal,banco,cuenta,tpCuenta,cci,suplente,fechaSece,personaEstado; 
        end if;
    end if;
    # END COMPOBAR SI ESA PERSONA TIENE UN DESCANSO
    end if;
    #END MODO 2

    #INCREMENTAR +1
    SET inicio_dia = ADDDATE(inicio_dia, INTERVAL 1 DAY);
    #END INCREMENTAR +1
   
    set dec_SueldoCodigoVigencia = 0;
    set dec_SueldoXdiaVigencia = 0;
    set dec_RemuneracionTotal = 0;
   
    END WHILE;
    # FIN DE BUCLE
   
    #RESTABLESCO EL DIA AL 01
    SET inicio_dia = mismo_inicio;
   
    END LOOP loop1;
CLOSE personas_tareo; 

#select  * from persona_tareo;

DROP TABLE IF EXISTS pre_planilla_;
create temporary table pre_planilla_(
    select 
    v.id_persona,
    v.fecha, 
    v.id_marcador,
    v.cst_dia,
    v.id_sueldo,
    concat(year(v.fecha),'-', 
        (
             SELECT WEEK(v.fecha, 5) - WEEK(DATE_SUB(v.fecha, INTERVAL DAYOFMONTH(v.fecha) - 1 DAY), 5) + 1
        )
    ) periodo
    ,dayofweek(v.fecha)-1 num_dia_sem
    ,(case when v.id_tareo <> 0 and v.ta_estado=1 and v.id_marcador=1   then 1 else 0 end) manana_cumple
    ,(case when v.id_tareo <> 0 and v.ta_estado<>1 and v.id_marcador=1   then 1 else 0 end) manana_no_cumple
    ,(case when v.id_tareo <> 0 and v.ta_estado=1 and v.id_marcador=2   then 1 else 0 end) tarde_cumple
    ,(case when v.id_tareo <> 0 and v.ta_estado<>1 and v.id_marcador=2   then 1 else 0 end) tarde_no_cumple
    ,(case when v.id_tareo <> 0 and v.ta_estado=1 and v.id_marcador=3   then 1 else 0 end) noche_cumple
    ,(case when v.id_tareo <> 0 and v.ta_estado<>1 and v.id_marcador=3   then 1 else 0 end) noche_no_cumple
    ,(case when v.id_marcador = 4  and v.ta_estado = 1  then 1 else 0 end) descanso
    ,(case when v.id_marcador = 5 then 1 else 0 end) faltas
    ,(case when v.id_marcador = 60 then 1 else 0 end) feriado 
    ,(case when v.ta_estado = 1  and v.id_marcador = 6 and v.ta_remunerado = 1 then 1 else 0 end) permiso_pago
    ,(case when v.ta_estado = 1  and v.id_marcador = 6 and v.ta_remunerado = 0 then 1 else 0 end) permiso_no_pago
    ,v.nombres,v.tPdocumento,v.nacionalidad,v.cargo,v.ingreso,v.remuneracion_Total,v.banco,v.cuenta,v.tpCuenta,v.cci,v.suplente,v.documento,v.fechaSece,v.personaEstado
    from persona_tareo v 
    group by v.id_persona,v.fecha,v.id_marcador, v.id_sueldo
);

#select  * from pre_planilla_;

DROP TABLE IF EXISTS pre_planilla_2;
create temporary table pre_planilla_2(
    select 
        p.id_persona,
        p.periodo,
        p.fecha,
        max(p.id_sueldo) id_sueldo,
        max(p.cst_dia) as cst_dia,
        min(p.fecha) inicio_sem,
        max(p.fecha) fin_sem,
        sum(p.manana_cumple) t_manana_v,
        sum(p.manana_no_cumple) t_manana_no,
        sum(p.tarde_cumple) t_tarde_v,
        sum(p.tarde_no_cumple) t_tarde_no,
        sum(p.noche_cumple) t_noche_v,
        sum(p.noche_no_cumple) t_noche_no,
        sum(p.descanso) descanso_calculo,
        if(((sum(p.manana_cumple) + sum(p.tarde_cumple) + sum(p.noche_cumple))) < 1 and sum(p.descanso) = 1 ,1,0) as descanso,
        if(((sum(p.manana_cumple) + sum(p.tarde_cumple) + sum(p.noche_cumple))) >= 1 and sum(p.descanso) = 1 ,1,0) as descanso_pago,
        sum(p.faltas) faltas,
        sum(p.permiso_pago) permiso_pago,
        sum(p.permiso_no_pago) permiso_no_pago,
        if(((sum(p.manana_cumple) + sum(p.tarde_cumple) + sum(p.noche_cumple))) >= 1 and sum(p.feriado) = 1 , 1, 0) as feriado_con_turnos, 
    case when (sum(faltas)) >= 1 and sum(p.feriado) = 1 
    then
        0
    when (sum(p.manana_cumple) + sum(p.tarde_cumple) + sum(p.noche_cumple)) >= 1 and sum(p.feriado) = 1 
    then
        sum(p.feriado)
    when (sum(p.manana_cumple) + sum(p.tarde_cumple) + sum(p.noche_cumple)) <= 0 and sum(p.feriado) = 1 and  sum(p.descanso) = 0
    then
         sum(p.feriado)
    when (sum(p.manana_cumple) + sum(p.tarde_cumple) + sum(p.noche_cumple)) <= 0 and sum(p.feriado) = 1 and  sum(p.descanso) >= 1
    then
        0
    else 
        0
    end as feriado 
    ,p.nombres,p.tPdocumento,p.nacionalidad,p.cargo,p.ingreso,p.remuneracion_Total,p.banco,p.cuenta,p.tpCuenta,p.cci,p.suplente,p.documento,p.fechaSece,p.personaEstado
    from pre_planilla_ p 
    group by 
    p.id_persona,
    p.fecha,
    p.id_sueldo
);

#select * from pre_planilla_2;

DROP TABLE IF EXISTS pre_planilla_3;
create temporary table pre_planilla_3(
    select
    a.id_persona,
    a.periodo,
    a.fecha,
    max(id_sueldo) id_sueldo,
    max(cst_dia) cst_dia,
    min(fecha) inicio_sem,
    max(fecha) fin_sem,
    sum(t_manana_v) t_manana_v,
    sum(t_manana_v * cst_dia) total_pago_maniana,
    sum(t_tarde_v) t_tarde_v, 
    sum(t_tarde_v * cst_dia) total_pago_tarde,
    sum(t_noche_v) t_noche_v,
    sum(t_noche_v * ROUND(CAST(cst_dia*dec_porcNoche AS DECIMAL(9,2)), 2)) total_pago_noche,
    sum(feriado) feriado,
    sum(faltas) faltas,
    sum(descanso) descanso,
    sum(descanso_pago) descanso_pago,
    sum(descanso_calculo) descanso_calculo,
    #permiso pago
    sum(permiso_pago) permiso_pago,
    sum(permiso_pago * cst_dia) total_permiso_pago,
    #end permiso pago
    case when sum(feriado_con_turnos) = 1 and sum(feriado) = 1 
    then
        ((((sum(t_manana_v)+sum(t_tarde_v))*max(cst_dia))+sum(t_noche_v)* ROUND(CAST(max(cst_dia)*dec_porcNoche AS DECIMAL(9,2)), 2))*2)
    when sum(feriado_con_turnos) = 0 and sum(feriado) = 1 
    then
            cst_dia
    when sum(feriado) = 0 
    then
        ((((sum(t_manana_v)+sum(t_tarde_v))*max(cst_dia))+sum(t_noche_v)* ROUND(CAST(max(cst_dia)*dec_porcNoche AS DECIMAL(9,2)), 2)))
    end as pago_feriado, 
    case when sum(feriado_con_turnos) = 1 and sum(feriado) = 1 then
        ((((sum(t_manana_v)+sum(t_tarde_v))*max(cst_dia))+sum(t_noche_v)* ROUND(CAST(max(cst_dia)*dec_porcNoche AS DECIMAL(9,2)), 2))*2)
    when sum(feriado_con_turnos) = 0 and sum(feriado) = 1 then
            cst_dia
    end as solo_pago_feriado, 
    sum(feriado_con_turnos) feriado_con_turnos
    ,a.nombres,a.tPdocumento,a.nacionalidad,a.cargo,a.ingreso,a.remuneracion_Total,a.banco,a.cuenta,a.tpCuenta,a.cci,a.suplente,a.documento,a.fechaSece,a.personaEstado
    from pre_planilla_2 a group by a.id_persona, a.id_sueldo, a.periodo, a.fecha
);

#select * from pre_planilla_3;

INSERT INTO ca_planilla
(
    cap_anio, 
    cap_mes, 
    cap_periodo, 
    cap_sede, 
    cap_estado, 
    cap_codigo
)VALUES(
    IN_ANIO,
    IN_MES,
    1,
    IN_SEDE,
    1,
    concat(IN_ANIO,IN_MES,IN_SEDE,1)
);

select id_planilla into dec_codPlanilla from  ca_planilla where cap_codigo = concat(IN_ANIO,IN_MES,IN_SEDE,1);

insert into de_planilla
select
    null,
    dec_codPlanilla,
    a.id_persona,
    a.periodo,
    max(a.id_sueldo) id_sueldo,
    max(a.cst_dia) cst_dia,
    min(a.fecha) inicio_sem,
    max(a.fecha) fin_sem,
    sum(a.t_manana_v) t_manana_v,
    sum(a.t_manana_v * cst_dia) total_pago_maniana,
    sum(a.t_tarde_v) t_tarde_v, 
    sum(a.t_tarde_v * cst_dia) total_pago_tarde,
    sum(a.t_noche_v) t_noche_v,
    sum(a.t_noche_v * ROUND(CAST(a.cst_dia*dec_porcNoche AS DECIMAL(9,2)), 2)) total_pago_noche,
    sum(a.feriado) feriado,
    sum(a.faltas) faltas,
    sum(a.descanso) descanso,
    sum(a.descanso_pago) descanso_pago,
    sum(a.descanso_calculo) descanso_calculo,
    if(sum(descanso_calculo)=1 and sum(a.descanso_pago) = 1,
            (case 
                when sum(faltas)=0 then max(cst_dia)
                when sum(faltas)=1 then ROUND(CAST(((max(cst_dia) /6)*5) AS DECIMAL(9,2)), 2)
                when sum(faltas)=2 then ROUND(CAST(((max(cst_dia)/6)*4) AS DECIMAL(9,2)), 2)
                when sum(faltas)=3 then ROUND(CAST(((max(cst_dia)/6)*3) AS DECIMAL(9,2)), 2)
                when sum(faltas)=4 then ROUND(CAST(((max(cst_dia)/6)*2) AS DECIMAL(9,2)), 2)
                when sum(faltas)=5 then ROUND(CAST(((max(cst_dia)/6)*1) AS DECIMAL(9,2)), 2)
                else 0 end),0
    ) as total_pago_descanso,
    (sum(pago_feriado))+
     sum(total_permiso_pago)+
                if(sum(descanso_calculo)=0,0,
                    (case 
                        when sum(faltas)=0 then max(cst_dia)
                        when sum(faltas)=1 then ROUND(CAST(((max(cst_dia)/6)*5) AS DECIMAL(9,2)), 2)
                        when sum(faltas)=2 then ROUND(CAST(((max(cst_dia)/6)*4) AS DECIMAL(9,2)), 2)
                        when sum(faltas)=3 then ROUND(CAST(((max(cst_dia)/6)*3) AS DECIMAL(9,2)), 2)
                        when sum(faltas)=4 then ROUND(CAST(((max(cst_dia)/6)*2) AS DECIMAL(9,2)), 2)
                        when sum(faltas)=5 then ROUND(CAST(((max(cst_dia)/6)*1) AS DECIMAL(9,2)), 2)
                        else 0 end)
   ) as TOTAL_CF,
    if(sum(a.solo_pago_feriado) = 0 or sum(a.solo_pago_feriado) IS NULL , 0, sum(a.solo_pago_feriado)) pago_feriado
    ,a.nombres,a.tPdocumento,a.nacionalidad,a.cargo,a.ingreso,a.remuneracion_Total,a.banco,a.cuenta,a.tpCuenta,a.cci,a.suplente,a.documento
    ,if(sum(descanso_calculo)=1 and sum(a.descanso) = 1,
            (case 
                when sum(faltas)=0 then max(cst_dia)
                when sum(faltas)=1 then ROUND(CAST(((max(cst_dia) /6)*5) AS DECIMAL(9,2)), 2)
                when sum(faltas)=2 then ROUND(CAST(((max(cst_dia)/6)*4) AS DECIMAL(9,2)), 2)
                when sum(faltas)=3 then ROUND(CAST(((max(cst_dia)/6)*3) AS DECIMAL(9,2)), 2)
                when sum(faltas)=4 then ROUND(CAST(((max(cst_dia)/6)*2) AS DECIMAL(9,2)), 2)
                when sum(faltas)=5 then ROUND(CAST(((max(cst_dia)/6)*1) AS DECIMAL(9,2)), 2)
                else 0 end),0
    ) as total_pago_descanso_sin_turno
    ,a.fechaSece,a.personaEstado,sum(a.permiso_pago),sum(total_permiso_pago)
from pre_planilla_3 a
group by a.id_persona,a.id_sueldo,a.periodo;
 

END$$

CREATE  PROCEDURE up_procesar_planilla_15CNA_2 (IN IN_MES VARCHAR(8), IN IN_ANIO VARCHAR(8), IN IN_SEDE INT, IN IN_REPROCESO INT)  begin 
    
    declare mismo_inicio date;
    declare inicio_dia date;
    declare final_quincena date; 
    declare perido_interno varchar(80);
    declare dias_x_mes int;
    declare dec_porcNoche decimal(9,2);
    declare dec_modoDescanso int;
    declare dec_codPlanilla int;
    declare dec_codPlanillaBorrado int;
   
   
    # CURSOR LOOP
    declare nombres varchar(50);
    declare tPdocumento varchar(50);
    declare nacionalidad varchar(50);
    declare cargo varchar(50);
    declare ingreso varchar(50); 
    declare banco varchar(50);
    declare cuenta varchar(50);
    declare tpCuenta varchar(50);
    declare cci varchar(50); 
    declare suplente varchar(50); 
    declare id_persona int;
    declare documento varchar(50);
    declare fechaSece varchar(50);
    declare personaEstado int;
   
    # SUELDO
    declare dec_SueldoXdiaVigencia decimal(9,2) default 0;
    declare dec_SueldoCodigoVigencia  int default 0;
    declare dec_RemuneracionTotal decimal(9,2) default 0;

    DECLARE findelbucle INTEGER DEFAULT 0; 
   
    #cursor para las personas
    DECLARE personas_tareo CURSOR for
    select distinct 
        fun_getNamePersona_planilla(p.id_persona) as nombres,
        fun_getTpDocumento_planilla(p.id_persona) as tPdocumento,
        fun_getNacionalidad_planilla(p.id_persona) as nacionalidad,
        fun_getCargo_planilla(p.id_persona) cargo,
        fun_getFechaIngreso_planilla(p.id_persona) ingreso, 
        fun_getBanco_planilla(p.id_persona) banco,
        fun_getCuentas_planilla(p.id_persona) cuenta,
        fun_getTipoCuentas_planilla(p.id_persona) tpCuenta,
        fun_getCci_planilla(p.id_persona) cci,
        fun_getDatosSuplente_planilla(p.id_persona) suplente,
        p.per_documento, 
        p.id_persona,
        p.pe_estado,
        date(p.pe_fecha_cese)
        from tareo t 
        inner join persona p
        on p.id_persona  = t.id_persona
        and t.id_sede  = IN_SEDE
        and date(t.ta_fecha_r) between  date(inicio_dia) and date(final_quincena)
        and t.ta_estado = 1
        and  
        CASE WHEN IN_REPROCESO = 1 THEN 
            NOT EXISTS
            (
            SELECT  null 
            FROM    de_planilla d 
                INNER JOIN ca_planilla ca 
                on d.id_planilla = ca.id_planilla
            WHERE   d.id_persona = t.id_persona
                and date(inicio_sem) between date(inicio_dia) and date(final_quincena)
                and ca.cap_anio = IN_ANIO and ca.cap_mes = IN_MES and ca.cap_periodo = 1
            )
         WHEN IN_REPROCESO = 2 THEN 
            NOT EXISTS
            (
            SELECT  null 
            FROM    de_planilla d 
                INNER JOIN ca_planilla ca 
                on d.id_planilla = ca.id_planilla
            WHERE   d.id_persona = t.id_persona
                and date(inicio_sem) between date(inicio_dia) and date(final_quincena)
                and ca.cap_anio = IN_ANIO and ca.cap_mes = IN_MES and ca.cap_periodo = 1 and ca.cap_sede <> IN_SEDE
            )
        ELSE 
            TRUE 
        END; 

        DECLARE CONTINUE HANDLER FOR NOT FOUND SET findelbucle=1;
   
        DROP TABLE IF EXISTS persona_tareo;
        CREATE TEMPORARY TABLE persona_tareo(
            id_tareo int,
            id_marcador int,
            remunerado int,
            ta_estado int,
            documento varchar(50),
            id_persona int,
            fecha date,
            id_sueldo int,
            cst_dia decimal(9,2),
            ta_remunerado int,
            nombres varchar(50),
            tPdocumento varchar(50),
            nacionalidad varchar(50),
            cargo varchar(50),
            ingreso varchar(50),
            remuneracion_Total decimal(9,2),
            banco varchar(50),
            cuenta varchar(50),
            tpCuenta varchar(50),
            cci varchar(50),
            suplente varchar(50),
            fechaSece varchar(50),
            personaEstado int
        );  
       
        set inicio_dia := concat(IN_ANIO,'-',IN_MES,'-16');
        set final_quincena := last_day(inicio_dia); 
        set mismo_inicio := concat(IN_ANIO,'-',IN_MES,'-16');
        set perido_interno := last_day(inicio_dia); 
        select EXTRACT(DAY from LAST_DAY(mismo_inicio)) into dias_x_mes;
        set dec_porcNoche := 1.35;
        # 1 = maestro descanso, 0 = tareo marcador
        select pc_modo_descanso into dec_modoDescanso from pla_configuraciones limit 1;
       
       if EXISTS(select * from  ca_planilla where cap_codigo = concat(IN_ANIO,IN_MES,IN_SEDE,2)) and IN_REPROCESO = 1
       then
            signal sqlstate '45000' set message_text = 'Esta sede ya tiene generado una planilla en este periodo';
       elseif EXISTS(select * from  ca_planilla where cap_codigo = concat(IN_ANIO,IN_MES,IN_SEDE,2)) and IN_REPROCESO = 2
       then
            select id_planilla into dec_codPlanillaBorrado from  ca_planilla where cap_codigo = concat(IN_ANIO,IN_MES,IN_SEDE,2); 
            DELETE FROM ca_planilla WHERE cap_codigo = concat(IN_ANIO,IN_MES,IN_SEDE,2);
            DELETE FROM de_planilla WHERE id_planilla = dec_codPlanillaBorrado; 
       end if;
       
       if(
            select count(p.id_persona)  from tareo t 
            inner join persona p
            on p.id_persona  = t.id_persona
            and t.id_sede  = IN_SEDE
            and date(t.ta_fecha_r) between  date(inicio_dia) and date(final_quincena) 
            and t.ta_estado  = 1
            AND
            CASE WHEN IN_REPROCESO = 1 THEN 
                NOT EXISTS
                (
                SELECT  null 
                FROM    de_planilla d 
                    INNER JOIN ca_planilla ca 
                    on d.id_planilla = ca.id_planilla
                WHERE   d.id_persona = t.id_persona
                    and date(inicio_sem) between date(inicio_dia) and date(final_quincena)
                    and ca.cap_anio = IN_ANIO and ca.cap_mes = IN_MES and ca.cap_periodo = 2
                )
             WHEN IN_REPROCESO = 2 THEN 
                NOT EXISTS
                (
                SELECT  null 
                FROM    de_planilla d 
                    INNER JOIN ca_planilla ca 
                    on d.id_planilla = ca.id_planilla
                WHERE   d.id_persona = t.id_persona
                    and date(inicio_sem) between date(inicio_dia) and date(final_quincena)
                    and ca.cap_anio = IN_ANIO and ca.cap_mes = IN_MES and ca.cap_periodo = 2 and ca.cap_sede <> IN_SEDE
                )
            ELSE 
                TRUE 
            END
        ) <= 0
       then
            signal sqlstate '45000' set message_text = 'No hay tareos que procesar en este mes!';
       end if;
      
      
#star cursor
OPEN personas_tareo;
    loop1: loop
      
    FETCH personas_tareo INTO nombres,tPdocumento,nacionalidad,cargo,ingreso,banco,cuenta,tpCuenta,cci,suplente,documento, id_persona,personaEstado, fechaSece; 
    IF findelbucle = 1 THEN
       LEAVE loop1;
    END IF;
   
    # CREAR UN BUCLE DESDE LA FECHA DE INICIO HASTA LA QUINCENA
    WHILE inicio_dia <= final_quincena DO
    
    # OBTENER EL SUELDO QUE TUVO EN ESE PERIODO
    select 
        ROUND(cast((fun_getRemuneracionBruta_planillav2(s.id_sueldo) / dias_x_mes) as decimal(9,2)), 2),
        id_sueldo,
        s.ta_total
        into 
        dec_SueldoXdiaVigencia,
        dec_SueldoCodigoVigencia,
        dec_RemuneracionTotal
    from sueldo s where
    s.id_persona = id_persona
    and s.ta_vigenciaInicio between  s.ta_vigenciaInicio and inicio_dia
    and s.ta_vigenciaFin  between inicio_dia and s.ta_vigenciaFin;
    #END SUELDO

    # 80 = REGISTRANDO LA RENUNCIA
    if personaEstado = 0
    then
        if date(fechaSece) <= inicio_dia
        then 
            insert into persona_tareo 
            select 
            80, 80, 1, 1, documento, id_persona, inicio_dia, dec_SueldoCodigoVigencia, dec_SueldoXdiaVigencia, 1
            ,nombres,tPdocumento,nacionalidad,cargo,ingreso,dec_RemuneracionTotal,banco,cuenta,tpCuenta,cci,suplente,fechaSece,personaEstado;
        end if;
    end if;
    # END RENUNCIA
   
    # 70 = REGISTRANDO INGRESO NUEVO
    if date(ingreso) > inicio_dia
    then 
        # 70 = ingreso nuevo xd
        insert into persona_tareo 
        select 
        70, 70, 1, 1, documento, id_persona, inicio_dia, dec_SueldoCodigoVigencia, dec_SueldoXdiaVigencia, 1
        ,nombres,tPdocumento,nacionalidad,cargo,ingreso,dec_RemuneracionTotal,banco,cuenta,tpCuenta,cci,suplente,fechaSece,personaEstado;
    end if;
    #END INGRESO NUEVO

    #MODO 1
    if dec_modoDescanso = 1 
    then
        # 50 = GENERAR LOS DESCANSOS MODO 1
            if exists(select * from descanso d where d.id_persona = id_persona and date(d.de_fecha) = date(inicio_dia) and d.de_estado = 1)
            then
                if personaEstado = 0 
                then
                    if date(fechaSece) >= inicio_dia
                    then
                        insert into persona_tareo 
                        select 
                        50, 4, 1, 1, documento, id_persona, inicio_dia, dec_SueldoCodigoVigencia, dec_SueldoXdiaVigencia, 1
                        ,nombres,tPdocumento,nacionalidad,cargo,ingreso,dec_RemuneracionTotal,banco,cuenta,tpCuenta,cci,suplente,fechaSece,personaEstado;
                    end if;
               else
                    insert into persona_tareo 
                    select 
                        50, 4, 1, 1, documento, id_persona, inicio_dia, dec_SueldoCodigoVigencia, dec_SueldoXdiaVigencia, 1
                        ,nombres,tPdocumento,nacionalidad,cargo,ingreso,dec_RemuneracionTotal,banco,cuenta,tpCuenta,cci,suplente,fechaSece,personaEstado;
               end if;
            end if;
       #END GENERAR LOS DESCANSOS MODO 1
    else
        #GENERAR LOS DESCANSOS MODO 2
        if exists(select * from tareo t inner join sueldo s 
                on t.id_sueldo  = s.id_sueldo 
                inner join  persona p on s.id_persona  = p.id_persona 
                where date(t.ta_fecha_r) = date(inicio_dia) and p.per_documento = documento
                and t.ta_estado = 1
                and t.id_marcador  = 4
            )
            then
                insert into persona_tareo
                select 
                    t.id_tareo,
                    t.id_marcador,
                    t.ta_remunerado,
                    t.ta_estado,
                    p.per_documento,
                    id_persona,
                    t.ta_fecha_r,
                    dec_SueldoCodigoVigencia,
                    #s.ta_csdia
                    dec_SueldoXdiaVigencia,
                    t.ta_remunerado
                    ,nombres,tPdocumento,nacionalidad,cargo,ingreso,dec_RemuneracionTotal,banco,cuenta,tpCuenta,cci,suplente,fechaSece,personaEstado
                from tareo t  
                inner join  persona p 
                on t.id_persona  = p.id_persona 
                where date(t.ta_fecha_r) = date(inicio_dia) and p.per_documento = documento and t.ta_estado = 1 and t.id_marcador  = 4;
           end if;
         #GENERAR LOS DESCANSOS MODO 2
    end if; 
    #END MODO 1
   
    # FERIADO 60
    if exists(select * from feriado f where date(f.fe_dia) = date(inicio_dia) and f.fe_estado = 1)
    then 
            if personaEstado = 0 
                then
                    if date(fechaSece) >= inicio_dia
                    then
                        insert into persona_tareo 
                        select 
                        60, 60, 1, 1, documento, id_persona, inicio_dia, dec_SueldoCodigoVigencia, dec_SueldoXdiaVigencia, 1 
                        ,nombres,tPdocumento,nacionalidad,cargo,ingreso,dec_RemuneracionTotal,banco,cuenta,tpCuenta,cci,suplente,fechaSece,personaEstado;
                    end if;
               else
                    insert into persona_tareo 
                    select 
                    60, 60, 1, 1, documento, id_persona, inicio_dia, dec_SueldoCodigoVigencia, dec_SueldoXdiaVigencia, 1 
                    ,nombres,tPdocumento,nacionalidad,cargo,ingreso,dec_RemuneracionTotal,banco,cuenta,tpCuenta,cci,suplente,fechaSece,personaEstado;
             end if;
    end if;
    # END FERIADO
   
    #MODO 2 - INFO DEL TAREO != DESCANSO
    if exists(select * from tareo t  
            inner join  persona p on t.id_persona  = p.id_persona 
            where date(t.ta_fecha_r) = date(inicio_dia) and p.per_documento = documento
            and t.ta_estado = 1
            and t.ta_etapa  = 1
            and t.id_marcador  <> 4 and t.id_marcador  <> 6
    )
    then
    insert into persona_tareo
    select 
        t.id_tareo,
        t.id_marcador,
        t.ta_remunerado,
        t.ta_estado,
        p.per_documento,
        id_persona,
        t.ta_fecha_r,
        dec_SueldoCodigoVigencia, 
        dec_SueldoXdiaVigencia,
        t.ta_remunerado
        ,nombres,tPdocumento,nacionalidad,cargo,ingreso,dec_RemuneracionTotal,banco,cuenta,tpCuenta,cci,suplente,fechaSece,personaEstado
        from tareo t  
        inner join  persona p 
                on t.id_persona  = p.id_persona 
        where date(t.ta_fecha_r) = date(inicio_dia) 
        and p.per_documento = documento 
        and t.ta_estado = 1 
        and t.ta_etapa  = 1
        and t.id_marcador  <> 4 
        and t.id_marcador  <> 6;
    else  
        # COMPOBAR SI ESA PERSONA TIENE UN PERMISO
    if exists(select * from tareo t  
        inner join  persona p on t.id_persona  = p.id_persona 
        where date(t.ta_fecha_r) = date(inicio_dia) and p.per_documento = documento
        and t.ta_estado = 1
        and t.id_marcador = 6 and t.ta_remunerado = 1
        )
    then
         insert into persona_tareo 
            select 
            90, 6, 1, 1, documento, id_persona, inicio_dia, dec_SueldoCodigoVigencia, dec_SueldoXdiaVigencia, 1 
            ,nombres,tPdocumento,nacionalidad,cargo,ingreso,dec_RemuneracionTotal,banco,cuenta,tpCuenta,cci,suplente,fechaSece,personaEstado;
    else
        if exists(select * from tareo t
            inner join  persona p on t.id_persona  = p.id_persona 
            where date(t.ta_fecha_r) = date(inicio_dia) and p.per_documento = documento
            and t.ta_estado = 1
            and t.id_marcador = 6 and t.ta_remunerado = 0
            )
        then
            insert into persona_tareo 
            select 
            0, 5, 1, 1, documento, id_persona, inicio_dia, dec_SueldoCodigoVigencia, dec_SueldoXdiaVigencia, 1 
            ,nombres,tPdocumento,nacionalidad,cargo,ingreso,dec_RemuneracionTotal,banco,cuenta,tpCuenta,cci,suplente,fechaSece,personaEstado; 
        end if;
    end if;
    # END COMPOBAR SI ESA PERSONA TIENE UN DESCANSO
    end if;
    #END MODO 2

    #INCREMENTAR +1
    SET inicio_dia = ADDDATE(inicio_dia, INTERVAL 1 DAY);
    #END INCREMENTAR +1
   
    set dec_SueldoCodigoVigencia = 0;
    set dec_SueldoXdiaVigencia = 0;
    set dec_RemuneracionTotal = 0;
   
    END WHILE;
    # FIN DE BUCLE
   
    #RESTABLESCO EL DIA AL 01
    SET inicio_dia = mismo_inicio;
   
    END LOOP loop1;
CLOSE personas_tareo; 

#select inicio_dia;


#select  * from persona_tareo;

DROP TABLE IF EXISTS pre_planilla_;
create temporary table pre_planilla_(
    select 
    v.id_persona,
    v.fecha, 
    v.id_marcador,
    v.cst_dia,
    v.id_sueldo,
    concat(year(v.fecha),'-', 
        (
             SELECT WEEK(v.fecha, 5) - WEEK(DATE_SUB(v.fecha, INTERVAL DAYOFMONTH(v.fecha) - 1 DAY), 5) + 1
        )
    ) periodo
    ,dayofweek(v.fecha)-1 num_dia_sem
    ,(case when v.id_tareo <> 0 and v.ta_estado=1 and v.id_marcador=1   then 1 else 0 end) manana_cumple
    ,(case when v.id_tareo <> 0 and v.ta_estado<>1 and v.id_marcador=1   then 1 else 0 end) manana_no_cumple
    ,(case when v.id_tareo <> 0 and v.ta_estado=1 and v.id_marcador=2   then 1 else 0 end) tarde_cumple
    ,(case when v.id_tareo <> 0 and v.ta_estado<>1 and v.id_marcador=2   then 1 else 0 end) tarde_no_cumple
    ,(case when v.id_tareo <> 0 and v.ta_estado=1 and v.id_marcador=3   then 1 else 0 end) noche_cumple
    ,(case when v.id_tareo <> 0 and v.ta_estado<>1 and v.id_marcador=3   then 1 else 0 end) noche_no_cumple
    ,(case when v.id_marcador = 4  and v.ta_estado = 1  then 1 else 0 end) descanso
    ,(case when v.id_marcador = 5 then 1 else 0 end) faltas
    ,(case when v.id_marcador = 60 then 1 else 0 end) feriado 
    ,(case when v.ta_estado = 1  and v.id_marcador = 6 and v.ta_remunerado = 1 then 1 else 0 end) permiso_pago
    ,(case when v.ta_estado = 1  and v.id_marcador = 6 and v.ta_remunerado = 0 then 1 else 0 end) permiso_no_pago
    ,v.nombres,v.tPdocumento,v.nacionalidad,v.cargo,v.ingreso,v.remuneracion_Total,v.banco,v.cuenta,v.tpCuenta,v.cci,v.suplente,v.documento,v.fechaSece,v.personaEstado
    from persona_tareo v 
    group by v.id_persona,v.fecha,v.id_marcador, v.id_sueldo
);

#select  * from pre_planilla_;

DROP TABLE IF EXISTS pre_planilla_2;
create temporary table pre_planilla_2(
    select 
        p.id_persona,
        p.periodo,
        p.fecha,
        max(p.id_sueldo) id_sueldo,
        max(p.cst_dia) as cst_dia,
        min(p.fecha) inicio_sem,
        max(p.fecha) fin_sem,
        sum(p.manana_cumple) t_manana_v,
        sum(p.manana_no_cumple) t_manana_no,
        sum(p.tarde_cumple) t_tarde_v,
        sum(p.tarde_no_cumple) t_tarde_no,
        sum(p.noche_cumple) t_noche_v,
        sum(p.noche_no_cumple) t_noche_no,
        sum(p.descanso) descanso_calculo,
        if(((sum(p.manana_cumple) + sum(p.tarde_cumple) + sum(p.noche_cumple))) < 1 and sum(p.descanso) = 1 ,1,0) as descanso,
        if(((sum(p.manana_cumple) + sum(p.tarde_cumple) + sum(p.noche_cumple))) >= 1 and sum(p.descanso) = 1 ,1,0) as descanso_pago,
        sum(p.faltas) faltas,
        sum(p.permiso_pago) permiso_pago,
        sum(p.permiso_no_pago) permiso_no_pago,
        if(((sum(p.manana_cumple) + sum(p.tarde_cumple) + sum(p.noche_cumple))) >= 1 and sum(p.feriado) = 1 , 1, 0) as feriado_con_turnos, 
    case when (sum(faltas)) >= 1 and sum(p.feriado) = 1 
    then
        0
    when (sum(p.manana_cumple) + sum(p.tarde_cumple) + sum(p.noche_cumple)) >= 1 and sum(p.feriado) = 1 
    then
        sum(p.feriado)
    when (sum(p.manana_cumple) + sum(p.tarde_cumple) + sum(p.noche_cumple)) <= 0 and sum(p.feriado) = 1 and  sum(p.descanso) = 0
    then
         sum(p.feriado)
    when (sum(p.manana_cumple) + sum(p.tarde_cumple) + sum(p.noche_cumple)) <= 0 and sum(p.feriado) = 1 and  sum(p.descanso) >= 1
    then
        0
    else 
        0
    end as feriado 
    ,p.nombres,p.tPdocumento,p.nacionalidad,p.cargo,p.ingreso,p.remuneracion_Total,p.banco,p.cuenta,p.tpCuenta,p.cci,p.suplente,p.documento,p.fechaSece,p.personaEstado
    from pre_planilla_ p 
    group by 
    p.id_persona,
    p.fecha,
    p.id_sueldo
);

#select * from pre_planilla_2;

DROP TABLE IF EXISTS pre_planilla_3;
create temporary table pre_planilla_3(
    select
    a.id_persona,
    a.periodo,
    a.fecha,
    max(id_sueldo) id_sueldo,
    max(cst_dia) cst_dia,
    min(fecha) inicio_sem,
    max(fecha) fin_sem,
    sum(t_manana_v) t_manana_v,
    sum(t_manana_v * cst_dia) total_pago_maniana,
    sum(t_tarde_v) t_tarde_v, 
    sum(t_tarde_v * cst_dia) total_pago_tarde,
    sum(t_noche_v) t_noche_v,
    sum(t_noche_v * ROUND(CAST(cst_dia*dec_porcNoche AS DECIMAL(9,2)), 2)) total_pago_noche,
    sum(feriado) feriado,
    sum(faltas) faltas,
    sum(descanso) descanso,
    sum(descanso_pago) descanso_pago,
    sum(descanso_calculo) descanso_calculo,
    #permiso pago
    sum(permiso_pago) permiso_pago,
    sum(permiso_pago * cst_dia) total_permiso_pago,
    #end permiso pago
    case when sum(feriado_con_turnos) = 1 and sum(feriado) = 1 
    then
        ((((sum(t_manana_v)+sum(t_tarde_v))*max(cst_dia))+sum(t_noche_v)* ROUND(CAST(max(cst_dia)*dec_porcNoche AS DECIMAL(9,2)), 2))*2)
    when sum(feriado_con_turnos) = 0 and sum(feriado) = 1 
    then
            cst_dia
    when sum(feriado) = 0 
    then
        ((((sum(t_manana_v)+sum(t_tarde_v))*max(cst_dia))+sum(t_noche_v)* ROUND(CAST(max(cst_dia)*dec_porcNoche AS DECIMAL(9,2)), 2)))
    end as pago_feriado, 
    case when sum(feriado_con_turnos) = 1 and sum(feriado) = 1 then
        ((((sum(t_manana_v)+sum(t_tarde_v))*max(cst_dia))+sum(t_noche_v)* ROUND(CAST(max(cst_dia)*dec_porcNoche AS DECIMAL(9,2)), 2))*2)
    when sum(feriado_con_turnos) = 0 and sum(feriado) = 1 then
            cst_dia
    end as solo_pago_feriado, 
    sum(feriado_con_turnos) feriado_con_turnos
    ,a.nombres,a.tPdocumento,a.nacionalidad,a.cargo,a.ingreso,a.remuneracion_Total,a.banco,a.cuenta,a.tpCuenta,a.cci,a.suplente,a.documento,a.fechaSece,a.personaEstado
    from pre_planilla_2 a group by a.id_persona, a.id_sueldo, a.periodo, a.fecha
);

#select * from pre_planilla_3;

INSERT INTO ca_planilla
(
    cap_anio, 
    cap_mes, 
    cap_periodo, 
    cap_sede, 
    cap_estado, 
    cap_codigo
)VALUES(
    IN_ANIO,
    IN_MES,
    1,
    IN_SEDE,
    1,
    concat(IN_ANIO,IN_MES,IN_SEDE,2)
);

select id_planilla into dec_codPlanilla from  ca_planilla where cap_codigo = concat(IN_ANIO,IN_MES,IN_SEDE,2);

insert into de_planilla
select
    null,
    dec_codPlanilla,
    a.id_persona,
    a.periodo,
    max(a.id_sueldo) id_sueldo,
    max(a.cst_dia) cst_dia,
    min(a.fecha) inicio_sem,
    max(a.fecha) fin_sem,
    sum(a.t_manana_v) t_manana_v,
    sum(a.t_manana_v * cst_dia) total_pago_maniana,
    sum(a.t_tarde_v) t_tarde_v, 
    sum(a.t_tarde_v * cst_dia) total_pago_tarde,
    sum(a.t_noche_v) t_noche_v,
    sum(a.t_noche_v * ROUND(CAST(a.cst_dia*dec_porcNoche AS DECIMAL(9,2)), 2)) total_pago_noche,
    sum(a.feriado) feriado,
    sum(a.faltas) faltas,
    sum(a.descanso) descanso,
    sum(a.descanso_pago) descanso_pago,
    sum(a.descanso_calculo) descanso_calculo,
    if(sum(descanso_calculo)=1 and sum(a.descanso_pago) = 1,
            (case 
                when sum(faltas)=0 then max(cst_dia)
                when sum(faltas)=1 then ROUND(CAST(((max(cst_dia) /6)*5) AS DECIMAL(9,2)), 2)
                when sum(faltas)=2 then ROUND(CAST(((max(cst_dia)/6)*4) AS DECIMAL(9,2)), 2)
                when sum(faltas)=3 then ROUND(CAST(((max(cst_dia)/6)*3) AS DECIMAL(9,2)), 2)
                when sum(faltas)=4 then ROUND(CAST(((max(cst_dia)/6)*2) AS DECIMAL(9,2)), 2)
                when sum(faltas)=5 then ROUND(CAST(((max(cst_dia)/6)*1) AS DECIMAL(9,2)), 2)
                else 0 end),0
    ) as total_pago_descanso,
    (sum(pago_feriado))+
     sum(total_permiso_pago)+
                if(sum(descanso_calculo)=0,0,
                    (case 
                        when sum(faltas)=0 then max(cst_dia)
                        when sum(faltas)=1 then ROUND(CAST(((max(cst_dia)/6)*5) AS DECIMAL(9,2)), 2)
                        when sum(faltas)=2 then ROUND(CAST(((max(cst_dia)/6)*4) AS DECIMAL(9,2)), 2)
                        when sum(faltas)=3 then ROUND(CAST(((max(cst_dia)/6)*3) AS DECIMAL(9,2)), 2)
                        when sum(faltas)=4 then ROUND(CAST(((max(cst_dia)/6)*2) AS DECIMAL(9,2)), 2)
                        when sum(faltas)=5 then ROUND(CAST(((max(cst_dia)/6)*1) AS DECIMAL(9,2)), 2)
                        else 0 end)
   ) as TOTAL_CF,
    if(sum(a.solo_pago_feriado) = 0 or sum(a.solo_pago_feriado) IS NULL , 0, sum(a.solo_pago_feriado)) pago_feriado
    ,a.nombres,a.tPdocumento,a.nacionalidad,a.cargo,a.ingreso,a.remuneracion_Total,a.banco,a.cuenta,a.tpCuenta,a.cci,a.suplente,a.documento
    ,if(sum(descanso_calculo)=1 and sum(a.descanso) = 1,
            (case 
                when sum(faltas)=0 then max(cst_dia)
                when sum(faltas)=1 then ROUND(CAST(((max(cst_dia) /6)*5) AS DECIMAL(9,2)), 2)
                when sum(faltas)=2 then ROUND(CAST(((max(cst_dia)/6)*4) AS DECIMAL(9,2)), 2)
                when sum(faltas)=3 then ROUND(CAST(((max(cst_dia)/6)*3) AS DECIMAL(9,2)), 2)
                when sum(faltas)=4 then ROUND(CAST(((max(cst_dia)/6)*2) AS DECIMAL(9,2)), 2)
                when sum(faltas)=5 then ROUND(CAST(((max(cst_dia)/6)*1) AS DECIMAL(9,2)), 2)
                else 0 end),0
    ) as total_pago_descanso_sin_turno
    ,a.fechaSece,a.personaEstado,sum(a.permiso_pago),sum(total_permiso_pago)
from pre_planilla_3 a
group by a.id_persona,a.id_sueldo,a.periodo;


END$$

CREATE  PROCEDURE UP_QUITAR_LISTA_NEGRA_PERSONA (IN IN_id_lista INT, IN IN_contrasenia VARCHAR(50), IN IN_motivo VARCHAR(250), IN IN_userCreacion VARCHAR(50))  BEGIN

 declare dec_contrasenia varchar(50);
 set dec_contrasenia = '123456789';

 if(IN_contrasenia != dec_contrasenia)
 then
    signal sqlstate '45000' set message_text = '¡La contraseña ingresada es incorrecta!';
 end if;

 UPDATE persona_has_listanegra 
    SET flEliminado = 0, 
    lis_motivo = IN_motivo
    ,userModificacion	= IN_userCreacion
	,fechaModificacion= now()
 WHERE id_lista = IN_id_lista;

END$$

CREATE  PROCEDURE UP_REACTIVAR_CARGO_PERSONAWEB (IN IN_id_persona INT, IN IN_id_caempleado INT, IN IN_userCreacion VARCHAR(50))  BEGIN 

	declare dec_tpUsuario int;
	declare dec_idUsuario int;
	declare dec_idCargo   int;

    UPDATE cargos_empleado 
    SET ce_estado = 0
    ,userModificacion	= IN_userCreacion
	,fechaModificacion= now()
    WHERE id_persona = IN_id_persona;

    UPDATE cargos_empleado 
    SET ce_estado = 1
    ,userModificacion	= IN_userCreacion
	,fechaModificacion= now()	
    WHERE id_caempleado = IN_id_caempleado;
   
    select id_cargo into dec_idCargo  from cargos_empleado ce where ce.id_caempleado  = IN_id_caempleado;
    select a.id_tipoUsuario into dec_tpUsuario from cargo a where a.id_cargo  = dec_idCargo;
    select id_usuario into dec_idUsuario  from usuario where us_persona = IN_id_persona;
   
    update usuario set id_tpusuario = dec_tpUsuario
   	,userModificacion	= IN_userCreacion
	,fechaModificacion= now()
    where id_usuario = dec_idUsuario; 
   
   	delete from sis_usuario_modperm where id_usuario = dec_idUsuario;
  
	insert into sis_usuario_modperm(id_mpermiso, id_usuario,userCreacion,userModificacion)
	select 
		id_mpermiso, 
		dec_idUsuario
		,IN_userCreacion
		,IN_userCreacion
	from sis_perfil_modperm a where a.id_tpusuario = dec_tpUsuario and a.flEliminado = 1;
   
END$$

CREATE  PROCEDURE UP_REGISTRAR_CARGO_PERSONAWEB (IN IN_id_persona INT, IN IN_id_cargo VARCHAR(25), IN IN_ce_estado VARCHAR(25), IN IN_ce_observacion TEXT, IN IN_userCreacion VARCHAR(50))  BEGIN 

	declare dec_tpUsuario int;
	declare dec_idUsuario int;

	if exists (select * from cargos_empleado a where a.id_persona = IN_id_persona and a.id_cargo = IN_id_cargo)
	then
		signal sqlstate '45000' set message_text = '¡Esta persona ya cuenta con este cargo, favor de revisar!';
	end if;
	
    UPDATE cargos_empleado 
    SET ce_estado = 0
    WHERE id_persona = IN_id_persona and ce_estado = 1;

    INSERT INTO cargos_empleado(
         id_persona, 
         id_cargo, 
         ce_estado, 
         ce_observacion
         ,userCreacion,userModificacion
     ) 
    VALUES (
        IN_id_persona,
        IN_id_cargo,
        IN_ce_estado,
        IN_ce_observacion
        ,IN_userCreacion
		,IN_userCreacion
    ); 
   
   
   	select a.id_tipoUsuario into dec_tpUsuario from cargo a where a.id_cargo  = IN_id_cargo;
    select id_usuario into dec_idUsuario  from usuario where us_persona = IN_id_persona;
   	delete from sis_usuario_modperm where id_usuario = dec_idUsuario;
  	
   	update usuario set 
   	id_tpusuario 		= dec_tpUsuario 
   	,userModificacion	= IN_userCreacion
	,fechaModificacion	= now()
	where id_usuario = dec_idUsuario; 
   
	insert into sis_usuario_modperm(id_mpermiso, id_usuario,userCreacion,userModificacion)
	select 
		id_mpermiso, 
		dec_idUsuario
		,IN_userCreacion
		,IN_userCreacion
	from sis_perfil_modperm a where a.id_tpusuario = dec_tpUsuario and a.flEliminado = 1;
   
   
END$$

CREATE  PROCEDURE UP_REGISTRAR_CESE_EMPLEADO (IN IN_id_persona INT, IN IN_fecha_cese DATE, IN IN_id_motivo INT, IN IN_motivo TEXT, IN IN_lista_negra INT, IN IN_userCreacion VARCHAR(50))  BEGIN

declare dec_id_lista int default 0;
  
update persona set pe_estado = 0 where id_persona = IN_id_persona;
 
 if IN_lista_negra = 1
 then
 
 	INSERT INTO persona_has_listanegra(
	 	id_persona, 
	 	lis_motivo, 
	 	userCreacion,  
	 	userModificacion
 	) 
	VALUES (
		IN_id_persona,
		IN_motivo,
		IN_userCreacion,
        IN_userCreacion
	);

	select id_lista into dec_id_lista from persona_has_listanegra a where a.flEliminado = 1 and id_persona = IN_id_persona order by fechaCreacion limit 1;

 end if;

INSERT INTO empleado_has_cese( 
    id_persona,
    id_motivo,
    id_lista, 
    ce_fecha_cese, 
    ce_motivo,  
    userCreacion, 
    userModificacion
    ) 
        VALUES 
    (
        IN_id_persona,
        IN_id_motivo,
        dec_id_lista,
        IN_fecha_cese, 
        IN_motivo,
        IN_userCreacion,
        IN_userCreacion
);

    update usuario 
    	set us_estado = 0
    	,userModificacion	= IN_userCreacion
		,fechaModificacion= now()
    where us_persona = IN_id_persona;
  
END$$

CREATE  PROCEDURE UP_REGISTRAR_CUENTA_TERCERO_PERSONAWEB (IN IN_id_origen INT, IN IN_doc_suplente VARCHAR(25), IN IN_userCreacion VARCHAR(50))  BEGIN 
    declare dec_documento_suplente int;
    
    select id_persona into dec_documento_suplente from persona where per_documento = IN_doc_suplente limit 1;

    UPDATE persona 
    SET pe_titular = 0
    ,userModificacion	= IN_userCreacion
	,fechaModificacion= now()
    WHERE id_persona = IN_id_origen;

    UPDATE persona_has_banco SET
     	phb_estado		 = 0
     	,userModificacion	= IN_userCreacion
		,fechaModificacion= now()
    WHERE id_persona = IN_id_origen and phb_estado = 1;

    UPDATE suplente_cobrar SET 
    	suc_estado = 0
    	,userModificacion	= IN_userCreacion
		,fechaModificacion= now()
    WHERE suc_origen = IN_id_origen and suc_estado = 1;

    INSERT INTO suplente_cobrar(
        id_persona, 
        suc_origen 
        ,userCreacion,userModificacion
    )  VALUES (
        dec_documento_suplente,
        IN_id_origen
        ,IN_userCreacion
		,IN_userCreacion
    );

END$$

CREATE  PROCEDURE UP_REGISTRAR_CUENTA_TITULAR_PERSONAWEB (IN IN_id_persona INT, IN IN_id_banco VARCHAR(25), IN IN_id_tpcuenta VARCHAR(25), IN IN_phb_cuenta VARCHAR(25), IN IN_phb_cci VARCHAR(25), IN IN_userCreacion VARCHAR(50))  BEGIN 

    UPDATE persona 
    SET 
    	 pe_titular = 1
    	,userModificacion	= IN_userCreacion
		,fechaModificacion	= now()
    WHERE id_persona 		= IN_id_persona;

    UPDATE suplente_cobrar SET
     	 suc_estado			= 0
     	,userModificacion	= IN_userCreacion
		,fechaModificacion	= now()
    WHERE suc_origen 		= IN_id_persona and suc_estado = 1;

    UPDATE persona_has_banco SET
     	 phb_estado			=0
     	,userModificacion	= IN_userCreacion
		,fechaModificacion	= now()
    WHERE id_persona 		= IN_id_persona and phb_estado = 1; 

    INSERT INTO persona_has_banco(
        id_persona, 
        id_banco, 
        id_tpcuenta, 
        phb_cuenta, 
        phb_cci
        ,userCreacion,userModificacion
    )  VALUES (
        IN_id_persona,
        IN_id_banco,
        IN_id_tpcuenta,
        IN_phb_cuenta,
        IN_phb_cci 
		,IN_userCreacion
		,IN_userCreacion
    );

END$$

CREATE  PROCEDURE UP_REGISTRAR_DESCANSO_PERSONAMOBIL (IN IN_id_persona INT, IN IN_de_fecha VARCHAR(25))  BEGIN  
    declare dec_datos varchar(80);
    declare dec_newMessage varchar(80); 
    select 
    UPPER(concat(a.per_nombre," ",a.per_apellido_paterno," ",a.per_apellido_materno)) into dec_datos
    from persona a where id_persona = IN_id_persona limit  1;

    if EXISTS( SELECT * FROM  descanso  WHERE  id_persona = IN_id_persona  and date(de_fecha) =   date(IN_de_fecha)) 
    then
        signal sqlstate '45000' set message_text = dec_datos;
    else
        INSERT INTO descanso(
            id_persona, 
            de_fecha, 
            de_observacion, 
            de_estado
         ) VALUES (
            IN_id_persona,
            IN_de_fecha,
            '',
            1
         ); 
    end if; 
END$$

CREATE  PROCEDURE UP_REGISTRAR_DESCANSO_PERSONAWEB (IN IN_id_persona INT, IN IN_de_fecha VARCHAR(25), IN IN_de_observacion VARCHAR(25), IN IN_de_estado VARCHAR(25), IN IN_de_referencia VARCHAR(25), IN IN_userCreacion VARCHAR(50))  BEGIN  
	
	if exists(
		select * from descanso a where a.de_referencia = IN_de_referencia and a.id_persona = IN_id_persona
	)
	then 
		signal sqlstate '45000' set message_text = 'Este dia de descanso ya existe';
	end if;
    
    update descanso set de_estado = 0 
   	,userModificacion	= IN_userCreacion
	,fechaModificacion= now()
    where id_persona = IN_id_persona and de_estado = 1;

   
    INSERT INTO descanso(
            id_persona, 
            de_observacion, 
            de_estado,
            de_referencia
            ,userCreacion,userModificacion
         ) VALUES (
            IN_id_persona,
            IN_de_observacion,
            IN_de_estado,
            IN_de_referencia
            ,IN_userCreacion
			,IN_userCreacion
         ); 
END$$

CREATE  PROCEDURE UP_REGISTRAR_DOCUMENTOS (IN IN_id_persona INT, IN IN_id_emdocumento INT, IN IN_emd_nombrefile VARCHAR(250), IN IN_emd_pesofile DECIMAL(15,4), IN IN_emd_emision DATE, IN IN_emd_vigencia DATE)  BEGIN

INSERT INTO documentos_has_empleado(
    id_persona, 
    id_emdocumento,
    emd_nombrefile, 
    emd_pesofile, 
    emd_emision, 
    emd_vigencia, 
    userCreacion, 
    fechaCreacion, 
    userModificacion, 
    fechaModificacion, 
    flEliminado
) 
VALUES (
    IN_id_persona,
    IN_id_emdocumento,
    IN_emd_nombrefile,
    IN_emd_pesofile,
    IN_emd_emision,
    IN_emd_vigencia,
    'jvergara',
    curdate(),
    'jvergara',
    curdate(),
    1
);

END$$

CREATE  PROCEDURE UP_REGISTRAR_DOCUMENTOS_EMPLEADO (IN IN_documento VARCHAR(50), IN IN_id_emdocumento INT, IN IN_emd_nombrefile VARCHAR(250), IN IN_emd_pesofile DECIMAL(15,4), IN IN_emd_emision DATE, IN IN_emd_vigencia DATE, IN IN_userCreacion VARCHAR(50))  BEGIN

INSERT INTO documentos_has_empleado(
    id_persona,  
    id_emdocumento,
    emd_nombrefile, 
    emd_pesofile, 
    emd_emision, 
    emd_vigencia 
    ,userCreacion,userModificacion
) 
VALUES (
    (select id_persona from persona pe where pe.per_documento = IN_documento),
    IN_id_emdocumento,
    IN_emd_nombrefile,
    IN_emd_pesofile,
    IN_emd_emision,
    IN_emd_vigencia
    ,IN_userCreacion
	,IN_userCreacion
);

END$$

CREATE  PROCEDURE UP_REGISTRAR_EMPLEADO (IN IN_id_tpdocumento VARCHAR(80), IN IN_id_nacionalidad INT, IN IN_per_nombre VARCHAR(80), IN IN_per_apellido_paterno VARCHAR(80), IN IN_per_apellido_materno VARCHAR(80), IN IN_per_documento VARCHAR(80), IN IN_per_fecha_nac DATE, IN IN_per_celular VARCHAR(80), IN IN_per_correo VARCHAR(80), IN IN_per_nacionalidad INT, IN IN_pe_fecha_ingreso DATE, IN IN_pe_titular INT, IN IN_pe_usuario INT, IN IN_pe_sexo VARCHAR(1), IN IN_pe_direccion VARCHAR(80), IN IN_empleado JSON, IN IN_pago JSON)  BEGIN

## DECLARACIONES
DECLARE dec_ID_PERSONA INT;
DECLARE dec_id_tpdocumento VARCHAR(80);
DECLARE dec_id_nacionalidad INT; 

DECLARE dec_json_empleado_items BIGINT UNSIGNED DEFAULT JSON_LENGTH(IN_empleado);
DECLARE dec_json_empleado_index BIGINT UNSIGNED DEFAULT 0;

DECLARE dec_json_pago_items BIGINT UNSIGNED DEFAULT JSON_LENGTH(IN_pago);
DECLARE dec_json_pago_index BIGINT UNSIGNED DEFAULT 0;
## TRANSACCION
    DECLARE errno INT;
    DECLARE msg_errno TEXT;
    DECLARE msg TEXT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET CURRENT DIAGNOSTICS CONDITION 1 errno = MYSQL_ERRNO,msg_errno = MESSAGE_TEXT ; 
            ##SELECT msg_errno  AS MYSQL_ERROR;
            set msg = concat('TRY: ', msg_errno);
            signal sqlstate '45000' set message_text = msg;
            #signal sqlstate MYSQL_ERROR set message_text = msg_errno;
        ROLLBACK;
    END;

    START TRANSACTION;
## END TRANSACCION

IF  JSON_VALID(IN_empleado) = 0
THEN
    signal sqlstate '45000' set message_text = 'Error datos incorrectos en el empleado!';
END IF; 

IF  JSON_VALID(IN_pago) = 0
THEN
    signal sqlstate '45000' set message_text = 'Error datos incorrectos en el Pago!';
END IF; 


IF NOT EXISTS(
    SELECT 1 FROM  persona WHERE per_documento = IN_per_documento
)
THEN
    INSERT INTO persona(
            id_tpdocumento, 
            id_nacionalidad, 
            per_nombre, 
            per_apellido_paterno, 
            per_apellido_materno, 
            per_documento, 
            per_fecha_nac, 
            per_celular, 
            per_correo, 
            per_nacionalidad,
            pe_fecha_ingreso, 
            pe_fecha_cese, 
            pe_titular, 
            pe_usuario, 
            pe_sexo, 
            pe_direccion
        ) VALUES 
        (
            IN_id_tpdocumento, 
            IN_id_nacionalidad, 
            IN_per_nombre, 
            IN_per_apellido_paterno, 
            IN_per_apellido_materno, 
            IN_per_documento, 
            IN_per_fecha_nac, 
            IN_per_celular, 
            IN_per_correo, 
            IN_per_nacionalidad,  
            IN_pe_fecha_ingreso, 
            IN_pe_fecha_ingreso, 
            IN_pe_titular, 
            IN_pe_usuario, 
            IN_pe_sexo, 
            IN_pe_direccion
        );   
        SELECT LAST_INSERT_ID() INTO dec_ID_PERSONA; 

        WHILE dec_json_empleado_index < dec_json_empleado_items DO
            INSERT INTO empleado(
                id_persona, 
                id_tpdocumento, 
                id_nacionalidad, 
                id_cargo, 
                id_sede, 
                phc_estado, 
                phc_fecha_r, 
                phc_fecha_c
            ) VALUES (
                dec_ID_PERSONA,
                IN_id_tpdocumento,
                IN_id_nacionalidad,
                JSON_UNQUOTE(JSON_EXTRACT(IN_empleado, CONCAT('$[', dec_json_empleado_index, '].cargo'))),
                JSON_UNQUOTE(JSON_EXTRACT(IN_empleado, CONCAT('$[', dec_json_empleado_index, '].sede'))),
                1,
                IN_pe_fecha_ingreso,
                IN_pe_fecha_ingreso
            );

            INSERT INTO descanso(
                id_persona, 
                id_tpdocumento, 
                id_nacionalidad, 
                id_cargo, 
                id_sede, 
                de_fecha, 
                de_observacion, 
                de_estado
            )VALUES(
                dec_ID_PERSONA,
                IN_id_tpdocumento,
                IN_id_nacionalidad,
                JSON_UNQUOTE(JSON_EXTRACT(IN_empleado, CONCAT('$[', dec_json_empleado_index, '].cargo'))),
                JSON_UNQUOTE(JSON_EXTRACT(IN_empleado, CONCAT('$[', dec_json_empleado_index, '].sede'))),
                JSON_UNQUOTE(JSON_EXTRACT(IN_empleado, CONCAT('$[', dec_json_empleado_index, '].descanso'))),
                '',
                1
            );

            INSERT INTO sueldo(
                    id_persona, 
                    id_tpdocumento, 
                    id_nacionalidad, 
                    id_cargo, 
                    id_sede, 
                    ta_basico, 
                    ta_estado, 
                    ta_observacion, 
                    ta_fecha_r, 
                    ta_fecha_c, 
                    ta_csdia, 
                    ta_asignacion_familiar, 
                    ta_bonificacion, 
                    ta_movilidad, 
                    ta_alimentos
                ) VALUES (
                    dec_ID_PERSONA,
                    IN_id_tpdocumento,
                    IN_id_nacionalidad,
                    JSON_UNQUOTE(JSON_EXTRACT(IN_empleado, CONCAT('$[', dec_json_empleado_index, '].cargo'))),
                    JSON_UNQUOTE(JSON_EXTRACT(IN_empleado, CONCAT('$[', dec_json_empleado_index, '].sede'))),
                    JSON_UNQUOTE(JSON_EXTRACT(IN_empleado, CONCAT('$[', dec_json_empleado_index, '].sueldo_basico'))),
                    1,
                    '',
                    NOW(),
                    NOW(),
                    JSON_UNQUOTE(JSON_EXTRACT(IN_empleado, CONCAT('$[', dec_json_empleado_index, '].costo_dia'))),
                    JSON_UNQUOTE(JSON_EXTRACT(IN_empleado, CONCAT('$[', dec_json_empleado_index, '].asignacion_familiar'))),
                    JSON_UNQUOTE(JSON_EXTRACT(IN_empleado, CONCAT('$[', dec_json_empleado_index, '].bonificacion'))),
                    JSON_UNQUOTE(JSON_EXTRACT(IN_empleado, CONCAT('$[', dec_json_empleado_index, '].movilidad'))),
                    JSON_UNQUOTE(JSON_EXTRACT(IN_empleado, CONCAT('$[', dec_json_empleado_index, '].alimentos'))) 
                );

            SET dec_json_empleado_index := dec_json_empleado_index + 1;
        END WHILE;

        WHILE dec_json_pago_index < dec_json_pago_items DO

            IF JSON_EXTRACT(IN_pago, CONCAT('$[', dec_json_pago_index, '].tipo')) = 1 THEN
                 INSERT INTO persona_has_banco(
                    id_persona, 
                    id_tpdocumento, 
                    id_nacionalidad, 
                    id_banco, 
                    id_tpcuenta, 
                    phb_cuenta, 
                    phb_cci
                ) VALUES (
                    dec_ID_PERSONA,
                    IN_id_tpdocumento,
                    IN_id_nacionalidad,
                    JSON_UNQUOTE(JSON_EXTRACT(IN_pago, CONCAT('$[', dec_json_pago_index, '].banco'))),
                    JSON_UNQUOTE(JSON_EXTRACT(IN_pago, CONCAT('$[', dec_json_pago_index, '].tipo_cuenta'))),
                    JSON_UNQUOTE(JSON_EXTRACT(IN_pago, CONCAT('$[', dec_json_pago_index, '].cuenta'))),
                    'AAAAAAAA'
                );
            ELSE
                INSERT INTO suplente_cobrar(
                    id_persona, 
                    id_tpdocumento, 
                    id_nacionalidad, 
                    suc_estado,
                    suc_observacion
                ) VALUES (
                    (select id_persona from persona where per_documento = JSON_UNQUOTE(JSON_EXTRACT(IN_pago, CONCAT('$[', dec_json_pago_index, '].documento')))),
                    (select id_tpdocumento from persona where per_documento = JSON_UNQUOTE(JSON_EXTRACT(IN_pago, CONCAT('$[', dec_json_pago_index, '].documento')))),
                    (select id_nacionalidad from persona where per_documento = JSON_UNQUOTE(JSON_EXTRACT(IN_pago, CONCAT('$[', dec_json_pago_index, '].documento')))),
                    1,
                    ''
                );
            END IF;

            SET dec_json_pago_index := dec_json_pago_index + 1;
        END WHILE;

ELSE
      signal sqlstate '45000' set message_text = 'ELSE => Esta persona ya esta registrada en el sistema!';
END IF; 

## RETURN TO TABLES...
COMMIT WORK;

END$$

CREATE  PROCEDURE UP_REGISTRAR_LISTA_NEGRA_PERSONA (IN IN_id_persona INT, IN IN_motivo TEXT)  BEGIN

 declare dec_id_listaNegra int;

 INSERT INTO persona_has_listanegra(
    id_persona, 
    lis_motivo,
    userCreacion, 
    fechaCreacion, 
    userModificacion, 
    fechaModificacion, 
    flEliminado
) 
VALUES (
    IN_id_persona,
    IN_motivo,
    'JVERGARA',
    curdate(),
    'JVERGARA',
    curdate(),
    1
);

select LAST_INSERT_ID() into dec_id_listaNegra;

select dec_id_listaNegra as id_lista;
  
END$$

CREATE  PROCEDURE up_registrar_permisos_perfil_usuario_modulos (IN IN_id_tpusuario INT, IN IN_id_mpermiso INT, IN IN_hasPermission BOOLEAN, IN IN_userCreacion VARCHAR(50))  begin 
    if not exists(
        select * from sis_perfil_modperm WHERE id_mpermiso = IN_id_mpermiso and id_tpusuario = IN_id_tpusuario 
    )
    then
          INSERT INTO sis_perfil_modperm(id_mpermiso, id_tpusuario,userCreacion,userModificacion) 
          VALUES 
          (
            IN_id_mpermiso,
            IN_id_tpusuario
            ,IN_userCreacion
			,IN_userCreacion
          );
    else 
         UPDATE sis_perfil_modperm 
            SET flEliminado = if(IN_hasPermission = true, 0, 1)
            ,userModificacion	= IN_userCreacion
			,fechaModificacion= now()
         WHERE id_mpermiso = IN_id_mpermiso and id_tpusuario = IN_id_tpusuario;

    end if;

end$$

CREATE  PROCEDURE up_registrar_permisos_usuario_modulos (IN IN_id_usuario INT, IN IN_id_mpermiso INT, IN IN_hasPermission BOOLEAN, IN IN_userCreacion VARCHAR(50))  begin 
	
	if not exists(
		select * from sis_usuario_modperm WHERE id_mpermiso = IN_id_mpermiso and id_usuario = IN_id_usuario 
	)
	then
		  INSERT INTO sis_usuario_modperm(id_mpermiso, id_usuario, userCreacion, userModificacion) 
		  VALUES 
		  (
			IN_id_mpermiso,
			IN_id_usuario
			,IN_userCreacion
			,IN_userCreacion
		  );
	else 
		 UPDATE sis_usuario_modperm 
		    SET flEliminado = if(IN_hasPermission = true, 0, 1) 
		    ,userModificacion	= IN_userCreacion
			,fechaModificacion= now()
		 WHERE id_mpermiso = IN_id_mpermiso and id_usuario = IN_id_usuario;

	end if;
 
	
end$$

CREATE  PROCEDURE UP_REGISTRAR_SEDE_PERSONAWEB (IN IN_id_persona INT, IN IN_id_sede VARCHAR(25), IN IN_sm_codigo VARCHAR(25), IN IN_sm_observacion TEXT, IN IN_sm_estado INT, IN IN_userCreacion VARCHAR(50))  BEGIN 

    IF EXISTS(select 1 from sede_empleado where id_persona = IN_id_persona and id_sede = IN_id_sede) 
    THEN
        signal sqlstate '45000' set message_text = 'Esta persona ya se encuentra registrado en esta sede!';
    else
    	update sede_empleado 
    	set 
    	sm_estado = 0
    	,userModificacion	= IN_userCreacion
		,fechaModificacion= now()
		where id_persona  = IN_id_persona and  sm_estado = 1;
    	
        INSERT INTO sede_empleado(
                id_persona, 
                id_sede, 
                sm_codigo,  
                sm_observacion, 
                sm_estado
                ,userCreacion,userModificacion
                ) 
            VALUES (
                IN_id_persona,
                IN_id_sede,
                IN_sm_codigo,
                IN_sm_observacion,
                IN_sm_estado
                ,IN_userCreacion
				,IN_userCreacion
            );
    END IF;
       
END$$

CREATE  PROCEDURE UP_REGISTRAR_SUELDO_PERSONAWEB (IN IN_id_persona INT, IN IN_ta_basico VARCHAR(25), IN IN_ta_estado VARCHAR(25), IN IN_ta_observacion VARCHAR(25), IN IN_ta_csdia VARCHAR(25), IN IN_ta_asignacion_familiar VARCHAR(25), IN IN_ta_bonificacion VARCHAR(25), IN IN_ta_movilidad VARCHAR(25), IN IN_ta_alimentos VARCHAR(25), IN IN_ta_total VARCHAR(25), IN IN_ta_vigenciaInicio DATE, IN IN_ta_vigenciaFin DATE, IN IN_userCreacion VARCHAR(50))  BEGIN 
	
    declare dec_estado int;
    declare dec_ultomoSueldo date;

    declare dec_idUltimoSuledo int;

    SET dec_ultomoSueldo = '1990-01-01';

    select phc_estado into dec_estado from empleado e where e.id_persona = IN_id_persona;
    select ta_vigenciaFin, id_sueldo into dec_ultomoSueldo, dec_idUltimoSuledo from sueldo e where e.id_persona  = IN_id_persona order by id_sueldo desc limit 1; 

 
    if dec_estado = 3
    then
    
        signal sqlstate '45000' set message_text = '¡Esta persona todavía no ha sido aprobado, por favor aprobarlo!';
        
    else

        if dec_ultomoSueldo = '1990-01-01'
        then

            UPDATE sueldo 
            SET ta_estado = 0
            WHERE id_persona = IN_id_persona
           	and ta_estado = 1
            ;
        
            INSERT INTO sueldo(
                id_persona, 
                ta_basico, 
                ta_estado, 
                ta_observacion, 
                ta_csdia, 
                ta_asignacion_familiar, 
                ta_bonificacion, 
                ta_movilidad, 
                ta_alimentos, 
                ta_total,
                ta_vigenciaInicio,
                ta_vigenciaFin
                ,userCreacion,userModificacion
            )VALUES (
                IN_id_persona, 
                IN_ta_basico, 
                IN_ta_estado, 
                IN_ta_observacion, 
                IN_ta_csdia, 
                IN_ta_asignacion_familiar, 
                IN_ta_bonificacion, 
                IN_ta_movilidad, 
                IN_ta_alimentos, 
                IN_ta_total,
                IN_ta_vigenciaInicio,
                IN_ta_vigenciaFin
				,IN_userCreacion
				,IN_userCreacion
            );

        else
            
            if (date(dec_ultomoSueldo) = date('2100-01-01') and date(IN_ta_vigenciaInicio) <= date(CURDATE()))
            then
                 signal sqlstate '45000' set message_text = '¡La fecha ingresada tiene que ser mayor a la ultima fecha ingresada en el sueldo anterior!';
            end if;

            if (date(dec_ultomoSueldo) <> date('2100-01-01') and date(IN_ta_vigenciaInicio) <= date(dec_ultomoSueldo))
            then
                 signal sqlstate '45000' set message_text = '¡La fecha ingresada tiene que ser mayor a la ultima fecha ingresada en el sueldo anterior!';
            end if; 

            UPDATE sueldo 
            SET ta_estado = 0
            ,userModificacion	= IN_userCreacion
			,fechaModificacion= now()
            WHERE id_persona = IN_id_persona
           	and ta_estado  = 1
            ;
           
            update sueldo  
            set ta_vigenciaFin = (date(IN_ta_vigenciaInicio) - 1) 
            ,userModificacion	= IN_userCreacion
			,fechaModificacion= now()
           	where id_sueldo  = dec_idUltimoSuledo;
        
            INSERT INTO sueldo(
                id_persona, 
                ta_basico, 
                ta_estado, 
                ta_observacion, 
                ta_csdia, 
                ta_asignacion_familiar, 
                ta_bonificacion, 
                ta_movilidad, 
                ta_alimentos, 
                ta_total,
                ta_vigenciaInicio,
                ta_vigenciaFin
                ,userCreacion,userModificacion
            )VALUES (
                IN_id_persona, 
                IN_ta_basico, 
                IN_ta_estado, 
                IN_ta_observacion, 
                IN_ta_csdia, 
                IN_ta_asignacion_familiar, 
                IN_ta_bonificacion, 
                IN_ta_movilidad, 
                IN_ta_alimentos, 
                IN_ta_total,
                IN_ta_vigenciaInicio,
                IN_ta_vigenciaFin
				,IN_userCreacion
				,IN_userCreacion
            );
            /*select date(CURDATE()) as hoy, 
          	date(IN_ta_vigenciaInicio) as ingreso,
         	date(dec_ultomoSueldo) as ultimo,
        	date('2100-01-01') as fix;*/
           
       end if;
   end if;

END$$

CREATE  PROCEDURE UP_REGISTRO_DESCANSO_FALTA_TAREO (IN IN_id_persona INT, IN IN_id_tpdocumento VARCHAR(50), IN IN_id_nacionalidad INT, IN IN_id_cargo INT, IN IN_id_sede INT, IN IN_trs_remunerado INT, IN IN_ta_estado INT, IN IN_trs_fecha_r DATETIME, IN IN_trs_fecha_c DATETIME, IN IN_trs_usuario INT, IN IN_id_sueldo INT, IN IN_id_marcador INT)  BEGIN   
    DECLARE dec_pagado int;
    DECLARE dec_idMarcador int;  

    ## TRANSACCION
    DECLARE errno INT;
    DECLARE msg_errno TEXT;
    DECLARE msg TEXT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET CURRENT DIAGNOSTICS CONDITION 1 errno = MYSQL_ERRNO,msg_errno = MESSAGE_TEXT ; 
            ##SELECT msg_errno  AS MYSQL_ERROR;
            set msg = concat('TRY: ', msg_errno);
            signal sqlstate '45000' set message_text = msg;
            #signal sqlstate MYSQL_ERROR set message_text = msg_errno;
        ROLLBACK;
    END;

START TRANSACTION;

if EXISTS(SELECT * FROM  tareo ta
            INNER JOIN persona su
            on ta.id_persona = su.id_persona
            where su.id_persona = IN_id_persona  
            and date(ta.ta_fecha_r) = date(IN_trs_fecha_r)
            and ta.id_marcador  = 5
            and ta.ta_estado = 1) 
THEN
    signal sqlstate '45000' set message_text = 'Esta persona tiene registrado una falta el dia de hoy!';
END IF; 

if EXISTS(SELECT * FROM  tareo ta
            INNER JOIN persona su
            on ta.id_persona = su.id_persona
            where su.id_persona = IN_id_persona  
            and date(ta.ta_fecha_r) = date(IN_trs_fecha_r)
            and ta.id_marcador  = 4
            and ta.ta_estado = 1) 
THEN
    signal sqlstate '45000' set message_text = 'Esta persona tiene registrado un descanso el dia de hoy!';
END IF; 


if IN_id_marcador = 4
        then
           IF EXISTS(
                SELECT * FROM  tareo ta
                    INNER JOIN persona su
                    on ta.id_persona = su.id_persona
                    where su.id_persona = IN_id_persona  
                    and date(ta.ta_fecha_r) = date(IN_trs_fecha_r)
                    and ta.id_marcador  = 4
                    and ta.ta_estado = 1
            )
            THEN 
                signal sqlstate '45000' set message_text = 'Esta persona ya cuenta con una descanso registrado el dia de hoy!';
            else
                INSERT INTO tareo(
                  id_sede, id_cargo,id_persona, id_sueldo, id_marcador, 
                  ta_remunerado, ta_estado, ta_fecha_r, 
                  ta_fecha_c, ta_hora_r, ta_hora_c, 
                  ta_hrstrabajadas, ta_usuario, ta_permiso
                ) 
                VALUES 
                  (
                    IN_id_sede, IN_id_cargo,IN_id_persona, IN_id_sueldo,IN_id_marcador, 
                    1, 1, IN_trs_fecha_r, 
                    IN_trs_fecha_r, '00:00:00', '00:00:00', 
                    0, IN_trs_usuario, 0
                  );
            end if; 
            #signal sqlstate '45000' set message_text = 'Ingreso xd!';
elseif IN_id_marcador = 5
then
            IF EXISTS(
                SELECT * FROM  tareo ta
                    INNER JOIN persona su
                    on ta.id_persona = su.id_persona
                    where su.id_persona = IN_id_persona
                    and date(ta.ta_fecha_r) = date(IN_trs_fecha_r)
                    and ta.id_marcador  = 5
                    and ta.ta_estado = 1
            )
            THEN 
                signal sqlstate '45000' set message_text = 'Esta persona ya cuenta con una falta registrado el dia de hoy!';
            else

                INSERT INTO tareo(
                      id_sede, id_cargo,id_persona, id_sueldo, id_marcador, 
                      ta_remunerado, ta_estado, ta_fecha_r, 
                      ta_fecha_c, ta_hora_r, ta_hora_c, 
                      ta_hrstrabajadas, ta_usuario, ta_permiso
                    ) 
                    VALUES 
                    (
                        IN_id_sede, IN_id_cargo,IN_id_persona, IN_id_sueldo,IN_id_marcador, 
                        0, 1, IN_trs_fecha_r, 
                        IN_trs_fecha_r, '00:00:00', '00:00:00', 
                        0, IN_trs_usuario, 0
                    );

                /*IF EXISTS(  
                    SELECT * FROM  descanso  WHERE id_persona = IN_id_persona and date(de_fecha) =  date(IN_trs_fecha_r)
                )
                THEN
                    signal sqlstate '45000' set message_text = 'Esta persona cuenta con un descanso el dia de hoy!';
                else
                    INSERT INTO tareo(
                      id_sede, id_cargo,id_persona, id_sueldo, id_marcador, 
                      ta_remunerado, ta_estado, ta_fecha_r, 
                      ta_fecha_c, ta_hora_r, ta_hora_c, 
                      ta_hrstrabajadas, ta_usuario, ta_permiso
                    ) 
                    VALUES 
                      (
                        IN_id_sede, IN_id_cargo,IN_id_persona, IN_id_sueldo,IN_id_marcador, 
                        0, 1, IN_trs_fecha_r, 
                        IN_trs_fecha_r, '00:00:00', '00:00:00', 
                        0, IN_trs_usuario, 0
                      );
                end if;*/ 
            end if; 
end if; 
 
## RETURN TO TABLES...
COMMIT WORK;

END$$

CREATE  PROCEDURE UP_REGISTRO_PERMISO_TAREO (IN IN_id_permiso INT, IN IN_id_persona INT, IN IN_id_tpdocumento VARCHAR(50), IN IN_id_nacionalidad INT, IN IN_id_cargo INT, IN IN_id_sede INT, IN IN_trs_remunerado INT, IN IN_ta_estado INT, IN IN_trs_fecha_r DATETIME, IN IN_trs_fecha_c DATETIME, IN IN_trs_usuario INT, IN IN_id_sueldo INT, IN IN_id_marcador INT)  BEGIN   
    DECLARE dec_pagado int;
    DECLARE dec_idMarcador int; 
    DECLARE dec_idPermiso int; 

    ## TRANSACCION
    DECLARE errno INT;
    DECLARE msg_errno TEXT;
    DECLARE msg TEXT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET CURRENT DIAGNOSTICS CONDITION 1 errno = MYSQL_ERRNO,msg_errno = MESSAGE_TEXT ; 
            ##SELECT msg_errno  AS MYSQL_ERROR;
            set msg = concat('TRY: ', msg_errno);
            signal sqlstate '45000' set message_text = msg;
            #signal sqlstate MYSQL_ERROR set message_text = msg_errno;
        ROLLBACK;
    END;

START TRANSACTION;


IF IN_trs_remunerado = 1
then
    set dec_pagado = 1;
else
    set dec_pagado = 0;
end if;

IF IN_id_marcador = 6
then
    set dec_idPermiso = IN_id_permiso;
else
    set dec_idPermiso = 0;
end if;

if EXISTS(SELECT * FROM  tareo ta
            INNER JOIN persona su
            on ta.id_persona = su.id_persona
            where su.id_persona = IN_id_persona  
            and date(ta.ta_fecha_r) = date(IN_trs_fecha_r)
            and ta.id_marcador  = 5
            and ta.ta_estado = 1) 
THEN
    signal sqlstate '45000' set message_text = 'Esta persona tiene registrado una falta el dia de hoy!';
END IF; 

if EXISTS(SELECT * FROM  tareo ta
            INNER JOIN persona su
            on ta.id_persona = su.id_persona
            where su.id_persona = IN_id_persona  
            and date(ta.ta_fecha_r) = date(IN_trs_fecha_r)
            and ta.id_marcador  = 4
            and ta.ta_estado = 1) 
THEN
    signal sqlstate '45000' set message_text = 'Esta persona tiene registrado un descanso el dia de hoy!';
END IF; 

IF EXISTS(
    SELECT * FROM  tareo ta
            INNER JOIN persona su
            on ta.id_persona = su.id_persona
            where su.id_persona = IN_id_persona  
            and date(ta.ta_fecha_r) = date(IN_trs_fecha_r)
            and ta.id_marcador  = 6
            and ta.ta_estado = 1
)
THEN 
    signal sqlstate '45000' set message_text = 'Esta persona ya cuenta con un permiso registrado el dia de hoy!';
ELSE 
    INSERT INTO tareo(
      id_sede, id_cargo,id_persona, id_sueldo, id_marcador, 
      ta_remunerado, ta_estado, ta_fecha_r, 
      ta_fecha_c, ta_hora_r, ta_hora_c, 
      ta_hrstrabajadas, ta_usuario, ta_permiso
    ) 
    VALUES 
      (
        IN_id_sede, IN_id_cargo,IN_id_persona, IN_id_sueldo, 
        IN_id_marcador, dec_pagado, 1, IN_trs_fecha_r, 
        IN_trs_fecha_r, '00:00:00', '00:00:00', 
        0, IN_trs_usuario, dec_idPermiso
      ); 
END IF;   

## RETURN TO TABLES...
COMMIT WORK;

END$$

CREATE  PROCEDURE UP_REGISTRO_TAREO (IN IN_id_marcador INT, IN IN_id_persona INT, IN IN_id_tpdocumento VARCHAR(50), IN IN_id_nacionalidad INT, IN IN_id_cargo INT, IN IN_id_sede INT, IN IN_ta_estado INT, IN IN_ta_fecha_r DATETIME, IN IN_ta_fecha_c DATETIME, IN IN_ta_hora_r TIME, IN IN_ta_hora_c TIME, IN IN_ta_usuario INT, IN IN_id_sede_em INT, IN IN_id_sueldo INT, IN IN_ta_remunerado INT)  BEGIN 

    DECLARE dec_permiso varchar(50);

    ## TRANSACCION
    DECLARE errno INT;
    DECLARE msg_errno TEXT;
    DECLARE msg TEXT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET CURRENT DIAGNOSTICS CONDITION 1 errno = MYSQL_ERRNO,msg_errno = MESSAGE_TEXT ; 
            ##SELECT msg_errno  AS MYSQL_ERROR;
            set msg = concat('TRY: ', msg_errno);
            signal sqlstate '45000' set message_text = msg;
            #signal sqlstate MYSQL_ERROR set message_text = msg_errno;
        ROLLBACK;
    END;

    START TRANSACTION;


    IF EXISTS(  
            select 
                * 
            from tareo t
            INNER JOIN persona s
            on t.id_persona = s.id_persona
            where t.id_marcador = 6
            and s.id_persona = IN_id_persona
            and date(t.ta_fecha_r) = date(IN_ta_fecha_r)
            and t.ta_estado = 1
    )
    THEN
        select 
            p.pe_nombre  into dec_permiso 
        from tareo t
        INNER JOIN persona s
        on t.id_persona = s.id_persona
        INNER JOIN permiso p on t.ta_permiso = p.id_permiso
        where t.id_marcador = 6
        and s.id_persona = IN_id_persona
        and date(t.ta_fecha_r) = date(IN_ta_fecha_r)
        and t.ta_estado = 1; 

        set msg = concat('Esta persona tiene un permiso : ', dec_permiso);
        signal sqlstate '45000' set message_text = msg;

    END IF;

    IF EXISTS(  
            select 
                * 
            from tareo t
            INNER JOIN persona s
            on t.id_persona = s.id_persona
            where t.id_marcador = 5
            and s.id_persona = IN_id_persona
            and date(t.ta_fecha_r) = date(IN_ta_fecha_r) 
            and t.ta_estado = 1
    )
    THEN
        signal sqlstate '45000' set message_text = 'Esta persona tiene una falta registrado hoy! :';
    END IF;


    IF EXISTS(
           SELECT 
            id_tareo 
            from tareo ta
            INNER JOIN persona su
            on ta.id_persona = su.id_persona
            INNER JOIN empleado em on em.id_persona = su.id_persona
            WHERE em.id_persona = IN_id_persona 
            and (Date(ta.ta_fecha_r) BETWEEN Date(IN_ta_fecha_r) and date(IN_ta_fecha_r))
            and ta.id_sede = IN_id_sede
            AND ta.id_marcador = IN_id_marcador
            and ta.id_marcador NOT IN (6,4,5)
            and ta.ta_etapa = 1
            and ta.ta_estado = 1
        )
        THEN
            signal sqlstate '45000' set message_text = 'Esta persona tiene un tareo en este turno!';
        ELSE 
            INSERT INTO tareo(
              id_sede_em, id_sede, id_cargo, id_sueldo, 
              id_marcador, ta_estado, ta_fecha_r, 
              ta_fecha_c, ta_hora_r, ta_hora_c, 
              ta_hrstrabajadas, ta_usuario, ta_remunerado,
              ta_etapa,id_persona
            ) 
            VALUES 
            (
                IN_id_sede_em, IN_id_sede, IN_id_cargo, 
                IN_id_sueldo, IN_id_marcador, IN_ta_estado, 
                IN_ta_fecha_r, IN_ta_fecha_c, IN_ta_hora_r, 
                IN_ta_hora_c, 0, IN_ta_usuario, IN_ta_remunerado,
                0, IN_id_persona
            ); 
    END IF;

 

    /*IF EXISTS( 
        SELECT 
            id_tareo 
            from tareo ta
            INNER JOIN sueldo su on ta.id_sueldo = su.id_sueldo
            INNER JOIN empleado em on em.id_persona = su.id_persona
            WHERE 
            em.id_persona = IN_id_persona 
            and (Date(ta.ta_fecha_r) BETWEEN Date(IN_ta_fecha_r) and date(IN_ta_fecha_r))
            and ta.id_sede = IN_id_sede
            AND ta.id_marcador = IN_id_marcador
            and ta.ta_etapa = 0
            and ta.ta_estado = 1
    )
    THEN
        signal sqlstate '45000' set message_text = 'Esta persona tiene un tareo pediente por cerrar!';
    ELSE
        
        IF EXISTS(
           SELECT 
            id_tareo 
            from tareo ta
            INNER JOIN sueldo su on ta.id_sueldo = su.id_sueldo
            INNER JOIN empleado em on em.id_persona = su.id_persona
            WHERE em.id_persona = IN_id_persona 
            and (Date(ta.ta_fecha_r) BETWEEN Date(IN_ta_fecha_r) and date(IN_ta_fecha_r))
            and ta.id_sede = IN_id_sede
            AND ta.id_marcador = IN_id_marcador
            and ta.ta_etapa = 1
            and ta.ta_estado = 1
        )
        THEN
            signal sqlstate '45000' set message_text = 'Esta persona tiene un tareo en este turno!';
        ELSE 
            INSERT INTO tareo(
              id_sede_em, id_sede, id_cargo, id_sueldo, 
              id_marcador, ta_estado, ta_fecha_r, 
              ta_fecha_c, ta_hora_r, ta_hora_c, 
              ta_hrstrabajadas, ta_usuario, ta_remunerado,
              ta_etapa,id_persona
            ) 
            VALUES 
            (
                IN_id_sede_em, IN_id_sede, IN_id_cargo, 
                IN_id_sueldo, IN_id_marcador, IN_ta_estado, 
                IN_ta_fecha_r, IN_ta_fecha_c, IN_ta_hora_r, 
                IN_ta_hora_c, 0, IN_ta_usuario, IN_ta_remunerado,
                0, IN_id_persona
            ); 
        END IF;

    END IF;*/

## RETURN TO TABLES...
COMMIT WORK;

END$$

CREATE  PROCEDURE up_reporte_documentos_caducados (IN IN_opcion INT, IN IN_nombre VARCHAR(50), IN IN_sede INT, IN IN_documento VARCHAR(50), IN IN_opcionFecha INT, IN IN_inicio DATE, IN IN_fin DATE)  begin 
	
	drop table  if exists documentoEmpleado;
	create temporary  table documentoEmpleado(
		id_docemp int
	);
	
	insert into documentoEmpleado
	select 
		a.id_docemp 
	from documentos_has_empleado a
	where 
		a.flEliminado  = 1 and
		date(a.emd_vigencia) <> '2100-01-01'
	;


	select 
		p.per_documento as nr_identidad,
		CONCAT(p.per_nombre," ",p.per_apellido_paterno," ",p.per_apellido_materno) AS datos,
		se.se_descripcion as sede,
		ca.ca_descripcion as cargo,
		de.de_descripcion as documento,
		b.emd_vigencia as fecha_vigencia
	from documentoEmpleado a
	inner join  documentos_has_empleado b on a.id_docemp = b.id_docemp 
	inner join documentos_empleado de on b.id_emdocumento = de.id_emdocumento 
	inner join  persona p on b.id_persona  = p.id_persona 
	INNER JOIN sede_empleado she on she.id_persona = p.id_persona and she.sm_estado = 1
	INNER JOIN sede se on se.id_sede = she.id_sede
	INNER JOIN cargos_empleado ce on ce.id_persona = p.id_persona and ce.ce_estado  = 1
	INNER JOIN cargo ca on ca.id_cargo = ce.id_cargo
	where 
		CASE WHEN IN_opcion = 1 THEN  
	        p.per_documento = IN_documento
	    WHEN IN_opcion = 2 THEN  
	        CONCAT(p.per_nombre," ",p.per_apellido_paterno," ",p.per_apellido_materno) LIKE CONCAT('%',IN_nombre,'%')  
	    WHEN IN_opcion = 3 THEN  
	        she.id_sede = IN_sede
	    ELSE 
	        TRUE  
	    end
    
    and  
	    CASE WHEN IN_opcionFecha = 1 THEN  
	        date(b.emd_vigencia) < IN_inicio
	    WHEN IN_opcionFecha = 2 THEN  
	        date(b.emd_vigencia) between date(IN_inicio)  and date(IN_fin) 
	    ELSE 
	        TRUE  
	    end
	order by b.emd_vigencia asc;
	 

end$$

CREATE  PROCEDURE up_reporte_planilla_15CNA (IN IN_MES VARCHAR(8), IN IN_ANIO VARCHAR(8), IN IN_SEDE INT)  begin 
    declare dec_codPlanilla varchar(40);

    set dec_codPlanilla := concat(IN_ANIO,IN_MES,IN_SEDE,1);

    select * from de_planilla dp
    INNER JOIN ca_planilla ca 
    on ca.id_planilla = dp.id_planilla
    where ca.cap_codigo = dec_codPlanilla;

    
END$$

CREATE  PROCEDURE up_reporte_planilla_15CNA_2 (IN IN_MES VARCHAR(8), IN IN_ANIO VARCHAR(8), IN IN_SEDE INT)  begin 
    declare dec_codPlanilla varchar(40);

    set dec_codPlanilla := concat(IN_ANIO,IN_MES,IN_SEDE,2);

    select * from de_planilla dp
    INNER JOIN ca_planilla ca 
    on ca.id_planilla = dp.id_planilla
    where ca.cap_codigo = dec_codPlanilla;

    
END$$

CREATE  PROCEDURE UP_SUPERVISOR_REGISTRAR_EMPLEADO (IN IN_id_tpdocumento VARCHAR(80), IN IN_id_nacionalidad INT, IN IN_per_nombre VARCHAR(80), IN IN_per_apellido_paterno VARCHAR(80), IN IN_per_apellido_materno VARCHAR(80), IN IN_per_documento VARCHAR(80), IN IN_per_fecha_nac DATE, IN IN_per_celular VARCHAR(80), IN IN_per_correo VARCHAR(80), IN IN_per_nacionalidad INT, IN IN_pe_fecha_ingreso DATE, IN IN_pe_titular INT, IN IN_pe_usuario INT, IN IN_pe_sexo VARCHAR(1), IN IN_pe_direccion VARCHAR(80), IN IN_pe_estado INT, IN IN_empleado JSON, IN IN_pago JSON)  BEGIN

## DECLARACIONES
DECLARE dec_ID_PERSONA INT;
DECLARE dec_id_tpdocumento VARCHAR(80);
DECLARE dec_id_nacionalidad INT; 

DECLARE dec_json_empleado_items BIGINT UNSIGNED DEFAULT JSON_LENGTH(IN_empleado);
DECLARE dec_json_empleado_index BIGINT UNSIGNED DEFAULT 0;

DECLARE dec_json_pago_items BIGINT UNSIGNED DEFAULT JSON_LENGTH(IN_pago);
DECLARE dec_json_pago_index BIGINT UNSIGNED DEFAULT 0;
## END DECLARACIONES

## TRANSACCION
    DECLARE errno INT;
    DECLARE msg_errno TEXT;
    DECLARE msg TEXT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET CURRENT DIAGNOSTICS CONDITION 1 errno = MYSQL_ERRNO,msg_errno = MESSAGE_TEXT ; 
            ##SELECT msg_errno  AS MYSQL_ERROR;
            set msg = concat('TRY: ', msg_errno);
            signal sqlstate '45000' set message_text = msg;
            #signal sqlstate MYSQL_ERROR set message_text = msg_errno;
        ROLLBACK;
    END;

    START TRANSACTION;
## END TRANSACCION

IF  JSON_VALID(IN_empleado) = 0
THEN
    signal sqlstate '45000' set message_text = 'Error datos incorrectos en el empleado!';
END IF; 

IF  JSON_VALID(IN_pago) = 0
THEN
    signal sqlstate '45000' set message_text = 'Error datos incorrectos en el Pago!';
END IF; 


IF NOT EXISTS(
    SELECT 1 FROM  persona WHERE per_documento = IN_per_documento
)
THEN
    INSERT INTO persona(
            id_tpdocumento, 
            id_nacionalidad, 
            per_nombre, 
            per_apellido_paterno, 
            per_apellido_materno, 
            per_documento, 
            per_fecha_nac, 
            per_celular, 
            per_correo, 
            per_nacionalidad,
            pe_fecha_ingreso, 
            pe_fecha_cese, 
            pe_titular, 
            pe_usuario, 
            pe_sexo, 
            pe_direccion,
            pe_estado
        ) VALUES 
        (
            IN_id_tpdocumento, 
            IN_id_nacionalidad, 
            IN_per_nombre, 
            IN_per_apellido_paterno, 
            IN_per_apellido_materno, 
            IN_per_documento, 
            IN_per_fecha_nac, 
            IN_per_celular, 
            IN_per_correo, 
            IN_per_nacionalidad,  
            IN_pe_fecha_ingreso, 
            IN_pe_fecha_ingreso, 
            IN_pe_titular, 
            IN_pe_usuario, 
            IN_pe_sexo, 
            IN_pe_direccion,
            IN_pe_estado
        ); 

        SELECT LAST_INSERT_ID() INTO dec_ID_PERSONA; 

        WHILE dec_json_empleado_index < dec_json_empleado_items DO
            INSERT INTO empleado(
                id_persona, 
                phc_estado, 
                phc_fecha_r, 
                phc_fecha_c,
                phc_codigo
                ) VALUES (
                    dec_ID_PERSONA,
                    3,
                    IN_pe_fecha_ingreso,
                    IN_pe_fecha_ingreso,
                    'CODIGO'
                );

            IF JSON_UNQUOTE(JSON_EXTRACT(IN_empleado, CONCAT('$[', dec_json_empleado_index, '].cargo'))) = '3'
            THEN
                INSERT INTO usuario(id_tpusuario, us_usuario, us_contrasenia, us_estado, us_fecha_r, us_fecha_c, us_empleado, us_persona) 
                VALUES (
                    3,
                    IN_per_documento,
                    IN_per_documento,
                    1,
                    NOW(),
                    NOW(),
                    dec_ID_PERSONA,
                    dec_ID_PERSONA
                );
            ELSE 
                INSERT INTO usuario(id_tpusuario, us_usuario, us_contrasenia, us_estado, us_fecha_r, us_fecha_c, us_empleado, us_persona) 
                VALUES (
                    1,
                    IN_per_documento,
                    IN_per_documento,
                    1,
                    NOW(),
                    NOW(),
                    dec_ID_PERSONA,
                    dec_ID_PERSONA
                );
            END IF;

            INSERT INTO cargos_empleado(
                id_persona, 
                id_cargo, 
                ce_fecha_r, 
                ce_fecha_c, 
                ce_estado, 
                ce_observacion
            )
            VALUES (
                dec_ID_PERSONA,
                JSON_UNQUOTE(JSON_EXTRACT(IN_empleado, CONCAT('$[', dec_json_empleado_index, '].cargo'))),
                IN_pe_fecha_ingreso,
                IN_pe_fecha_ingreso,
                1,
                'OBSERVACION'
            );

            INSERT INTO sede_empleado(id_persona, id_sede, sm_codigo, sm_fecha_r, sm_fecha_c, sm_observacion, sm_estado) 
            VALUES 
            (
                dec_ID_PERSONA,
                JSON_UNQUOTE(JSON_EXTRACT(IN_empleado, CONCAT('$[', dec_json_empleado_index, '].sede'))),
                'CODIGO',
                IN_pe_fecha_ingreso,
                IN_pe_fecha_ingreso,
                'OBSERVACION',
                1
            );

            INSERT INTO descanso(
                id_persona,   
                de_fecha, 
                de_observacion, 
                de_estado
            )VALUES (
                dec_ID_PERSONA, 
                JSON_UNQUOTE(JSON_EXTRACT(IN_empleado, CONCAT('$[', dec_json_empleado_index, '].descanso'))),
                '',
                1
            );

            INSERT INTO sueldo(
                    id_persona,   
                    ta_basico, 
                    ta_estado, 
                    ta_observacion, 
                    ta_fecha_r, 
                    ta_fecha_c, 
                    ta_csdia, 
                    ta_asignacion_familiar, 
                    ta_bonificacion, 
                    ta_movilidad, 
                    ta_alimentos,
                    ta_total
                ) VALUES (
                    dec_ID_PERSONA,  
                    JSON_UNQUOTE(JSON_EXTRACT(IN_empleado, CONCAT('$[', dec_json_empleado_index, '].sueldo_basico'))),
                    1,
                    '',
                    NOW(),
                    NOW(),
                    JSON_UNQUOTE(JSON_EXTRACT(IN_empleado, CONCAT('$[', dec_json_empleado_index, '].costo_dia'))),
                    JSON_UNQUOTE(JSON_EXTRACT(IN_empleado, CONCAT('$[', dec_json_empleado_index, '].asignacion_familiar'))),
                    JSON_UNQUOTE(JSON_EXTRACT(IN_empleado, CONCAT('$[', dec_json_empleado_index, '].bonificacion'))),
                    JSON_UNQUOTE(JSON_EXTRACT(IN_empleado, CONCAT('$[', dec_json_empleado_index, '].movilidad'))),
                    JSON_UNQUOTE(JSON_EXTRACT(IN_empleado, CONCAT('$[', dec_json_empleado_index, '].alimentos'))),
                    JSON_UNQUOTE(JSON_EXTRACT(IN_empleado, CONCAT('$[', dec_json_empleado_index, '].sueldo_total'))) 
                );
            SET dec_json_empleado_index := dec_json_empleado_index + 1;
        END WHILE;

        WHILE dec_json_pago_index < dec_json_pago_items DO

            IF JSON_EXTRACT(IN_pago, CONCAT('$[', dec_json_pago_index, '].tipo')) = 1 THEN
                 INSERT INTO persona_has_banco(
                    id_persona, 
                    id_banco, 
                    id_tpcuenta, 
                    phb_cuenta, 
                    phb_cci
                ) VALUES (
                    dec_ID_PERSONA, 
                    JSON_UNQUOTE(JSON_EXTRACT(IN_pago, CONCAT('$[', dec_json_pago_index, '].banco'))),
                    JSON_UNQUOTE(JSON_EXTRACT(IN_pago, CONCAT('$[', dec_json_pago_index, '].tipo_cuenta'))),
                    JSON_UNQUOTE(JSON_EXTRACT(IN_pago, CONCAT('$[', dec_json_pago_index, '].cuenta'))),
                    JSON_UNQUOTE(JSON_EXTRACT(IN_pago, CONCAT('$[', dec_json_pago_index, '].cuentaCi')))
                );
            ELSE

                IF NOT EXISTS(select id_persona from persona where per_documento = JSON_UNQUOTE(JSON_EXTRACT(IN_pago, CONCAT('$[', dec_json_pago_index, '].documento'))))
                THEN
                    signal sqlstate '45000' set message_text = 'La persona suplente no existe!';
                ELSE
                    INSERT INTO suplente_cobrar(
                        id_persona,   
                        suc_estado,
                        suc_origen,
                        suc_observacion
                    ) VALUES (
                        (select id_persona from persona where per_documento = JSON_UNQUOTE(JSON_EXTRACT(IN_pago, CONCAT('$[', dec_json_pago_index, '].documento')))), 
                        1,
                        dec_ID_PERSONA,
                        ''
                    );
                END if;
            END IF;

            SET dec_json_pago_index := dec_json_pago_index + 1;
        END WHILE;

ELSE
      signal sqlstate '45000' set message_text = 'ELSE => Esta persona ya esta registrada en el sistema!';
END IF; 

## RETURN TO TABLES...
COMMIT WORK;

END$$

CREATE  PROCEDURE UP_SUPERVISOR_REGISTRAR_EMPLEADOV2 (IN IN_id_tpdocumento VARCHAR(80), IN IN_id_nacionalidad INT, IN IN_per_nombre VARCHAR(80), IN IN_per_apellido_paterno VARCHAR(80), IN IN_per_apellido_materno VARCHAR(80), IN IN_per_documento VARCHAR(80), IN IN_per_fecha_nac DATE, IN IN_per_celular VARCHAR(80), IN IN_per_correo VARCHAR(80), IN IN_per_nacionalidad INT, IN IN_pe_fecha_ingreso DATE, IN IN_pe_titular INT, IN IN_pe_usuario INT, IN IN_pe_sexo VARCHAR(1), IN IN_pe_direccion VARCHAR(80), IN IN_pe_estado INT, IN IN_empleado JSON, IN IN_pago JSON)  BEGIN

## DECLARACIONES
DECLARE dec_ID_PERSONA INT;
DECLARE dec_id_tpdocumento VARCHAR(80);
DECLARE dec_id_nacionalidad INT; 

declare dia_descanso date;
declare acumulador date;
declare two_week date;
DECLARE dec_id_sueldo INT; 

DECLARE dec_json_empleado_items BIGINT UNSIGNED DEFAULT JSON_LENGTH(IN_empleado);
DECLARE dec_json_empleado_index BIGINT UNSIGNED DEFAULT 0;

DECLARE dec_json_pago_items BIGINT UNSIGNED DEFAULT JSON_LENGTH(IN_pago);
DECLARE dec_json_pago_index BIGINT UNSIGNED DEFAULT 0;
## END DECLARACIONES

## TRANSACCION
DECLARE errno INT;
DECLARE msg_errno TEXT;
DECLARE msg TEXT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET CURRENT DIAGNOSTICS CONDITION 1 errno = MYSQL_ERRNO,msg_errno = MESSAGE_TEXT ; 
            ##SELECT msg_errno  AS MYSQL_ERROR;
            set msg = concat(' ', msg_errno);
            signal sqlstate '45000' set message_text = msg;
            #signal sqlstate MYSQL_ERROR set message_text = msg_errno;
        ROLLBACK;
    END;

    START TRANSACTION;
## END TRANSACCION



IF  JSON_VALID(IN_empleado) = 0
THEN
    signal sqlstate '45000' set message_text = 'Error datos incorrectos en el empleado!';
END IF; 

IF  JSON_VALID(IN_pago) = 0
THEN
    signal sqlstate '45000' set message_text = 'Error datos incorrectos en el Pago!';
END IF; 


        IF NOT EXISTS(
            SELECT 1 FROM  persona WHERE per_documento = IN_per_documento
        )
        THEN
            INSERT INTO persona(
              id_tpdocumento, id_nacionalidad, 
              per_nombre, per_apellido_paterno, 
              per_apellido_materno, per_documento, 
              per_fecha_nac, per_celular, per_correo, 
              per_nacionalidad, pe_fecha_ingreso, 
              pe_fecha_cese, pe_titular, pe_usuario, 
              pe_sexo, pe_direccion, pe_estado
            ) 
            VALUES 
              (
                IN_id_tpdocumento, IN_id_nacionalidad, 
                IN_per_nombre, IN_per_apellido_paterno, 
                IN_per_apellido_materno, IN_per_documento, 
                IN_per_fecha_nac, IN_per_celular, 
                IN_per_correo, IN_per_nacionalidad, 
                IN_pe_fecha_ingreso, IN_pe_fecha_ingreso, 
                IN_pe_titular, IN_pe_usuario, IN_pe_sexo, 
                IN_pe_direccion, IN_pe_estado
              ); 

        SELECT LAST_INSERT_ID() INTO dec_ID_PERSONA; 

        WHILE dec_json_empleado_index < dec_json_empleado_items DO
                        INSERT INTO empleado(
                          id_persona, phc_estado, phc_fecha_r, 
                          phc_fecha_c, phc_codigo
                        ) 
                        VALUES 
                        (
                            dec_ID_PERSONA, 3, IN_pe_fecha_ingreso, 
                            IN_pe_fecha_ingreso, 'CODIGO'
                        );

                        IF JSON_UNQUOTE(JSON_EXTRACT(IN_empleado, CONCAT('$[', dec_json_empleado_index, '].cargo'))) = '3'
                        THEN
                            INSERT INTO usuario(
                              id_tpusuario, us_usuario, us_contrasenia, 
                              us_estado, us_fecha_r, us_fecha_c, 
                              us_empleado, us_persona
                            ) 
                            VALUES 
                             (
                                3, IN_per_documento, IN_per_documento, 
                                3, NOW(), NOW(), dec_ID_PERSONA, dec_ID_PERSONA
                            );
                        ELSEIF JSON_UNQUOTE(JSON_EXTRACT(IN_empleado, CONCAT('$[', dec_json_empleado_index, '].cargo'))) = '2'
                        THEN
                            INSERT INTO usuario(
                              id_tpusuario, us_usuario, us_contrasenia, 
                              us_estado, us_fecha_r, us_fecha_c, 
                              us_empleado, us_persona
                            ) 
                            VALUES 
                             (
                                2, IN_per_documento, IN_per_documento, 
                                3, NOW(), NOW(), dec_ID_PERSONA, dec_ID_PERSONA
                            );
                        ELSEIF JSON_UNQUOTE(JSON_EXTRACT(IN_empleado, CONCAT('$[', dec_json_empleado_index, '].cargo'))) = '5'
                        THEN
                            INSERT INTO usuario(
                              id_tpusuario, us_usuario, us_contrasenia, 
                              us_estado, us_fecha_r, us_fecha_c, 
                              us_empleado, us_persona
                            ) 
                            VALUES 
                             (
                                5, IN_per_documento, IN_per_documento, 
                                3, NOW(), NOW(), dec_ID_PERSONA, dec_ID_PERSONA
                            );
                        ELSEIF JSON_UNQUOTE(JSON_EXTRACT(IN_empleado, CONCAT('$[', dec_json_empleado_index, '].cargo'))) = '1'
                        THEN
                            INSERT INTO usuario(
                              id_tpusuario, us_usuario, us_contrasenia, 
                              us_estado, us_fecha_r, us_fecha_c, 
                              us_empleado, us_persona
                            ) 
                            VALUES 
                             (
                                1, IN_per_documento, IN_per_documento, 
                                3, NOW(), NOW(), dec_ID_PERSONA, dec_ID_PERSONA
                            );
                        ELSEIF JSON_UNQUOTE(JSON_EXTRACT(IN_empleado, CONCAT('$[', dec_json_empleado_index, '].cargo'))) = '4'
                        THEN
                            INSERT INTO usuario(
                              id_tpusuario, us_usuario, us_contrasenia, 
                              us_estado, us_fecha_r, us_fecha_c, 
                              us_empleado, us_persona
                            ) 
                            VALUES 
                             (
                                4, IN_per_documento, IN_per_documento, 
                                3, NOW(), NOW(), dec_ID_PERSONA, dec_ID_PERSONA
                            );
                        END IF;

                        INSERT INTO cargos_empleado(
                            id_persona, 
                            id_cargo, 
                            ce_fecha_r, 
                            ce_fecha_c, 
                            ce_estado, 
                            ce_observacion
                        )
                        VALUES (
                            dec_ID_PERSONA,
                            JSON_UNQUOTE(JSON_EXTRACT(IN_empleado, CONCAT('$[', dec_json_empleado_index, '].cargo'))),
                            IN_pe_fecha_ingreso,
                            IN_pe_fecha_ingreso,
                            1,
                            'OBSERVACION'
                        );

                        INSERT INTO sede_empleado(id_persona, id_sede, sm_codigo, sm_fecha_r, sm_fecha_c, sm_observacion, sm_estado) 
                        VALUES 
                        (
                            dec_ID_PERSONA,
                            JSON_UNQUOTE(JSON_EXTRACT(IN_empleado, CONCAT('$[', dec_json_empleado_index, '].sede'))),
                            'CODIGO',
                            IN_pe_fecha_ingreso,
                            IN_pe_fecha_ingreso,
                            'OBSERVACION',
                            1
                        );

                        INSERT INTO descanso(
                            id_persona,   
                            de_fecha, 
                            de_observacion, 
                            de_estado
                        )VALUES (
                            dec_ID_PERSONA, 
                            JSON_UNQUOTE(JSON_EXTRACT(IN_empleado, CONCAT('$[', dec_json_empleado_index, '].descanso'))),
                            '',
                            1
                        );

                        INSERT INTO sueldo(
                          id_persona, ta_basico, ta_estado, 
                          ta_observacion, ta_fecha_r, ta_fecha_c, 
                          ta_csdia, ta_asignacion_familiar, 
                          ta_bonificacion, ta_movilidad, ta_alimentos, 
                          ta_total
                        ) 
                        VALUES 
                        (
                            dec_ID_PERSONA, 0, 3, '', NOW(), NOW(), 
                            0, 0, 0, 0, 0, 0
                        ); 
                    SET dec_json_empleado_index := dec_json_empleado_index + 1;
            END WHILE;

        WHILE dec_json_pago_index < dec_json_pago_items DO

            IF JSON_UNQUOTE(JSON_EXTRACT(IN_pago, CONCAT('$[', dec_json_pago_index, '].tipo'))) = 0 THEN
              IF NOT EXISTS(select id_persona from persona where per_documento = JSON_UNQUOTE(JSON_EXTRACT(IN_pago, CONCAT('$[', dec_json_pago_index, '].documento'))))
              THEN
                  signal sqlstate '45000' set message_text = 'La persona suplente no existe!';
              ELSE
                  INSERT INTO suplente_cobrar(
                        id_persona,   
                        suc_estado,
                        suc_origen,
                        suc_observacion
                    ) VALUES (
                        (select id_persona from persona where per_documento = JSON_UNQUOTE(JSON_EXTRACT(IN_pago, CONCAT('$[', dec_json_pago_index, '].documento')))), 
                        1,
                        dec_ID_PERSONA,
                        ''
                    );
                END if;
            END IF;
            SET dec_json_pago_index := dec_json_pago_index + 1;
        END WHILE;

ELSE
      signal sqlstate '45000' set message_text = 'Esta persona ya esta registrada en el sistema!';
END IF; 

## RETURN TO TABLES...
COMMIT WORK;

END$$

CREATE  PROCEDURE UP_SUPERVISOR_REGISTRAR_SUPLENTE (IN IN_id_tpdocumento VARCHAR(80), IN IN_id_nacionalidad INT, IN IN_per_nombre VARCHAR(80), IN IN_per_apellido_paterno VARCHAR(80), IN IN_per_apellido_materno VARCHAR(80), IN IN_per_documento VARCHAR(80), IN IN_per_fecha_nac DATE, IN IN_per_celular VARCHAR(80), IN IN_per_correo VARCHAR(80), IN IN_per_nacionalidad INT, IN IN_pe_fecha_ingreso DATE, IN IN_pe_titular INT, IN IN_pe_usuario INT, IN IN_pe_sexo VARCHAR(1), IN IN_pe_direccion VARCHAR(80), IN IN_pe_estado INT, IN IN_pago JSON, IN IN_userCreacion VARCHAR(50))  BEGIN

## DECLARACIONES
DECLARE dec_ID_PERSONA INT;
DECLARE dec_id_tpdocumento VARCHAR(80);
DECLARE dec_id_nacionalidad INT; 

DECLARE dec_json_pago_items BIGINT UNSIGNED DEFAULT JSON_LENGTH(IN_pago);
DECLARE dec_json_pago_index BIGINT UNSIGNED DEFAULT 0;
## END DECLARACIONES

## TRANSACCION
    DECLARE errno INT;
    DECLARE msg_errno TEXT;
    DECLARE msg TEXT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET CURRENT DIAGNOSTICS CONDITION 1 errno = MYSQL_ERRNO,msg_errno = MESSAGE_TEXT ; 
            ##SELECT msg_errno  AS MYSQL_ERROR;
            set msg = concat('* ', msg_errno);
            signal sqlstate '45000' set message_text = msg;
            #signal sqlstate MYSQL_ERROR set message_text = msg_errno;
        ROLLBACK;
    END;

    START TRANSACTION;
## END TRANSACCION
  
IF  JSON_VALID(IN_pago) = 0
THEN
    signal sqlstate '45000' set message_text = 'Error datos incorrectos en el Pago!';
END IF; 


IF NOT EXISTS(
    SELECT 1 FROM  persona WHERE per_documento = IN_per_documento
)
THEN
    INSERT INTO persona(
            id_tpdocumento, 
            id_nacionalidad, 
            per_nombre, 
            per_apellido_paterno, 
            per_apellido_materno, 
            per_documento, 
            per_fecha_nac, 
            per_celular, 
            per_correo, 
            per_nacionalidad,
            pe_fecha_ingreso, 
            pe_fecha_cese, 
            pe_titular, 
            pe_usuario, 
            pe_sexo, 
            pe_direccion,
            pe_estado
            ,userCreacion,userModificacion
        ) VALUES 
        (
            IN_id_tpdocumento, 
            IN_id_nacionalidad, 
            IN_per_nombre, 
            IN_per_apellido_paterno, 
            IN_per_apellido_materno, 
            IN_per_documento, 
            IN_per_fecha_nac, 
            IN_per_celular, 
            IN_per_correo, 
            IN_per_nacionalidad,  
            IN_pe_fecha_ingreso, 
            IN_pe_fecha_ingreso, 
            IN_pe_titular, 
            IN_pe_usuario, 
            IN_pe_sexo, 
            IN_pe_direccion,
            IN_pe_estado
            ,IN_userCreacion
			,IN_userCreacion
        ); 

        SELECT LAST_INSERT_ID() INTO dec_ID_PERSONA; 

        WHILE dec_json_pago_index < dec_json_pago_items DO

            INSERT INTO persona_has_banco(
                    id_persona,   
                    id_banco, 
                    id_tpcuenta, 
                    phb_cuenta, 
                    phb_cci
                    ,userCreacion,userModificacion
            ) VALUES (
                    dec_ID_PERSONA, 
                    JSON_UNQUOTE(JSON_EXTRACT(IN_pago, CONCAT('$[', dec_json_pago_index, '].banco'))),
                    JSON_UNQUOTE(JSON_EXTRACT(IN_pago, CONCAT('$[', dec_json_pago_index, '].tipo_cuenta'))),
                    JSON_UNQUOTE(JSON_EXTRACT(IN_pago, CONCAT('$[', dec_json_pago_index, '].cuenta'))),
                    JSON_UNQUOTE(JSON_EXTRACT(IN_pago, CONCAT('$[', dec_json_pago_index, '].cuentaCi')))
                    ,IN_userCreacion
					,IN_userCreacion

            );

            SET dec_json_pago_index := dec_json_pago_index + 1;
        END WHILE;  

ELSE
      signal sqlstate '45000' set message_text = 'Esta persona ya está registrada en el sistema!';
END IF; 

## RETURN TO TABLES...
COMMIT WORK;

END$$

CREATE  PROCEDURE UP_VALIDAR_DESCANSO (IN IN_id_permiso INT, IN IN_id_persona INT, IN IN_id_tpdocumento VARCHAR(50), IN IN_id_nacionalidad INT, IN IN_id_cargo INT, IN IN_id_sede INT, IN IN_trs_remunerado INT, IN IN_ta_estado INT, IN IN_trs_fecha_r DATETIME, IN IN_trs_fecha_c DATETIME, IN IN_trs_usuario INT, IN IN_id_sueldo INT, IN IN_id_marcador INT)  BEGIN 
    
    DECLARE dec_pagado int;
    DECLARE dec_idMarcador int; 
    DECLARE dec_idPermiso int;
    
        IF IN_trs_remunerado = 1
        then
            set dec_pagado = 1;
        else
            set dec_pagado = 0;
        end if;
        
        IF IN_id_marcador = 6
        then
            set dec_idPermiso = IN_id_permiso;
        else
            set dec_idPermiso = 0;
        end if;

      IF IN_id_marcador = 4
        THEN

            IF  DAY(IN_trs_fecha_r) >= 1 and DAY(IN_trs_fecha_r) <= 8
            THEN 
                if EXISTS(SELECT * FROM  tareo ta
                    INNER JOIN sueldo su
                    on ta.id_sueldo = su.id_sueldo
                    where su.id_persona = IN_id_persona and date(ta.ta_fecha_r) between concat(year(IN_trs_fecha_r),'-',month(IN_trs_fecha_r),'-1') and concat(year(IN_trs_fecha_r),'-',month(IN_trs_fecha_r),'-8') and ta.id_marcador = 4
                ) 
                then
                    signal sqlstate '45000' set message_text = 'Esta persona ya cuenta con un descanso registrado en esta semana!';
                else
                
                    INSERT INTO tareo(
                      id_sede, id_cargo, id_sueldo, id_marcador, 
                      ta_remunerado, ta_estado, ta_fecha_r, 
                      ta_fecha_c, ta_hora_r, ta_hora_c, 
                      ta_hrstrabajadas, ta_usuario, ta_permiso
                    ) 
                    VALUES 
                      (
                        IN_id_sede, IN_id_cargo, IN_id_sueldo, 
                        IN_id_marcador, dec_pagado, 1, IN_trs_fecha_r, 
                        IN_trs_fecha_r, '00:00:00', '00:00:00', 
                        0, IN_trs_usuario, 0
                      );
                
                end if;
    
            ELSEIF DAY(IN_trs_fecha_r) > 8 and DAY(IN_trs_fecha_r) <= 15
            THEN 
                    if EXISTS(SELECT * FROM  tareo ta
                    INNER JOIN sueldo su
                    on ta.id_sueldo = su.id_sueldo
                    where su.id_persona = IN_id_persona and date(ta.ta_fecha_r) between concat(year(IN_trs_fecha_r),'-',month(IN_trs_fecha_r),'-9') and concat(year(IN_trs_fecha_r),'-',month(IN_trs_fecha_r),'-15') and ta.id_marcador = 4
                    ) 
                    then
                        signal sqlstate '45000' set message_text = 'Esta persona ya cuenta con un descanso registrado en esta semana!';
                    else
                
                        INSERT INTO tareo(
                          id_sede, id_cargo, id_sueldo, id_marcador, 
                          ta_remunerado, ta_estado, ta_fecha_r, 
                          ta_fecha_c, ta_hora_r, ta_hora_c, 
                          ta_hrstrabajadas, ta_usuario, ta_permiso
                        ) 
                        VALUES 
                          (
                            IN_id_sede, IN_id_cargo, IN_id_sueldo, 
                            IN_id_marcador, dec_pagado, 1, IN_trs_fecha_r, 
                            IN_trs_fecha_r, '00:00:00', '00:00:00', 
                            0, IN_trs_usuario, 0
                          );

                
                    end if;
            ELSEIF DAY(IN_trs_fecha_r) > 15 and DAY(IN_trs_fecha_r) <= 22
            THEN 
                
                    if EXISTS(SELECT * FROM  tareo ta
                        INNER JOIN sueldo su
                        on ta.id_sueldo = su.id_sueldo
                        where su.id_persona = IN_id_persona and date(ta.ta_fecha_r) between concat(year(IN_trs_fecha_r),'-',month(IN_trs_fecha_r),'-16') and concat(year(IN_trs_fecha_r),'-',month(IN_trs_fecha_r),'-22') and ta.id_marcador = 4
                    ) 
                    then
                        signal sqlstate '45000' set message_text = 'Esta persona ya cuenta con un descanso registrado en esta semana!';
                    else
                
                        INSERT INTO tareo(
                          id_sede, id_cargo, id_sueldo, id_marcador, 
                          ta_remunerado, ta_estado, ta_fecha_r, 
                          ta_fecha_c, ta_hora_r, ta_hora_c, 
                          ta_hrstrabajadas, ta_usuario, ta_permiso
                        ) 
                        VALUES 
                          (
                            IN_id_sede, IN_id_cargo, IN_id_sueldo, 
                            IN_id_marcador, dec_pagado, 1, IN_trs_fecha_r, 
                            IN_trs_fecha_r, '00:00:00', '00:00:00', 
                            0, IN_trs_usuario, 0
                        );

                
                    end if;
                
            ELSEIF DAY(IN_trs_fecha_r) > 22 and DAY(IN_trs_fecha_r) <= DAY(LAST_DAY(IN_trs_fecha_r))
            THEN
                    
                    if EXISTS(SELECT * FROM  tareo ta
                        INNER JOIN sueldo su
                        on ta.id_sueldo = su.id_sueldo
                        where su.id_persona = IN_id_persona and date(ta.ta_fecha_r) between concat(year(IN_trs_fecha_r),'-',month(IN_trs_fecha_r),'-23') and date(LAST_DAY(IN_trs_fecha_r)) and ta.id_marcador = 4
                    ) 
                    then
                        signal sqlstate '45000' set message_text = 'Esta persona ya cuenta con un descanso registrado en esta semana!';
                    else
                
                        INSERT INTO tareo(
                          id_sede, id_cargo, id_sueldo, id_marcador, 
                          ta_remunerado, ta_estado, ta_fecha_r, 
                          ta_fecha_c, ta_hora_r, ta_hora_c, 
                          ta_hrstrabajadas, ta_usuario, ta_permiso
                        ) 
                        VALUES 
                          (
                            IN_id_sede, IN_id_cargo, IN_id_sueldo, 
                            IN_id_marcador, dec_pagado, 1, IN_trs_fecha_r, 
                            IN_trs_fecha_r, '00:00:00', '00:00:00', 
                            0, IN_trs_usuario, 0
                          ); 
                    end if;
           
            END IF;

        END IF;
    
END$$

--
-- Funciones
--
CREATE  FUNCTION fun_getBanco_Mobil (IN_id_persona INT) RETURNS VARCHAR(250) CHARSET utf8 READS SQL DATA
begin
    declare  isTitular int;
    select pe_titular into isTitular from persona p where id_persona  = IN_id_persona;
    if isTitular = 1 then 
        return Coalesce((SELECT
        concat(ba.ba_abreviatura," ",ba.ba_nombre) banco
        FROM persona pe
        INNER JOIN persona_has_banco phb on phb.id_persona = pe.id_persona and phb.phb_estado = 1
        INNER JOIN banco ba on phb.id_banco = ba.id_banco 
        where pe.id_persona = IN_id_persona and pe.pe_titular = 1 limit 1),' NONE ');
    else
         RETURN coalesce((select 
        concat(ba.ba_abreviatura," ",ba.ba_nombre) banco
        from suplente_cobrar sc 
        INNER JOIN persona pe 
        on sc.suc_origen = pe.id_persona
        INNER JOIN persona pe2 on 
        sc.id_persona = pe2.id_persona
        INNER JOIN persona_has_banco phb on phb.id_persona = pe2.id_persona and phb.phb_estado = 1
        INNER JOIN banco ba on phb.id_banco = ba.id_banco
        inner join tipo_cuenta tc on phb.id_tpcuenta  = tc.id_tpcuenta 
        WHERE pe.pe_titular = 0
        and sc.suc_origen = IN_id_persona
        limit 1), ' NONE ');
    end if;  
END$$

CREATE  FUNCTION fun_getBanco_planilla (IN_id_persona INT) RETURNS VARCHAR(250) CHARSET utf8 READS SQL DATA
begin
    declare  isTitular int;
    select pe_titular into isTitular from persona p where id_persona  = IN_id_persona;
    if isTitular = 1 then 
        return Coalesce((SELECT
        concat(ba.ba_abreviatura," ",ba.ba_nombre) banco
        FROM persona pe
        INNER JOIN persona_has_banco phb on phb.id_persona = pe.id_persona and phb.phb_estado = 1
        INNER JOIN banco ba on phb.id_banco = ba.id_banco 
        where pe.id_persona = IN_id_persona and pe.pe_titular = 1 limit 1),'');
    else
         RETURN coalesce((select 
        concat(ba.ba_abreviatura," ",ba.ba_nombre) banco
        from suplente_cobrar sc 
        INNER JOIN persona pe 
        on sc.suc_origen = pe.id_persona
        INNER JOIN persona pe2 on 
        sc.id_persona = pe2.id_persona
        INNER JOIN persona_has_banco phb on phb.id_persona = pe2.id_persona and phb.phb_estado = 1
        INNER JOIN banco ba on phb.id_banco = ba.id_banco
        inner join tipo_cuenta tc on phb.id_tpcuenta  = tc.id_tpcuenta 
        WHERE pe.pe_titular = 0
        and sc.suc_origen = IN_id_persona
        limit 1), '');
    end if;  
END$$

CREATE  FUNCTION fun_getCargo_planilla (IN_id_persona INT) RETURNS VARCHAR(250) CHARSET utf8 READS SQL DATA
BEGIN
        RETURN coalesce((SELECT  
        ca.ca_descripcion
        from persona pe
        INNER JOIN cargos_empleado ce on pe.id_persona = ce.id_persona and ce.ce_estado = 1
        INNER JOIN cargo ca on ca.id_cargo = ce.id_cargo
        where pe.id_persona = IN_id_persona
        LIMIT 1), '');
END$$

CREATE  FUNCTION fun_getCci_Mobil (IN_id_persona INT) RETURNS VARCHAR(250) CHARSET utf8 READS SQL DATA
begin
    declare  isTitular int;
    select pe_titular into isTitular from persona p where id_persona  = IN_id_persona;
    if isTitular = 1 then 
        return Coalesce((SELECT
        phb.phb_cci 
        FROM persona pe
        INNER JOIN persona_has_banco phb on phb.id_persona = pe.id_persona and phb.phb_estado = 1
        INNER JOIN banco ba on phb.id_banco = ba.id_banco 
        inner join tipo_cuenta tc on phb.id_tpcuenta  = tc.id_tpcuenta 
        where pe.id_persona = IN_id_persona and pe.pe_titular = 1 limit 1),'');
    else
        RETURN coalesce((select 
        phb.phb_cci
        from suplente_cobrar sc 
        INNER JOIN persona pe 
        on sc.suc_origen = pe.id_persona
        INNER JOIN persona pe2 on 
        sc.id_persona = pe2.id_persona
        INNER JOIN persona_has_banco phb on phb.id_persona = pe2.id_persona and phb.phb_estado = 1
        INNER JOIN banco ba on phb.id_banco = ba.id_banco
        inner join tipo_cuenta tc on phb.id_tpcuenta  = tc.id_tpcuenta 
        WHERE pe.pe_titular = 0
        and sc.suc_origen = IN_id_persona
        limit 1), '');
    end if;  
END$$

CREATE  FUNCTION fun_getCci_planilla (IN_id_persona INT) RETURNS VARCHAR(250) CHARSET utf8 READS SQL DATA
begin
    declare  isTitular int;
    select pe_titular into isTitular from persona p where id_persona  = IN_id_persona;
    if isTitular = 1 then 
        return Coalesce((SELECT
        phb.phb_cci 
        FROM persona pe
        INNER JOIN persona_has_banco phb on phb.id_persona = pe.id_persona and phb.phb_estado = 1
        INNER JOIN banco ba on phb.id_banco = ba.id_banco 
        inner join tipo_cuenta tc on phb.id_tpcuenta  = tc.id_tpcuenta 
        where pe.id_persona = IN_id_persona and pe.pe_titular = 1 limit 1),'');
    else
        RETURN coalesce((select 
        phb.phb_cci
        from suplente_cobrar sc 
        INNER JOIN persona pe 
        on sc.suc_origen = pe.id_persona
        INNER JOIN persona pe2 on 
        sc.id_persona = pe2.id_persona
        INNER JOIN persona_has_banco phb on phb.id_persona = pe2.id_persona and phb.phb_estado = 1
        INNER JOIN banco ba on phb.id_banco = ba.id_banco
        inner join tipo_cuenta tc on phb.id_tpcuenta  = tc.id_tpcuenta 
        WHERE pe.pe_titular = 0
        and sc.suc_origen = IN_id_persona
        limit 1), '');
    end if;  
END$$

CREATE  FUNCTION fun_getCeseAuditoria (IN_id_persona INT, IN_opcion INT) RETURNS VARCHAR(250) CHARSET utf8 READS SQL DATA
begin
    
    RETURN coalesce((
    select 
    	case 
            when IN_opcion = 1
            then 
                ehc.userCreacion 
             when IN_opcion = 2
            then 
                 ehc.fechaCreacion 
             when IN_opcion = 3
            then 
                 ehc.userModificacion  
             when IN_opcion = 4
            then 
                 ehc.fechaModificacion  
            end 
     from empleado_has_cese ehc where ehc.id_persona  = IN_id_persona order by ehc.id_cese desc limit 1
   ), '');
    
    
END$$

CREATE  FUNCTION fun_getCostoPorDiaEmpleadoReporte (IN_id_persona INT, IN_fecha_registro DATE) RETURNS VARCHAR(250) CHARSET utf8 READS SQL DATA
begin
    
    declare dias_x_mes int;

    select EXTRACT(DAY from LAST_DAY(IN_fecha_registro)) into dias_x_mes;

    RETURN coalesce((select 
        ROUND(cast((fun_getRemuneracionBruta_planillav2(s.id_sueldo) / dias_x_mes) as decimal(9,2)), 2)
    from sueldo s where
    s.id_persona = id_persona
    and s.ta_vigenciaInicio between  s.ta_vigenciaInicio and IN_fecha_registro
    and s.ta_vigenciaFin  between IN_fecha_registro and s.ta_vigenciaFin limit 1), '');
    
    
END$$

CREATE  FUNCTION fun_getCuentas_Mobil (IN_id_persona INT) RETURNS VARCHAR(250) CHARSET utf8 READS SQL DATA
begin
    declare  isTitular int;
    select pe_titular into isTitular from persona p where id_persona  = IN_id_persona;
    if isTitular = 1 then 
        return Coalesce((SELECT
        phb.phb_cuenta 
        FROM persona pe
        INNER JOIN persona_has_banco phb on phb.id_persona = pe.id_persona and phb.phb_estado = 1
        INNER JOIN banco ba on phb.id_banco = ba.id_banco 
        where pe.id_persona = IN_id_persona and pe.pe_titular = 1 limit 1),' NONE ');
    else
         RETURN coalesce((select 
        phb.phb_cuenta 
        from suplente_cobrar sc 
        INNER JOIN persona pe 
        on sc.suc_origen = pe.id_persona
        INNER JOIN persona pe2 on 
        sc.id_persona = pe2.id_persona
        INNER JOIN persona_has_banco phb on phb.id_persona = pe2.id_persona and phb.phb_estado = 1
        INNER JOIN banco ba on phb.id_banco = ba.id_banco
        inner join tipo_cuenta tc on phb.id_tpcuenta  = tc.id_tpcuenta 
        WHERE pe.pe_titular = 0
        and sc.suc_origen = IN_id_persona
        limit 1), ' NONE ');
    end if;  
END$$

CREATE  FUNCTION fun_getCuentas_planilla (IN_id_persona INT) RETURNS VARCHAR(250) CHARSET utf8 READS SQL DATA
begin
    declare  isTitular int;
    select pe_titular into isTitular from persona p where id_persona  = IN_id_persona;
    if isTitular = 1 then 
        return Coalesce((SELECT
        phb.phb_cuenta 
        FROM persona pe
        INNER JOIN persona_has_banco phb on phb.id_persona = pe.id_persona and phb.phb_estado = 1
        INNER JOIN banco ba on phb.id_banco = ba.id_banco 
        where pe.id_persona = IN_id_persona and pe.pe_titular = 1 limit 1),'');
    else
         RETURN coalesce((select 
        phb.phb_cuenta 
        from suplente_cobrar sc 
        INNER JOIN persona pe 
        on sc.suc_origen = pe.id_persona
        INNER JOIN persona pe2 on 
        sc.id_persona = pe2.id_persona
        INNER JOIN persona_has_banco phb on phb.id_persona = pe2.id_persona and phb.phb_estado = 1
        INNER JOIN banco ba on phb.id_banco = ba.id_banco
        inner join tipo_cuenta tc on phb.id_tpcuenta  = tc.id_tpcuenta 
        WHERE pe.pe_titular = 0
        and sc.suc_origen = IN_id_persona
        limit 1), '');
    end if;  
END$$

CREATE  FUNCTION fun_getDatosSuplente_planilla (IN_id_persona INT) RETURNS VARCHAR(250) CHARSET utf8 READS SQL DATA
begin
    declare  isTitular int;
    select pe_titular into isTitular from persona p where id_persona  = IN_id_persona;
    if isTitular = 1 then 
        return '';
    else
        RETURN coalesce((select 
        concat(pe2.per_apellido_paterno," ",pe2.per_apellido_materno," ",pe2.per_nombre) as datos
        from suplente_cobrar sc 
        INNER JOIN persona pe 
        on sc.suc_origen = pe.id_persona
        INNER JOIN persona pe2 on 
        sc.id_persona = pe2.id_persona
        INNER JOIN persona_has_banco phb on phb.id_persona = pe2.id_persona and phb.phb_estado = 1
        INNER JOIN banco ba on phb.id_banco = ba.id_banco
        inner join tipo_cuenta tc on phb.id_tpcuenta  = tc.id_tpcuenta 
        WHERE pe.pe_titular = 0
        and sc.suc_origen = IN_id_persona
        limit 1), '');
    end if;  
END$$

CREATE  FUNCTION fun_getFechaIngreso_planilla (IN_id_persona INT) RETURNS VARCHAR(250) CHARSET utf8 READS SQL DATA
BEGIN
        RETURN coalesce((SELECT  
            date(pe.pe_fecha_ingreso)
        from persona pe 
        where pe.id_persona = IN_id_persona
        LIMIT 1), '');
END$$

CREATE  FUNCTION fun_getNacionalidad_planilla (IN_id_persona INT) RETURNS VARCHAR(250) CHARSET utf8 READS SQL DATA
BEGIN
        RETURN coalesce((SELECT  
        CASE when pe.id_nacionalidad = 1 then
             'L'
            ELSE
             'E'
        end
        from persona pe
        INNER JOIN tipo_documento td on pe.id_tpdocumento = td.id_tpdocumento
        where id_persona = IN_id_persona
        LIMIT 1), '');
END$$

CREATE  FUNCTION fun_getNamePersona_planilla (IN_id_persona INT) RETURNS VARCHAR(250) CHARSET utf8 READS SQL DATA
BEGIN
        RETURN coalesce((SELECT  
        upper(CONCAT(per_nombre," ",per_apellido_paterno," ",per_apellido_materno)) 
        from persona
        where id_persona = IN_id_persona LIMIT 1), '');
END$$

CREATE  FUNCTION fun_getNumeroDoc_planilla (IN_id_persona INT) RETURNS VARCHAR(250) CHARSET utf8 READS SQL DATA
BEGIN
        RETURN coalesce((SELECT  
        pe.per_documento
        from persona pe
        INNER JOIN tipo_documento td on pe.id_tpdocumento = td.id_tpdocumento
        where id_persona = IN_id_persona
        LIMIT 1), '');
END$$

CREATE  FUNCTION fun_getRemuneracionBruta_planilla (IN_id_persona INT) RETURNS VARCHAR(250) CHARSET utf8 READS SQL DATA
BEGIN
        RETURN coalesce((SELECT  
             su.ta_total as sss
        from persona pe 
        INNER JOIN sueldo su on pe.id_persona = su.id_persona
        where pe.id_persona = IN_id_persona
        LIMIT 1), '');
END$$

CREATE  FUNCTION fun_getRemuneracionBruta_planillav2 (IN_id_sueldo INT) RETURNS VARCHAR(250) CHARSET utf8 READS SQL DATA
BEGIN
        RETURN coalesce((SELECT  
             su.ta_total as sss
        from sueldo su 

        where su.id_sueldo = IN_id_sueldo
        LIMIT 1), '0');
END$$

CREATE  FUNCTION fun_getTipoCuentas_planilla (IN_id_persona INT) RETURNS VARCHAR(250) CHARSET utf8 READS SQL DATA
begin
    declare  isTitular int;
    select pe_titular into isTitular from persona p where id_persona  = IN_id_persona;
    if isTitular = 1 then 
        return Coalesce((SELECT
        tc.tpc_abreviatura 
        FROM persona pe
        INNER JOIN persona_has_banco phb on phb.id_persona = pe.id_persona and phb.phb_estado = 1
        INNER JOIN banco ba on phb.id_banco = ba.id_banco 
        inner join tipo_cuenta tc on phb.id_tpcuenta  = tc.id_tpcuenta 
        where pe.id_persona = IN_id_persona and pe.pe_titular = 1 limit 1),'');
    else
         RETURN coalesce((select 
        tc.tpc_abreviatura 
        from suplente_cobrar sc 
        INNER JOIN persona pe 
        on sc.suc_origen = pe.id_persona
        INNER JOIN persona pe2 on 
        sc.id_persona = pe2.id_persona
        INNER JOIN persona_has_banco phb on phb.id_persona = pe2.id_persona and phb.phb_estado = 1
        INNER JOIN banco ba on phb.id_banco = ba.id_banco
        inner join tipo_cuenta tc on phb.id_tpcuenta  = tc.id_tpcuenta 
        WHERE pe.pe_titular = 0
        and sc.suc_origen = IN_id_persona
        limit 1), '');
    end if;  
END$$

CREATE  FUNCTION fun_getTpDocumento_planilla (IN_id_persona INT) RETURNS VARCHAR(250) CHARSET utf8 READS SQL DATA
BEGIN
        RETURN coalesce((SELECT  
        td.tpd_abreviatura
        from persona pe
        INNER JOIN tipo_documento td on pe.id_tpdocumento = td.id_tpdocumento
        where id_persona = IN_id_persona
        LIMIT 1), '');
END$$

CREATE  FUNCTION fun_get_asistencia_by_day (IN_id_persona INT, IN_day DATE, IN_turno VARCHAR(5)) RETURNS INT(11) READS SQL DATA
begin
	
       RETURN coalesce((select 
       				case 
						when temp.maniana > 0 or  temp.tarde > 0  or temp.noche > 0
						then
							1
						when temp.falta > 0
						then
							0
						end as vino
					from (
						select 
							t.id_persona,
							if(m.id_marcador = 1, 1, 0) maniana,
							if(m.id_marcador = 2, 1, 0) tarde,
							if(m.id_marcador = 3, 1, 0) noche,
							if(m.id_marcador = 5, 1, 0) falta
						from tareo t 
						inner join marcador m 
						on t.id_marcador  = m.id_marcador 
						where 
						t.id_persona  = IN_id_persona and 
						(
							t.id_marcador not IN (4,6) and 
							t.id_marcador = 
							case 
							when IN_turno <> 'T' then
									IN_turno 
							when IN_turno = 'T' then
									t.id_marcador
							end
						) and 
						t.ta_estado = 1 and 
						date(t.ta_fecha_r) = date(IN_day) 
						#Date(t.ta_fecha_r) BETWEEN Date(IN_day) and Date(IN_day)
					) temp group by temp.id_persona
        limit 1), 0);
   
END$$

CREATE  FUNCTION fun_get_banco_gen (IN_idBanco INT) RETURNS VARCHAR(250) CHARSET utf8 READS SQL DATA
BEGIN
    RETURN coalesce((
    	select b.ba_descripcion  from banco b where b.id_banco  =  IN_idBanco
    ), '');
END$$

CREATE  FUNCTION fun_get_cantidad_permisos_gen (IN_idTpusuario INT) RETURNS VARCHAR(250) CHARSET utf8 READS SQL DATA
BEGIN
    RETURN coalesce(( 
     select count(*) from sis_perfil_modperm a where a.id_tpusuario = IN_idTpusuario and a.flEliminado = 1 
     limit 1), '0');
END$$

CREATE  FUNCTION fun_get_cargo_gen (IN_id_cargo INT) RETURNS VARCHAR(250) CHARSET utf8 READS SQL DATA
BEGIN
        RETURN coalesce((select c.ca_descripcion from cargo c where c.id_cargo = IN_id_cargo
        LIMIT 1), '');
END$$

CREATE  FUNCTION fun_get_cci_gen (IN_idPersona INT) RETURNS VARCHAR(250) CHARSET utf8 READS SQL DATA
BEGIN
    RETURN coalesce((select 
        phb.phb_cci  
        from suplente_cobrar sc 
        INNER JOIN persona pe 
        on sc.suc_origen = pe.id_persona
        INNER JOIN persona pe2 on 
        sc.id_persona = pe2.id_persona
        INNER JOIN persona_has_banco phb on phb.id_persona = pe2.id_persona and phb.phb_estado = 1
        INNER JOIN banco ba on phb.id_banco = ba.id_banco
        inner join tipo_cuenta tc on phb.id_tpcuenta  = tc.id_tpcuenta 
        WHERE pe.pe_titular = 0
        and sc.suc_origen = IN_id_persona
     limit 1), '');
END$$

CREATE  FUNCTION fun_get_cc_gen (IN_idPersona INT) RETURNS VARCHAR(250) CHARSET utf8 READS SQL DATA
BEGIN
    RETURN coalesce((select 
        phb.phb_cuenta 
        from suplente_cobrar sc 
        INNER JOIN persona pe 
        on sc.suc_origen = pe.id_persona
        INNER JOIN persona pe2 on 
        sc.id_persona = pe2.id_persona
        INNER JOIN persona_has_banco phb on phb.id_persona = pe2.id_persona and phb.phb_estado = 1
        INNER JOIN banco ba on phb.id_banco = ba.id_banco
        inner join tipo_cuenta tc on phb.id_tpcuenta  = tc.id_tpcuenta 
        WHERE pe.pe_titular = 0
        and sc.suc_origen = IN_id_persona
     limit 1), '');
END$$

CREATE  FUNCTION fun_get_documentos_empleado_gen (IN_idEmdocumento INT) RETURNS VARCHAR(250) CHARSET utf8 READS SQL DATA
BEGIN
    RETURN coalesce(( 
     select de_descripcion from documentos_empleado dc
     where dc.id_emdocumento = IN_idEmdocumento
     limit 1), '');
END$$

CREATE  FUNCTION fun_get_estado_gen (IN_estado INT) RETURNS VARCHAR(250) CHARSET utf8 READS SQL DATA
BEGIN
        RETURN coalesce((select if(IN_estado=1,'ACTIVO','INACTIVO')), '');
END$$

CREATE  FUNCTION fun_get_etapa_tareo_gen (IN_idTareo INT) RETURNS VARCHAR(250) CHARSET utf8 READS SQL DATA
BEGIN
    RETURN coalesce(( 
     select 
    	case 
    	when ta.id_marcador in(1,2,3)  and ta.ta_etapa = 0
    	then
    		'PENDIENTE POR CERRAR'
    	when ta.id_marcador in(1,2,3)  and ta.ta_etapa = 1
    	then
    		'CERRADO'
    	when ta.id_marcador in(4,5,6)  and ta.ta_etapa = 1
    	then
    		ma.ma_descripcion
    end as etapa 
    FROM
    tareo ta
    INNER JOIN marcador ma on ta.id_marcador = ma.id_marcador
    where ta.id_tareo = IN_idTareo
     limit 1), '');
END$$

CREATE  FUNCTION fun_get_fecha_indeterminado_gen (IN_fecha VARCHAR(50)) RETURNS VARCHAR(250) CHARSET utf8 READS SQL DATA
BEGIN
    RETURN coalesce((select if(IN_fecha='2100-01-01','NO DEFINIDO',IN_fecha)), '');
END$$

CREATE  FUNCTION fun_get_feCierre_tareo_gen (IN_idTareo INT) RETURNS VARCHAR(250) CHARSET utf8 READS SQL DATA
BEGIN
    RETURN coalesce(( 
     select 
    	case 
    when ta.id_marcador  = 6
    then 
        'PERMISO'
    when ta.id_marcador  =  4
    then 
        'DESCANSO'
    when ta.id_marcador  =  5
    then 
        'FALTA'
    else 
        case 
        when ta.ta_etapa  = 1
        then 
             date(ta.ta_fecha_c) 
        else
            ''
        end
    end as fecha_cierre
    FROM
    tareo ta
    INNER JOIN marcador ma on ta.id_marcador = ma.id_marcador
    where ta.id_tareo = IN_idTareo
     limit 1), '');
END$$

CREATE  FUNCTION fun_get_hcierre_tareo_gen (IN_idTareo INT) RETURNS VARCHAR(250) CHARSET utf8 READS SQL DATA
BEGIN
    RETURN coalesce(( 
     select 
    	case 
		    when ta.id_marcador  = 6
		    then 
		        'PERMISO'
		    when ta.id_marcador  =  4
		    then 
		        'DESCANSO'
		    when ta.id_marcador  =  5
		    then 
		        'FALTA'
		    else 
		        case 
		        when ta.ta_etapa  = 1
		        then 
		             ta.ta_hora_c 
		        else
		            ''
		        end
		    end as hora_cierre
    FROM
    tareo ta
    INNER JOIN marcador ma on ta.id_marcador = ma.id_marcador
    where ta.id_tareo = IN_idTareo
     limit 1), '');
END$$

CREATE  FUNCTION fun_get_marcador_tareo_gen (IN_idTareo INT) RETURNS VARCHAR(250) CHARSET utf8 READS SQL DATA
BEGIN
    RETURN coalesce(( 
     select 
    	CONCAT(ma_abreviatura," - ",ma_descripcion) AS marcador_datos
    FROM
    tareo ta
    INNER JOIN marcador ma on ta.id_marcador = ma.id_marcador
    where ta.id_tareo = IN_idTareo
     limit 1), '');
END$$

CREATE  FUNCTION fun_get_marcador_tareo_new_gen (IN_idMarcador INT) RETURNS VARCHAR(250) CHARSET utf8 READS SQL DATA
BEGIN
    RETURN coalesce(( 
     select 
    	CONCAT(ma_abreviatura," - ",ma_descripcion) AS marcador_datos
    FROM
    marcador m where m.id_marcador  = IN_idMarcador
     limit 1), '');
END$$

CREATE  FUNCTION fun_get_motivo_cese_gen (IN_idMotivo INT) RETURNS VARCHAR(250) CHARSET utf8 READS SQL DATA
BEGIN
    RETURN coalesce(( 
     select a.mo_nombre  from motivos_cese a where a.id_motivo = IN_idMotivo
     limit 1), '');
END$$

CREATE  FUNCTION fun_get_motivo_lista_negra_gen (IN_idLista INT) RETURNS VARCHAR(250) CHARSET utf8 READS SQL DATA
BEGIN
    RETURN coalesce(( 
     select a.lis_motivo  from persona_has_listanegra a where a.id_lista = IN_idLista
     limit 1), '');
END$$

CREATE  FUNCTION fun_get_nacionalidad_gen (IN_idNacionalidad INT) RETURNS VARCHAR(250) CHARSET utf8 READS SQL DATA
BEGIN
    RETURN coalesce(( 
      select  a.na_descripcion  from nacionalidad a where a.id_nacionalidad  = IN_idNacionalidad
     limit 1), '');
END$$

CREATE  FUNCTION fun_get_nombres_persona_gen (IN_idPersona INT) RETURNS VARCHAR(250) CHARSET utf8 READS SQL DATA
BEGIN
    RETURN coalesce((
    	select 
			concat(a.per_apellido_paterno," ",a.per_apellido_materno," ",a.per_nombre)
    	from persona a where a.id_persona  = IN_idPersona
    ), '');
END$$

CREATE  FUNCTION fun_get_origen_banco_gen (IN_idPersona INT) RETURNS VARCHAR(250) CHARSET utf8 READS SQL DATA
BEGIN
    RETURN coalesce((SELECT
        ba.ba_descripcion  
        FROM persona pe
        INNER JOIN persona_has_banco phb on phb.id_persona = pe.id_persona and phb.phb_estado = 1
        INNER JOIN banco ba on phb.id_banco = ba.id_banco 
        where pe.id_persona = IN_idPersona and pe.pe_titular = 1 limit 1), '');
END$$

CREATE  FUNCTION fun_get_origen_cci_gen (IN_idPersona INT) RETURNS VARCHAR(250) CHARSET utf8 READS SQL DATA
BEGIN
    RETURN coalesce((SELECT
        phb.phb_cci  
        FROM persona pe
        INNER JOIN persona_has_banco phb on phb.id_persona = pe.id_persona and phb.phb_estado = 1
        INNER JOIN banco ba on phb.id_banco = ba.id_banco 
        where pe.id_persona = IN_idPersona and pe.pe_titular = 1 limit 1), '');
END$$

CREATE  FUNCTION fun_get_origen_cuenta_gen (IN_idPersona INT) RETURNS VARCHAR(250) CHARSET utf8 READS SQL DATA
BEGIN
    RETURN coalesce((SELECT
        phb.phb_cuenta  
        FROM persona pe
        INNER JOIN persona_has_banco phb on phb.id_persona = pe.id_persona and phb.phb_estado = 1
        INNER JOIN banco ba on phb.id_banco = ba.id_banco 
        where pe.id_persona = IN_idPersona and pe.pe_titular = 1 limit 1), '');
END$$

CREATE  FUNCTION fun_get_origen_tp_cuenta_gen (IN_idPersona INT) RETURNS VARCHAR(250) CHARSET utf8 READS SQL DATA
BEGIN
    RETURN coalesce((SELECT
          tc.tpc_descripcion 
        FROM persona pe
        INNER JOIN persona_has_banco phb on phb.id_persona = pe.id_persona and phb.phb_estado = 1
        inner join tipo_cuenta tc on phb.id_tpcuenta  = tc.id_tpcuenta
        where pe.id_persona = IN_idPersona and pe.pe_titular = 1 limit 1), '');
END$$

CREATE  FUNCTION fun_get_sede_gen (IN_idSede INT) RETURNS VARCHAR(250) CHARSET utf8 READS SQL DATA
BEGIN
    RETURN coalesce((
    	select se_descripcion  from sede s where s.id_sede  = IN_idSede 
    ), '');
END$$

CREATE  FUNCTION fun_get_tipo_cuenta_gen (IN_idTpCuenta INT) RETURNS VARCHAR(250) CHARSET utf8 READS SQL DATA
BEGIN
    RETURN coalesce((
    	select tp.tpc_descripcion  from tipo_cuenta tp where tp.id_tpcuenta  = IN_idTpCuenta
    ), '');
END$$

CREATE  FUNCTION fun_get_tipo_documento_p_gen (IN_idTpdocumento VARCHAR(50)) RETURNS VARCHAR(250) CHARSET utf8 READS SQL DATA
BEGIN
    RETURN coalesce(( 
      select  a.tpd_descripcion  from tipo_documento a where a.id_tpdocumento = IN_idTpdocumento
     limit 1), '');
END$$

CREATE  FUNCTION fun_get_tipo_usuario_p_gen (IN_idTpusuario INT) RETURNS VARCHAR(250) CHARSET utf8 READS SQL DATA
BEGIN
    RETURN coalesce(( 
     select 
    	m.tpu_descripcion 
    FROM
    tipo_usuario m where m.id_tpusuario  = IN_idTpusuario
     limit 1), '');
END$$

CREATE  FUNCTION fun_get_tp_cuenta_gen (IN_idPersona INT) RETURNS VARCHAR(250) CHARSET utf8 READS SQL DATA
BEGIN
    RETURN coalesce((select 
        tc.tpc_descripcion  
        from suplente_cobrar sc 
        INNER JOIN persona pe 
        on sc.suc_origen = pe.id_persona
        INNER JOIN persona pe2 on 
        sc.id_persona = pe2.id_persona
        INNER JOIN persona_has_banco phb on phb.id_persona = pe2.id_persona and phb.phb_estado = 1
        INNER JOIN banco ba on phb.id_banco = ba.id_banco
        inner join tipo_cuenta tc on phb.id_tpcuenta  = tc.id_tpcuenta 
        WHERE pe.pe_titular = 0
        and sc.suc_origen = IN_id_persona
     limit 1), '');
END$$

CREATE  FUNCTION sp_CENSURING_DNI (input VARCHAR(255)) RETURNS VARCHAR(255) CHARSET utf8 BEGIN
    DECLARE len INT;
    DECLARE i INT;

    SET len   = CHAR_LENGTH(input);
    SET input = LOWER(input);
    SET i = 0;

    WHILE (i < len) DO
        IF (MID(input,i,1) = ' ' OR i in(1,2,3,4,5,6,7,8,9)) THEN
            IF (i < len) THEN
                SET input = CONCAT(
                    LEFT(input,i),
                    REPLACE(MID(input,i + 1,1), MID(input,i + 1,1), "*"),
                    RIGHT(input,len - i - 1)
                );
            END IF;
        END IF;
        SET i = i + 1;
    END WHILE;

    RETURN input;
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla app_version
--

CREATE TABLE app_version (
  id_version int(11) NOT NULL,
  ve_observacion text,
  ve_version varchar(5) DEFAULT NULL,
  ve_fecha datetime DEFAULT NULL,
  ve_archivo varchar(50) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Volcado de datos para la tabla app_version
--

INSERT INTO app_version (id_version, ve_observacion, ve_version, ve_fecha, ve_archivo) VALUES
(1, 'Primera versión del aplicativo', '0.01', '2021-10-03 19:47:30', 'asdasdasd'),
(2, 'Segunda correcion', '0.02', '2021-10-03 19:47:30', 'asdasdasd'),
(3, 'Segunda correcion', '0.03', '2021-10-04 19:47:30', 'asdasdasd'),
(4, 'Tercera corrección', '0.04', '2021-10-05 19:47:30', 'asdasdasd'),
(5, 'Cuarta corrección', '0.05', '2021-10-11 19:47:30', 'XD'),
(6, 'Sexta corrección', '0.06', '2021-11-24 19:47:30', 'XD'),
(7, 'Séptima corrección', '0.07', '2022-03-09 19:47:30', 'XD'),
(8, 'Séptima corrección', '0.08', '2022-03-09 19:47:30', 'XD'),
(9, 'Séptima corrección', '0.09', '2022-03-09 19:47:30', 'XD'),
(10, 'Séptima corrección', '0.10', '2022-03-18 19:47:30', 'XD'),
(11, 'Séptima corrección', '0.11', '2022-03-18 19:47:30', 'XD'),
(12, 'Séptima corrección', '0.12', '2022-03-18 19:47:30', 'XD'),
(13, 'Séptima corrección', '0.13', '2022-03-18 19:47:30', 'XD'),
(14, 'Séptima corrección', '0.14', '2022-03-18 19:47:30', 'XD');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla auditoria
--

CREATE TABLE auditoria (
  id_auditoria int(11) NOT NULL,
  id_tablas int(11) DEFAULT NULL,
  tipo_auditoria varchar(50) NOT NULL,
  old_value text NOT NULL,
  new_value text NOT NULL,
  usuario varchar(50) DEFAULT NULL,
  fecha datetime NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Volcado de datos para la tabla auditoria
--

INSERT INTO auditoria (id_auditoria, id_tablas, tipo_auditoria, old_value, new_value, usuario, fecha) VALUES
(1, 15, '1', '', 'CODIGO: [CE] NOMBRE: [Carnet de Extranjería] ABREVIATURA: [CE] LONGITUD: [20] ESTADO: [ACTIVO] FECHA: [2022-03-17 23:41:05] ', 'admin', '2022-03-17 23:41:05'),
(2, 15, '1', '', 'CODIGO: [CE] NOMBRE: [Carnet de Extranjerías] ABREVIATURA: [CE] LONGITUD: [20] ESTADO: [ACTIVO] FECHA: [2022-03-17 23:41:18] ', 'admin', '2022-03-17 23:41:18'),
(3, 15, '2', 'CODIGO: [CE] NOMBRE: [Carnet de Extranjería] ABREVIATURA: [CE] LONGITUD: [20] ESTADO: [ACTIVO] FECHA: [2022-03-17 23:41:05] ', 'CODIGO: [CE] NOMBRE: [Carnet de Extranjerías] ABREVIATURA: [CE] LONGITUD: [20] ESTADO: [ACTIVO] FECHA: [2022-03-17 23:41:18] ', 'admin', '2022-03-17 23:41:18'),
(4, 15, '1', '', 'CODIGO: [CE] NOMBRE: [Carnet de Extranjería] ABREVIATURA: [CE] LONGITUD: [20] ESTADO: [ACTIVO] FECHA: [2022-03-17 23:41:29] ', 'admin', '2022-03-17 23:41:29'),
(5, 15, '2', 'CODIGO: [CE] NOMBRE: [Carnet de Extranjerías] ABREVIATURA: [CE] LONGITUD: [20] ESTADO: [ACTIVO] FECHA: [2022-03-17 23:41:18] ', 'CODIGO: [CE] NOMBRE: [Carnet de Extranjería] ABREVIATURA: [CE] LONGITUD: [20] ESTADO: [ACTIVO] FECHA: [2022-03-17 23:41:29] ', 'admin', '2022-03-17 23:41:29'),
(6, 18, '1', '', 'CODIGO: [0] NOMBRE: [RRHH] ABREVIATURA: [RRHH] TIPO DE PERFIL: [ADM. DEL SISTEMA] ESTADO: [ACTIVO] FECHA: [2022-03-17 23:48:06] ', 'admin', '2022-03-17 23:48:06'),
(7, 16, '1', '', 'CODIGO: [0] NOMBRE: [Venezolana] ABREVIATURA: [VNZ] ESTADO: [ACTIVO] FECHA: [2022-03-17 23:48:35] ', 'admin', '2022-03-17 23:48:35'),
(8, 1, '1', '', 'CODIGO: [0] NOMBRE: [Marisol] APELLIDO P: [Pasco] APELLIDO M: [Chavez] SEXO: [1] NACIONALIDAD: [1] TIPO DOCUMENTO: [DNI] DOCUMENTO: [72260964] FECHA DE NACIMIENTO: [1999-01-20] DIRECCION: [Lima] CELULAR: [] CORREO: [] FECHA DE INGRESO: [2022-02-01 00:00:00] ', 'admin', '2022-03-17 23:52:36'),
(9, 12, '1', '', 'CODIGO: [0] PERSONA: [Pasco Chavez Marisol] USAURIO: [72260964] CONTRASEÑA: [72260964] PERFIL DE USUARIO: [ADM. DEL SISTEMA] ESTADO: [ACTIVO] FECHA: [2022-03-17 23:52:36] ', 'admin', '2022-03-17 23:52:36'),
(10, 2, '1', '', 'CODIGO: [0] CARGO: [RRHH] ESTADO: [ACTIVO] FECHA: [2022-03-17 23:52:36] ', 'admin', '2022-03-17 23:52:36'),
(11, 5, '1', '', 'CODIGO: [0] SEDE: [Hospital los Olivos] OBSERVACION: [OBSERVACION] ESTADO: [ACTIVO] FECHA: [2022-03-17 23:52:36] ', 'admin', '2022-03-17 23:52:36'),
(12, 1, '1', '', 'CODIGO: [0] NOMBRE: [Miriam] APELLIDO P: [Halanoca] APELLIDO M: [Mamani] SEXO: [1] NACIONALIDAD: [1] TIPO DOCUMENTO: [DNI] DOCUMENTO: [46480582] FECHA DE NACIMIENTO: [1990-08-22] DIRECCION: [Lima] CELULAR: [] CORREO: [] FECHA DE INGRESO: [2022-02-15 00:00:00] ', 'admin', '2022-03-17 23:53:53'),
(13, 12, '1', '', 'CODIGO: [0] PERSONA: [Halanoca Mamani Miriam] USAURIO: [46480582] CONTRASEÑA: [46480582] PERFIL DE USUARIO: [ADM. DEL SISTEMA] ESTADO: [ACTIVO] FECHA: [2022-03-17 23:53:53] ', 'admin', '2022-03-17 23:53:53'),
(14, 2, '1', '', 'CODIGO: [0] CARGO: [RRHH] ESTADO: [ACTIVO] FECHA: [2022-03-17 23:53:53] ', 'admin', '2022-03-17 23:53:53'),
(15, 5, '1', '', 'CODIGO: [0] SEDE: [Hospital los Olivos] OBSERVACION: [OBSERVACION] ESTADO: [ACTIVO] FECHA: [2022-03-17 23:53:53] ', 'admin', '2022-03-17 23:53:53'),
(16, 1, '1', '', 'CODIGO: [0] NOMBRE: [Zuleyker] APELLIDO P: [Figueroa] APELLIDO M: [Rodriguez] SEXO: [1] NACIONALIDAD: [9] TIPO DOCUMENTO: [CE] DOCUMENTO: [003909808] FECHA DE NACIMIENTO: [1988-11-18] DIRECCION: [Lima] CELULAR: [] CORREO: [] FECHA DE INGRESO: [2022-02-21 00:00:00] ', 'admin', '2022-03-17 23:55:17'),
(17, 12, '1', '', 'CODIGO: [0] PERSONA: [Figueroa Rodriguez Zuleyker] USAURIO: [003909808] CONTRASEÑA: [003909808] PERFIL DE USUARIO: [ADM. DEL SISTEMA] ESTADO: [ACTIVO] FECHA: [2022-03-17 23:55:17] ', 'admin', '2022-03-17 23:55:17'),
(18, 2, '1', '', 'CODIGO: [0] CARGO: [RRHH] ESTADO: [ACTIVO] FECHA: [2022-03-17 23:55:17] ', 'admin', '2022-03-17 23:55:17'),
(19, 5, '1', '', 'CODIGO: [0] SEDE: [Hospital los Olivos] OBSERVACION: [OBSERVACION] ESTADO: [ACTIVO] FECHA: [2022-03-17 23:55:17] ', 'admin', '2022-03-17 23:55:17'),
(20, 1, '1', '', 'CODIGO: [0] NOMBRE: [Oscarly] APELLIDO P: [Medina] APELLIDO M: [Gil] SEXO: [1] NACIONALIDAD: [9] TIPO DOCUMENTO: [CE] DOCUMENTO: [004644398] FECHA DE NACIMIENTO: [1993-10-11] DIRECCION: [Lima] CELULAR: [] CORREO: [] FECHA DE INGRESO: [2022-01-27 00:00:00] ', 'admin', '2022-03-17 23:56:16'),
(21, 12, '1', '', 'CODIGO: [0] PERSONA: [Medina Gil Oscarly] USAURIO: [004644398] CONTRASEÑA: [004644398] PERFIL DE USUARIO: [ADM. DEL SISTEMA] ESTADO: [ACTIVO] FECHA: [2022-03-17 23:56:16] ', 'admin', '2022-03-17 23:56:16'),
(22, 2, '1', '', 'CODIGO: [0] CARGO: [RRHH] ESTADO: [ACTIVO] FECHA: [2022-03-17 23:56:16] ', 'admin', '2022-03-17 23:56:16'),
(23, 5, '1', '', 'CODIGO: [0] SEDE: [Hospital los Olivos] OBSERVACION: [OBSERVACION] ESTADO: [ACTIVO] FECHA: [2022-03-17 23:56:16] ', 'admin', '2022-03-17 23:56:16'),
(24, 1, '1', '', 'CODIGO: [0] NOMBRE: [Danny] APELLIDO P: [Bolaños] APELLIDO M: [Perez] SEXO: [2] NACIONALIDAD: [1] TIPO DOCUMENTO: [DNI] DOCUMENTO: [10203040] FECHA DE NACIMIENTO: [1975-05-01] DIRECCION: [] CELULAR: [] CORREO: [] FECHA DE INGRESO: [2022-03-17 00:00:00] ', 'admin', '2022-03-17 23:57:16'),
(25, 12, '1', '', 'CODIGO: [0] PERSONA: [Bolaños Perez Danny] USAURIO: [10203040] CONTRASEÑA: [10203040] PERFIL DE USUARIO: [ADM. DEL SISTEMA] ESTADO: [ACTIVO] FECHA: [2022-03-17 23:57:16] ', 'admin', '2022-03-17 23:57:16'),
(26, 2, '1', '', 'CODIGO: [0] CARGO: [RRHH] ESTADO: [ACTIVO] FECHA: [2022-03-17 23:57:16] ', 'admin', '2022-03-17 23:57:16'),
(27, 5, '1', '', 'CODIGO: [0] SEDE: [Hospital los Olivos] OBSERVACION: [OBSERVACION] ESTADO: [ACTIVO] FECHA: [2022-03-17 23:57:16] ', 'admin', '2022-03-17 23:57:16'),
(28, 8, '1', '', 'CODIGO: [0] TIPO DE DOCUMENTO: [Documento de identidad] FECHA EMISION: [2000-04-15] FECHA DE VIGENCIA: [2023-05-31] ARCHIVO: [10203040623411823b77a.pdf] ESTADO: [ACTIVO] FECHA: [2022-03-17 23:58:42] ', 'admin', '2022-03-17 23:58:42'),
(29, 8, '1', '', 'CODIGO: [0] TIPO DE DOCUMENTO: [Documento de identidad] FECHA EMISION: [2020-10-10] FECHA DE VIGENCIA: [2025-12-31] ARCHIVO: [003909808623411d2a3da2.pdf] ESTADO: [ACTIVO] FECHA: [2022-03-18 00:00:02] ', 'admin', '2022-03-18 00:00:02'),
(30, 9, '1', '', 'CODIGO: [0] PERSONA: [Bolaños Perez Danny] MOTIVO DEL CESE: [Renuncia voluntaria] MOTIVO LISTA NEGRA: [] ESTADO: [ACTIVO] FECHA: [2022-03-18 00:01:48] ', 'admin', '2022-03-18 00:01:48'),
(31, 12, '2', 'CODIGO: [40] PERSONA: [Bolaños Perez Danny] USAURIO: [10203040] CONTRASEÑA: [10203040] PERFIL DE USUARIO: [ADM. DEL SISTEMA] ESTADO: [ACTIVO] FECHA: [2022-03-17 23:57:16] ', 'CODIGO: [40] PERSONA: [Bolaños Perez Danny] USAURIO: [10203040] CONTRASEÑA: [10203040] PERFIL DE USUARIO: [ADM. DEL SISTEMA] ESTADO: [INACTIVO] FECHA: [2022-03-18 00:01:48] ', 'admin', '2022-03-18 00:01:48'),
(32, 1, '1', '', 'CODIGO: [0] NOMBRE: [Luis] APELLIDO P: [Swayne] APELLIDO M: [Grados] SEXO: [2] NACIONALIDAD: [1] TIPO DOCUMENTO: [DNI] DOCUMENTO: [80604020] FECHA DE NACIMIENTO: [1970-04-19] DIRECCION: [] CELULAR: [] CORREO: [] FECHA DE INGRESO: [2022-01-15 00:00:00] ', 'admin', '2022-03-18 00:05:31'),
(33, 12, '1', '', 'CODIGO: [0] PERSONA: [Swayne Grados Luis] USAURIO: [80604020] CONTRASEÑA: [80604020] PERFIL DE USUARIO: [SUPERVISOR] ESTADO: [ACTIVO] FECHA: [2022-03-18 00:05:31] ', 'admin', '2022-03-18 00:05:31'),
(34, 2, '1', '', 'CODIGO: [0] CARGO: [SUPERVISOR] ESTADO: [ACTIVO] FECHA: [2022-03-18 00:05:31] ', 'admin', '2022-03-18 00:05:31'),
(35, 5, '1', '', 'CODIGO: [0] SEDE: [Hospital los Olivos] OBSERVACION: [OBSERVACION] ESTADO: [ACTIVO] FECHA: [2022-03-18 00:05:31] ', 'admin', '2022-03-18 00:05:31'),
(36, 11, '1', '', 'CODIGO: [0] PERSONA: [Swayne Grados Luis] SEDE: [Hospital los Olivos] ETAPA: [] FECHA INGRESO: [2022-03-14] HORA INGRESO: [06:07:00] FECHA CIERRE: [] HORA CIERRE: [] MARCADOR: [MA - MAÑANA] ESTADO: [ACTIVO] FECHA: [2022-03-18 00:08:33] ', '80604020', '2022-03-18 00:08:33'),
(37, 11, '2', 'CODIGO: [3] PERSONA: [Swayne Grados Luis] SEDE: [Hospital los Olivos] ETAPA: [PENDIENTE POR CERRAR] FECHA INGRESO: [2022-03-14] HORA INGRESO: [06:07:00] FECHA CIERRE: [] HORA CIERRE: [] MARCADOR: [MA - MAÑANA] ESTADO: [ACTIVO] FECHA: [2022-03-18 00:08:33] ', 'CODIGO: [3] PERSONA: [Swayne Grados Luis] SEDE: [Hospital los Olivos] ETAPA: [PENDIENTE POR CERRAR] FECHA INGRESO: [2022-03-14] HORA INGRESO: [06:07:00] FECHA CIERRE: [] HORA CIERRE: [] MARCADOR: [MA - MAÑANA] ESTADO: [ACTIVO] FECHA: [2022-03-18 00:08:33] ', '80604020', '2022-03-18 00:09:00'),
(38, 11, '1', '', 'CODIGO: [0] PERSONA: [Swayne Grados Luis] SEDE: [Hospital los Olivos] ETAPA: [] FECHA INGRESO: [2022-03-16] HORA INGRESO: [06:07:00] FECHA CIERRE: [] HORA CIERRE: [] MARCADOR: [MA - MAÑANA] ESTADO: [ACTIVO] FECHA: [2022-03-18 00:09:33] ', '80604020', '2022-03-18 00:09:33'),
(39, 11, '2', 'CODIGO: [4] PERSONA: [Swayne Grados Luis] SEDE: [Hospital los Olivos] ETAPA: [PENDIENTE POR CERRAR] FECHA INGRESO: [2022-03-16] HORA INGRESO: [06:07:00] FECHA CIERRE: [] HORA CIERRE: [] MARCADOR: [MA - MAÑANA] ESTADO: [ACTIVO] FECHA: [2022-03-18 00:09:33] ', 'CODIGO: [4] PERSONA: [Swayne Grados Luis] SEDE: [Hospital los Olivos] ETAPA: [PENDIENTE POR CERRAR] FECHA INGRESO: [2022-03-16] HORA INGRESO: [06:07:00] FECHA CIERRE: [] HORA CIERRE: [] MARCADOR: [MA - MAÑANA] ESTADO: [ACTIVO] FECHA: [2022-03-18 00:09:33] ', '80604020', '2022-03-18 00:10:07'),
(40, 17, '1', '', 'CODIGO: [0] LUGAR: [ IPD ] DESCRIPCION: [COMPLEJO IPD ] ESTADO: [ACTIVO] FECHA: [2022-03-18 06:24:25] ', '004644398', '2022-03-18 06:24:25'),
(61, 19, '1', '', 'CODIGO: [0] NOMBRE: [Ant.Policiales] DESCRIPCION: [Antecedentes Policiales] ESTADO: [INACTIVO] FECHA: [2022-03-18 07:07:03] ', 'admin', '2022-03-18 07:07:03'),
(62, 19, '1', '', 'CODIGO: [0] NOMBRE: [Ant.Penales] DESCRIPCION: [Antecedentes Penales] ESTADO: [INACTIVO] FECHA: [2022-03-18 07:07:21] ', 'admin', '2022-03-18 07:07:21'),
(63, 19, '1', '', 'CODIGO: [0] NOMBRE: [Vac.Tetano] DESCRIPCION: [Vacunacion Tetano] ESTADO: [INACTIVO] FECHA: [2022-03-18 07:08:47] ', 'admin', '2022-03-18 07:08:47'),
(64, 19, '1', '', 'CODIGO: [0] NOMBRE: [Vac.Hepatitis] DESCRIPCION: [Vacunacion Hepatitis] ESTADO: [INACTIVO] FECHA: [2022-03-18 07:09:10] ', 'admin', '2022-03-18 07:09:10'),
(65, 19, '1', '', 'CODIGO: [0] NOMBRE: [Vac.COVID] DESCRIPCION: [Vacunacion COVID] ESTADO: [INACTIVO] FECHA: [2022-03-18 07:09:25] ', 'admin', '2022-03-18 07:09:25'),
(66, 19, '1', '', 'CODIGO: [0] NOMBRE: [DJ.Estudios] DESCRIPCION: [Declaracion Jurada Estudios] ESTADO: [INACTIVO] FECHA: [2022-03-18 07:10:11] ', 'admin', '2022-03-18 07:10:11'),
(67, 19, '1', '', 'CODIGO: [0] NOMBRE: [Prueba] DESCRIPCION: [Prueba] ESTADO: [INACTIVO] FECHA: [2022-03-18 07:14:22] ', 'admin', '2022-03-18 07:14:22'),
(68, 19, '1', '', 'CODIGO: [2] NOMBRE: [Ant.Policiales] DESCRIPCION: [Antecedentes Policiales] ESTADO: [INACTIVO] FECHA: [2022-03-18 07:15:22] ', 'admin', '2022-03-18 07:15:22'),
(69, 19, '2', 'CODIGO: [2] NOMBRE: [Ant.Policiales] DESCRIPCION: [Antecedentes Policiales] ESTADO: [INACTIVO] FECHA: [2022-03-18 07:07:03] ', 'CODIGO: [2] NOMBRE: [Ant.Policiales] DESCRIPCION: [Antecedentes Policiales] ESTADO: [INACTIVO] FECHA: [2022-03-18 07:15:22] ', 'admin', '2022-03-18 07:15:22'),
(70, 19, '1', '', 'CODIGO: [2] NOMBRE: [Ant.Policiales] DESCRIPCION: [Antecedentes Policiales] ESTADO: [INACTIVO] FECHA: [2022-03-18 07:15:53] ', 'admin', '2022-03-18 07:15:53'),
(71, 19, '2', 'CODIGO: [2] NOMBRE: [Ant.Policiales] DESCRIPCION: [Antecedentes Policiales] ESTADO: [INACTIVO] FECHA: [2022-03-18 07:15:22] ', 'CODIGO: [2] NOMBRE: [Ant.Policiales] DESCRIPCION: [Antecedentes Policiales] ESTADO: [INACTIVO] FECHA: [2022-03-18 07:15:53] ', 'admin', '2022-03-18 07:15:53'),
(72, 19, '1', '', 'CODIGO: [2] NOMBRE: [Ant.Policiales] DESCRIPCION: [Antecedentes Policiales] ESTADO: [ACTIVO] FECHA: [2022-03-18 07:29:20] ', 'JVERGARA', '2022-03-18 07:29:20'),
(73, 19, '2', 'CODIGO: [2] NOMBRE: [Ant.Policiales] DESCRIPCION: [Antecedentes Policiales] ESTADO: [INACTIVO] FECHA: [2022-03-18 07:15:53] ', 'CODIGO: [2] NOMBRE: [Ant.Policiales] DESCRIPCION: [Antecedentes Policiales] ESTADO: [ACTIVO] FECHA: [2022-03-18 07:29:20] ', 'JVERGARA', '2022-03-18 07:29:20'),
(74, 19, '1', '', 'CODIGO: [0] NOMBRE: [preuba2] DESCRIPCION: [preuba2] ESTADO: [ACTIVO] FECHA: [2022-03-18 07:29:47] ', 'JVERGARA', '2022-03-18 07:29:47'),
(75, 19, '1', '', 'CODIGO: [3] NOMBRE: [Ant.Penales] DESCRIPCION: [Antecedentes Penales] ESTADO: [ACTIVO] FECHA: [2022-03-18 07:30:53] ', 'JVERGARA', '2022-03-18 07:30:53'),
(76, 19, '2', 'CODIGO: [3] NOMBRE: [Ant.Penales] DESCRIPCION: [Antecedentes Penales] ESTADO: [INACTIVO] FECHA: [2022-03-18 07:07:21] ', 'CODIGO: [3] NOMBRE: [Ant.Penales] DESCRIPCION: [Antecedentes Penales] ESTADO: [ACTIVO] FECHA: [2022-03-18 07:30:53] ', 'JVERGARA', '2022-03-18 07:30:53'),
(77, 1, '1', '', 'CODIGO: [0] NOMBRE: [ALEJANDRO JOSE] APELLIDO P: [SALAZAR ] APELLIDO M: [SALAZAR] SEXO: [2] NACIONALIDAD: [9] TIPO DOCUMENTO: [CE] DOCUMENTO: [002018776] FECHA DE NACIMIENTO: [1989-12-06] DIRECCION: [JR SAN MARTIN 3849] CELULAR: [922007239] CORREO: [] FECHA DE INGRESO: [2022-03-18 00:00:00] ', '004644398', '2022-03-18 10:38:02'),
(78, 12, '1', '', 'CODIGO: [0] PERSONA: [SALAZAR  SALAZAR ALEJANDRO JOSE] USAURIO: [002018776] CONTRASEÑA: [002018776] PERFIL DE USUARIO: [SUPERVISOR] ESTADO: [ACTIVO] FECHA: [2022-03-18 10:38:02] ', '004644398', '2022-03-18 10:38:02'),
(79, 2, '1', '', 'CODIGO: [0] CARGO: [SUPERVISOR] ESTADO: [ACTIVO] FECHA: [2022-03-18 10:38:02] ', '004644398', '2022-03-18 10:38:02'),
(80, 5, '1', '', 'CODIGO: [0] SEDE: [Hospital los Olivos] OBSERVACION: [OBSERVACION] ESTADO: [ACTIVO] FECHA: [2022-03-18 10:38:02] ', '004644398', '2022-03-18 10:38:02'),
(81, 4, '1', '', 'CODIGO: [0] DIA DESCANSO: [Domingo] OBSERVACION: [] ESTADO: [ACTIVO] FECHA: [2022-03-18 10:38:02] ', '004644398', '2022-03-18 10:38:02'),
(82, 3, '1', '', 'CODIGO: [0] VIGENCIA I: [2022-03-18] VIGENCIA F: [2022-03-31] BASICO: [1000.00] ASIGNACION FAMILIAR: [90.00] BONIFICACION: [1000.00] MOVILIDAD: [1000.00] ALIMENTOS: [1000.00] ESTADO: [ACTIVO] FECHA: [2022-03-18 10:38:02] ', '004644398', '2022-03-18 10:38:02'),
(83, 17, '1', '', 'CODIGO: [0] LUGAR: [LIMA] DESCRIPCION: [CAAT CAYETANO HEREDIA] ESTADO: [ACTIVO] FECHA: [2022-03-18 10:45:06] ', '004644398', '2022-03-18 10:45:06'),
(84, 17, '1', '', 'CODIGO: [1] LUGAR: [HOSP.HUACHO] DESCRIPCION: [CAAT HUACHO] ESTADO: [ACTIVO] FECHA: [2022-03-18 10:45:31] ', '004644398', '2022-03-18 10:45:31'),
(85, 17, '2', 'CODIGO: [1] LUGAR: [HOSP.OLIVOS] DESCRIPCION: [Hospital los Olivos] ESTADO: [ACTIVO] FECHA: [2022-03-17 20:49:59] ', 'CODIGO: [1] LUGAR: [HOSP.HUACHO] DESCRIPCION: [CAAT HUACHO] ESTADO: [ACTIVO] FECHA: [2022-03-18 10:45:31] ', '004644398', '2022-03-18 10:45:31'),
(86, 11, '1', '', 'CODIGO: [0] PERSONA: [Halanoca Mamani Miriam] SEDE: [CAAT HUACHO] ETAPA: [] FECHA INGRESO: [2022-03-18] HORA INGRESO: [00:00:00] FECHA CIERRE: [] HORA CIERRE: [] MARCADOR: [D - DESCANSO] ESTADO: [ACTIVO] FECHA: [2022-03-18 15:31:19] ', NULL, '2022-03-18 15:31:19'),
(87, 11, '4', 'CODIGO: [5] PERSONA: [Halanoca Mamani Miriam] SEDE: [CAAT HUACHO] ETAPA: [] FECHA INGRESO: [2022-03-18] HORA INGRESO: [00:00:00] FECHA CIERRE: [DESCANSO] HORA CIERRE: [DESCANSO] MARCADOR: [D - DESCANSO] ESTADO: [ACTIVO] FECHA: [2022-03-18 15:31:19] ', '', NULL, '2022-03-18 15:35:07'),
(88, 11, '1', '', 'CODIGO: [0] PERSONA: [Halanoca Mamani Miriam] SEDE: [CAAT HUACHO] ETAPA: [] FECHA INGRESO: [2022-03-18] HORA INGRESO: [00:00:00] FECHA CIERRE: [] HORA CIERRE: [] MARCADOR: [PE - PERMISO] ESTADO: [ACTIVO] FECHA: [2022-03-18 15:35:33] ', NULL, '2022-03-18 15:35:33'),
(89, 1, '1', '', 'CODIGO: [0] NOMBRE: [ELIDA ROSA] APELLIDO P: [GONZALES] APELLIDO M: [GUTIERREZ] SEXO: [1] NACIONALIDAD: [1] TIPO DOCUMENTO: [DNI] DOCUMENTO: [40588094] FECHA DE NACIMIENTO: [1980-08-23] DIRECCION: [AV. SAN ANTONIO 179 INDEPENDENCIA] CELULAR: [999338323] CORREO: [] FECHA DE INGRESO: [2022-03-18 00:00:00] ', '004644398', '2022-03-18 15:38:01'),
(90, 12, '1', '', 'CODIGO: [0] PERSONA: [GONZALES GUTIERREZ ELIDA ROSA] USAURIO: [40588094] CONTRASEÑA: [40588094] PERFIL DE USUARIO: [OPERARIO] ESTADO: [ACTIVO] FECHA: [2022-03-18 15:38:01] ', '004644398', '2022-03-18 15:38:01'),
(91, 2, '1', '', 'CODIGO: [0] CARGO: [OPERARIO] ESTADO: [ACTIVO] FECHA: [2022-03-18 15:38:01] ', '004644398', '2022-03-18 15:38:01'),
(92, 5, '1', '', 'CODIGO: [0] SEDE: [COMPLEJO IPD ] OBSERVACION: [OBSERVACION] ESTADO: [ACTIVO] FECHA: [2022-03-18 15:38:01] ', '004644398', '2022-03-18 15:38:01'),
(93, 4, '1', '', 'CODIGO: [0] DIA DESCANSO: [Jueves] OBSERVACION: [] ESTADO: [ACTIVO] FECHA: [2022-03-18 15:38:01] ', '004644398', '2022-03-18 15:38:01'),
(94, 3, '1', '', 'CODIGO: [0] VIGENCIA I: [2022-03-18] VIGENCIA F: [2022-04-30] BASICO: [1400.00] ASIGNACION FAMILIAR: [0.00] BONIFICACION: [0.00] MOVILIDAD: [0.00] ALIMENTOS: [0.00] ESTADO: [ACTIVO] FECHA: [2022-03-18 15:38:01] ', '004644398', '2022-03-18 15:38:01'),
(95, 6, '1', '', 'CODIGO: [0] BANCO: [Banco de Credito] TIPO DE CUENTA: [Propio] CUENTA: [0024587698741522] CCI: [null] ESTADO: [ACTIVO] FECHA: [2022-03-18 15:38:01] ', '004644398', '2022-03-18 15:38:01'),
(96, 8, '1', '', 'CODIGO: [0] TIPO DE DOCUMENTO: [Documento de identidad] FECHA EMISION: [2002-01-15] FECHA DE VIGENCIA: [2022-12-12] ARCHIVO: [405880946234edacb3c89.pdf] ESTADO: [ACTIVO] FECHA: [2022-03-18 15:38:04] ', '004644398', '2022-03-18 15:38:04'),
(97, 11, '1', '', 'CODIGO: [0] PERSONA: [Figueroa Rodriguez Zuleyker] SEDE: [CAAT HUACHO] ETAPA: [] FECHA INGRESO: [2022-03-18] HORA INGRESO: [00:00:00] FECHA CIERRE: [] HORA CIERRE: [] MARCADOR: [PE - PERMISO] ESTADO: [ACTIVO] FECHA: [2022-03-18 15:42:38] ', '46480582', '2022-03-18 15:42:38'),
(98, 11, '4', 'CODIGO: [7] PERSONA: [Figueroa Rodriguez Zuleyker] SEDE: [CAAT HUACHO] ETAPA: [] FECHA INGRESO: [2022-03-18] HORA INGRESO: [00:00:00] FECHA CIERRE: [PERMISO] HORA CIERRE: [PERMISO] MARCADOR: [PE - PERMISO] ESTADO: [ACTIVO] FECHA: [2022-03-18 15:42:38] ', '', '46480582', '2022-03-18 15:42:53'),
(99, 11, '1', '', 'CODIGO: [0] PERSONA: [Figueroa Rodriguez Zuleyker] SEDE: [CAAT HUACHO] ETAPA: [] FECHA INGRESO: [2022-03-18] HORA INGRESO: [00:00:00] FECHA CIERRE: [] HORA CIERRE: [] MARCADOR: [D - DESCANSO] ESTADO: [ACTIVO] FECHA: [2022-03-18 15:46:33] ', '46480582', '2022-03-18 15:46:33'),
(100, 11, '4', 'CODIGO: [8] PERSONA: [Figueroa Rodriguez Zuleyker] SEDE: [CAAT HUACHO] ETAPA: [] FECHA INGRESO: [2022-03-18] HORA INGRESO: [00:00:00] FECHA CIERRE: [DESCANSO] HORA CIERRE: [DESCANSO] MARCADOR: [D - DESCANSO] ESTADO: [ACTIVO] FECHA: [2022-03-18 15:46:33] ', '', '46480582', '2022-03-18 15:46:49'),
(101, 11, '4', 'CODIGO: [6] PERSONA: [Halanoca Mamani Miriam] SEDE: [CAAT HUACHO] ETAPA: [] FECHA INGRESO: [2022-03-18] HORA INGRESO: [00:00:00] FECHA CIERRE: [PERMISO] HORA CIERRE: [PERMISO] MARCADOR: [PE - PERMISO] ESTADO: [ACTIVO] FECHA: [2022-03-18 15:35:33] ', '', NULL, '2022-03-18 15:46:51'),
(102, 11, '1', '', 'CODIGO: [0] PERSONA: [Halanoca Mamani Miriam] SEDE: [CAAT HUACHO] ETAPA: [] FECHA INGRESO: [2022-03-18] HORA INGRESO: [15:57:00] FECHA CIERRE: [] HORA CIERRE: [] MARCADOR: [MA - MAÑANA] ESTADO: [ACTIVO] FECHA: [2022-03-18 15:58:11] ', '46480582', '2022-03-18 15:58:11'),
(103, 11, '2', 'CODIGO: [9] PERSONA: [Halanoca Mamani Miriam] SEDE: [CAAT HUACHO] ETAPA: [PENDIENTE POR CERRAR] FECHA INGRESO: [2022-03-18] HORA INGRESO: [15:57:00] FECHA CIERRE: [] HORA CIERRE: [] MARCADOR: [MA - MAÑANA] ESTADO: [ACTIVO] FECHA: [2022-03-18 15:58:11] ', 'CODIGO: [9] PERSONA: [Halanoca Mamani Miriam] SEDE: [CAAT HUACHO] ETAPA: [PENDIENTE POR CERRAR] FECHA INGRESO: [2022-03-18] HORA INGRESO: [15:57:00] FECHA CIERRE: [] HORA CIERRE: [] MARCADOR: [MA - MAÑANA] ESTADO: [ACTIVO] FECHA: [2022-03-18 15:58:11] ', '46480582', '2022-03-18 15:58:38'),
(104, 11, '4', 'CODIGO: [9] PERSONA: [Halanoca Mamani Miriam] SEDE: [CAAT HUACHO] ETAPA: [CERRADO] FECHA INGRESO: [2022-03-18] HORA INGRESO: [15:57:00] FECHA CIERRE: [2022-03-18] HORA CIERRE: [15:57:00] MARCADOR: [MA - MAÑANA] ESTADO: [ACTIVO] FECHA: [2022-03-18 15:58:11] ', '', '46480582', '2022-03-18 15:58:47'),
(105, 11, '1', '', 'CODIGO: [0] PERSONA: [Halanoca Mamani Miriam] SEDE: [CAAT HUACHO] ETAPA: [] FECHA INGRESO: [2022-03-18] HORA INGRESO: [15:57:00] FECHA CIERRE: [] HORA CIERRE: [] MARCADOR: [MA - MAÑANA] ESTADO: [ACTIVO] FECHA: [2022-03-18 15:59:24] ', '46480582', '2022-03-18 15:59:24'),
(106, 11, '2', 'CODIGO: [10] PERSONA: [Halanoca Mamani Miriam] SEDE: [CAAT HUACHO] ETAPA: [PENDIENTE POR CERRAR] FECHA INGRESO: [2022-03-18] HORA INGRESO: [15:57:00] FECHA CIERRE: [] HORA CIERRE: [] MARCADOR: [MA - MAÑANA] ESTADO: [ACTIVO] FECHA: [2022-03-18 15:59:24] ', 'CODIGO: [10] PERSONA: [Halanoca Mamani Miriam] SEDE: [CAAT HUACHO] ETAPA: [PENDIENTE POR CERRAR] FECHA INGRESO: [2022-03-18] HORA INGRESO: [15:57:00] FECHA CIERRE: [] HORA CIERRE: [] MARCADOR: [MA - MAÑANA] ESTADO: [ACTIVO] FECHA: [2022-03-18 15:59:24] ', '46480582', '2022-03-18 15:59:38'),
(107, 11, '4', 'CODIGO: [10] PERSONA: [Halanoca Mamani Miriam] SEDE: [CAAT HUACHO] ETAPA: [CERRADO] FECHA INGRESO: [2022-03-18] HORA INGRESO: [15:57:00] FECHA CIERRE: [2022-03-18] HORA CIERRE: [15:57:00] MARCADOR: [MA - MAÑANA] ESTADO: [ACTIVO] FECHA: [2022-03-18 15:59:24] ', '', '46480582', '2022-03-18 16:00:07'),
(108, 11, '1', '', 'CODIGO: [0] PERSONA: [Halanoca Mamani Miriam] SEDE: [CAAT HUACHO] ETAPA: [] FECHA INGRESO: [2022-03-18] HORA INGRESO: [00:00:00] FECHA CIERRE: [] HORA CIERRE: [] MARCADOR: [PE - PERMISO] ESTADO: [ACTIVO] FECHA: [2022-03-18 16:00:33] ', '46480582', '2022-03-18 16:00:33'),
(109, 11, '1', '', 'CODIGO: [0] PERSONA: [Halanoca Mamani Miriam] SEDE: [CAAT HUACHO] ETAPA: [] FECHA INGRESO: [2022-03-18] HORA INGRESO: [00:00:00] FECHA CIERRE: [] HORA CIERRE: [] MARCADOR: [D - DESCANSO] ESTADO: [ACTIVO] FECHA: [2022-03-18 16:01:00] ', '46480582', '2022-03-18 16:01:00'),
(110, 11, '4', 'CODIGO: [11] PERSONA: [Halanoca Mamani Miriam] SEDE: [CAAT HUACHO] ETAPA: [] FECHA INGRESO: [2022-03-18] HORA INGRESO: [00:00:00] FECHA CIERRE: [PERMISO] HORA CIERRE: [PERMISO] MARCADOR: [PE - PERMISO] ESTADO: [ACTIVO] FECHA: [2022-03-18 16:00:33] ', '', '46480582', '2022-03-18 16:01:13'),
(111, 11, '4', 'CODIGO: [12] PERSONA: [Halanoca Mamani Miriam] SEDE: [CAAT HUACHO] ETAPA: [] FECHA INGRESO: [2022-03-18] HORA INGRESO: [00:00:00] FECHA CIERRE: [DESCANSO] HORA CIERRE: [DESCANSO] MARCADOR: [D - DESCANSO] ESTADO: [ACTIVO] FECHA: [2022-03-18 16:01:00] ', '', '46480582', '2022-03-18 16:01:13'),
(112, 1, '1', '', 'CODIGO: [0] NOMBRE: [JETSSA MAGDALY ] APELLIDO P: [GOMEZ] APELLIDO M: [TROMPETERO ] SEXO: [1] NACIONALIDAD: [9] TIPO DOCUMENTO: [CE] DOCUMENTO: [004547356] FECHA DE NACIMIENTO: [1879-10-05] DIRECCION: [PUENTE PIEDRA SAN LAZARO ] CELULAR: [969798096] CORREO: [] FECHA DE INGRESO: [2022-03-02 00:00:00] ', '004644398', '2022-03-18 18:37:23'),
(113, 12, '1', '', 'CODIGO: [0] PERSONA: [GOMEZ TROMPETERO  JETSSA MAGDALY ] USAURIO: [004547356] CONTRASEÑA: [004547356] PERFIL DE USUARIO: [OPERARIO] ESTADO: [ACTIVO] FECHA: [2022-03-18 18:37:23] ', '004644398', '2022-03-18 18:37:23'),
(114, 2, '1', '', 'CODIGO: [0] CARGO: [OPERARIO] ESTADO: [ACTIVO] FECHA: [2022-03-18 18:37:23] ', '004644398', '2022-03-18 18:37:23'),
(115, 5, '1', '', 'CODIGO: [0] SEDE: [COMPLEJO IPD ] OBSERVACION: [OBSERVACION] ESTADO: [ACTIVO] FECHA: [2022-03-18 18:37:23] ', '004644398', '2022-03-18 18:37:23'),
(116, 3, '1', '', 'CODIGO: [0] VIGENCIA I: [2022-03-02] VIGENCIA F: [NO DEFINIDO] BASICO: [1400.00] ASIGNACION FAMILIAR: [0.00] BONIFICACION: [0.00] MOVILIDAD: [0.00] ALIMENTOS: [0.00] ESTADO: [ACTIVO] FECHA: [2022-03-18 18:37:23] ', '004644398', '2022-03-18 18:37:23'),
(117, 1, '1', '', 'CODIGO: [0] NOMBRE: [DANIELA NACARELIS ] APELLIDO P: [VARGAS ] APELLIDO M: [ANTEQUERA] SEXO: [1] NACIONALIDAD: [9] TIPO DOCUMENTO: [CE] DOCUMENTO: [005114915] FECHA DE NACIMIENTO: [1996-08-21] DIRECCION: [AV CAMINO REAL ] CELULAR: [917496090] CORREO: [] FECHA DE INGRESO: [2022-03-17 00:00:00] ', '004644398', '2022-03-18 18:41:02'),
(118, 12, '1', '', 'CODIGO: [0] PERSONA: [VARGAS  ANTEQUERA DANIELA NACARELIS ] USAURIO: [005114915] CONTRASEÑA: [005114915] PERFIL DE USUARIO: [OPERARIO] ESTADO: [ACTIVO] FECHA: [2022-03-18 18:41:02] ', '004644398', '2022-03-18 18:41:02'),
(119, 2, '1', '', 'CODIGO: [0] CARGO: [OPERARIO] ESTADO: [ACTIVO] FECHA: [2022-03-18 18:41:02] ', '004644398', '2022-03-18 18:41:02'),
(120, 5, '1', '', 'CODIGO: [0] SEDE: [COMPLEJO IPD ] OBSERVACION: [OBSERVACION] ESTADO: [ACTIVO] FECHA: [2022-03-18 18:41:02] ', '004644398', '2022-03-18 18:41:02'),
(121, 3, '1', '', 'CODIGO: [0] VIGENCIA I: [2022-03-18] VIGENCIA F: [NO DEFINIDO] BASICO: [1400.00] ASIGNACION FAMILIAR: [0.00] BONIFICACION: [0.00] MOVILIDAD: [0.00] ALIMENTOS: [0.00] ESTADO: [ACTIVO] FECHA: [2022-03-18 18:41:02] ', '004644398', '2022-03-18 18:41:02'),
(122, 1, '1', '', 'CODIGO: [0] NOMBRE: [YUNELLY LIESKA ] APELLIDO P: [DIAZ ] APELLIDO M: [PEREIRA ] SEXO: [1] NACIONALIDAD: [9] TIPO DOCUMENTO: [CE] DOCUMENTO: [004850867] FECHA DE NACIMIENTO: [2022-02-10] DIRECCION: [AV NARANJAL ON UNIVERSITARIA ] CELULAR: [] CORREO: [] FECHA DE INGRESO: [2022-03-18 00:00:00] ', '004644398', '2022-03-18 18:43:42'),
(123, 12, '1', '', 'CODIGO: [0] PERSONA: [DIAZ  PEREIRA  YUNELLY LIESKA ] USAURIO: [004850867] CONTRASEÑA: [004850867] PERFIL DE USUARIO: [OPERARIO] ESTADO: [ACTIVO] FECHA: [2022-03-18 18:43:42] ', '004644398', '2022-03-18 18:43:42'),
(124, 2, '1', '', 'CODIGO: [0] CARGO: [OPERARIO] ESTADO: [ACTIVO] FECHA: [2022-03-18 18:43:42] ', '004644398', '2022-03-18 18:43:42'),
(125, 5, '1', '', 'CODIGO: [0] SEDE: [COMPLEJO IPD ] OBSERVACION: [OBSERVACION] ESTADO: [ACTIVO] FECHA: [2022-03-18 18:43:42] ', '004644398', '2022-03-18 18:43:42'),
(126, 8, '1', '', 'CODIGO: [0] TIPO DE DOCUMENTO: [Documento de identidad] FECHA EMISION: [NO DEFINIDO] FECHA DE VIGENCIA: [NO DEFINIDO] ARCHIVO: [00485086762351d703ff2c.pdf] ESTADO: [ACTIVO] FECHA: [2022-03-18 19:01:52] ', '004644398', '2022-03-18 19:01:52'),
(127, 8, '2', 'CODIGO: [38] TIPO DE DOCUMENTO: [Documento de identidad] FECHA EMISION: [NO DEFINIDO] FECHA DE VIGENCIA: [NO DEFINIDO] ARCHIVO: [00485086762351d703ff2c.pdf] ESTADO: [ACTIVO] FECHA: [2022-03-18 19:01:52] ', 'CODIGO: [38] TIPO DE DOCUMENTO: [Documento de identidad] FECHA EMISION: [NO DEFINIDO] FECHA DE VIGENCIA: [NO DEFINIDO] ARCHIVO: [00485086762351d703ff2c.pdf] ESTADO: [INACTIVO] FECHA: [2022-03-18 19:01:52] ', '004644398', '2022-03-18 19:02:02'),
(128, 8, '1', '', 'CODIGO: [0] TIPO DE DOCUMENTO: [Antecedentes Policiales] FECHA EMISION: [NO DEFINIDO] FECHA DE VIGENCIA: [NO DEFINIDO] ARCHIVO: [00485086762351d83b5607.pdf] ESTADO: [ACTIVO] FECHA: [2022-03-18 19:02:11] ', '004644398', '2022-03-18 19:02:11'),
(129, 8, '1', '', 'CODIGO: [0] TIPO DE DOCUMENTO: [Antecedentes Penales] FECHA EMISION: [NO DEFINIDO] FECHA DE VIGENCIA: [NO DEFINIDO] ARCHIVO: [00485086762351d9b2a02a.pdf] ESTADO: [ACTIVO] FECHA: [2022-03-18 19:02:35] ', '004644398', '2022-03-18 19:02:35'),
(130, 8, '1', '', 'CODIGO: [0] TIPO DE DOCUMENTO: [Documento de identidad] FECHA EMISION: [NO DEFINIDO] FECHA DE VIGENCIA: [NO DEFINIDO] ARCHIVO: [00485086762351e219591d.pdf] ESTADO: [ACTIVO] FECHA: [2022-03-18 19:04:49] ', '004644398', '2022-03-18 19:04:49'),
(131, 8, '2', 'CODIGO: [41] TIPO DE DOCUMENTO: [Documento de identidad] FECHA EMISION: [NO DEFINIDO] FECHA DE VIGENCIA: [NO DEFINIDO] ARCHIVO: [00485086762351e219591d.pdf] ESTADO: [ACTIVO] FECHA: [2022-03-18 19:04:49] ', 'CODIGO: [41] TIPO DE DOCUMENTO: [Documento de identidad] FECHA EMISION: [NO DEFINIDO] FECHA DE VIGENCIA: [NO DEFINIDO] ARCHIVO: [00485086762351e219591d.pdf] ESTADO: [INACTIVO] FECHA: [2022-03-18 19:04:49] ', '004644398', '2022-03-18 19:05:37'),
(132, 8, '1', '', 'CODIGO: [0] TIPO DE DOCUMENTO: [Documento de identidad] FECHA EMISION: [NO DEFINIDO] FECHA DE VIGENCIA: [NO DEFINIDO] ARCHIVO: [00485086762351e8927a51.pdf] ESTADO: [ACTIVO] FECHA: [2022-03-18 19:06:33] ', '004644398', '2022-03-18 19:06:33'),
(133, 8, '1', '', 'CODIGO: [0] TIPO DE DOCUMENTO: [Antecedentes Policiales] FECHA EMISION: [NO DEFINIDO] FECHA DE VIGENCIA: [NO DEFINIDO] ARCHIVO: [4058809462351f43d48d0.pdf] ESTADO: [ACTIVO] FECHA: [2022-03-18 19:09:39] ', '004644398', '2022-03-18 19:09:39'),
(134, 8, '2', 'CODIGO: [43] TIPO DE DOCUMENTO: [Antecedentes Policiales] FECHA EMISION: [NO DEFINIDO] FECHA DE VIGENCIA: [NO DEFINIDO] ARCHIVO: [4058809462351f43d48d0.pdf] ESTADO: [ACTIVO] FECHA: [2022-03-18 19:09:39] ', 'CODIGO: [43] TIPO DE DOCUMENTO: [Antecedentes Policiales] FECHA EMISION: [NO DEFINIDO] FECHA DE VIGENCIA: [2022-06-13] ARCHIVO: [4058809462351f43d48d0.pdf] ESTADO: [ACTIVO] FECHA: [2022-03-18 19:09:39] ', '004644398', '2022-03-18 19:10:13'),
(135, 8, '2', 'CODIGO: [43] TIPO DE DOCUMENTO: [Antecedentes Policiales] FECHA EMISION: [NO DEFINIDO] FECHA DE VIGENCIA: [2022-06-13] ARCHIVO: [4058809462351f43d48d0.pdf] ESTADO: [ACTIVO] FECHA: [2022-03-18 19:09:39] ', 'CODIGO: [43] TIPO DE DOCUMENTO: [Antecedentes Policiales] FECHA EMISION: [NO DEFINIDO] FECHA DE VIGENCIA: [2022-06-13] ARCHIVO: [4058809462351f43d48d0.pdf] ESTADO: [INACTIVO] FECHA: [2022-03-18 19:09:39] ', '004644398', '2022-03-18 19:10:35'),
(136, 8, '1', '', 'CODIGO: [0] TIPO DE DOCUMENTO: [Antecedentes Penales] FECHA EMISION: [NO DEFINIDO] FECHA DE VIGENCIA: [NO DEFINIDO] ARCHIVO: [4058809462351f864c77f.pdf] ESTADO: [ACTIVO] FECHA: [2022-03-18 19:10:46] ', '004644398', '2022-03-18 19:10:46'),
(137, 8, '2', 'CODIGO: [44] TIPO DE DOCUMENTO: [Antecedentes Penales] FECHA EMISION: [NO DEFINIDO] FECHA DE VIGENCIA: [NO DEFINIDO] ARCHIVO: [4058809462351f864c77f.pdf] ESTADO: [ACTIVO] FECHA: [2022-03-18 19:10:46] ', 'CODIGO: [44] TIPO DE DOCUMENTO: [Antecedentes Penales] FECHA EMISION: [NO DEFINIDO] FECHA DE VIGENCIA: [2022-06-13] ARCHIVO: [4058809462351f864c77f.pdf] ESTADO: [ACTIVO] FECHA: [2022-03-18 19:10:46] ', '004644398', '2022-03-18 19:10:57'),
(138, 8, '2', 'CODIGO: [44] TIPO DE DOCUMENTO: [Antecedentes Penales] FECHA EMISION: [NO DEFINIDO] FECHA DE VIGENCIA: [2022-06-13] ARCHIVO: [4058809462351f864c77f.pdf] ESTADO: [ACTIVO] FECHA: [2022-03-18 19:10:46] ', 'CODIGO: [44] TIPO DE DOCUMENTO: [Antecedentes Penales] FECHA EMISION: [2022-03-15] FECHA DE VIGENCIA: [2022-06-13] ARCHIVO: [4058809462351f864c77f.pdf] ESTADO: [ACTIVO] FECHA: [2022-03-18 19:10:46] ', '004644398', '2022-03-18 19:11:25'),
(139, 1, '1', '', 'CODIGO: [0] NOMBRE: [ELIZABET ] APELLIDO P: [RENGEL] APELLIDO M: [GONZALES] SEXO: [1] NACIONALIDAD: [9] TIPO DOCUMENTO: [CE] DOCUMENTO: [003488713] FECHA DE NACIMIENTO: [1987-04-06] DIRECCION: [CALLE GARDENIAS 887] CELULAR: [985123654] CORREO: [ELIZBG@HOTMAIL.COM] FECHA DE INGRESO: [2022-01-16 00:00:00] ', '46480582', '2022-03-18 22:45:23'),
(140, 6, '1', '', 'CODIGO: [0] BANCO: [Banco de Credito] TIPO DE CUENTA: [Propio] CUENTA: [000012354525] CCI: [] ESTADO: [ACTIVO] FECHA: [2022-03-18 22:45:23] ', '46480582', '2022-03-18 22:45:23'),
(141, 17, '1', '', 'CODIGO: [0] LUGAR: [HOSPITAL LANFRANCO] DESCRIPCION: [PACIENTES COVID] ESTADO: [ACTIVO] FECHA: [2022-03-18 22:54:33] ', '46480582', '2022-03-18 22:54:33'),
(142, 18, '1', '', 'CODIGO: [0] NOMBRE: [ELIZABETH RENGEL GONZALES] ABREVIATURA: [ERG] TIPO DE PERFIL: [SUPERVISOR] ESTADO: [ACTIVO] FECHA: [2022-03-18 22:55:57] ', '46480582', '2022-03-18 22:55:57'),
(143, 6, '2', 'CODIGO: [2] BANCO: [Banco de Credito] TIPO DE CUENTA: [Propio] CUENTA: [000012354525] CCI: [] ESTADO: [ACTIVO] FECHA: [2022-03-18 22:45:23] ', 'CODIGO: [2] BANCO: [Banco de Credito] TIPO DE CUENTA: [Propio] CUENTA: [000012354525] CCI: [] ESTADO: [INACTIVO] FECHA: [2022-03-18 22:45:23] ', '46480582', '2022-03-18 23:10:43'),
(144, 6, '1', '', 'CODIGO: [2] BANCO: [Banco de Credito] TIPO DE CUENTA: [Propio] CUENTA: [000012354525] CCI: [] ESTADO: [ACTIVO] FECHA: [2022-03-18 23:10:43] ', '46480582', '2022-03-18 23:10:43'),
(145, 6, '2', 'CODIGO: [2] BANCO: [Banco de Credito] TIPO DE CUENTA: [Propio] CUENTA: [000012354525] CCI: [] ESTADO: [INACTIVO] FECHA: [2022-03-18 23:10:43] ', 'CODIGO: [2] BANCO: [Banco de Credito] TIPO DE CUENTA: [Propio] CUENTA: [000012354525] CCI: [] ESTADO: [ACTIVO] FECHA: [2022-03-18 22:45:23] ', '46480582', '2022-03-18 23:10:43'),
(146, 6, '2', 'CODIGO: [2] BANCO: [Banco de Credito] TIPO DE CUENTA: [Propio] CUENTA: [000012354525] CCI: [] ESTADO: [ACTIVO] FECHA: [2022-03-18 23:10:43] ', 'CODIGO: [2] BANCO: [Banco de Credito] TIPO DE CUENTA: [Propio] CUENTA: [000012354525] CCI: [] ESTADO: [INACTIVO] FECHA: [2022-03-18 22:45:23] ', '46480582', '2022-03-18 23:11:57'),
(147, 6, '1', '', 'CODIGO: [2] BANCO: [Banco de Credito] TIPO DE CUENTA: [Propio] CUENTA: [000012354525] CCI: [] ESTADO: [ACTIVO] FECHA: [2022-03-18 23:11:57] ', '46480582', '2022-03-18 23:11:57'),
(148, 6, '2', 'CODIGO: [2] BANCO: [Banco de Credito] TIPO DE CUENTA: [Propio] CUENTA: [000012354525] CCI: [] ESTADO: [INACTIVO] FECHA: [2022-03-18 23:11:57] ', 'CODIGO: [2] BANCO: [Banco de Credito] TIPO DE CUENTA: [Propio] CUENTA: [000012354525] CCI: [] ESTADO: [ACTIVO] FECHA: [2022-03-18 22:45:23] ', '46480582', '2022-03-18 23:11:57'),
(149, 17, '1', '', 'CODIGO: [0] LUGAR: [LANFRANCO] DESCRIPCION: [COVID] ESTADO: [ACTIVO] FECHA: [2022-03-18 23:19:28] ', '46480582', '2022-03-18 23:19:28'),
(150, 1, '1', '', 'CODIGO: [0] NOMBRE: [ANA] APELLIDO P: [MALCA] APELLIDO M: [ROJAS] SEXO: [1] NACIONALIDAD: [1] TIPO DOCUMENTO: [DNI] DOCUMENTO: [48256987] FECHA DE NACIMIENTO: [1990-03-18] DIRECCION: [] CELULAR: [985264588] CORREO: [] FECHA DE INGRESO: [2022-03-17 00:00:00] ', '46480582', '2022-03-18 23:23:54'),
(151, 12, '1', '', 'CODIGO: [0] PERSONA: [MALCA ROJAS ANA] USAURIO: [48256987] CONTRASEÑA: [48256987] PERFIL DE USUARIO: [SUPERVISOR] ESTADO: [ACTIVO] FECHA: [2022-03-18 23:23:54] ', '46480582', '2022-03-18 23:23:54'),
(152, 2, '1', '', 'CODIGO: [0] CARGO: [SUPERVISOR] ESTADO: [ACTIVO] FECHA: [2022-03-18 23:23:54] ', '46480582', '2022-03-18 23:23:54'),
(153, 5, '1', '', 'CODIGO: [0] SEDE: [PACIENTES COVID] OBSERVACION: [OBSERVACION] ESTADO: [ACTIVO] FECHA: [2022-03-18 23:23:54] ', '46480582', '2022-03-18 23:23:54'),
(154, 4, '1', '', 'CODIGO: [0] DIA DESCANSO: [Jueves] OBSERVACION: [] ESTADO: [ACTIVO] FECHA: [2022-03-18 23:23:54] ', '46480582', '2022-03-18 23:23:54'),
(155, 4, '2', 'CODIGO: [3] DIA DESCANSO: [Jueves] OBSERVACION: [] ESTADO: [ACTIVO] FECHA: [2022-03-18 23:23:54] ', 'CODIGO: [3] DIA DESCANSO: [Jueves] OBSERVACION: [] ESTADO: [INACTIVO] FECHA: [2022-03-18 23:23:54] ', '46480582', '2022-03-18 23:24:53'),
(156, 4, '1', '', 'CODIGO: [0] DIA DESCANSO: [Martes] OBSERVACION: [PERSONAL NUEVO] ESTADO: [ACTIVO] FECHA: [2022-03-18 23:24:53] ', '46480582', '2022-03-18 23:24:53'),
(157, 2, '2', 'CODIGO: [37] CARGO: [SUPERVISOR] ESTADO: [ACTIVO] FECHA: [2022-03-18 23:23:54] ', 'CODIGO: [37] CARGO: [SUPERVISOR] ESTADO: [INACTIVO] FECHA: [2022-03-18 23:23:54] ', '46480582', '2022-03-18 23:25:25'),
(158, 2, '1', '', 'CODIGO: [0] CARGO: [OPERARIO] ESTADO: [ACTIVO] FECHA: [2022-03-18 23:25:25] ', '46480582', '2022-03-18 23:25:25'),
(159, 12, '2', 'CODIGO: [51] PERSONA: [MALCA ROJAS ANA] USAURIO: [48256987] CONTRASEÑA: [48256987] PERFIL DE USUARIO: [SUPERVISOR] ESTADO: [ACTIVO] FECHA: [2022-03-18 23:23:54] ', 'CODIGO: [51] PERSONA: [MALCA ROJAS ANA] USAURIO: [48256987] CONTRASEÑA: [48256987] PERFIL DE USUARIO: [OPERARIO] ESTADO: [ACTIVO] FECHA: [2022-03-18 23:25:25] ', '46480582', '2022-03-18 23:25:25'),
(160, 5, '1', '', 'CODIGO: [0] SEDE: [COVID] OBSERVACION: [] ESTADO: [ACTIVO] FECHA: [2022-03-18 23:25:47] ', '46480582', '2022-03-18 23:25:47'),
(161, 6, '1', '', 'CODIGO: [0] BANCO: [Banco de Credito] TIPO DE CUENTA: [Propio] CUENTA: [45645216] CCI: [] ESTADO: [ACTIVO] FECHA: [2022-03-18 23:26:07] ', '46480582', '2022-03-18 23:26:07'),
(162, 8, '1', '', 'CODIGO: [0] TIPO DE DOCUMENTO: [Documento de identidad] FECHA EMISION: [2011-04-22] FECHA DE VIGENCIA: [2023-02-10] ARCHIVO: [4825698762355c7e6647d.pdf] ESTADO: [ACTIVO] FECHA: [2022-03-18 23:30:54] ', '46480582', '2022-03-18 23:30:54'),
(163, 8, '1', '', 'CODIGO: [0] TIPO DE DOCUMENTO: [Antecedentes Policiales] FECHA EMISION: [NO DEFINIDO] FECHA DE VIGENCIA: [NO DEFINIDO] ARCHIVO: [4825698762355ca92a964.pdf] ESTADO: [ACTIVO] FECHA: [2022-03-18 23:31:37] ', '46480582', '2022-03-18 23:31:37'),
(164, 8, '1', '', 'CODIGO: [0] TIPO DE DOCUMENTO: [Antecedentes Penales] FECHA EMISION: [NO DEFINIDO] FECHA DE VIGENCIA: [NO DEFINIDO] ARCHIVO: [4825698762355cb38745a.pdf] ESTADO: [ACTIVO] FECHA: [2022-03-18 23:31:47] ', '46480582', '2022-03-18 23:31:47'),
(165, 1, '1', '', 'CODIGO: [0] NOMBRE: [DOLORES] APELLIDO P: [MEJIA ] APELLIDO M: [RIOS] SEXO: [1] NACIONALIDAD: [1] TIPO DOCUMENTO: [DNI] DOCUMENTO: [45826874] FECHA DE NACIMIENTO: [1992-03-18] DIRECCION: [] CELULAR: [985647892] CORREO: [] FECHA DE INGRESO: [2022-03-18 00:00:00] ', '46480582', '2022-03-18 23:33:59'),
(166, 12, '1', '', 'CODIGO: [0] PERSONA: [MEJIA  RIOS DOLORES] USAURIO: [45826874] CONTRASEÑA: [45826874] PERFIL DE USUARIO: [SUPERVISOR] ESTADO: [ACTIVO] FECHA: [2022-03-18 23:33:59] ', '46480582', '2022-03-18 23:33:59'),
(167, 2, '1', '', 'CODIGO: [0] CARGO: [SUPERVISOR] ESTADO: [ACTIVO] FECHA: [2022-03-18 23:33:59] ', '46480582', '2022-03-18 23:33:59'),
(168, 5, '1', '', 'CODIGO: [0] SEDE: [PACIENTES COVID] OBSERVACION: [OBSERVACION] ESTADO: [ACTIVO] FECHA: [2022-03-18 23:33:59] ', '46480582', '2022-03-18 23:33:59'),
(169, 2, '2', 'CODIGO: [39] CARGO: [SUPERVISOR] ESTADO: [ACTIVO] FECHA: [2022-03-18 23:33:59] ', 'CODIGO: [39] CARGO: [SUPERVISOR] ESTADO: [INACTIVO] FECHA: [2022-03-18 23:33:59] ', '46480582', '2022-03-18 23:35:41'),
(170, 2, '1', '', 'CODIGO: [0] CARGO: [OPERARIO] ESTADO: [ACTIVO] FECHA: [2022-03-18 23:35:41] ', '46480582', '2022-03-18 23:35:41'),
(171, 12, '2', 'CODIGO: [52] PERSONA: [MEJIA  RIOS DOLORES] USAURIO: [45826874] CONTRASEÑA: [45826874] PERFIL DE USUARIO: [SUPERVISOR] ESTADO: [ACTIVO] FECHA: [2022-03-18 23:33:59] ', 'CODIGO: [52] PERSONA: [MEJIA  RIOS DOLORES] USAURIO: [45826874] CONTRASEÑA: [45826874] PERFIL DE USUARIO: [OPERARIO] ESTADO: [ACTIVO] FECHA: [2022-03-18 23:35:41] ', '46480582', '2022-03-18 23:35:41'),
(172, 5, '1', '', 'CODIGO: [0] SEDE: [COVID] OBSERVACION: [] ESTADO: [ACTIVO] FECHA: [2022-03-18 23:36:20] ', '46480582', '2022-03-18 23:36:20'),
(173, 8, '1', '', 'CODIGO: [0] TIPO DE DOCUMENTO: [Documento de identidad] FECHA EMISION: [NO DEFINIDO] FECHA DE VIGENCIA: [NO DEFINIDO] ARCHIVO: [4582687462355dd601d2e.pdf] ESTADO: [ACTIVO] FECHA: [2022-03-18 23:36:38] ', '46480582', '2022-03-18 23:36:38'),
(174, 8, '1', '', 'CODIGO: [0] TIPO DE DOCUMENTO: [Antecedentes Policiales] FECHA EMISION: [NO DEFINIDO] FECHA DE VIGENCIA: [NO DEFINIDO] ARCHIVO: [4582687462355de08fa1d.pdf] ESTADO: [ACTIVO] FECHA: [2022-03-18 23:36:48] ', '46480582', '2022-03-18 23:36:48'),
(175, 8, '1', '', 'CODIGO: [0] TIPO DE DOCUMENTO: [Antecedentes Penales] FECHA EMISION: [NO DEFINIDO] FECHA DE VIGENCIA: [NO DEFINIDO] ARCHIVO: [4582687462355dec746a4.pdf] ESTADO: [ACTIVO] FECHA: [2022-03-18 23:37:00] ', '46480582', '2022-03-18 23:37:00'),
(176, 1, '1', '', 'CODIGO: [0] NOMBRE: [Paola] APELLIDO P: [Suyon] APELLIDO M: [Perez] SEXO: [1] NACIONALIDAD: [9] TIPO DOCUMENTO: [CE] DOCUMENTO: [12344321] FECHA DE NACIMIENTO: [2000-01-10] DIRECCION: [] CELULAR: [] CORREO: [] FECHA DE INGRESO: [2022-03-19 00:00:00] ', 'admin', '2022-03-19 10:27:03'),
(177, 12, '1', '', 'CODIGO: [0] PERSONA: [Suyon Perez Paola] USAURIO: [12344321] CONTRASEÑA: [12344321] PERFIL DE USUARIO: [SUPERVISOR] ESTADO: [ACTIVO] FECHA: [2022-03-19 10:27:03] ', 'admin', '2022-03-19 10:27:03'),
(178, 2, '1', '', 'CODIGO: [0] CARGO: [SUPERVISOR] ESTADO: [ACTIVO] FECHA: [2022-03-19 10:27:03] ', 'admin', '2022-03-19 10:27:03'),
(179, 5, '1', '', 'CODIGO: [0] SEDE: [CAAT HUACHO] OBSERVACION: [OBSERVACION] ESTADO: [ACTIVO] FECHA: [2022-03-19 10:27:03] ', 'admin', '2022-03-19 10:27:03'),
(180, 8, '2', 'CODIGO: [42] TIPO DE DOCUMENTO: [Documento de identidad] FECHA EMISION: [NO DEFINIDO] FECHA DE VIGENCIA: [NO DEFINIDO] ARCHIVO: [00485086762351e8927a51.pdf] ESTADO: [ACTIVO] FECHA: [2022-03-18 19:06:33] ', 'CODIGO: [42] TIPO DE DOCUMENTO: [Documento de identidad] FECHA EMISION: [NO DEFINIDO] FECHA DE VIGENCIA: [2020-03-15] ARCHIVO: [00485086762351e8927a51.pdf] ESTADO: [ACTIVO] FECHA: [2022-03-18 19:06:33] ', '004644398', '2022-03-19 10:35:58'),
(181, 8, '2', 'CODIGO: [40] TIPO DE DOCUMENTO: [Antecedentes Penales] FECHA EMISION: [NO DEFINIDO] FECHA DE VIGENCIA: [NO DEFINIDO] ARCHIVO: [00485086762351d9b2a02a.pdf] ESTADO: [ACTIVO] FECHA: [2022-03-18 19:02:35] ', 'CODIGO: [40] TIPO DE DOCUMENTO: [Antecedentes Penales] FECHA EMISION: [NO DEFINIDO] FECHA DE VIGENCIA: [2020-02-01] ARCHIVO: [00485086762351d9b2a02a.pdf] ESTADO: [ACTIVO] FECHA: [2022-03-18 19:02:35] ', '004644398', '2022-03-19 10:36:11'),
(182, 2, '2', 'CODIGO: [41] CARGO: [SUPERVISOR] ESTADO: [ACTIVO] FECHA: [2022-03-19 10:27:03] ', 'CODIGO: [41] CARGO: [SUPERVISOR] ESTADO: [INACTIVO] FECHA: [2022-03-19 10:27:03] ', 'admin', '2022-03-19 11:02:56'),
(183, 2, '1', '', 'CODIGO: [0] CARGO: [OPERARIO] ESTADO: [ACTIVO] FECHA: [2022-03-19 11:02:56] ', 'admin', '2022-03-19 11:02:56'),
(184, 12, '2', 'CODIGO: [53] PERSONA: [Suyon Perez Paola] USAURIO: [12344321] CONTRASEÑA: [12344321] PERFIL DE USUARIO: [SUPERVISOR] ESTADO: [ACTIVO] FECHA: [2022-03-19 10:27:03] ', 'CODIGO: [53] PERSONA: [Suyon Perez Paola] USAURIO: [12344321] CONTRASEÑA: [12344321] PERFIL DE USUARIO: [OPERARIO] ESTADO: [ACTIVO] FECHA: [2022-03-19 11:02:56] ', 'admin', '2022-03-19 11:02:56'),
(185, 11, '1', '', 'CODIGO: [0] PERSONA: [Suyon Perez Paola] SEDE: [CAAT HUACHO] ETAPA: [] FECHA INGRESO: [2022-03-18] HORA INGRESO: [11:03:00] FECHA CIERRE: [] HORA CIERRE: [] MARCADOR: [MA - MAÑANA] ESTADO: [ACTIVO] FECHA: [2022-03-19 11:04:19] ', '002018776', '2022-03-19 11:04:19'),
(186, 11, '2', 'CODIGO: [13] PERSONA: [Suyon Perez Paola] SEDE: [CAAT HUACHO] ETAPA: [PENDIENTE POR CERRAR] FECHA INGRESO: [2022-03-18] HORA INGRESO: [11:03:00] FECHA CIERRE: [] HORA CIERRE: [] MARCADOR: [MA - MAÑANA] ESTADO: [ACTIVO] FECHA: [2022-03-19 11:04:19] ', 'CODIGO: [13] PERSONA: [Suyon Perez Paola] SEDE: [CAAT HUACHO] ETAPA: [PENDIENTE POR CERRAR] FECHA INGRESO: [2022-03-18] HORA INGRESO: [11:03:00] FECHA CIERRE: [] HORA CIERRE: [] MARCADOR: [MA - MAÑANA] ESTADO: [ACTIVO] FECHA: [2022-03-19 11:04:19] ', '002018776', '2022-03-19 11:04:47'),
(187, 19, '1', '', 'CODIGO: [0] NOMBRE: [Vacuna X] DESCRIPCION: [vacuna x] ESTADO: [ACTIVO] FECHA: [2022-03-19 11:09:50] ', 'admin', '2022-03-19 11:09:50'),
(188, 9, '1', '', 'CODIGO: [0] PERSONA: [Suyon Perez Paola] MOTIVO DEL CESE: [Renuncia voluntaria] MOTIVO LISTA NEGRA: [] ESTADO: [ACTIVO] FECHA: [2022-03-19 22:06:03] ', 'admin', '2022-03-19 22:06:03'),
(189, 12, '2', 'CODIGO: [53] PERSONA: [Suyon Perez Paola] USAURIO: [12344321] CONTRASEÑA: [12344321] PERFIL DE USUARIO: [OPERARIO] ESTADO: [ACTIVO] FECHA: [2022-03-19 11:02:56] ', 'CODIGO: [53] PERSONA: [Suyon Perez Paola] USAURIO: [12344321] CONTRASEÑA: [12344321] PERFIL DE USUARIO: [OPERARIO] ESTADO: [INACTIVO] FECHA: [2022-03-19 22:06:03] ', 'admin', '2022-03-19 22:06:03'),
(190, 11, '1', '', 'CODIGO: [0] PERSONA: [Swayne Grados Luis] SEDE: [CAAT HUACHO] ETAPA: [] FECHA INGRESO: [2022-03-19] HORA INGRESO: [22:16:00] FECHA CIERRE: [] HORA CIERRE: [] MARCADOR: [MA - MAÑANA] ESTADO: [ACTIVO] FECHA: [2022-03-19 22:16:34] ', '80604020', '2022-03-19 22:16:34'),
(191, 11, '2', 'CODIGO: [14] PERSONA: [Swayne Grados Luis] SEDE: [CAAT HUACHO] ETAPA: [PENDIENTE POR CERRAR] FECHA INGRESO: [2022-03-19] HORA INGRESO: [22:16:00] FECHA CIERRE: [] HORA CIERRE: [] MARCADOR: [MA - MAÑANA] ESTADO: [ACTIVO] FECHA: [2022-03-19 22:16:34] ', 'CODIGO: [14] PERSONA: [Swayne Grados Luis] SEDE: [CAAT HUACHO] ETAPA: [PENDIENTE POR CERRAR] FECHA INGRESO: [2022-03-19] HORA INGRESO: [22:16:00] FECHA CIERRE: [] HORA CIERRE: [] MARCADOR: [MA - MAÑANA] ESTADO: [ACTIVO] FECHA: [2022-03-19 22:16:34] ', '80604020', '2022-03-19 22:16:45'),
(192, 11, '1', '', 'CODIGO: [0] PERSONA: [Swayne Grados Luis] SEDE: [CAAT HUACHO] ETAPA: [] FECHA INGRESO: [2022-03-17] HORA INGRESO: [00:00:00] FECHA CIERRE: [] HORA CIERRE: [] MARCADOR: [PE - PERMISO] ESTADO: [ACTIVO] FECHA: [2022-03-19 22:18:43] ', '80604020', '2022-03-19 22:18:43'),
(193, 11, '1', '', 'CODIGO: [0] PERSONA: [Swayne Grados Luis] SEDE: [CAAT HUACHO] ETAPA: [] FECHA INGRESO: [2022-03-15] HORA INGRESO: [00:00:00] FECHA CIERRE: [] HORA CIERRE: [] MARCADOR: [D - DESCANSO] ESTADO: [ACTIVO] FECHA: [2022-03-19 22:19:06] ', '80604020', '2022-03-19 22:19:06'),
(194, 11, '2', 'CODIGO: [15] PERSONA: [Swayne Grados Luis] SEDE: [CAAT HUACHO] ETAPA: [] FECHA INGRESO: [2022-03-17] HORA INGRESO: [00:00:00] FECHA CIERRE: [PERMISO] HORA CIERRE: [PERMISO] MARCADOR: [PE - PERMISO] ESTADO: [ACTIVO] FECHA: [2022-03-19 22:18:43] ', 'CODIGO: [15] PERSONA: [Swayne Grados Luis] SEDE: [CAAT HUACHO] ETAPA: [] FECHA INGRESO: [2022-03-17] HORA INGRESO: [00:00:00] FECHA CIERRE: [PERMISO] HORA CIERRE: [PERMISO] MARCADOR: [PE - PERMISO] ESTADO: [ACTIVO] FECHA: [2022-03-19 22:18:43] ', '80604020', '2022-03-19 22:48:07'),
(195, 11, '2', 'CODIGO: [15] PERSONA: [Swayne Grados Luis] SEDE: [CAAT HUACHO] ETAPA: [] FECHA INGRESO: [2022-03-17] HORA INGRESO: [00:00:00] FECHA CIERRE: [PERMISO] HORA CIERRE: [PERMISO] MARCADOR: [PE - PERMISO] ESTADO: [ACTIVO] FECHA: [2022-03-19 22:18:43] ', 'CODIGO: [15] PERSONA: [Swayne Grados Luis] SEDE: [CAAT HUACHO] ETAPA: [] FECHA INGRESO: [2022-03-17] HORA INGRESO: [00:00:00] FECHA CIERRE: [PERMISO] HORA CIERRE: [PERMISO] MARCADOR: [PE - PERMISO] ESTADO: [ACTIVO] FECHA: [2022-03-19 22:18:43] ', '80604020', '2022-03-19 22:48:38'),
(196, 11, '2', 'CODIGO: [15] PERSONA: [Swayne Grados Luis] SEDE: [CAAT HUACHO] ETAPA: [] FECHA INGRESO: [2022-03-17] HORA INGRESO: [00:00:00] FECHA CIERRE: [PERMISO] HORA CIERRE: [PERMISO] MARCADOR: [PE - PERMISO] ESTADO: [ACTIVO] FECHA: [2022-03-19 22:18:43] ', 'CODIGO: [15] PERSONA: [Swayne Grados Luis] SEDE: [CAAT HUACHO] ETAPA: [] FECHA INGRESO: [2022-03-17] HORA INGRESO: [22:00:00] FECHA CIERRE: [PERMISO] HORA CIERRE: [PERMISO] MARCADOR: [PE - PERMISO] ESTADO: [ACTIVO] FECHA: [2022-03-19 22:18:43] ', '80604020', '2022-03-19 22:48:44'),
(197, 11, '2', 'CODIGO: [16] PERSONA: [Swayne Grados Luis] SEDE: [CAAT HUACHO] ETAPA: [] FECHA INGRESO: [2022-03-15] HORA INGRESO: [00:00:00] FECHA CIERRE: [DESCANSO] HORA CIERRE: [DESCANSO] MARCADOR: [D - DESCANSO] ESTADO: [ACTIVO] FECHA: [2022-03-19 22:19:06] ', 'CODIGO: [16] PERSONA: [Swayne Grados Luis] SEDE: [CAAT HUACHO] ETAPA: [] FECHA INGRESO: [2022-03-15] HORA INGRESO: [22:00:00] FECHA CIERRE: [DESCANSO] HORA CIERRE: [DESCANSO] MARCADOR: [D - DESCANSO] ESTADO: [ACTIVO] FECHA: [2022-03-19 22:19:06] ', '80604020', '2022-03-19 22:48:47'),
(198, 11, '2', 'CODIGO: [16] PERSONA: [Swayne Grados Luis] SEDE: [CAAT HUACHO] ETAPA: [] FECHA INGRESO: [2022-03-15] HORA INGRESO: [22:00:00] FECHA CIERRE: [DESCANSO] HORA CIERRE: [DESCANSO] MARCADOR: [D - DESCANSO] ESTADO: [ACTIVO] FECHA: [2022-03-19 22:19:06] ', 'CODIGO: [16] PERSONA: [Swayne Grados Luis] SEDE: [CAAT HUACHO] ETAPA: [] FECHA INGRESO: [2022-03-15] HORA INGRESO: [22:00:00] FECHA CIERRE: [DESCANSO] HORA CIERRE: [DESCANSO] MARCADOR: [D - DESCANSO] ESTADO: [ACTIVO] FECHA: [2022-03-19 22:19:06] ', '80604020', '2022-03-19 22:48:49'),
(199, 11, '2', 'CODIGO: [15] PERSONA: [Swayne Grados Luis] SEDE: [CAAT HUACHO] ETAPA: [] FECHA INGRESO: [2022-03-17] HORA INGRESO: [22:00:00] FECHA CIERRE: [PERMISO] HORA CIERRE: [PERMISO] MARCADOR: [PE - PERMISO] ESTADO: [ACTIVO] FECHA: [2022-03-19 22:18:43] ', 'CODIGO: [15] PERSONA: [Swayne Grados Luis] SEDE: [CAAT HUACHO] ETAPA: [] FECHA INGRESO: [2022-03-17] HORA INGRESO: [00:00:00] FECHA CIERRE: [PERMISO] HORA CIERRE: [PERMISO] MARCADOR: [PE - PERMISO] ESTADO: [ACTIVO] FECHA: [2022-03-19 22:18:43] ', '80604020', '2022-03-19 22:49:53'),
(200, 11, '2', 'CODIGO: [15] PERSONA: [Swayne Grados Luis] SEDE: [CAAT HUACHO] ETAPA: [] FECHA INGRESO: [2022-03-17] HORA INGRESO: [00:00:00] FECHA CIERRE: [PERMISO] HORA CIERRE: [PERMISO] MARCADOR: [PE - PERMISO] ESTADO: [ACTIVO] FECHA: [2022-03-19 22:18:43] ', 'CODIGO: [15] PERSONA: [Swayne Grados Luis] SEDE: [CAAT HUACHO] ETAPA: [] FECHA INGRESO: [2022-03-17] HORA INGRESO: [22:00:00] FECHA CIERRE: [PERMISO] HORA CIERRE: [PERMISO] MARCADOR: [PE - PERMISO] ESTADO: [ACTIVO] FECHA: [2022-03-19 22:18:43] ', '80604020', '2022-03-19 22:49:58'),
(201, 11, '2', 'CODIGO: [15] PERSONA: [Swayne Grados Luis] SEDE: [CAAT HUACHO] ETAPA: [] FECHA INGRESO: [2022-03-17] HORA INGRESO: [22:00:00] FECHA CIERRE: [PERMISO] HORA CIERRE: [PERMISO] MARCADOR: [PE - PERMISO] ESTADO: [ACTIVO] FECHA: [2022-03-19 22:18:43] ', 'CODIGO: [15] PERSONA: [Swayne Grados Luis] SEDE: [CAAT HUACHO] ETAPA: [] FECHA INGRESO: [2022-03-17] HORA INGRESO: [00:00:00] FECHA CIERRE: [PERMISO] HORA CIERRE: [PERMISO] MARCADOR: [PE - PERMISO] ESTADO: [ACTIVO] FECHA: [2022-03-19 22:18:43] ', '80604020', '2022-03-19 22:50:03'),
(202, 11, '2', 'CODIGO: [15] PERSONA: [Swayne Grados Luis] SEDE: [CAAT HUACHO] ETAPA: [] FECHA INGRESO: [2022-03-17] HORA INGRESO: [00:00:00] FECHA CIERRE: [PERMISO] HORA CIERRE: [PERMISO] MARCADOR: [PE - PERMISO] ESTADO: [ACTIVO] FECHA: [2022-03-19 22:18:43] ', 'CODIGO: [15] PERSONA: [Swayne Grados Luis] SEDE: [CAAT HUACHO] ETAPA: [] FECHA INGRESO: [2022-03-17] HORA INGRESO: [00:00:00] FECHA CIERRE: [PERMISO] HORA CIERRE: [PERMISO] MARCADOR: [PE - PERMISO] ESTADO: [ACTIVO] FECHA: [2022-03-19 22:18:43] ', '80604020', '2022-03-19 22:50:07'),
(203, 11, '2', 'CODIGO: [16] PERSONA: [Swayne Grados Luis] SEDE: [CAAT HUACHO] ETAPA: [] FECHA INGRESO: [2022-03-15] HORA INGRESO: [22:00:00] FECHA CIERRE: [DESCANSO] HORA CIERRE: [DESCANSO] MARCADOR: [D - DESCANSO] ESTADO: [ACTIVO] FECHA: [2022-03-19 22:19:06] ', 'CODIGO: [16] PERSONA: [Swayne Grados Luis] SEDE: [CAAT HUACHO] ETAPA: [] FECHA INGRESO: [2022-03-15] HORA INGRESO: [00:00:00] FECHA CIERRE: [DESCANSO] HORA CIERRE: [DESCANSO] MARCADOR: [D - DESCANSO] ESTADO: [ACTIVO] FECHA: [2022-03-19 22:19:06] ', '80604020', '2022-03-19 22:50:08');
INSERT INTO auditoria (id_auditoria, id_tablas, tipo_auditoria, old_value, new_value, usuario, fecha) VALUES
(204, 11, '2', 'CODIGO: [16] PERSONA: [Swayne Grados Luis] SEDE: [CAAT HUACHO] ETAPA: [] FECHA INGRESO: [2022-03-15] HORA INGRESO: [00:00:00] FECHA CIERRE: [DESCANSO] HORA CIERRE: [DESCANSO] MARCADOR: [D - DESCANSO] ESTADO: [ACTIVO] FECHA: [2022-03-19 22:19:06] ', 'CODIGO: [16] PERSONA: [Swayne Grados Luis] SEDE: [CAAT HUACHO] ETAPA: [] FECHA INGRESO: [2022-03-15] HORA INGRESO: [00:00:00] FECHA CIERRE: [DESCANSO] HORA CIERRE: [DESCANSO] MARCADOR: [D - DESCANSO] ESTADO: [ACTIVO] FECHA: [2022-03-19 22:19:06] ', '80604020', '2022-03-19 22:50:10'),
(205, 11, '1', '', 'CODIGO: [0] PERSONA: [Swayne Grados Luis] SEDE: [CAAT HUACHO] ETAPA: [] FECHA INGRESO: [2022-03-07] HORA INGRESO: [00:00:00] FECHA CIERRE: [] HORA CIERRE: [] MARCADOR: [D - DESCANSO] ESTADO: [ACTIVO] FECHA: [2022-03-19 22:51:24] ', '80604020', '2022-03-19 22:51:24'),
(206, 11, '1', '', 'CODIGO: [0] PERSONA: [Swayne Grados Luis] SEDE: [CAAT HUACHO] ETAPA: [] FECHA INGRESO: [2022-03-09] HORA INGRESO: [00:00:00] FECHA CIERRE: [] HORA CIERRE: [] MARCADOR: [FAL - FALTA] ESTADO: [ACTIVO] FECHA: [2022-03-19 22:53:57] ', '80604020', '2022-03-19 22:53:57'),
(207, 17, '2', 'CODIGO: [4] LUGAR: [HOSPITAL LANFRANCO] DESCRIPCION: [PACIENTES COVID] ESTADO: [ACTIVO] FECHA: [2022-03-18 22:54:33] ', 'CODIGO: [4] LUGAR: [HOSPITAL LANFRANCO] DESCRIPCION: [HOSPITAL LANFRANCO] ESTADO: [ACTIVO] FECHA: [2022-03-21 22:09:28] ', 'admin', '2022-03-21 22:09:28'),
(208, 17, '2', 'CODIGO: [5] LUGAR: [LANFRANCO] DESCRIPCION: [COVID] ESTADO: [ACTIVO] FECHA: [2022-03-18 23:19:28] ', 'CODIGO: [5] LUGAR: [LANFRANCO] DESCRIPCION: [LANFRANCO] ESTADO: [ACTIVO] FECHA: [2022-03-21 22:09:45] ', 'admin', '2022-03-21 22:09:45'),
(209, 19, '2', 'CODIGO: [4] NOMBRE: [Vac.Tetano] DESCRIPCION: [Vacunacion Tetano] ESTADO: [INACTIVO] FECHA: [2022-03-18 07:08:47] ', 'CODIGO: [4] NOMBRE: [Vac.Tetano] DESCRIPCION: [Vacunacion Tetano] ESTADO: [ACTIVO] FECHA: [2022-03-22 21:46:10] ', 'admin', '2022-03-22 21:46:10'),
(210, 19, '2', 'CODIGO: [5] NOMBRE: [Vac.Hepatitis] DESCRIPCION: [Vacunacion Hepatitis] ESTADO: [INACTIVO] FECHA: [2022-03-18 07:09:10] ', 'CODIGO: [5] NOMBRE: [Vac.Hepatitis] DESCRIPCION: [Vacunacion Hepatitis] ESTADO: [ACTIVO] FECHA: [2022-03-22 21:46:21] ', 'admin', '2022-03-22 21:46:21'),
(211, 19, '2', 'CODIGO: [6] NOMBRE: [Vac.COVID] DESCRIPCION: [Vacunacion COVID] ESTADO: [INACTIVO] FECHA: [2022-03-18 07:09:25] ', 'CODIGO: [6] NOMBRE: [Vac.COVID] DESCRIPCION: [Vacunacion COVID] ESTADO: [ACTIVO] FECHA: [2022-03-22 21:46:34] ', 'admin', '2022-03-22 21:46:34'),
(212, 19, '2', 'CODIGO: [7] NOMBRE: [DJ.Estudios] DESCRIPCION: [Declaracion Jurada Estudios] ESTADO: [INACTIVO] FECHA: [2022-03-18 07:10:11] ', 'CODIGO: [7] NOMBRE: [DJ.Estudios] DESCRIPCION: [Declaracion Jurada Estudios] ESTADO: [ACTIVO] FECHA: [2022-03-22 21:46:46] ', 'admin', '2022-03-22 21:46:46'),
(213, 19, '2', 'CODIGO: [9] NOMBRE: [Vacuna X] DESCRIPCION: [vacuna x] ESTADO: [ACTIVO] FECHA: [2022-03-19 11:09:50] ', 'CODIGO: [9] NOMBRE: [Vacuna X] DESCRIPCION: [vacuna x] ESTADO: [INACTIVO] FECHA: [2022-03-22 21:46:59] ', 'admin', '2022-03-22 21:46:59'),
(214, 12, '2', 'CODIGO: [36] PERSONA: [Pasco Chavez Marisol] USAURIO: [72260964] CONTRASEÑA: [72260964] PERFIL DE USUARIO: [ADM. DEL SISTEMA] ESTADO: [ACTIVO] FECHA: [2022-03-17 23:52:36] ', 'CODIGO: [36] PERSONA: [Pasco Chavez Marisol] USAURIO: [72260964] CONTRASEÑA: [asdsaasdasasd] PERFIL DE USUARIO: [ADM. DEL SISTEMA] ESTADO: [ACTIVO] FECHA: [2022-03-17 23:52:36] ', 'admin', '2022-03-24 09:45:58'),
(215, 12, '2', 'CODIGO: [36] PERSONA: [Pasco Chavez Marisol] USAURIO: [72260964] CONTRASEÑA: [asdsaasdasasd] PERFIL DE USUARIO: [ADM. DEL SISTEMA] ESTADO: [ACTIVO] FECHA: [2022-03-17 23:52:36] ', 'CODIGO: [36] PERSONA: [Pasco Chavez Marisol] USAURIO: [72260964] CONTRASEÑA: [72260964] PERFIL DE USUARIO: [ADM. DEL SISTEMA] ESTADO: [ACTIVO] FECHA: [2022-03-17 23:52:36] ', 'admin', '2022-03-24 09:46:16');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla banco
--

CREATE TABLE banco (
  id_banco int(11) NOT NULL,
  ba_nombre varchar(45) DEFAULT NULL,
  ba_abreviatura varchar(45) DEFAULT NULL,
  ba_descripcion varchar(45) DEFAULT NULL,
  ba_estado int(11) DEFAULT '1',
  ba_fecha_r datetime DEFAULT CURRENT_TIMESTAMP,
  ba_fecha_c datetime DEFAULT CURRENT_TIMESTAMP,
  userCreacion varchar(50) NOT NULL,
  fechaCreacion datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  userModificacion varchar(50) NOT NULL,
  fechaModificacion datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  flEliminado int(11) NOT NULL DEFAULT '1'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Volcado de datos para la tabla banco
--

INSERT INTO banco (id_banco, ba_nombre, ba_abreviatura, ba_descripcion, ba_estado, ba_fecha_r, ba_fecha_c, userCreacion, fechaCreacion, userModificacion, fechaModificacion, flEliminado) VALUES
(1, 'Credito', 'BCO.CREDITO', 'Banco de Credito', 1, '2022-02-20 22:39:37', '2022-02-20 22:39:37', '', '2022-03-15 00:42:08', '12345678', '2022-03-17 16:16:28', 0);

--
-- Disparadores banco
--
DELIMITER $$
CREATE TRIGGER trg_log_actualizar_banco BEFORE UPDATE ON banco FOR EACH ROW BEGIN

/*
 * REGISTRO: 1
 * EDICION : 2
 * ANULACION: 3
 * ELIMINACION: 4
 * */
  
  DECLARE dec_NewRegistro TEXT;
  DECLARE dec_OldRegistro TEXT;

  SELECT 
    group_concat(
        concat(
             "CODIGO: [",IFNULL(NEW.id_banco    , ''),"] " 
            ,"NOMBRE: [",IFNULL(NEW.ba_nombre, ''),"] " 
            ,"ABREVIATURA: [",IFNULL(NEW.ba_abreviatura, ''),"] " 
            ,"ESTADO: [",IFNULL(fun_get_estado_gen(new.ba_estado), ''),"] " 
            ,"FECHA: [",IFNULL(NEW.fechaModificacion, ''),"] "
        )
        SEPARATOR ' '
    ) into dec_NewRegistro;
   
   SELECT 
    group_concat(
       concat(
             "CODIGO: [",IFNULL(OLD.id_banco    , ''),"] " 
            ,"NOMBRE: [",IFNULL(OLD.ba_nombre, ''),"] " 
            ,"ABREVIATURA: [",IFNULL(OLD.ba_abreviatura, ''),"] " 
            ,"ESTADO: [",IFNULL(fun_get_estado_gen(OLD.ba_estado), ''),"] " 
            ,"FECHA: [",IFNULL(OLD.fechaModificacion, ''),"] "
        )
        SEPARATOR ' '
    ) into dec_OldRegistro;

    INSERT INTO auditoria(id_tablas, tipo_auditoria, old_value, new_value, usuario, fecha) 
    VALUES (
        14,
        2,
        dec_OldRegistro, 
        dec_NewRegistro,
        NEW.userModificacion,
        now()
    );


END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER trg_log_registrar_tipo_banco BEFORE INSERT ON banco FOR EACH ROW BEGIN

/*
 * REGISTRO: 1
 * EDICION : 2
 * ANULACION: 3
 * ELIMINACION: 4
 * */
  
  DECLARE dec_NewRegistro TEXT;
  DECLARE dec_OldRegistro TEXT;

  SELECT 
    group_concat(
        concat(
             "CODIGO: [",IFNULL(NEW.id_banco    , ''),"] " 
            ,"NOMBRE: [",IFNULL(NEW.ba_nombre, ''),"] " 
            ,"ABREVIATURA: [",IFNULL(NEW.ba_abreviatura, ''),"] " 
            ,"ESTADO: [",IFNULL(fun_get_estado_gen(new.ba_estado), ''),"] " 
            ,"FECHA: [",IFNULL(NEW.fechaModificacion, ''),"] "
        )
        SEPARATOR ' '
    ) into dec_NewRegistro;
   
    INSERT INTO auditoria(id_tablas, tipo_auditoria, old_value, new_value, usuario, fecha) 
    VALUES (
        14,
        1,
        '', 
        dec_NewRegistro,
        NEW.userCreacion,
        now()
    );


END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla cargo
--

CREATE TABLE cargo (
  id_cargo int(11) NOT NULL,
  id_tipoUsuario int(11) NOT NULL,
  ca_descripcion varchar(45) DEFAULT NULL,
  ca_abreviatura varchar(45) DEFAULT NULL,
  ca_estado int(11) DEFAULT '1',
  ca_fecha_r datetime DEFAULT CURRENT_TIMESTAMP,
  ca_fecha_c datetime DEFAULT CURRENT_TIMESTAMP,
  userCreacion varchar(50) NOT NULL,
  fechaCreacion datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  userModificacion varchar(50) NOT NULL,
  fechaModificacion datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  flEliminado int(11) NOT NULL DEFAULT '1'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Volcado de datos para la tabla cargo
--

INSERT INTO cargo (id_cargo, id_tipoUsuario, ca_descripcion, ca_abreviatura, ca_estado, ca_fecha_r, ca_fecha_c, userCreacion, fechaCreacion, userModificacion, fechaModificacion, flEliminado) VALUES
(1, 1, 'SUPERVISOR', 'SUP', 1, '2022-02-03 22:31:39', '2022-02-03 22:31:39', 'sdf', '2022-03-13 18:43:23', '12345678', '2022-03-17 16:32:34', 0),
(3, 3, 'OPERARIO', 'OP', 1, '2022-02-03 22:31:39', '2022-02-03 22:31:39', 'sdf', '2022-03-13 18:43:23', 'sdf', '2022-03-13 18:43:23', 0),
(4, 6, 'ADM. DEL SISTEMA', 'ADM', 1, '2022-02-20 02:15:20', '2022-02-20 02:15:20', 'sdf', '2022-03-13 18:43:23', 'sdf', '2022-03-13 18:43:23', 0),
(14, 6, 'RRHH', 'RRHH', 1, '2022-03-17 23:48:06', '2022-03-17 23:48:06', 'admin', '2022-03-17 23:48:06', 'admin', '2022-03-17 23:48:06', 1),
(15, 1, 'ELIZABETH RENGEL GONZALES', 'ERG', 1, '2022-03-18 22:55:57', '2022-03-18 22:55:57', '46480582', '2022-03-18 22:55:57', '46480582', '2022-03-18 22:55:57', 1);

--
-- Disparadores cargo
--
DELIMITER $$
CREATE TRIGGER trg_log_actualizar_cargo BEFORE UPDATE ON cargo FOR EACH ROW BEGIN

/*
 * REGISTRO: 1
 * EDICION : 2
 * ANULACION: 3
 * ELIMINACION: 4
 * */
  
  DECLARE dec_NewRegistro TEXT;
  DECLARE dec_OldRegistro TEXT;

  SELECT 
    group_concat(
        concat(
             "CODIGO: [",IFNULL(NEW.id_cargo        , ''),"] " 
            ,"NOMBRE: [",IFNULL(NEW.ca_descripcion, ''),"] " 
            ,"ABREVIATURA: [",IFNULL(NEW.ca_abreviatura, ''),"] "  
            ,"TIPO DE PERFIL: [",IFNULL(fun_get_tipo_usuario_p_gen(NEW.id_tipoUsuario), ''),"] "  
            ,"ESTADO: [",IFNULL(fun_get_estado_gen(new.ca_estado), ''),"] " 
            ,"FECHA: [",IFNULL(NEW.fechaModificacion, ''),"] "
        )
        SEPARATOR ' '
    ) into dec_NewRegistro;
   
   SELECT 
    group_concat(
        concat(
             "CODIGO: [",IFNULL(OLD.id_cargo        , ''),"] " 
            ,"NOMBRE: [",IFNULL(OLD.ca_descripcion, ''),"] " 
            ,"ABREVIATURA: [",IFNULL(OLD.ca_abreviatura, ''),"] "  
            ,"TIPO DE PERFIL: [",IFNULL(fun_get_tipo_usuario_p_gen(OLD.id_tipoUsuario), ''),"] "  
            ,"ESTADO: [",IFNULL(fun_get_estado_gen(OLD.ca_estado), ''),"] " 
            ,"FECHA: [",IFNULL(OLD.fechaModificacion, ''),"] "
        )
        SEPARATOR ' '
    ) into dec_OldRegistro;

    INSERT INTO auditoria(id_tablas, tipo_auditoria, old_value, new_value, usuario, fecha) 
    VALUES (
        18,
        2,
        dec_OldRegistro, 
        dec_NewRegistro,
        NEW.userModificacion,
        now()
    );


END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER trg_log_registrar_cargo BEFORE INSERT ON cargo FOR EACH ROW BEGIN

/*
 * REGISTRO: 1
 * EDICION : 2
 * ANULACION: 3
 * ELIMINACION: 4
 * */
  
  DECLARE dec_NewRegistro TEXT;
  DECLARE dec_OldRegistro TEXT;

  SELECT 
    group_concat(
        concat(
             "CODIGO: [",IFNULL(NEW.id_cargo        , ''),"] " 
            ,"NOMBRE: [",IFNULL(NEW.ca_descripcion, ''),"] " 
            ,"ABREVIATURA: [",IFNULL(NEW.ca_abreviatura, ''),"] "  
            ,"TIPO DE PERFIL: [",IFNULL(fun_get_tipo_usuario_p_gen(NEW.id_tipoUsuario), ''),"] "  
            ,"ESTADO: [",IFNULL(fun_get_estado_gen(new.ca_estado), ''),"] " 
            ,"FECHA: [",IFNULL(NEW.fechaModificacion, ''),"] "
        )
        SEPARATOR ' '
    ) into dec_NewRegistro;
   
    INSERT INTO auditoria(id_tablas, tipo_auditoria, old_value, new_value, usuario, fecha) 
    VALUES (
        18,
        1,
        '', 
        dec_NewRegistro,
        NEW.userCreacion,
        now()

    );


END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla cargos_empleado
--

CREATE TABLE cargos_empleado (
  id_caempleado int(11) NOT NULL,
  id_persona int(11) DEFAULT NULL,
  id_cargo int(11) DEFAULT NULL,
  ce_fecha_r datetime DEFAULT CURRENT_TIMESTAMP,
  ce_fecha_c datetime DEFAULT CURRENT_TIMESTAMP,
  ce_estado int(11) DEFAULT NULL,
  ce_observacion text,
  userCreacion varchar(50) NOT NULL,
  fechaCreacion datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  userModificacion varchar(50) NOT NULL,
  fechaModificacion datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  flEliminado int(11) NOT NULL DEFAULT '1'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Volcado de datos para la tabla cargos_empleado
--

INSERT INTO cargos_empleado (id_caempleado, id_persona, id_cargo, ce_fecha_r, ce_fecha_c, ce_estado, ce_observacion, userCreacion, fechaCreacion, userModificacion, fechaModificacion, flEliminado) VALUES
(22, 2, 14, '2022-02-01 00:00:00', '2022-02-01 00:00:00', 1, 'OBSERVACION', 'admin', '2022-03-17 23:52:36', 'admin', '2022-03-17 23:52:36', 1),
(23, 3, 14, '2022-02-15 00:00:00', '2022-02-15 00:00:00', 1, 'OBSERVACION', 'admin', '2022-03-17 23:53:53', 'admin', '2022-03-17 23:53:53', 1),
(24, 4, 14, '2022-02-21 00:00:00', '2022-02-21 00:00:00', 1, 'OBSERVACION', 'admin', '2022-03-17 23:55:17', 'admin', '2022-03-17 23:55:17', 1),
(25, 5, 14, '2022-01-27 00:00:00', '2022-01-27 00:00:00', 1, 'OBSERVACION', 'admin', '2022-03-17 23:56:16', 'admin', '2022-03-17 23:56:16', 1),
(26, 6, 14, '2022-03-17 00:00:00', '2022-03-17 00:00:00', 1, 'OBSERVACION', 'admin', '2022-03-17 23:57:16', 'admin', '2022-03-17 23:57:16', 1),
(27, 7, 1, '2022-01-15 00:00:00', '2022-01-15 00:00:00', 1, 'OBSERVACION', 'admin', '2022-03-18 00:05:31', 'admin', '2022-03-18 00:05:31', 1),
(32, 12, 1, '2022-03-18 00:00:00', '2022-03-18 00:00:00', 1, 'OBSERVACION', '004644398', '2022-03-18 10:38:02', '004644398', '2022-03-18 10:38:02', 1),
(33, 13, 3, '2022-03-18 00:00:00', '2022-03-18 00:00:00', 1, 'OBSERVACION', '004644398', '2022-03-18 15:38:01', '004644398', '2022-03-18 15:38:01', 1),
(34, 14, 3, '2022-03-02 00:00:00', '2022-03-02 00:00:00', 1, 'OBSERVACION', '004644398', '2022-03-18 18:37:23', '004644398', '2022-03-18 18:37:23', 1),
(35, 15, 3, '2022-03-17 00:00:00', '2022-03-17 00:00:00', 1, 'OBSERVACION', '004644398', '2022-03-18 18:41:02', '004644398', '2022-03-18 18:41:02', 1),
(36, 16, 3, '2022-03-18 00:00:00', '2022-03-18 00:00:00', 1, 'OBSERVACION', '004644398', '2022-03-18 18:43:42', '004644398', '2022-03-18 18:43:42', 1),
(37, 18, 1, '2022-03-17 00:00:00', '2022-03-17 00:00:00', 0, 'OBSERVACION', '46480582', '2022-03-18 23:23:54', '46480582', '2022-03-18 23:23:54', 1),
(38, 18, 3, '2022-03-18 23:25:25', '2022-03-18 23:25:25', 1, '5 DIAS A LA SEMANA', '46480582', '2022-03-18 23:25:25', '46480582', '2022-03-18 23:25:25', 1),
(39, 19, 1, '2022-03-18 00:00:00', '2022-03-18 00:00:00', 0, 'OBSERVACION', '46480582', '2022-03-18 23:33:59', '46480582', '2022-03-18 23:33:59', 1),
(40, 19, 3, '2022-03-18 23:35:41', '2022-03-18 23:35:41', 1, NULL, '46480582', '2022-03-18 23:35:41', '46480582', '2022-03-18 23:35:41', 1),
(41, 20, 1, '2022-03-19 00:00:00', '2022-03-19 00:00:00', 0, 'OBSERVACION', 'admin', '2022-03-19 10:27:03', 'admin', '2022-03-19 10:27:03', 1),
(42, 20, 3, '2022-03-19 11:02:56', '2022-03-19 11:02:56', 1, NULL, 'admin', '2022-03-19 11:02:56', 'admin', '2022-03-19 11:02:56', 1);

--
-- Disparadores cargos_empleado
--
DELIMITER $$
CREATE TRIGGER trg_log_actualizar_cargo_has_empleado BEFORE UPDATE ON cargos_empleado FOR EACH ROW BEGIN

/*
 * REGISTRO: 1
 * EDICION : 2
 * ANULACION: 3
 * ELIMINACION: 4
 * */
  
  DECLARE dec_NewRegistro TEXT;
  DECLARE dec_OldRegistro TEXT;

  SELECT 
    group_concat(
        concat(
             "CODIGO: [",IFNULL(NEW.id_caempleado , ''),"] " 

            ,"CARGO: [",IFNULL(fun_get_cargo_gen(new.id_cargo), ''),"] "
            ,"ESTADO: [",IFNULL(fun_get_estado_gen(new.ce_estado), ''),"] "
            ,"FECHA: [",IFNULL(NEW.fechaCreacion, ''),"] " 
        )
        SEPARATOR ' '
    ) into dec_NewRegistro;
   
   SELECT 
    group_concat(
        concat(
             "CODIGO: [",IFNULL(OLD.id_caempleado , ''),"] " 
            ,"CARGO: [",IFNULL(fun_get_cargo_gen(OLD.id_cargo), ''),"] "
            ,"ESTADO: [",IFNULL(fun_get_estado_gen(OLD.ce_estado), ''),"] "
            ,"FECHA: [",IFNULL(OLD.fechaCreacion, ''),"] " 
        )
        SEPARATOR ' '
    ) into dec_OldRegistro;

    INSERT INTO auditoria(id_tablas, tipo_auditoria, old_value, new_value, usuario, fecha) 
    VALUES (
        2,
        2,
        dec_OldRegistro, 
        dec_NewRegistro,
        NEW.userModificacion,
        now()
    );


END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER trg_log_registrar_cargo_has_empleado BEFORE INSERT ON cargos_empleado FOR EACH ROW BEGIN

/*
 * REGISTRO: 1
 * EDICION : 2
 * ANULACION: 3
 * ELIMINACION: 4
 * */
  
  DECLARE dec_NewRegistro TEXT;

  SELECT 
    group_concat(
        concat(
             "CODIGO: [",IFNULL(NEW.id_caempleado , ''),"] " 
            ,"CARGO: [",IFNULL(fun_get_cargo_gen(new.id_cargo), ''),"] "
            ,"ESTADO: [",IFNULL(fun_get_estado_gen(new.ce_estado), ''),"] "
            ,"FECHA: [",IFNULL(NEW.fechaCreacion, ''),"] " 
        )
        SEPARATOR ' '
    ) into dec_NewRegistro;
 

    INSERT INTO auditoria(id_tablas, tipo_auditoria, old_value, new_value, usuario, fecha) 
    VALUES (
        2,
        1,
        '', 
        dec_NewRegistro,
        NEW.userModificacion,
        now()
    );


END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla ca_planilla
--

CREATE TABLE ca_planilla (
  id_planilla int(10) UNSIGNED NOT NULL,
  cap_anio varchar(30) NOT NULL,
  cap_mes varchar(30) NOT NULL,
  cap_periodo varchar(30) NOT NULL,
  cap_sede int(11) NOT NULL,
  cap_estado int(11) DEFAULT NULL,
  cap_codigo varchar(30) DEFAULT NULL,
  cap_fecha datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  userCreacion varchar(50) NOT NULL,
  fechaCreacion datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  userModificacion varchar(50) NOT NULL,
  fechaModificacion datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  flEliminado int(11) NOT NULL DEFAULT '1'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla cliente
--

CREATE TABLE cliente (
  id_cliente int(11) NOT NULL,
  cli_nombre varchar(45) DEFAULT NULL,
  cli_descripcion varchar(45) DEFAULT NULL,
  cli_codigo varchar(45) DEFAULT NULL,
  cli_estado int(11) DEFAULT '1',
  cli_fecha_r datetime DEFAULT CURRENT_TIMESTAMP,
  cli_fecha_c datetime DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla descanso
--

CREATE TABLE descanso (
  id_descanso int(11) NOT NULL,
  id_persona int(11) NOT NULL,
  de_fecha datetime DEFAULT CURRENT_TIMESTAMP,
  de_observacion varchar(100) DEFAULT NULL,
  de_estado int(11) DEFAULT '1',
  de_fecha_r datetime DEFAULT CURRENT_TIMESTAMP,
  de_fecha_c datetime DEFAULT CURRENT_TIMESTAMP,
  de_referencia varchar(50) NOT NULL DEFAULT '-',
  userCreacion varchar(50) NOT NULL,
  fechaCreacion datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  userModificacion varchar(50) NOT NULL,
  fechaModificacion datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  flEliminado int(11) NOT NULL DEFAULT '1'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Volcado de datos para la tabla descanso
--

INSERT INTO descanso (id_descanso, id_persona, de_fecha, de_observacion, de_estado, de_fecha_r, de_fecha_c, de_referencia, userCreacion, fechaCreacion, userModificacion, fechaModificacion, flEliminado) VALUES
(1, 12, '2022-12-12 00:00:00', '', 1, '2022-03-18 10:38:02', '2022-03-18 10:38:02', 'Domingo', '004644398', '2022-03-18 10:38:02', '004644398', '2022-03-18 10:38:02', 1),
(2, 13, '2022-12-12 00:00:00', '', 1, '2022-03-18 15:38:01', '2022-03-18 15:38:01', 'Jueves', '004644398', '2022-03-18 15:38:01', '004644398', '2022-03-18 15:38:01', 1),
(3, 18, '2022-12-12 00:00:00', '', 0, '2022-03-18 23:23:54', '2022-03-18 23:23:54', 'Jueves', '46480582', '2022-03-18 23:23:54', '46480582', '2022-03-18 23:24:53', 1),
(4, 18, '2022-03-18 23:24:53', 'PERSONAL NUEVO', 1, '2022-03-18 23:24:53', '2022-03-18 23:24:53', 'Martes', '46480582', '2022-03-18 23:24:53', '46480582', '2022-03-18 23:24:53', 1);

--
-- Disparadores descanso
--
DELIMITER $$
CREATE TRIGGER trg_log_actualizar_descanso_has_sueldo BEFORE UPDATE ON descanso FOR EACH ROW BEGIN

/*
 * REGISTRO: 1
 * EDICION : 2
 * ANULACION: 3
 * ELIMINACION: 4
 * */
  
  DECLARE dec_NewRegistro TEXT;
  DECLARE dec_OldRegistro TEXT;

  SELECT 
    group_concat(
        concat(
             "CODIGO: [",IFNULL(NEW.id_descanso   , ''),"] " 
            ,"DIA DESCANSO: [",IFNULL(NEW.de_referencia, ''),"] "
            ,"OBSERVACION: [",IFNULL(NEW.de_observacion, ''),"] " 
            ,"ESTADO: [",IFNULL(fun_get_estado_gen(new.de_estado), ''),"] " 
            ,"FECHA: [",IFNULL(NEW.fechaCreacion, ''),"] "
        )
        SEPARATOR ' '
    ) into dec_NewRegistro;
   
   SELECT 
    group_concat(
        concat(
             "CODIGO: [",IFNULL(OLD.id_descanso   , ''),"] " 
            ,"DIA DESCANSO: [",IFNULL(OLD.de_referencia, ''),"] "
            ,"OBSERVACION: [",IFNULL(OLD.de_observacion, ''),"] " 
            ,"ESTADO: [",IFNULL(fun_get_estado_gen(OLD.de_estado), ''),"] " 
            ,"FECHA: [",IFNULL(OLD.fechaCreacion, ''),"] "
        )
        SEPARATOR ' '
    ) into dec_OldRegistro;

    INSERT INTO auditoria(id_tablas, tipo_auditoria, old_value, new_value, usuario, fecha) 
    VALUES (
        4,
        2,
        dec_OldRegistro, 
        dec_NewRegistro,
        NEW.userModificacion,
        now()
    );


END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER trg_log_registrar_descanso_has_sueldo BEFORE INSERT ON descanso FOR EACH ROW BEGIN

/*
 * REGISTRO: 1
 * EDICION : 2
 * ANULACION: 3
 * ELIMINACION: 4
 * */
  
  DECLARE dec_NewRegistro TEXT;
  DECLARE dec_OldRegistro TEXT;

  SELECT 
    group_concat(
        concat(
             "CODIGO: [",IFNULL(NEW.id_descanso   , ''),"] " 
            ,"DIA DESCANSO: [",IFNULL(NEW.de_referencia, ''),"] "
            ,"OBSERVACION: [",IFNULL(NEW.de_observacion, ''),"] " 
            ,"ESTADO: [",IFNULL(fun_get_estado_gen(new.de_estado), ''),"] " 
            ,"FECHA: [",IFNULL(NEW.fechaCreacion, ''),"] "
        )
        SEPARATOR ' '
    ) into dec_NewRegistro;
   
    INSERT INTO auditoria(id_tablas, tipo_auditoria, old_value, new_value, usuario, fecha) 
    VALUES (
        4,
        1,
        '', 
        dec_NewRegistro,
        NEW.userCreacion,
        now()
    );


END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla de_planilla
--

CREATE TABLE de_planilla (
  de_planilla int(10) UNSIGNED NOT NULL,
  id_planilla int(11) DEFAULT NULL,
  id_persona int(11) DEFAULT NULL,
  periodo varchar(30) DEFAULT NULL,
  id_sueldo int(11) DEFAULT NULL,
  cst_dia decimal(9,2) DEFAULT NULL,
  inicio_sem date DEFAULT NULL,
  fin_sem date DEFAULT NULL,
  t_manana_v int(11) DEFAULT NULL,
  total_pago_maniana decimal(9,2) DEFAULT NULL,
  t_tarde_v int(11) DEFAULT NULL,
  total_pago_tarde decimal(9,2) DEFAULT NULL,
  t_noche_v int(11) DEFAULT NULL,
  total_pago_noche decimal(9,2) DEFAULT NULL,
  feriado int(11) DEFAULT NULL,
  faltas int(11) DEFAULT NULL,
  descanso int(11) DEFAULT NULL,
  descanso_pago int(11) DEFAULT NULL,
  descanso_calculo int(11) DEFAULT NULL,
  total_pago_descanso decimal(9,2) DEFAULT NULL,
  TOTAL_CF decimal(9,2) DEFAULT NULL,
  pago_feriado decimal(9,2) DEFAULT NULL,
  nombres varchar(50) DEFAULT NULL,
  tPdocumento varchar(50) DEFAULT NULL,
  nacionalidad varchar(50) DEFAULT NULL,
  cargo varchar(50) DEFAULT NULL,
  ingreso varchar(50) DEFAULT NULL,
  remuneracion_bruta decimal(9,2) DEFAULT NULL,
  banco varchar(50) DEFAULT NULL,
  cuenta varchar(50) DEFAULT NULL,
  tpCuenta varchar(50) DEFAULT NULL,
  cci varchar(50) DEFAULT NULL,
  suplente varchar(50) DEFAULT NULL,
  documento varchar(50) DEFAULT NULL,
  total_pago_descanso_sin_turno decimal(9,2) DEFAULT NULL,
  fechaSece varchar(50) DEFAULT NULL,
  estado_persona int(11) DEFAULT NULL,
  permiso_pago int(11) NOT NULL,
  total_permiso_pago decimal(9,2) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla documentos_empleado
--

CREATE TABLE documentos_empleado (
  id_emdocumento int(11) NOT NULL,
  de_nombre varchar(50) NOT NULL,
  de_descripcion varchar(50) NOT NULL,
  de_obligatirio int(11) NOT NULL,
  de_fecha date NOT NULL,
  userCreacion varchar(50) NOT NULL,
  fechaCreacion datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  userModificacion varchar(50) NOT NULL,
  fechaModificacion datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  flEliminado int(11) NOT NULL DEFAULT '1'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Volcado de datos para la tabla documentos_empleado
--

INSERT INTO documentos_empleado (id_emdocumento, de_nombre, de_descripcion, de_obligatirio, de_fecha, userCreacion, fechaCreacion, userModificacion, fechaModificacion, flEliminado) VALUES
(1, 'Doc.Identidad', 'Documento de identidad', 0, '2022-02-20', 'A', '2022-02-20 00:00:00', '12345678', '2022-03-17 16:41:56', 1),
(2, 'Ant.Policiales', 'Antecedentes Policiales', 0, '2022-03-18', 'admin', '2022-03-18 07:07:03', 'JVERGARA', '2022-03-18 07:29:20', 1),
(3, 'Ant.Penales', 'Antecedentes Penales', 0, '2022-03-18', 'admin', '2022-03-18 07:07:21', 'JVERGARA', '2022-03-18 07:30:53', 1),
(4, 'Vac.Tetano', 'Vacunacion Tetano', 0, '2022-03-18', 'admin', '2022-03-18 07:08:47', 'admin', '2022-03-22 21:46:10', 1),
(5, 'Vac.Hepatitis', 'Vacunacion Hepatitis', 0, '2022-03-18', 'admin', '2022-03-18 07:09:10', 'admin', '2022-03-22 21:46:21', 1),
(6, 'Vac.COVID', 'Vacunacion COVID', 0, '2022-03-18', 'admin', '2022-03-18 07:09:25', 'admin', '2022-03-22 21:46:34', 1),
(7, 'DJ.Estudios', 'Declaracion Jurada Estudios', 0, '2022-03-18', 'admin', '2022-03-18 07:10:11', 'admin', '2022-03-22 21:46:46', 1),
(8, 'Prueba', 'Prueba', 0, '2022-03-18', 'admin', '2022-03-18 07:14:22', 'admin', '2022-03-18 07:14:22', 0),
(9, 'Vacuna X', 'vacuna x', 0, '2022-03-19', 'admin', '2022-03-19 11:09:50', 'admin', '2022-03-22 21:46:59', 0);

--
-- Disparadores documentos_empleado
--
DELIMITER $$
CREATE TRIGGER trg_log_actualizar_documentos_empleado BEFORE UPDATE ON documentos_empleado FOR EACH ROW BEGIN

/*
 * REGISTRO: 1
 * EDICION : 2
 * ANULACION: 3
 * ELIMINACION: 4
 * */
  
  DECLARE dec_NewRegistro TEXT;
  DECLARE dec_OldRegistro TEXT;

  SELECT 
    group_concat(
        concat(
             "CODIGO: [",IFNULL(NEW.id_emdocumento         , ''),"] " 
            ,"NOMBRE: [",IFNULL(NEW.de_nombre, ''),"] " 
            ,"DESCRIPCION: [",IFNULL(NEW.de_descripcion, ''),"] "   
            ,"ESTADO: [",IFNULL(fun_get_estado_gen(new.flEliminado), ''),"] " 
            ,"FECHA: [",IFNULL(NEW.fechaModificacion, ''),"] "
        )
        SEPARATOR ' '
    ) into dec_NewRegistro;
   
   SELECT 
    group_concat(
        concat(
             "CODIGO: [",IFNULL(OLD.id_emdocumento         , ''),"] " 
            ,"NOMBRE: [",IFNULL(OLD.de_nombre, ''),"] " 
            ,"DESCRIPCION: [",IFNULL(OLD.de_descripcion, ''),"] "   
            ,"ESTADO: [",IFNULL(fun_get_estado_gen(OLD.flEliminado), ''),"] " 
            ,"FECHA: [",IFNULL(OLD.fechaModificacion, ''),"] "
        )
        SEPARATOR ' '
    ) into dec_OldRegistro;

    INSERT INTO auditoria(id_tablas, tipo_auditoria, old_value, new_value, usuario, fecha) 
    VALUES (
        19,
        2,
        dec_OldRegistro, 
        dec_NewRegistro,
        NEW.userModificacion,
        now()
    );


END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER trg_log_registrar_documentos_empleado BEFORE INSERT ON documentos_empleado FOR EACH ROW BEGIN

/*
 * REGISTRO: 1
 * EDICION : 2
 * ANULACION: 3
 * ELIMINACION: 4
 * */
  
  DECLARE dec_NewRegistro TEXT;
  DECLARE dec_OldRegistro TEXT;

  SELECT 
    group_concat(
         concat(
             "CODIGO: [",IFNULL(NEW.id_emdocumento         , ''),"] " 
            ,"NOMBRE: [",IFNULL(NEW.de_nombre, ''),"] " 
            ,"DESCRIPCION: [",IFNULL(NEW.de_descripcion, ''),"] "   
            ,"ESTADO: [",IFNULL(fun_get_estado_gen(new.flEliminado), ''),"] " 
            ,"FECHA: [",IFNULL(NEW.fechaModificacion, ''),"] "
        )
        SEPARATOR ' '
    ) into dec_NewRegistro;
   
    INSERT INTO auditoria(id_tablas, tipo_auditoria, old_value, new_value, usuario, fecha) 
    VALUES (
        19,
        1,
        '', 
        dec_NewRegistro,
        NEW.userCreacion,
        now()
    );


END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla documentos_has_empleado
--

CREATE TABLE documentos_has_empleado (
  id_docemp int(11) NOT NULL,
  id_persona int(11) NOT NULL,
  id_emdocumento int(11) NOT NULL,
  emd_nombrefile varchar(250) NOT NULL,
  emd_pesofile decimal(15,4) NOT NULL,
  emd_emision date NOT NULL,
  emd_vigencia date NOT NULL,
  userCreacion varchar(50) DEFAULT NULL,
  fechaCreacion datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  userModificacion varchar(50) DEFAULT NULL,
  fechaModificacion datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  flEliminado int(11) NOT NULL DEFAULT '1'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Volcado de datos para la tabla documentos_has_empleado
--

INSERT INTO documentos_has_empleado (id_docemp, id_persona, id_emdocumento, emd_nombrefile, emd_pesofile, emd_emision, emd_vigencia, userCreacion, fechaCreacion, userModificacion, fechaModificacion, flEliminado) VALUES
(35, 6, 1, '10203040623411823b77a.pdf', '245275.0000', '2000-04-15', '2023-05-31', 'admin', '2022-03-17 23:58:42', 'admin', '2022-03-17 23:58:42', 1),
(36, 4, 1, '003909808623411d2a3da2.pdf', '245275.0000', '2020-10-10', '2025-12-31', 'admin', '2022-03-18 00:00:02', 'admin', '2022-03-18 00:00:02', 1),
(37, 13, 1, '405880946234edacb3c89.pdf', '9.3200', '2002-01-15', '2022-12-12', '004644398', '2022-03-18 15:38:04', '004644398', '2022-03-18 15:38:04', 1),
(38, 16, 1, '00485086762351d703ff2c.pdf', '662516.0000', '2100-01-01', '2100-01-01', '004644398', '2022-03-18 19:01:52', '004644398', '2022-03-18 19:01:52', 0),
(39, 16, 2, '00485086762351d83b5607.pdf', '662516.0000', '2100-01-01', '2100-01-01', '004644398', '2022-03-18 19:02:11', '004644398', '2022-03-18 19:02:11', 1),
(40, 16, 3, '00485086762351d9b2a02a.pdf', '137146.0000', '2100-01-01', '2020-02-01', '004644398', '2022-03-18 19:02:35', '004644398', '2022-03-18 19:02:35', 1),
(41, 16, 1, '00485086762351e219591d.pdf', '326350.0000', '2100-01-01', '2100-01-01', '004644398', '2022-03-18 19:04:49', '004644398', '2022-03-18 19:04:49', 0),
(42, 16, 1, '00485086762351e8927a51.pdf', '8960966.0000', '2100-01-01', '2020-03-15', '004644398', '2022-03-18 19:06:33', '004644398', '2022-03-18 19:06:33', 1),
(43, 13, 2, '4058809462351f43d48d0.pdf', '380619.0000', '2100-01-01', '2022-06-13', '004644398', '2022-03-18 19:09:39', '004644398', '2022-03-18 19:09:39', 0),
(44, 13, 3, '4058809462351f864c77f.pdf', '380619.0000', '2022-03-15', '2022-06-13', '004644398', '2022-03-18 19:10:46', '004644398', '2022-03-18 19:10:46', 1),
(45, 18, 1, '4825698762355c7e6647d.pdf', '159456.0000', '2011-04-22', '2023-02-10', '46480582', '2022-03-18 23:30:54', '46480582', '2022-03-18 23:30:54', 1),
(46, 18, 2, '4825698762355ca92a964.pdf', '281538.0000', '2100-01-01', '2100-01-01', '46480582', '2022-03-18 23:31:37', '46480582', '2022-03-18 23:31:37', 1),
(47, 18, 3, '4825698762355cb38745a.pdf', '200394.0000', '2100-01-01', '2100-01-01', '46480582', '2022-03-18 23:31:47', '46480582', '2022-03-18 23:31:47', 1),
(48, 19, 1, '4582687462355dd601d2e.pdf', '459180.0000', '2100-01-01', '2100-01-01', '46480582', '2022-03-18 23:36:38', '46480582', '2022-03-18 23:36:38', 1),
(49, 19, 2, '4582687462355de08fa1d.pdf', '453977.0000', '2100-01-01', '2100-01-01', '46480582', '2022-03-18 23:36:48', '46480582', '2022-03-18 23:36:48', 1),
(50, 19, 3, '4582687462355dec746a4.pdf', '453977.0000', '2100-01-01', '2100-01-01', '46480582', '2022-03-18 23:37:00', '46480582', '2022-03-18 23:37:00', 1);

--
-- Disparadores documentos_has_empleado
--
DELIMITER $$
CREATE TRIGGER trg_log_actualizar_documentos_has_empleado BEFORE UPDATE ON documentos_has_empleado FOR EACH ROW BEGIN

/*
 * REGISTRO: 1
 * EDICION : 2
 * ANULACION: 3
 * ELIMINACION: 4
 * */
  
  DECLARE dec_NewRegistro TEXT;
  DECLARE dec_OldRegistro TEXT;

  SELECT 
    group_concat(
        concat(
             "CODIGO: [",IFNULL(NEW.id_docemp       , ''),"] " 
            ,"TIPO DE DOCUMENTO: [",IFNULL(fun_get_documentos_empleado_gen(NEW.id_emdocumento ), ''),"] "  
            ,"FECHA EMISION: [",IFNULL(fun_get_fecha_indeterminado_gen(NEW.emd_emision ), ''),"] "
            ,"FECHA DE VIGENCIA: [",IFNULL(fun_get_fecha_indeterminado_gen(NEW.emd_vigencia ), ''),"] " 
            ,"ARCHIVO: [",IFNULL(NEW.emd_nombrefile, ''),"] "
            ,"ESTADO: [",IFNULL(fun_get_estado_gen(new.flEliminado), ''),"] " 
            ,"FECHA: [",IFNULL(NEW.fechaModificacion, ''),"] "
        )
        SEPARATOR ' '
    ) into dec_NewRegistro;
   
   SELECT 
    group_concat(
        concat(
             "CODIGO: [",IFNULL(OLD.id_docemp       , ''),"] " 
            ,"TIPO DE DOCUMENTO: [",IFNULL(fun_get_documentos_empleado_gen(OLD.id_emdocumento ), ''),"] "  
            ,"FECHA EMISION: [",IFNULL(fun_get_fecha_indeterminado_gen(OLD.emd_emision ), ''),"] "
            ,"FECHA DE VIGENCIA: [",IFNULL(fun_get_fecha_indeterminado_gen(OLD.emd_vigencia ), ''),"] " 
            ,"ARCHIVO: [",IFNULL(OLD.emd_nombrefile, ''),"] "
            ,"ESTADO: [",IFNULL(fun_get_estado_gen(OLD.flEliminado), ''),"] " 
            ,"FECHA: [",IFNULL(OLD.fechaModificacion, ''),"] "
        )
        SEPARATOR ' '
    ) into dec_OldRegistro;

    INSERT INTO auditoria(id_tablas, tipo_auditoria, old_value, new_value, usuario, fecha) 
    VALUES (
        8,
        2,
        dec_OldRegistro, 
        dec_NewRegistro,
        NEW.userModificacion,
        now()
    );


END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER trg_log_registrar_documentos_has_empleado BEFORE INSERT ON documentos_has_empleado FOR EACH ROW BEGIN

/*
 * REGISTRO: 1
 * EDICION : 2
 * ANULACION: 3
 * ELIMINACION: 4
 * */
  
  DECLARE dec_NewRegistro TEXT;
  DECLARE dec_OldRegistro TEXT;

  SELECT 
    group_concat(
        concat(
             "CODIGO: [",IFNULL(NEW.id_docemp       , ''),"] " 
            ,"TIPO DE DOCUMENTO: [",IFNULL(fun_get_documentos_empleado_gen(NEW.id_emdocumento ), ''),"] "  
            ,"FECHA EMISION: [",IFNULL(fun_get_fecha_indeterminado_gen(NEW.emd_emision ), ''),"] "
            ,"FECHA DE VIGENCIA: [",IFNULL(fun_get_fecha_indeterminado_gen(NEW.emd_vigencia ), ''),"] " 
            ,"ARCHIVO: [",IFNULL(NEW.emd_nombrefile, ''),"] "
            ,"ESTADO: [",IFNULL(fun_get_estado_gen(new.flEliminado), ''),"] " 
            ,"FECHA: [",IFNULL(NEW.fechaModificacion, ''),"] "
        )
        SEPARATOR ' '
    ) into dec_NewRegistro;
   
    INSERT INTO auditoria(id_tablas, tipo_auditoria, old_value, new_value, usuario, fecha) 
    VALUES (
        8,
        1,
        '', 
        dec_NewRegistro,
        NEW.userCreacion,
        now()
    );


END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla empleado
--

CREATE TABLE empleado (
  id_persona int(11) NOT NULL,
  phc_estado int(11) DEFAULT '1',
  phc_fecha_r datetime DEFAULT CURRENT_TIMESTAMP,
  phc_fecha_c datetime DEFAULT CURRENT_TIMESTAMP,
  phc_auditoria datetime DEFAULT CURRENT_TIMESTAMP,
  phc_codigo varchar(45) DEFAULT NULL,
  phc_foto_perfil varchar(200) DEFAULT 'NONE',
  userCreacion varchar(50) NOT NULL,
  fechaCreacion datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  userModificacion varchar(50) NOT NULL,
  fechaModificacion datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  flEliminado int(11) NOT NULL DEFAULT '1'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Volcado de datos para la tabla empleado
--

INSERT INTO empleado (id_persona, phc_estado, phc_fecha_r, phc_fecha_c, phc_auditoria, phc_codigo, phc_foto_perfil, userCreacion, fechaCreacion, userModificacion, fechaModificacion, flEliminado) VALUES
(1, 1, '2021-08-21 00:00:00', '2021-08-21 00:00:00', '2021-08-21 17:59:26', 'CODIGO', '12345678', '', '2022-03-14 21:26:12', '', '2022-03-14 21:26:12', 1),
(2, 1, '2022-02-01 00:00:00', '2022-02-01 00:00:00', '2022-03-17 23:52:36', 'CODIGO', 'NONE', 'admin', '2022-03-17 23:52:36', 'admin', '2022-03-17 23:52:36', 1),
(3, 1, '2022-02-15 00:00:00', '2022-02-15 00:00:00', '2022-03-17 23:53:53', 'CODIGO', 'NONE', 'admin', '2022-03-17 23:53:53', 'admin', '2022-03-17 23:53:53', 1),
(4, 1, '2022-02-21 00:00:00', '2022-02-21 00:00:00', '2022-03-17 23:55:17', 'CODIGO', 'NONE', 'admin', '2022-03-17 23:55:17', 'admin', '2022-03-17 23:55:17', 1),
(5, 1, '2022-01-27 00:00:00', '2022-01-27 00:00:00', '2022-03-17 23:56:16', 'CODIGO', 'NONE', 'admin', '2022-03-17 23:56:16', 'admin', '2022-03-17 23:56:16', 1),
(6, 1, '2022-03-17 00:00:00', '2022-03-17 00:00:00', '2022-03-17 23:57:16', 'CODIGO', 'NONE', 'admin', '2022-03-17 23:57:16', 'admin', '2022-03-17 23:57:16', 1),
(7, 1, '2022-01-15 00:00:00', '2022-01-15 00:00:00', '2022-03-18 00:05:31', 'CODIGO', 'NONE', 'admin', '2022-03-18 00:05:31', 'admin', '2022-03-18 00:05:31', 1),
(12, 1, '2022-03-18 00:00:00', '2022-03-18 00:00:00', '2022-03-18 10:38:02', 'CODIGO', '002018776', '004644398', '2022-03-18 10:38:02', '004644398', '2022-03-18 10:38:02', 1),
(13, 1, '2022-03-18 00:00:00', '2022-03-18 00:00:00', '2022-03-18 15:38:01', 'CODIGO', '40588094', '004644398', '2022-03-18 15:38:01', '004644398', '2022-03-18 15:38:01', 1),
(14, 1, '2022-03-02 00:00:00', '2022-03-02 00:00:00', '2022-03-18 18:37:23', 'CODIGO', 'NONE', '004644398', '2022-03-18 18:37:23', '004644398', '2022-03-18 18:37:23', 1),
(15, 1, '2022-03-17 00:00:00', '2022-03-17 00:00:00', '2022-03-18 18:41:02', 'CODIGO', 'NONE', '004644398', '2022-03-18 18:41:02', '004644398', '2022-03-18 18:41:02', 1),
(16, 1, '2022-03-18 00:00:00', '2022-03-18 00:00:00', '2022-03-18 18:43:42', 'CODIGO', 'NONE', '004644398', '2022-03-18 18:43:42', '004644398', '2022-03-18 18:43:42', 1),
(18, 1, '2022-03-17 00:00:00', '2022-03-17 00:00:00', '2022-03-18 23:23:54', 'CODIGO', 'NONE', '46480582', '2022-03-18 23:23:54', '46480582', '2022-03-18 23:23:54', 1),
(19, 1, '2022-03-18 00:00:00', '2022-03-18 00:00:00', '2022-03-18 23:33:59', 'CODIGO', 'NONE', '46480582', '2022-03-18 23:33:59', '46480582', '2022-03-18 23:33:59', 1),
(20, 1, '2022-03-19 00:00:00', '2022-03-19 00:00:00', '2022-03-19 10:27:03', 'CODIGO', '12344321', 'admin', '2022-03-19 10:27:03', 'admin', '2022-03-19 10:27:03', 1);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla empleado_has_cese
--

CREATE TABLE empleado_has_cese (
  id_cese int(11) NOT NULL,
  id_motivo int(11) NOT NULL,
  id_persona int(11) NOT NULL,
  id_lista int(11) NOT NULL,
  ce_fecha_cese datetime NOT NULL,
  ce_motivo text NOT NULL,
  userCreacion varchar(50) NOT NULL,
  fechaCreacion datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  userModificacion varchar(50) NOT NULL,
  fechaModificacion datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  flEliminado int(11) NOT NULL DEFAULT '1'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Volcado de datos para la tabla empleado_has_cese
--

INSERT INTO empleado_has_cese (id_cese, id_motivo, id_persona, id_lista, ce_fecha_cese, ce_motivo, userCreacion, fechaCreacion, userModificacion, fechaModificacion, flEliminado) VALUES
(33, 1, 6, 0, '2022-03-17 00:00:00', 'mejora USD', 'admin', '2022-03-18 00:01:48', 'admin', '2022-03-18 00:01:48', 1),
(34, 1, 20, 0, '2022-03-18 00:00:00', 'mejora USD', 'admin', '2022-03-19 22:06:03', 'admin', '2022-03-19 22:06:03', 1);

--
-- Disparadores empleado_has_cese
--
DELIMITER $$
CREATE TRIGGER trg_log_actualizar_empleado_has_cese BEFORE UPDATE ON empleado_has_cese FOR EACH ROW BEGIN

/*
 * REGISTRO: 1
 * EDICION : 2
 * ANULACION: 3
 * ELIMINACION: 4
 * */
  
  DECLARE dec_NewRegistro TEXT;
  DECLARE dec_OldRegistro TEXT;

  SELECT 
    group_concat(
        concat(
             "CODIGO: [",IFNULL(NEW.id_cese        , ''),"] " 
            ,"PERSONA: [",IFNULL(fun_get_nombres_persona_gen(NEW.id_persona ), ''),"] " 
            ,"MOTIVO DEL CESE: [",IFNULL(fun_get_motivo_cese_gen(NEW.id_motivo ), ''),"] "   
            ,"MOTIVO LISTA NEGRA: [",IFNULL(fun_get_motivo_lista_negra_gen(NEW.id_lista ), ''),"] "  
            ,"ESTADO: [",IFNULL(fun_get_estado_gen(new.flEliminado), ''),"] " 
            ,"FECHA: [",IFNULL(NEW.fechaModificacion, ''),"] "
        )
        SEPARATOR ' '
    ) into dec_NewRegistro;
   
   SELECT 
    group_concat(
        concat(
             "CODIGO: [",IFNULL(OLD.id_cese        , ''),"] " 
            ,"PERSONA: [",IFNULL(fun_get_nombres_persona_gen(OLD.id_persona ), ''),"] " 
            ,"MOTIVO DEL CESE: [",IFNULL(fun_get_motivo_cese_gen(OLD.id_motivo ), ''),"] "   
            ,"MOTIVO LISTA NEGRA: [",IFNULL(fun_get_motivo_lista_negra_gen(OLD.id_lista ), ''),"] "  
            ,"ESTADO: [",IFNULL(fun_get_estado_gen(OLD.flEliminado), ''),"] " 
            ,"FECHA: [",IFNULL(OLD.fechaModificacion, ''),"] "
        )
        SEPARATOR ' '
    ) into dec_OldRegistro;

    INSERT INTO auditoria(id_tablas, tipo_auditoria, old_value, new_value, usuario, fecha) 
    VALUES (
        9,
        2,
        dec_OldRegistro, 
        dec_NewRegistro,
        NEW.userModificacion,
        now()
    );


END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER trg_log_registrar_empleado_has_cese BEFORE INSERT ON empleado_has_cese FOR EACH ROW BEGIN

/*
 * REGISTRO: 1
 * EDICION : 2
 * ANULACION: 3
 * ELIMINACION: 4
 * */
  
  DECLARE dec_NewRegistro TEXT;
  DECLARE dec_OldRegistro TEXT;

  SELECT 
    group_concat(
        concat(
             "CODIGO: [",IFNULL(NEW.id_cese        , ''),"] " 
            ,"PERSONA: [",IFNULL(fun_get_nombres_persona_gen(NEW.id_persona ), ''),"] " 
            ,"MOTIVO DEL CESE: [",IFNULL(fun_get_motivo_cese_gen(NEW.id_motivo ), ''),"] "   
            ,"MOTIVO LISTA NEGRA: [",IFNULL(fun_get_motivo_lista_negra_gen(NEW.id_lista ), ''),"] "  
            ,"ESTADO: [",IFNULL(fun_get_estado_gen(new.flEliminado), ''),"] " 
            ,"FECHA: [",IFNULL(NEW.fechaModificacion, ''),"] "
        )
        SEPARATOR ' '
    ) into dec_NewRegistro;
   
    INSERT INTO auditoria(id_tablas, tipo_auditoria, old_value, new_value, usuario, fecha) 
    VALUES (
        9,
        1,
        '', 
        dec_NewRegistro,
        NEW.userCreacion,
        now()
    );


END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla feriado
--

CREATE TABLE feriado (
  id_feriado int(11) NOT NULL,
  fe_dia date DEFAULT NULL,
  fe_descripcion varchar(45) DEFAULT NULL,
  fe_estado int(11) DEFAULT '1',
  fe_fecha_r datetime DEFAULT CURRENT_TIMESTAMP,
  fe_fecha_c datetime DEFAULT CURRENT_TIMESTAMP,
  userCreacion varchar(50) NOT NULL,
  fechaCreacion datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  userModificacion varchar(50) NOT NULL,
  fechaModificacion datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  flEliminado int(11) NOT NULL DEFAULT '1'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla marcador
--

CREATE TABLE marcador (
  id_marcador int(11) NOT NULL,
  ma_tipo int(11) NOT NULL,
  ma_descripcion varchar(45) DEFAULT NULL,
  ma_abreviatura varchar(45) DEFAULT NULL,
  ma_estado int(11) DEFAULT '1',
  ma_fecha_r datetime DEFAULT CURRENT_TIMESTAMP,
  ma_fecha_c datetime DEFAULT CURRENT_TIMESTAMP,
  userCreacion varchar(50) NOT NULL,
  fechaCreacion datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  userModificacion varchar(50) NOT NULL,
  fechaModificacion datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  flEliminado int(11) NOT NULL DEFAULT '1'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Volcado de datos para la tabla marcador
--

INSERT INTO marcador (id_marcador, ma_tipo, ma_descripcion, ma_abreviatura, ma_estado, ma_fecha_r, ma_fecha_c, userCreacion, fechaCreacion, userModificacion, fechaModificacion, flEliminado) VALUES
(1, 1, 'MAÑANA', 'MA', 1, '2021-08-21 17:29:27', '2021-08-21 17:29:27', '', '2022-03-13 18:51:31', '', '2022-03-13 18:51:31', 1),
(2, 1, 'TARDE', 'TA', 1, '2021-08-21 17:29:27', '2021-08-21 17:29:27', '', '2022-03-13 18:51:31', '', '2022-03-13 18:51:31', 1),
(3, 1, 'NOCHE', 'NO', 1, '2021-08-21 17:29:27', '2021-08-21 17:29:27', '', '2022-03-13 18:51:31', '', '2022-03-13 18:51:31', 1),
(4, 2, 'DESCANSO', 'D', 1, '2021-08-22 22:43:10', '2021-08-22 22:43:10', '', '2022-03-13 18:51:31', '', '2022-03-13 18:51:31', 1),
(5, 2, 'FALTA', 'FAL', 1, '2021-08-22 22:43:10', '2021-08-22 22:43:10', '', '2022-03-13 18:51:31', '', '2022-03-13 18:51:31', 1),
(6, 2, 'PERMISO', 'PE', 1, '2021-08-24 00:06:02', '2021-08-24 00:06:02', '', '2022-03-13 18:51:31', '', '2022-03-13 18:51:31', 1);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla motivos_cese
--

CREATE TABLE motivos_cese (
  id_motivo int(11) NOT NULL,
  mo_nombre varchar(50) NOT NULL,
  userCreacion varchar(50) NOT NULL,
  fechaCreacion datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  userModificacion varchar(50) NOT NULL,
  fechaModificacion datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  flEliminado int(11) NOT NULL DEFAULT '1'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Volcado de datos para la tabla motivos_cese
--

INSERT INTO motivos_cese (id_motivo, mo_nombre, userCreacion, fechaCreacion, userModificacion, fechaModificacion, flEliminado) VALUES
(1, 'Renuncia voluntaria', 'JVERGARA', '2022-02-19 23:47:27', 'JVERGARA', '2022-02-19 23:47:27', 1),
(2, 'Despido arbitrario', 'JVERGARA', '2022-02-19 23:47:27', 'JVERGARA', '2022-02-19 23:47:27', 1),
(3, 'Error de inscripcion', 'JVERGARA', '2022-02-19 23:47:27', 'JVERGARA', '2022-02-19 23:47:27', 1);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla nacionalidad
--

CREATE TABLE nacionalidad (
  id_nacionalidad int(11) NOT NULL,
  na_descripcion varchar(45) DEFAULT NULL,
  na_abreviatura varchar(45) DEFAULT NULL,
  na_estado int(11) DEFAULT '1',
  na_fecha_r datetime DEFAULT CURRENT_TIMESTAMP,
  na_fecha_c datetime DEFAULT CURRENT_TIMESTAMP,
  userCreacion varchar(50) NOT NULL,
  fechaCreacion datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  userModificacion varchar(50) NOT NULL,
  fechaModificacion datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  flEliminado int(11) NOT NULL DEFAULT '1'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Volcado de datos para la tabla nacionalidad
--

INSERT INTO nacionalidad (id_nacionalidad, na_descripcion, na_abreviatura, na_estado, na_fecha_r, na_fecha_c, userCreacion, fechaCreacion, userModificacion, fechaModificacion, flEliminado) VALUES
(1, 'Peruana', 'PEER', 0, '2021-07-26 21:00:31', '2021-07-26 21:00:31', '', '2022-03-13 18:52:21', '12345678', '2022-03-17 16:53:04', 1),
(9, 'Venezolana', 'VNZ', 1, '2022-03-17 23:48:35', '2022-03-17 23:48:35', 'admin', '2022-03-17 23:48:35', 'admin', '2022-03-17 23:48:35', 1);

--
-- Disparadores nacionalidad
--
DELIMITER $$
CREATE TRIGGER trg_log_actualizar_nacionalidad BEFORE UPDATE ON nacionalidad FOR EACH ROW BEGIN

/*
 * REGISTRO: 1
 * EDICION : 2
 * ANULACION: 3
 * ELIMINACION: 4
 * */
  
  DECLARE dec_NewRegistro TEXT;
  DECLARE dec_OldRegistro TEXT;

  SELECT 
    group_concat(
        concat(
             "CODIGO: [",IFNULL(NEW.id_nacionalidad      , ''),"] " 
            ,"NOMBRE: [",IFNULL(NEW.na_descripcion, ''),"] " 
            ,"ABREVIATURA: [",IFNULL(NEW.na_abreviatura, ''),"] " 
            ,"ESTADO: [",IFNULL(fun_get_estado_gen(new.na_estado), ''),"] " 
            ,"FECHA: [",IFNULL(NEW.fechaModificacion, ''),"] "
        )
        SEPARATOR ' '
    ) into dec_NewRegistro;
   
   SELECT 
    group_concat(
       concat(
             "CODIGO: [",IFNULL(OLD.id_nacionalidad      , ''),"] " 
            ,"NOMBRE: [",IFNULL(OLD.na_descripcion, ''),"] " 
            ,"ABREVIATURA: [",IFNULL(OLD.na_abreviatura, ''),"] " 
            ,"ESTADO: [",IFNULL(fun_get_estado_gen(OLD.na_estado), ''),"] " 
            ,"FECHA: [",IFNULL(OLD.fechaModificacion, ''),"] "
        )
        SEPARATOR ' '
    ) into dec_OldRegistro;

    INSERT INTO auditoria(id_tablas, tipo_auditoria, old_value, new_value, usuario, fecha) 
    VALUES (
        16,
        2,
        dec_OldRegistro, 
        dec_NewRegistro,
        NEW.userModificacion,
        now()
    );


END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER trg_log_registrar_nacionalidad BEFORE INSERT ON nacionalidad FOR EACH ROW BEGIN

/*
 * REGISTRO: 1
 * EDICION : 2
 * ANULACION: 3
 * ELIMINACION: 4
 * */
  
  DECLARE dec_NewRegistro TEXT;
  DECLARE dec_OldRegistro TEXT;

  SELECT 
    group_concat(
        concat(
             "CODIGO: [",IFNULL(NEW.id_nacionalidad      , ''),"] " 
            ,"NOMBRE: [",IFNULL(NEW.na_descripcion, ''),"] " 
            ,"ABREVIATURA: [",IFNULL(NEW.na_abreviatura, ''),"] " 
            ,"ESTADO: [",IFNULL(fun_get_estado_gen(new.na_estado), ''),"] " 
            ,"FECHA: [",IFNULL(NEW.fechaModificacion, ''),"] "
        )
        SEPARATOR ' '
    ) into dec_NewRegistro;
   
    INSERT INTO auditoria(id_tablas, tipo_auditoria, old_value, new_value, usuario, fecha) 
    VALUES (
        16,
        1,
        '', 
        dec_NewRegistro,
        NEW.userCreacion,
        now()
    );


END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla permiso
--

CREATE TABLE permiso (
  id_permiso int(11) NOT NULL,
  pe_nombre varchar(50) DEFAULT NULL,
  pe_descripcion varchar(45) DEFAULT NULL,
  pe_fecha_r datetime DEFAULT CURRENT_TIMESTAMP,
  pe_fecha_c datetime DEFAULT CURRENT_TIMESTAMP,
  pe_estado int(11) DEFAULT '1',
  userCreacion varchar(50) NOT NULL,
  fechaCreacion datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  userModificacion varchar(50) NOT NULL,
  fechaModificacion datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  flEliminado int(11) NOT NULL DEFAULT '1'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Volcado de datos para la tabla permiso
--

INSERT INTO permiso (id_permiso, pe_nombre, pe_descripcion, pe_fecha_r, pe_fecha_c, pe_estado, userCreacion, fechaCreacion, userModificacion, fechaModificacion, flEliminado) VALUES
(1, 'COVID', 'COVID', '2021-07-26 20:59:51', '2021-07-26 20:59:51', 1, '', '2022-03-13 18:52:41', '', '2022-03-13 18:52:41', 1);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla persona
--

CREATE TABLE persona (
  id_persona int(11) NOT NULL,
  id_tpdocumento varchar(45) NOT NULL,
  id_nacionalidad int(11) NOT NULL,
  per_nombre varchar(100) DEFAULT NULL,
  per_apellido_paterno varchar(100) DEFAULT NULL,
  per_apellido_materno varchar(100) DEFAULT NULL,
  per_documento varchar(100) DEFAULT NULL,
  per_fecha_nac date DEFAULT NULL,
  per_celular varchar(12) DEFAULT NULL,
  per_correo varchar(50) DEFAULT NULL,
  per_nacionalidad varchar(45) DEFAULT NULL,
  pe_estado int(11) DEFAULT NULL,
  pe_fecha_ingreso datetime DEFAULT CURRENT_TIMESTAMP,
  pe_fecha_cese datetime DEFAULT CURRENT_TIMESTAMP,
  pe_titular int(11) DEFAULT NULL,
  pe_usuario int(11) DEFAULT NULL,
  pe_sexo varchar(1) DEFAULT NULL,
  pe_direccion varchar(45) DEFAULT NULL,
  userCreacion varchar(50) NOT NULL,
  fechaCreacion datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  userModificacion varchar(50) NOT NULL,
  fechaModificacion datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  flEliminado int(11) NOT NULL DEFAULT '1'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Volcado de datos para la tabla persona
--

INSERT INTO persona (id_persona, id_tpdocumento, id_nacionalidad, per_nombre, per_apellido_paterno, per_apellido_materno, per_documento, per_fecha_nac, per_celular, per_correo, per_nacionalidad, pe_estado, pe_fecha_ingreso, pe_fecha_cese, pe_titular, pe_usuario, pe_sexo, pe_direccion, userCreacion, fechaCreacion, userModificacion, fechaModificacion, flEliminado) VALUES
(1, 'DNI', 1, 'Administrador', '', '', '12345678', '2021-08-21', '123456789', 'correo@gmail.com', '1', 1, '2021-08-21 00:00:00', '2021-08-21 00:00:00', 1, 1, '2', 'Chincha', 'a', '2022-03-13 18:53:18', 'g', '2022-03-13 18:53:18', 1),
(2, 'DNI', 1, 'Marisol', 'Pasco', 'Chavez', '72260964', '1999-01-20', NULL, NULL, '1', 1, '2022-02-01 00:00:00', '2022-02-01 00:00:00', 1, 1, '1', 'Lima', 'admin', '2022-03-17 23:52:36', 'admin', '2022-03-17 23:52:36', 1),
(3, 'DNI', 1, 'Miriam', 'Halanoca', 'Mamani', '46480582', '1990-08-22', NULL, NULL, '1', 1, '2022-02-15 00:00:00', '2022-02-15 00:00:00', 1, 1, '1', 'Lima', 'admin', '2022-03-17 23:53:53', 'admin', '2022-03-17 23:53:53', 1),
(4, 'CE', 9, 'Zuleyker', 'Figueroa', 'Rodriguez', '003909808', '1988-11-18', NULL, NULL, '9', 1, '2022-02-21 00:00:00', '2022-02-21 00:00:00', 1, 1, '1', 'Lima', 'admin', '2022-03-17 23:55:17', 'admin', '2022-03-17 23:55:17', 1),
(5, 'CE', 9, 'Oscarly', 'Medina', 'Gil', '004644398', '1993-10-11', NULL, NULL, '9', 1, '2022-01-27 00:00:00', '2022-01-27 00:00:00', 1, 1, '1', 'Lima', 'admin', '2022-03-17 23:56:16', 'admin', '2022-03-17 23:56:16', 1),
(6, 'DNI', 1, 'Danny', 'Bolaños', 'Perez', '10203040', '1975-05-01', NULL, NULL, '1', 0, '2022-03-17 00:00:00', '2022-03-17 00:00:00', 1, 1, '2', NULL, 'admin', '2022-03-17 23:57:16', 'admin', '2022-03-17 23:57:16', 1),
(7, 'DNI', 1, 'Luis', 'Swayne', 'Grados', '80604020', '1970-04-19', NULL, NULL, '1', 1, '2022-01-15 00:00:00', '2022-01-15 00:00:00', 1, 1, '2', NULL, 'admin', '2022-03-18 00:05:31', 'admin', '2022-03-18 00:05:31', 1),
(12, 'CE', 9, 'ALEJANDRO JOSE', 'SALAZAR ', 'SALAZAR', '002018776', '1989-12-06', '922007239', NULL, '9', 1, '2022-03-18 00:00:00', '2022-03-18 00:00:00', 1, 1, '2', 'JR SAN MARTIN 3849', '004644398', '2022-03-18 10:38:02', '004644398', '2022-03-18 10:38:02', 1),
(13, 'DNI', 1, 'ELIDA ROSA', 'GONZALES', 'GUTIERREZ', '40588094', '1980-08-23', '999338323', NULL, '1', 1, '2022-03-18 00:00:00', '2022-03-18 00:00:00', 1, 1, '1', 'AV. SAN ANTONIO 179 INDEPENDENCIA', '004644398', '2022-03-18 15:38:01', '004644398', '2022-03-18 15:38:01', 1),
(14, 'CE', 9, 'JETSSA MAGDALY ', 'GOMEZ', 'TROMPETERO ', '004547356', '1879-10-05', '969798096', NULL, '9', 1, '2022-03-02 00:00:00', '2022-03-02 00:00:00', 1, 1, '1', 'PUENTE PIEDRA SAN LAZARO ', '004644398', '2022-03-18 18:37:23', '004644398', '2022-03-18 18:37:23', 1),
(15, 'CE', 9, 'DANIELA NACARELIS ', 'VARGAS ', 'ANTEQUERA', '005114915', '1996-08-21', '917496090', NULL, '9', 1, '2022-03-17 00:00:00', '2022-03-17 00:00:00', 1, 1, '1', 'AV CAMINO REAL ', '004644398', '2022-03-18 18:41:02', '004644398', '2022-03-18 18:41:02', 1),
(16, 'CE', 9, 'YUNELLY LIESKA ', 'DIAZ ', 'PEREIRA ', '004850867', '2022-02-10', NULL, NULL, '9', 1, '2022-03-18 00:00:00', '2022-03-18 00:00:00', 1, 1, '1', 'AV NARANJAL ON UNIVERSITARIA ', '004644398', '2022-03-18 18:43:42', '004644398', '2022-03-18 18:43:42', 1),
(17, 'CE', 9, 'ELIZABET ', 'RENGEL', 'GONZALES', '003488713', '1987-04-06', '985123654', 'ELIZBG@HOTMAIL.COM', '9', 1, NULL, '2022-01-16 00:00:00', 1, 1, '1', 'CALLE GARDENIAS 887', '46480582', '2022-03-18 22:45:23', '46480582', '2022-03-18 23:11:32', 1),
(18, 'DNI', 1, 'ANA', 'MALCA', 'ROJAS', '48256987', '1990-03-18', '985264588', NULL, '1', 1, '2022-03-17 00:00:00', '2022-03-17 00:00:00', 1, 1, '1', NULL, '46480582', '2022-03-18 23:23:54', '46480582', '2022-03-18 23:26:07', 1),
(19, 'DNI', 1, 'DOLORES', 'MEJIA ', 'RIOS', '45826874', '1992-03-18', '985647892', NULL, '1', 1, '2022-03-18 00:00:00', '2022-03-18 00:00:00', 1, 1, '1', NULL, '46480582', '2022-03-18 23:33:59', '46480582', '2022-03-18 23:33:59', 1),
(20, 'CE', 9, 'Paola', 'Suyon', 'Perez', '12344321', '2000-01-10', NULL, NULL, '9', 0, '2022-03-19 00:00:00', '2022-03-19 00:00:00', 1, 1, '1', NULL, 'admin', '2022-03-19 10:27:03', 'admin', '2022-03-19 10:27:03', 1);

--
-- Disparadores persona
--
DELIMITER $$
CREATE TRIGGER trg_log_registrar_persona BEFORE INSERT ON persona FOR EACH ROW BEGIN

/*
 * REGISTRO: 1
 * EDICION : 2
 * ANULACION: 3
 * ELIMINACION: 4
 * */
  
  DECLARE dec_NewRegistro TEXT;
  DECLARE dec_OldRegistro TEXT;

  SELECT 
    group_concat(
        concat(
             "CODIGO: [",IFNULL(NEW.id_persona, ''),"] " 
            ,"NOMBRE: [",IFNULL(NEW.per_nombre, ''),"] "
            ,"APELLIDO P: [",IFNULL(NEW.per_apellido_paterno, ''),"] "
            ,"APELLIDO M: [",IFNULL(NEW.per_apellido_materno, ''),"] "
            ,"SEXO: [",IFNULL(NEW.pe_sexo, ''),"] "
            ,"NACIONALIDAD: [",IFNULL(fun_get_nacionalidad_gen(NEW.id_nacionalidad), ''),"] "
            ,"TIPO DOCUMENTO: [",IFNULL(fun_get_tipo_documento_p_gen(NEW.id_tpdocumento), ''),"] " 
            ,"DOCUMENTO: [",IFNULL(NEW.per_documento, ''),"] "
            ,"FECHA DE NACIMIENTO: [",IFNULL(NEW.per_fecha_nac, ''),"] "
            ,"DIRECCION: [",IFNULL(NEW.pe_direccion, '') ,"] "
            ,"CELULAR: [",IFNULL(NEW.per_celular, ''),"] "
            ,"CORREO: [",IFNULL(NEW.per_correo, ''),"] "
            ,"FECHA DE INGRESO: [",IFNULL(NEW.pe_fecha_ingreso, ''),"] " 
        )
        SEPARATOR ' '
    ) into dec_NewRegistro;
   
    INSERT INTO auditoria(id_tablas, tipo_auditoria, old_value, new_value, usuario, fecha) 
    VALUES (
        1,
        1,
        '', 
        dec_NewRegistro,
        NEW.userModificacion,
        now()
    );


END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla persona_has_banco
--

CREATE TABLE persona_has_banco (
  id_phbanco int(11) NOT NULL,
  id_persona int(11) NOT NULL,
  id_banco int(11) NOT NULL,
  id_tpcuenta int(11) NOT NULL,
  phb_cuenta varchar(45) DEFAULT NULL,
  phb_cci varchar(45) DEFAULT NULL,
  phb_estado int(11) DEFAULT '1',
  phb_fecha_r datetime DEFAULT CURRENT_TIMESTAMP,
  phb_fecha_c datetime DEFAULT CURRENT_TIMESTAMP,
  userCreacion varchar(50) NOT NULL,
  fechaCreacion datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  userModificacion varchar(50) NOT NULL,
  fechaModificacion datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  flEliminado int(11) NOT NULL DEFAULT '1'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Volcado de datos para la tabla persona_has_banco
--

INSERT INTO persona_has_banco (id_phbanco, id_persona, id_banco, id_tpcuenta, phb_cuenta, phb_cci, phb_estado, phb_fecha_r, phb_fecha_c, userCreacion, fechaCreacion, userModificacion, fechaModificacion, flEliminado) VALUES
(1, 13, 1, 1, '0024587698741522', 'null', 1, '2022-03-18 15:38:01', '2022-03-18 15:38:01', '004644398', '2022-03-18 15:38:01', '004644398', '2022-03-18 15:38:01', 1),
(2, 17, 1, 1, '000012354525', '', 1, '2022-03-18 22:45:23', '2022-03-18 22:45:23', '46480582', '2022-03-18 22:45:23', '46480582', '2022-03-18 23:11:57', 1),
(3, 18, 1, 1, '45645216', NULL, 1, '2022-03-18 23:26:07', '2022-03-18 23:26:07', '46480582', '2022-03-18 23:26:07', '46480582', '2022-03-18 23:26:07', 1);

--
-- Disparadores persona_has_banco
--
DELIMITER $$
CREATE TRIGGER trg_log_actualizar_persona_has_banco BEFORE UPDATE ON persona_has_banco FOR EACH ROW BEGIN

/*
 * REGISTRO: 1
 * EDICION : 2
 * ANULACION: 3
 * ELIMINACION: 4
 * */
  
  DECLARE dec_NewRegistro TEXT;
  DECLARE dec_OldRegistro TEXT;

  SELECT 
    group_concat(
        concat(
             "CODIGO: [",IFNULL(NEW.id_phbanco     , ''),"] " 
            ,"BANCO: [",IFNULL(fun_get_banco_gen(NEW.id_banco), ''),"] "
            ,"TIPO DE CUENTA: [",IFNULL(fun_get_tipo_cuenta_gen(NEW.id_tpcuenta), ''),"] " 
            ,"CUENTA: [",IFNULL(NEW.phb_cuenta, ''),"] " 
            ,"CCI: [",IFNULL(NEW.phb_cci, ''),"] "  
            ,"ESTADO: [",IFNULL(fun_get_estado_gen(new.phb_estado), ''),"] " 
            ,"FECHA: [",IFNULL(NEW.fechaCreacion, ''),"] "
        )
        SEPARATOR ' '
    ) into dec_NewRegistro;
   
   SELECT 
    group_concat(
        concat(
             "CODIGO: [",IFNULL(OLD.id_phbanco     , ''),"] " 
            ,"BANCO: [",IFNULL(fun_get_banco_gen(OLD.id_banco), ''),"] "
            ,"TIPO DE CUENTA: [",IFNULL(fun_get_tipo_cuenta_gen(OLD.id_tpcuenta), ''),"] " 
            ,"CUENTA: [",IFNULL(OLD.phb_cuenta, ''),"] " 
            ,"CCI: [",IFNULL(OLD.phb_cci, ''),"] "  
            ,"ESTADO: [",IFNULL(fun_get_estado_gen(OLD.phb_estado), ''),"] " 
            ,"FECHA: [",IFNULL(OLD.fechaModificacion, ''),"] "
        )
        SEPARATOR ' '
    ) into dec_OldRegistro;

    INSERT INTO auditoria(id_tablas, tipo_auditoria, old_value, new_value, usuario, fecha) 
    VALUES (
        6,
        2,
        dec_OldRegistro, 
        dec_NewRegistro,
        NEW.userModificacion,
        now()
    );


END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER trg_log_registrar_persona_has_banco BEFORE INSERT ON persona_has_banco FOR EACH ROW BEGIN

/*
 * REGISTRO: 1
 * EDICION : 2
 * ANULACION: 3
 * ELIMINACION: 4
 * */
  
  DECLARE dec_NewRegistro TEXT;
  DECLARE dec_OldRegistro TEXT;

  SELECT 
    group_concat(
        concat(
             "CODIGO: [",IFNULL(NEW.id_phbanco     , ''),"] " 
            ,"BANCO: [",IFNULL(fun_get_banco_gen(NEW.id_banco), ''),"] "
            ,"TIPO DE CUENTA: [",IFNULL(fun_get_tipo_cuenta_gen(NEW.id_tpcuenta), ''),"] " 
            ,"CUENTA: [",IFNULL(NEW.phb_cuenta, ''),"] " 
            ,"CCI: [",IFNULL(NEW.phb_cci, ''),"] "  
            ,"ESTADO: [",IFNULL(fun_get_estado_gen(new.phb_estado), ''),"] " 
            ,"FECHA: [",IFNULL(NEW.fechaCreacion, ''),"] "
        )
        SEPARATOR ' '
    ) into dec_NewRegistro;
   
    INSERT INTO auditoria(id_tablas, tipo_auditoria, old_value, new_value, usuario, fecha) 
    VALUES (
        6,
        1,
        '', 
        dec_NewRegistro,
        NEW.userCreacion,
        now()
    );


END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla persona_has_listanegra
--

CREATE TABLE persona_has_listanegra (
  id_lista int(11) NOT NULL,
  id_persona int(11) NOT NULL,
  lis_motivo text NOT NULL,
  userCreacion varchar(50) NOT NULL,
  fechaCreacion datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  userModificacion varchar(50) NOT NULL,
  fechaModificacion datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  flEliminado int(11) NOT NULL DEFAULT '1'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Disparadores persona_has_listanegra
--
DELIMITER $$
CREATE TRIGGER trg_log_actualizar_persona_has_listanegra BEFORE UPDATE ON persona_has_listanegra FOR EACH ROW BEGIN

/*
 * REGISTRO: 1
 * EDICION : 2
 * ANULACION: 3
 * ELIMINACION: 4
 * */
  
  DECLARE dec_NewRegistro TEXT;
  DECLARE dec_OldRegistro TEXT;

  SELECT 
    group_concat(
        concat(
             "CODIGO: [",IFNULL(NEW.id_lista         , ''),"] " 
            ,"PERSONA: [",IFNULL(fun_get_nombres_persona_gen(NEW.id_persona ), ''),"] " 
            ,"MOTIVO LISTA NEGRA: [",IFNULL(NEW.lis_motivo , ''),"] "  
            ,"ESTADO: [",IFNULL(fun_get_estado_gen(new.flEliminado), ''),"] " 
            ,"FECHA: [",IFNULL(NEW.fechaModificacion, ''),"] "
        )
        SEPARATOR ' '
    ) into dec_NewRegistro;
   
   SELECT 
    group_concat(
        concat(
             "CODIGO: [",IFNULL(NEW.id_lista         , ''),"] " 
            ,"PERSONA: [",IFNULL(fun_get_nombres_persona_gen(NEW.id_persona ), ''),"] " 
            ,"MOTIVO LISTA NEGRA: [",IFNULL(NEW.lis_motivo , ''),"] "  
            ,"ESTADO: [",IFNULL(fun_get_estado_gen(new.flEliminado), ''),"] " 
            ,"FECHA: [",IFNULL(NEW.fechaModificacion, ''),"] "
        )
        SEPARATOR ' '
    ) into dec_OldRegistro;

    INSERT INTO auditoria(id_tablas, tipo_auditoria, old_value, new_value, usuario, fecha) 
    VALUES (
        10,
        3,
        dec_OldRegistro, 
        dec_NewRegistro,
        NEW.userModificacion,
        now()
    );


END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER trg_log_registrar_persona_has_listanegra BEFORE INSERT ON persona_has_listanegra FOR EACH ROW BEGIN

/*
 * REGISTRO: 1
 * EDICION : 2
 * ANULACION: 3
 * ELIMINACION: 4
 * */
  
  DECLARE dec_NewRegistro TEXT;
  DECLARE dec_OldRegistro TEXT;

  SELECT 
    group_concat(
        concat(
             "CODIGO: [",IFNULL(NEW.id_lista         , ''),"] " 
            ,"PERSONA: [",IFNULL(fun_get_nombres_persona_gen(NEW.id_persona ), ''),"] " 
            ,"MOTIVO LISTA NEGRA: [",IFNULL(NEW.lis_motivo , ''),"] "  
            ,"ESTADO: [",IFNULL(fun_get_estado_gen(new.flEliminado), ''),"] " 
            ,"FECHA: [",IFNULL(NEW.fechaModificacion, ''),"] "
        )
        SEPARATOR ' '
    ) into dec_NewRegistro;
   
    INSERT INTO auditoria(id_tablas, tipo_auditoria, old_value, new_value, usuario, fecha) 
    VALUES (
        10,
        1,
        '', 
        dec_NewRegistro,
        NEW.userCreacion,
        now()
    );


END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla planilla_procesada
--

CREATE TABLE planilla_procesada (
  id_proplanilla int(6) UNSIGNED NOT NULL,
  id_sede varchar(30) NOT NULL,
  ppla_documento varchar(30) NOT NULL,
  ppla_periodo varchar(30) NOT NULL,
  ppla_fecha_proceso datetime DEFAULT CURRENT_TIMESTAMP,
  userCreacion varchar(50) NOT NULL,
  fechaCreacion datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  userModificacion varchar(50) NOT NULL,
  fechaModificacion datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  flEliminado int(11) NOT NULL DEFAULT '1'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla pla_configuraciones
--

CREATE TABLE pla_configuraciones (
  id_configuracion int(10) UNSIGNED NOT NULL,
  pc_modo_descanso int(11) NOT NULL,
  pc_precio_noche decimal(9,2) DEFAULT NULL,
  cap_fecha datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  userCreacion varchar(50) NOT NULL,
  fechaCreacion datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  userModificacion varchar(50) NOT NULL,
  fechaModificacion datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  flEliminado int(11) NOT NULL DEFAULT '1'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Volcado de datos para la tabla pla_configuraciones
--

INSERT INTO pla_configuraciones (id_configuracion, pc_modo_descanso, pc_precio_noche, cap_fecha, userCreacion, fechaCreacion, userModificacion, fechaModificacion, flEliminado) VALUES
(1, 0, '1.36', '2021-09-12 21:28:50', '', '2022-03-13 18:55:37', '', '2022-03-13 18:55:37', 1);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla sede
--

CREATE TABLE sede (
  id_sede int(11) NOT NULL,
  se_descripcion varchar(45) DEFAULT NULL,
  se_lugar varchar(45) DEFAULT NULL,
  se_cantidad int(11) DEFAULT NULL,
  se_estado int(11) DEFAULT '1',
  se_fecha_r datetime DEFAULT CURRENT_TIMESTAMP,
  se_fecha_c datetime DEFAULT CURRENT_TIMESTAMP,
  userCreacion varchar(50) NOT NULL,
  fechaCreacion datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  userModificacion varchar(50) NOT NULL,
  fechaModificacion datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  flEliminado int(11) NOT NULL DEFAULT '1'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Volcado de datos para la tabla sede
--

INSERT INTO sede (id_sede, se_descripcion, se_lugar, se_cantidad, se_estado, se_fecha_r, se_fecha_c, userCreacion, fechaCreacion, userModificacion, fechaModificacion, flEliminado) VALUES
(1, 'CAAT HUACHO', 'HOSP.HUACHO', 99, 1, '2022-02-20 22:35:04', '2022-02-20 22:35:04', '', '2022-03-13 18:56:01', '004644398', '2022-03-18 10:45:31', 1),
(2, 'COMPLEJO IPD ', ' IPD ', 99, 1, '2022-03-18 06:24:25', '2022-03-18 06:24:25', '004644398', '2022-03-18 06:24:25', '004644398', '2022-03-18 06:24:25', 1),
(3, 'CAAT CAYETANO HEREDIA', 'LIMA', 99, 1, '2022-03-18 10:45:06', '2022-03-18 10:45:06', '004644398', '2022-03-18 10:45:06', '004644398', '2022-03-18 10:45:06', 1),
(4, 'HOSPITAL LANFRANCO', 'HOSPITAL LANFRANCO', 99, 1, '2022-03-18 22:54:33', '2022-03-18 22:54:33', '46480582', '2022-03-18 22:54:33', 'admin', '2022-03-21 22:09:28', 1),
(5, 'LANFRANCO', 'LANFRANCO', 99, 1, '2022-03-18 23:19:28', '2022-03-18 23:19:28', '46480582', '2022-03-18 23:19:28', 'admin', '2022-03-21 22:09:45', 1);

--
-- Disparadores sede
--
DELIMITER $$
CREATE TRIGGER trg_log_actualizar_sede BEFORE UPDATE ON sede FOR EACH ROW BEGIN

/*
 * REGISTRO: 1
 * EDICION : 2
 * ANULACION: 3
 * ELIMINACION: 4
 * */
  
  DECLARE dec_NewRegistro TEXT;
  DECLARE dec_OldRegistro TEXT;

  SELECT 
    group_concat(
        concat(
             "CODIGO: [",IFNULL(NEW.id_sede       , ''),"] " 
            ,"LUGAR: [",IFNULL(NEW.se_lugar, ''),"] " 
            ,"DESCRIPCION: [",IFNULL(NEW.se_descripcion, ''),"] "  
            ,"ESTADO: [",IFNULL(fun_get_estado_gen(new.se_estado), ''),"] " 
            ,"FECHA: [",IFNULL(NEW.fechaModificacion, ''),"] "
        )
        SEPARATOR ' '
    ) into dec_NewRegistro;
   
   SELECT 
    group_concat(
       concat(
             "CODIGO: [",IFNULL(OLD.id_sede       , ''),"] " 
            ,"LUGAR: [",IFNULL(OLD.se_lugar, ''),"] " 
            ,"DESCRIPCION: [",IFNULL(OLD.se_descripcion, ''),"] "  
            ,"ESTADO: [",IFNULL(fun_get_estado_gen(OLD.se_estado), ''),"] " 
            ,"FECHA: [",IFNULL(OLD.fechaModificacion, ''),"] "
        )
        SEPARATOR ' '
    ) into dec_OldRegistro;

    INSERT INTO auditoria(id_tablas, tipo_auditoria, old_value, new_value, usuario, fecha) 
    VALUES (
        17,
        2,
        dec_OldRegistro, 
        dec_NewRegistro,
        NEW.userModificacion,
        now()
    );


END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER trg_log_registrar_sede BEFORE INSERT ON sede FOR EACH ROW BEGIN

/*
 * REGISTRO: 1
 * EDICION : 2
 * ANULACION: 3
 * ELIMINACION: 4
 * */
  
  DECLARE dec_NewRegistro TEXT;
  DECLARE dec_OldRegistro TEXT;

  SELECT 
    group_concat(
        concat(
             "CODIGO: [",IFNULL(NEW.id_sede       , ''),"] " 
            ,"LUGAR: [",IFNULL(NEW.se_lugar, ''),"] " 
            ,"DESCRIPCION: [",IFNULL(NEW.se_descripcion, ''),"] "  
            ,"ESTADO: [",IFNULL(fun_get_estado_gen(new.se_estado), ''),"] " 
            ,"FECHA: [",IFNULL(NEW.fechaModificacion, ''),"] "
        )
        SEPARATOR ' '
    ) into dec_NewRegistro;
   
    INSERT INTO auditoria(id_tablas, tipo_auditoria, old_value, new_value, usuario, fecha) 
    VALUES (
        17,
        1,
        '', 
        dec_NewRegistro,
        NEW.userCreacion,
        now()
    );


END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla sede_empleado
--

CREATE TABLE sede_empleado (
  id_sede_em int(11) NOT NULL,
  id_persona int(11) DEFAULT NULL,
  id_sede int(11) DEFAULT NULL,
  sm_codigo varchar(45) DEFAULT NULL,
  sm_fecha_r datetime DEFAULT CURRENT_TIMESTAMP,
  sm_fecha_c datetime DEFAULT CURRENT_TIMESTAMP,
  sm_observacion text,
  sm_estado int(11) DEFAULT '1',
  userCreacion varchar(50) NOT NULL,
  fechaCreacion datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  userModificacion varchar(50) NOT NULL,
  fechaModificacion datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  flEliminado int(11) NOT NULL DEFAULT '1'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Volcado de datos para la tabla sede_empleado
--

INSERT INTO sede_empleado (id_sede_em, id_persona, id_sede, sm_codigo, sm_fecha_r, sm_fecha_c, sm_observacion, sm_estado, userCreacion, fechaCreacion, userModificacion, fechaModificacion, flEliminado) VALUES
(55, 2, 1, 'CODIGO', '2022-02-01 00:00:00', '2022-02-01 00:00:00', 'OBSERVACION', 1, 'admin', '2022-03-17 23:52:36', 'admin', '2022-03-17 23:52:36', 1),
(56, 3, 1, 'CODIGO', '2022-02-15 00:00:00', '2022-02-15 00:00:00', 'OBSERVACION', 1, 'admin', '2022-03-17 23:53:53', 'admin', '2022-03-17 23:53:53', 1),
(57, 4, 1, 'CODIGO', '2022-02-21 00:00:00', '2022-02-21 00:00:00', 'OBSERVACION', 1, 'admin', '2022-03-17 23:55:17', 'admin', '2022-03-17 23:55:17', 1),
(58, 5, 1, 'CODIGO', '2022-01-27 00:00:00', '2022-01-27 00:00:00', 'OBSERVACION', 1, 'admin', '2022-03-17 23:56:16', 'admin', '2022-03-17 23:56:16', 1),
(59, 6, 1, 'CODIGO', '2022-03-17 00:00:00', '2022-03-17 00:00:00', 'OBSERVACION', 1, 'admin', '2022-03-17 23:57:16', 'admin', '2022-03-17 23:57:16', 1),
(60, 7, 1, 'CODIGO', '2022-01-15 00:00:00', '2022-01-15 00:00:00', 'OBSERVACION', 1, 'admin', '2022-03-18 00:05:31', 'admin', '2022-03-18 00:05:31', 1),
(65, 12, 1, 'CODIGO', '2022-03-18 00:00:00', '2022-03-18 00:00:00', 'OBSERVACION', 1, '004644398', '2022-03-18 10:38:02', '004644398', '2022-03-18 10:38:02', 1),
(66, 13, 2, 'CODIGO', '2022-03-18 00:00:00', '2022-03-18 00:00:00', 'OBSERVACION', 1, '004644398', '2022-03-18 15:38:01', '004644398', '2022-03-18 15:38:01', 1),
(67, 14, 2, 'CODIGO', '2022-03-02 00:00:00', '2022-03-02 00:00:00', 'OBSERVACION', 1, '004644398', '2022-03-18 18:37:23', '004644398', '2022-03-18 18:37:23', 1),
(68, 15, 2, 'CODIGO', '2022-03-17 00:00:00', '2022-03-17 00:00:00', 'OBSERVACION', 1, '004644398', '2022-03-18 18:41:02', '004644398', '2022-03-18 18:41:02', 1),
(69, 16, 2, 'CODIGO', '2022-03-18 00:00:00', '2022-03-18 00:00:00', 'OBSERVACION', 1, '004644398', '2022-03-18 18:43:42', '004644398', '2022-03-18 18:43:42', 1),
(70, 18, 4, 'CODIGO', '2022-03-17 00:00:00', '2022-03-17 00:00:00', 'OBSERVACION', 1, '46480582', '2022-03-18 23:23:54', '46480582', '2022-03-18 23:23:54', 1),
(71, 18, 5, NULL, '2022-03-18 23:25:47', '2022-03-18 23:25:47', NULL, 1, '46480582', '2022-03-18 23:25:47', '46480582', '2022-03-18 23:25:47', 1),
(72, 19, 4, 'CODIGO', '2022-03-18 00:00:00', '2022-03-18 00:00:00', 'OBSERVACION', 1, '46480582', '2022-03-18 23:33:59', '46480582', '2022-03-18 23:33:59', 1),
(73, 19, 5, NULL, '2022-03-18 23:36:20', '2022-03-18 23:36:20', NULL, 1, '46480582', '2022-03-18 23:36:20', '46480582', '2022-03-18 23:36:20', 1),
(74, 20, 1, 'CODIGO', '2022-03-19 00:00:00', '2022-03-19 00:00:00', 'OBSERVACION', 1, 'admin', '2022-03-19 10:27:03', 'admin', '2022-03-19 10:27:03', 1);

--
-- Disparadores sede_empleado
--
DELIMITER $$
CREATE TRIGGER trg_log_actualizar_empleado_has_sede BEFORE UPDATE ON sede_empleado FOR EACH ROW BEGIN

/*
 * REGISTRO: 1
 * EDICION : 2
 * ANULACION: 3
 * ELIMINACION: 4
 * */
  
  DECLARE dec_NewRegistro TEXT;
  DECLARE dec_OldRegistro TEXT;

  SELECT 
    group_concat(
        concat(
             "CODIGO: [",IFNULL(NEW.id_sede_em    , ''),"] " 
            ,"SEDE: [",IFNULL(fun_get_sede_gen(NEW.id_sede), ''),"] "
            ,"OBSERVACION: [",IFNULL(NEW.sm_observacion, ''),"] " 
            ,"ESTADO: [",IFNULL(fun_get_estado_gen(new.sm_estado), ''),"] " 
            ,"FECHA: [",IFNULL(NEW.fechaCreacion, ''),"] "
        )
        SEPARATOR ' '
    ) into dec_NewRegistro;
   
   SELECT 
    group_concat(
        concat(
             "CODIGO: [",IFNULL(OLD.id_sede_em    , ''),"] " 
            ,"SEDE: [",IFNULL(fun_get_sede_gen(OLD.id_sede), ''),"] "
            ,"OBSERVACION: [",IFNULL(OLD.sm_observacion, ''),"] " 
            ,"ESTADO: [",IFNULL(fun_get_estado_gen(OLD.sm_estado), ''),"] " 
            ,"FECHA: [",IFNULL(OLD.fechaCreacion, ''),"] "
        )
        SEPARATOR ' '
    ) into dec_OldRegistro;

    INSERT INTO auditoria(id_tablas, tipo_auditoria, old_value, new_value, usuario, fecha) 
    VALUES (
        5,
        2,
        dec_OldRegistro, 
        dec_NewRegistro,
        NEW.userModificacion,
        now()
    );


END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER trg_log_registrar_empleado_has_sede BEFORE INSERT ON sede_empleado FOR EACH ROW BEGIN

/*
 * REGISTRO: 1
 * EDICION : 2
 * ANULACION: 3
 * ELIMINACION: 4
 * */
  
  DECLARE dec_NewRegistro TEXT;
  DECLARE dec_OldRegistro TEXT;

  SELECT 
    group_concat(
        concat(
             "CODIGO: [",IFNULL(NEW.id_sede_em    , ''),"] " 
            ,"SEDE: [",IFNULL(fun_get_sede_gen(NEW.id_sede), ''),"] "
            ,"OBSERVACION: [",IFNULL(NEW.sm_observacion, ''),"] " 
            ,"ESTADO: [",IFNULL(fun_get_estado_gen(new.sm_estado), ''),"] " 
            ,"FECHA: [",IFNULL(NEW.fechaCreacion, ''),"] "
        )
        SEPARATOR ' '
    ) into dec_NewRegistro;
   
    INSERT INTO auditoria(id_tablas, tipo_auditoria, old_value, new_value, usuario, fecha) 
    VALUES (
        5,
        1,
        '', 
        dec_NewRegistro,
        NEW.userCreacion,
        now()
    );


END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla sis_modulo
--

CREATE TABLE sis_modulo (
  id_smodulo int(11) NOT NULL,
  sm_nombre varchar(250) NOT NULL,
  sm_descripcion varchar(250) NOT NULL,
  userCreacion varchar(50) NOT NULL,
  fechaCreacion datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  userModificacion varchar(50) NOT NULL,
  fechaModificacion datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  flEliminado int(11) NOT NULL DEFAULT '1'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Volcado de datos para la tabla sis_modulo
--

INSERT INTO sis_modulo (id_smodulo, sm_nombre, sm_descripcion, userCreacion, fechaCreacion, userModificacion, fechaModificacion, flEliminado) VALUES
(1, 'Empleado', 'Manejo de los empleados', 'JVERGARA', '2022-02-10 21:39:12', 'JVERGARA', '2022-02-10 21:39:12', 1),
(2, 'Suplentes', 'Manejo de los suplentes', 'JVERGARA', '2022-02-10 21:39:12', 'JVERGARA', '2022-02-10 21:39:12', 1),
(3, 'Banco', 'Manejo de los bancos', 'JVERGARA', '2022-02-10 21:39:12', 'JVERGARA', '2022-02-10 21:39:12', 1),
(4, 'Documentos Identidad', 'Manejo de los documentos de identidad', 'JVERGARA', '2022-02-10 21:39:12', 'JVERGARA', '2022-02-10 21:39:12', 1),
(5, 'Nacionalidad', 'Manejo de las nacionalidades', 'JVERGARA', '2022-02-10 21:39:12', 'JVERGARA', '2022-02-10 21:39:12', 1),
(6, 'Sede', 'Manejo de las sedes', 'JVERGARA', '2022-02-10 21:39:12', 'JVERGARA', '2022-02-10 21:39:12', 1),
(7, 'Cargo', 'Manejo de las cargo', 'JVERGARA', '2022-02-10 21:39:12', 'JVERGARA', '2022-02-10 21:39:12', 1),
(8, 'Documentos Empleado', 'Manejo de los documentos de los empleado', 'JVERGARA', '2022-02-10 21:39:12', 'JVERGARA', '2022-02-10 21:39:12', 1),
(9, 'Cese', 'Manejo de los ceses', 'JVERGARA', '2022-02-10 21:39:12', 'JVERGARA', '2022-02-10 21:39:12', 1),
(10, 'Lista Negra', 'Manejo de las lista negra', 'JVERGARA', '2022-02-10 21:39:12', 'JVERGARA', '2022-02-10 21:39:12', 1),
(11, 'Usuarios', 'Manejo de los usuarios', 'JVERGARA', '2022-02-10 21:39:12', 'JVERGARA', '2022-02-10 21:39:12', 1),
(12, 'Tareo', 'Manejo de los tareos', 'JVERGARA', '2022-02-10 21:39:12', 'JVERGARA', '2022-02-10 21:39:12', 1),
(13, 'Planilla', 'Manejo de las Planillas', 'JVERGARA', '2022-02-10 21:39:12', 'JVERGARA', '2022-02-10 21:39:12', 1),
(14, 'Sustituto', 'Manejo de las personas sustitutas', 'JVERGARA', '2022-02-10 21:39:12', 'JVERGARA', '2022-02-10 21:39:12', 1),
(15, 'Tareo', 'Manejo de los tareos de los empleados', 'JVERGARA', '2022-02-10 21:39:12', 'JVERGARA', '2022-02-10 21:39:12', 1);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla sis_modulo_permiso
--

CREATE TABLE sis_modulo_permiso (
  id_mpermiso int(11) NOT NULL,
  id_smodulo int(11) NOT NULL,
  id_spermiso int(11) NOT NULL,
  userCreacion varchar(50) NOT NULL,
  fechaCreacion datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  userModificacion varchar(50) NOT NULL,
  fechaModificacion datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  flEliminado int(11) NOT NULL DEFAULT '1'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Volcado de datos para la tabla sis_modulo_permiso
--

INSERT INTO sis_modulo_permiso (id_mpermiso, id_smodulo, id_spermiso, userCreacion, fechaCreacion, userModificacion, fechaModificacion, flEliminado) VALUES
(1, 1, 1, 'JVERGARA', '2022-02-10 21:40:44', 'JVERGARA', '2022-01-18 23:32:42', 1),
(2, 1, 2, 'JVERGARA', '2022-02-10 21:40:44', 'JVERGARA', '2022-01-18 23:32:42', 1),
(3, 1, 3, 'JVERGARA', '2022-02-10 21:40:44', 'JVERGARA', '2022-01-18 23:32:42', 1),
(5, 1, 5, 'JVERGARA', '2022-02-10 21:40:44', 'JVERGARA', '2022-01-18 23:32:42', 1),
(6, 1, 6, 'JVERGARA', '2022-02-10 21:40:44', 'JVERGARA', '2022-01-18 23:32:42', 1),
(7, 1, 7, 'JVERGARA', '2022-02-10 21:40:44', 'JVERGARA', '2022-01-18 23:32:42', 1),
(8, 1, 8, 'JVERGARA', '2022-02-10 21:40:44', 'JVERGARA', '2022-01-18 23:32:42', 1),
(9, 1, 9, 'JVERGARA', '2022-02-10 21:40:44', 'JVERGARA', '2022-01-18 23:32:42', 1),
(10, 1, 10, 'JVERGARA', '2022-02-10 21:40:44', 'JVERGARA', '2022-01-18 23:32:42', 1),
(11, 3, 1, 'JVERGARA', '2022-02-10 21:40:44', 'JVERGARA', '2022-01-18 23:32:42', 1),
(12, 3, 2, 'JVERGARA', '2022-02-10 21:40:44', 'JVERGARA', '2022-01-18 23:32:42', 1),
(13, 4, 1, 'JVERGARA', '2022-02-10 21:40:44', 'JVERGARA', '2022-01-18 23:32:42', 1),
(14, 4, 2, 'JVERGARA', '2022-02-10 21:40:44', 'JVERGARA', '2022-01-18 23:32:42', 1),
(15, 5, 1, 'JVERGARA', '2022-02-10 21:40:44', 'JVERGARA', '2022-01-18 23:32:42', 1),
(16, 5, 2, 'JVERGARA', '2022-02-10 21:40:44', 'JVERGARA', '2022-01-18 23:32:42', 1),
(17, 6, 1, 'JVERGARA', '2022-02-10 21:40:44', 'JVERGARA', '2022-01-18 23:32:42', 1),
(18, 6, 2, 'JVERGARA', '2022-02-10 21:40:44', 'JVERGARA', '2022-01-18 23:32:42', 1),
(19, 7, 1, 'JVERGARA', '2022-02-10 21:40:44', 'JVERGARA', '2022-01-18 23:32:42', 1),
(20, 7, 2, 'JVERGARA', '2022-02-10 21:40:44', 'JVERGARA', '2022-01-18 23:32:42', 1),
(21, 8, 1, 'JVERGARA', '2022-02-10 21:40:44', 'JVERGARA', '2022-01-18 23:32:42', 1),
(22, 8, 2, 'JVERGARA', '2022-02-10 21:40:44', 'JVERGARA', '2022-01-18 23:32:42', 1),
(23, 9, 1, 'JVERGARA', '2022-02-10 21:40:44', 'JVERGARA', '2022-01-18 23:32:42', 1),
(24, 9, 11, 'JVERGARA', '2022-02-10 21:40:44', 'JVERGARA', '2022-01-18 23:32:42', 1),
(25, 10, 11, 'JVERGARA', '2022-02-10 21:40:44', 'JVERGARA', '2022-01-18 23:32:42', 1),
(26, 11, 2, 'JVERGARA', '2022-02-10 21:40:44', 'JVERGARA', '2022-01-18 23:32:42', 1),
(27, 11, 12, 'JVERGARA', '2022-02-10 21:40:44', 'JVERGARA', '2022-01-18 23:32:42', 1),
(28, 14, 1, 'JVERGARA', '2022-02-10 21:40:44', 'JVERGARA', '2022-01-18 23:32:42', 1),
(29, 14, 2, 'JVERGARA', '2022-02-10 21:40:44', 'JVERGARA', '2022-01-18 23:32:42', 1),
(30, 15, 13, 'JVERGARA', '2022-02-10 21:40:44', 'JVERGARA', '2022-01-18 23:32:42', 1),
(31, 15, 2, 'JVERGARA', '2022-02-10 21:40:44', 'JVERGARA', '2022-01-18 23:32:42', 1);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla sis_perfil_modperm
--

CREATE TABLE sis_perfil_modperm (
  id_permodper int(11) NOT NULL,
  id_mpermiso int(11) NOT NULL,
  id_tpusuario int(11) NOT NULL,
  userCreacion varchar(50) NOT NULL,
  fechaCreacion datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  userModificacion varchar(50) NOT NULL,
  fechaModificacion datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  flEliminado int(11) NOT NULL DEFAULT '1'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Volcado de datos para la tabla sis_perfil_modperm
--

INSERT INTO sis_perfil_modperm (id_permodper, id_mpermiso, id_tpusuario, userCreacion, fechaCreacion, userModificacion, fechaModificacion, flEliminado) VALUES
(1, 1, 1, 'JVERGARA', '2022-02-28 00:00:00', 'JVERGARA', '2022-02-28 00:00:00', 1),
(2, 2, 1, 'JVERGARA', '2022-02-28 00:00:00', 'JVERGARA', '2022-02-28 00:00:00', 1),
(3, 5, 1, 'JVERGARA', '2022-02-28 00:00:00', 'JVERGARA', '2022-02-28 00:00:00', 1),
(4, 6, 1, 'JVERGARA', '2022-02-28 00:00:00', '12345678', '2022-03-14 23:04:21', 1),
(5, 7, 1, 'JVERGARA', '2022-02-28 00:00:00', 'JVERGARA', '2022-02-28 00:00:00', 1),
(6, 8, 1, 'JVERGARA', '2022-02-28 00:00:00', 'JVERGARA', '2022-03-14 00:00:00', 1),
(7, 9, 1, 'JVERGARA', '2022-02-28 00:00:00', 'JVERGARA', '2022-02-28 00:00:00', 1),
(8, 10, 1, 'JVERGARA', '2022-02-28 00:00:00', 'JVERGARA', '2022-03-14 00:00:00', 1),
(9, 11, 1, 'JVERGARA', '2022-02-28 00:00:00', 'JVERGARA', '2022-02-28 00:00:00', 0),
(10, 12, 1, 'JVERGARA', '2022-02-28 00:00:00', 'JVERGARA', '2022-02-28 00:00:00', 0),
(11, 13, 1, 'JVERGARA', '2022-02-28 00:00:00', 'JVERGARA', '2022-02-28 00:00:00', 0),
(12, 14, 1, 'JVERGARA', '2022-02-28 00:00:00', 'JVERGARA', '2022-02-28 00:00:00', 0),
(13, 15, 1, 'JVERGARA', '2022-02-28 00:00:00', 'JVERGARA', '2022-02-28 00:00:00', 0),
(14, 16, 1, 'JVERGARA', '2022-02-28 00:00:00', 'JVERGARA', '2022-02-28 00:00:00', 0),
(15, 17, 1, 'JVERGARA', '2022-02-28 00:00:00', 'JVERGARA', '2022-02-28 00:00:00', 0),
(16, 18, 1, 'JVERGARA', '2022-02-28 00:00:00', 'JVERGARA', '2022-02-28 00:00:00', 0),
(17, 19, 1, 'JVERGARA', '2022-02-28 00:00:00', 'JVERGARA', '2022-02-28 00:00:00', 0),
(18, 20, 1, 'JVERGARA', '2022-02-28 00:00:00', 'JVERGARA', '2022-02-28 00:00:00', 0),
(19, 21, 1, 'JVERGARA', '2022-02-28 00:00:00', 'JVERGARA', '2022-02-28 00:00:00', 0),
(20, 22, 1, 'JVERGARA', '2022-02-28 00:00:00', 'JVERGARA', '2022-02-28 00:00:00', 0),
(21, 23, 1, 'JVERGARA', '2022-02-28 00:00:00', 'JVERGARA', '2022-02-28 00:00:00', 0),
(22, 24, 1, 'JVERGARA', '2022-02-28 00:00:00', 'JVERGARA', '2022-02-28 00:00:00', 0),
(23, 25, 1, 'JVERGARA', '2022-02-28 00:00:00', 'JVERGARA', '2022-02-28 00:00:00', 0),
(24, 26, 1, 'JVERGARA', '2022-02-28 00:00:00', 'JVERGARA', '2022-02-28 00:00:00', 0),
(25, 27, 1, 'JVERGARA', '2022-02-28 00:00:00', 'JVERGARA', '2022-02-28 00:00:00', 0),
(26, 28, 1, 'JVERGARA', '2022-02-28 00:00:00', 'JVERGARA', '2022-03-05 00:00:00', 0),
(27, 29, 1, 'JVERGARA', '2022-02-28 00:00:00', 'JVERGARA', '2022-03-05 00:00:00', 0),
(28, 5, 6, 'JVERGARA', '2022-02-28 00:00:00', 'JVERGARA', '2022-02-28 00:00:00', 1),
(29, 6, 6, 'JVERGARA', '2022-02-28 00:00:00', 'JVERGARA', '2022-02-28 00:00:00', 1),
(30, 1, 6, 'JVERGARA', '2022-02-28 00:00:00', 'JVERGARA', '2022-02-28 00:00:00', 1),
(31, 2, 6, 'JVERGARA', '2022-02-28 00:00:00', 'JVERGARA', '2022-02-28 00:00:00', 1),
(32, 7, 6, 'JVERGARA', '2022-02-28 00:00:00', 'JVERGARA', '2022-02-28 00:00:00', 1),
(33, 9, 6, 'JVERGARA', '2022-02-28 00:00:00', 'JVERGARA', '2022-02-28 00:00:00', 1),
(34, 10, 6, 'JVERGARA', '2022-02-28 00:00:00', 'JVERGARA', '2022-02-28 00:00:00', 1),
(35, 8, 6, 'JVERGARA', '2022-02-28 00:00:00', 'JVERGARA', '2022-02-28 00:00:00', 1),
(36, 11, 6, 'JVERGARA', '2022-02-28 00:00:00', 'JVERGARA', '2022-02-28 00:00:00', 1),
(37, 14, 6, 'JVERGARA', '2022-02-28 00:00:00', 'JVERGARA', '2022-02-28 00:00:00', 1),
(38, 12, 6, 'JVERGARA', '2022-02-28 00:00:00', 'JVERGARA', '2022-02-28 00:00:00', 1),
(39, 13, 6, 'JVERGARA', '2022-02-28 00:00:00', 'JVERGARA', '2022-02-28 00:00:00', 1),
(40, 17, 6, 'JVERGARA', '2022-02-28 00:00:00', 'JVERGARA', '2022-02-28 00:00:00', 1),
(41, 15, 6, 'JVERGARA', '2022-02-28 00:00:00', 'JVERGARA', '2022-02-28 00:00:00', 1),
(42, 16, 6, 'JVERGARA', '2022-02-28 00:00:00', 'JVERGARA', '2022-02-28 00:00:00', 1),
(43, 18, 6, 'JVERGARA', '2022-02-28 00:00:00', 'JVERGARA', '2022-02-28 00:00:00', 1),
(44, 19, 6, 'JVERGARA', '2022-02-28 00:00:00', 'JVERGARA', '2022-02-28 00:00:00', 1),
(45, 20, 6, 'JVERGARA', '2022-02-28 00:00:00', 'JVERGARA', '2022-02-28 00:00:00', 1),
(46, 23, 6, 'JVERGARA', '2022-02-28 00:00:00', 'JVERGARA', '2022-02-28 00:00:00', 1),
(47, 24, 6, 'JVERGARA', '2022-02-28 00:00:00', 'JVERGARA', '2022-02-28 00:00:00', 1),
(48, 21, 6, 'JVERGARA', '2022-02-28 00:00:00', 'JVERGARA', '2022-02-28 00:00:00', 1),
(49, 22, 6, 'JVERGARA', '2022-02-28 00:00:00', 'JVERGARA', '2022-02-28 00:00:00', 1),
(50, 25, 6, 'JVERGARA', '2022-02-28 00:00:00', 'JVERGARA', '2022-02-28 00:00:00', 1),
(51, 26, 6, 'JVERGARA', '2022-02-28 00:00:00', 'JVERGARA', '2022-02-28 00:00:00', 1),
(52, 27, 6, 'JVERGARA', '2022-02-28 00:00:00', 'JVERGARA', '2022-02-28 00:00:00', 1),
(53, 28, 6, 'JVERGARA', '2022-02-28 00:00:00', 'JVERGARA', '2022-02-28 00:00:00', 1),
(54, 29, 6, 'JVERGARA', '2022-02-28 00:00:00', 'JVERGARA', '2022-02-28 00:00:00', 1);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla sis_permiso
--

CREATE TABLE sis_permiso (
  id_spermiso int(11) NOT NULL,
  sp_nombre varchar(250) NOT NULL,
  sp_descripcion varchar(250) NOT NULL,
  userCreacion varchar(50) NOT NULL,
  fechaCreacion datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  userModificacion varchar(50) NOT NULL,
  fechaModificacion datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  flEliminado int(11) NOT NULL DEFAULT '1'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Volcado de datos para la tabla sis_permiso
--

INSERT INTO sis_permiso (id_spermiso, sp_nombre, sp_descripcion, userCreacion, fechaCreacion, userModificacion, fechaModificacion, flEliminado) VALUES
(1, 'Registrar', 'Registrar', 'JVERGARA', '2022-02-20 04:03:55', 'JVERGARA', '2022-02-20 04:03:55', 1),
(2, 'Editar', 'Editar', 'JVERGARA', '2022-02-20 04:03:55', 'JVERGARA', '2022-02-20 04:03:55', 1),
(3, 'Visualizar', 'Visualizar', 'JVERGARA', '2022-02-20 04:03:55', 'JVERGARA', '2022-02-20 04:03:55', 0),
(5, 'Acceso Cargo', 'Acceso Cargo', 'JVERGARA', '2022-02-20 04:03:55', 'JVERGARA', '2022-02-20 04:03:55', 1),
(6, 'Acceso Sueldo', 'Acceso Sueldo', 'JVERGARA', '2022-02-20 04:03:55', 'JVERGARA', '2022-02-20 04:03:55', 1),
(7, 'Acceso Sede', 'Acceso Sede', 'JVERGARA', '2022-02-20 04:03:55', 'JVERGARA', '2022-02-20 04:03:55', 1),
(8, 'Acceso Documentos', 'Acceso Documentos', 'JVERGARA', '2022-02-20 04:03:55', 'JVERGARA', '2022-02-20 04:03:55', 1),
(9, 'Acceso Descanso', 'Acceso Descanso', 'JVERGARA', '2022-02-20 04:03:55', 'JVERGARA', '2022-02-20 04:03:55', 1),
(10, 'Acceso Forma de pago', 'Acceso Forma de pago', 'JVERGARA', '2022-02-20 04:03:55', 'JVERGARA', '2022-02-20 04:03:55', 1),
(11, 'Anular', 'Anular', 'JVERGARA', '2022-02-20 04:03:55', 'JVERGARA', '2022-02-20 04:03:55', 1),
(12, 'Asignar permisos', 'Asignar permisos', 'JVERGARA', '2022-02-20 04:03:55', 'JVERGARA', '2022-02-20 04:03:55', 1),
(13, 'Eliminar', 'Eliminar datos', 'JVERGARA', '2022-02-20 04:03:55', 'JVERGARA', '2022-02-20 04:03:55', 1);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla sis_usuario_modperm
--

CREATE TABLE sis_usuario_modperm (
  id_usmodper int(11) NOT NULL,
  id_mpermiso int(11) NOT NULL,
  id_usuario int(11) NOT NULL,
  userCreacion varchar(50) NOT NULL,
  fechaCreacion datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  userModificacion varchar(50) NOT NULL,
  fechaModificacion datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  flEliminado int(11) NOT NULL DEFAULT '1'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Volcado de datos para la tabla sis_usuario_modperm
--

INSERT INTO sis_usuario_modperm (id_usmodper, id_mpermiso, id_usuario, userCreacion, fechaCreacion, userModificacion, fechaModificacion, flEliminado) VALUES
(127, 5, 1, 'JVERGARA', '2022-03-03 00:00:00', 'JVERGARA', '2022-03-03 00:00:00', 1),
(128, 6, 1, 'JVERGARA', '2022-03-03 00:00:00', 'JVERGARA', '2022-03-03 00:00:00', 1),
(129, 1, 1, 'JVERGARA', '2022-03-03 00:00:00', 'JVERGARA', '2022-03-03 00:00:00', 1),
(130, 2, 1, 'JVERGARA', '2022-03-03 00:00:00', 'JVERGARA', '2022-03-03 00:00:00', 1),
(131, 7, 1, 'JVERGARA', '2022-03-03 00:00:00', 'JVERGARA', '2022-03-03 00:00:00', 1),
(132, 9, 1, 'JVERGARA', '2022-03-03 00:00:00', 'JVERGARA', '2022-03-03 00:00:00', 1),
(133, 10, 1, 'JVERGARA', '2022-03-03 00:00:00', 'JVERGARA', '2022-03-03 00:00:00', 1),
(134, 8, 1, 'JVERGARA', '2022-03-03 00:00:00', 'JVERGARA', '2022-03-03 00:00:00', 1),
(135, 11, 1, 'JVERGARA', '2022-03-03 00:00:00', 'JVERGARA', '2022-03-03 00:00:00', 1),
(136, 14, 1, 'JVERGARA', '2022-03-03 00:00:00', 'JVERGARA', '2022-03-03 00:00:00', 1),
(137, 12, 1, 'JVERGARA', '2022-03-03 00:00:00', 'JVERGARA', '2022-03-03 00:00:00', 1),
(138, 13, 1, 'JVERGARA', '2022-03-03 00:00:00', 'JVERGARA', '2022-03-03 00:00:00', 1),
(139, 17, 1, 'JVERGARA', '2022-03-03 00:00:00', 'JVERGARA', '2022-03-03 00:00:00', 1),
(140, 15, 1, 'JVERGARA', '2022-03-03 00:00:00', 'JVERGARA', '2022-03-03 00:00:00', 1),
(141, 16, 1, 'JVERGARA', '2022-03-03 00:00:00', 'JVERGARA', '2022-03-03 00:00:00', 1),
(142, 18, 1, 'JVERGARA', '2022-03-03 00:00:00', 'JVERGARA', '2022-03-03 00:00:00', 1),
(143, 19, 1, 'JVERGARA', '2022-03-03 00:00:00', 'JVERGARA', '2022-03-03 00:00:00', 1),
(144, 20, 1, 'JVERGARA', '2022-03-03 00:00:00', 'JVERGARA', '2022-03-03 00:00:00', 1),
(145, 23, 1, 'JVERGARA', '2022-03-03 00:00:00', 'JVERGARA', '2022-03-03 00:00:00', 1),
(146, 24, 1, 'JVERGARA', '2022-03-03 00:00:00', 'JVERGARA', '2022-03-03 00:00:00', 1),
(147, 21, 1, 'JVERGARA', '2022-03-03 00:00:00', 'JVERGARA', '2022-03-03 00:00:00', 1),
(148, 22, 1, 'JVERGARA', '2022-03-03 00:00:00', 'JVERGARA', '2022-03-03 00:00:00', 1),
(149, 25, 1, 'JVERGARA', '2022-03-03 00:00:00', 'JVERGARA', '2022-03-03 00:00:00', 1),
(150, 26, 1, 'JVERGARA', '2022-03-03 00:00:00', 'JVERGARA', '2022-03-03 00:00:00', 1),
(151, 27, 1, 'JVERGARA', '2022-03-03 00:00:00', 'JVERGARA', '2022-03-03 00:00:00', 1),
(152, 28, 1, 'JVERGARA', '2022-03-03 00:00:00', 'JVERGARA', '2022-03-05 00:00:00', 1),
(153, 29, 1, 'JVERGARA', '2022-03-03 00:00:00', 'JVERGARA', '2022-03-05 00:00:00', 1),
(154, 1, 10, 'JVERGARA', '2022-03-05 00:00:00', 'JVERGARA', '2022-03-05 00:00:00', 1),
(155, 2, 10, 'JVERGARA', '2022-03-05 00:00:00', 'JVERGARA', '2022-03-05 00:00:00', 1),
(156, 5, 10, 'JVERGARA', '2022-03-05 00:00:00', 'JVERGARA', '2022-03-05 00:00:00', 1),
(157, 7, 10, 'JVERGARA', '2022-03-05 00:00:00', 'JVERGARA', '2022-03-05 00:00:00', 1),
(158, 9, 10, 'JVERGARA', '2022-03-05 00:00:00', 'JVERGARA', '2022-03-05 00:00:00', 1),
(159, 28, 10, 'JVERGARA', '2022-03-05 00:00:00', 'JVERGARA', '2022-03-05 00:00:00', 1),
(160, 29, 10, 'JVERGARA', '2022-03-05 00:00:00', 'JVERGARA', '2022-03-05 00:00:00', 1),
(175, 1, 11, 'JVERGARA', '2022-03-05 00:00:00', 'JVERGARA', '2022-03-05 00:00:00', 1),
(176, 2, 11, 'JVERGARA', '2022-03-05 00:00:00', 'JVERGARA', '2022-03-05 00:00:00', 1),
(177, 5, 11, 'JVERGARA', '2022-03-05 00:00:00', 'JVERGARA', '2022-03-05 00:00:00', 1),
(178, 7, 11, 'JVERGARA', '2022-03-05 00:00:00', 'JVERGARA', '2022-03-05 00:00:00', 1),
(179, 9, 11, 'JVERGARA', '2022-03-05 00:00:00', 'JVERGARA', '2022-03-05 00:00:00', 1),
(180, 28, 11, 'JVERGARA', '2022-03-05 00:00:00', 'JVERGARA', '2022-03-05 00:00:00', 1),
(181, 29, 11, 'JVERGARA', '2022-03-05 00:00:00', 'JVERGARA', '2022-03-05 00:00:00', 1),
(189, 1, 13, 'JVERGARA', '2022-03-05 00:00:00', 'JVERGARA', '2022-03-05 00:00:00', 1),
(190, 2, 13, 'JVERGARA', '2022-03-05 00:00:00', 'JVERGARA', '2022-03-05 00:00:00', 1),
(191, 5, 13, 'JVERGARA', '2022-03-05 00:00:00', 'JVERGARA', '2022-03-05 00:00:00', 1),
(192, 7, 13, 'JVERGARA', '2022-03-05 00:00:00', 'JVERGARA', '2022-03-05 00:00:00', 1),
(193, 9, 13, 'JVERGARA', '2022-03-05 00:00:00', 'JVERGARA', '2022-03-05 00:00:00', 1),
(194, 28, 13, 'JVERGARA', '2022-03-05 00:00:00', 'JVERGARA', '2022-03-05 00:00:00', 1),
(195, 29, 13, 'JVERGARA', '2022-03-05 00:00:00', 'JVERGARA', '2022-03-05 00:00:00', 1),
(196, 11, 14, 'JVERGARA', '2022-03-05 00:00:00', 'JVERGARA', '2022-03-05 00:00:00', 1),
(197, 17, 14, 'JVERGARA', '2022-03-05 00:00:00', 'JVERGARA', '2022-03-05 00:00:00', 1),
(198, 12, 14, 'JVERGARA', '2022-03-05 00:00:00', 'JVERGARA', '2022-03-05 00:00:00', 1),
(199, 13, 14, 'JVERGARA', '2022-03-05 00:00:00', 'JVERGARA', '2022-03-05 00:00:00', 1),
(200, 10, 14, 'JVERGARA', '2022-03-05 00:00:00', 'JVERGARA', '2022-03-05 00:00:00', 1),
(201, 8, 14, 'JVERGARA', '2022-03-05 00:00:00', 'JVERGARA', '2022-03-05 00:00:00', 1),
(202, 6, 14, 'JVERGARA', '2022-03-05 00:00:00', 'JVERGARA', '2022-03-05 00:00:00', 1),
(203, 1, 14, 'JVERGARA', '2022-03-05 00:00:00', 'JVERGARA', '2022-03-05 00:00:00', 1),
(204, 7, 14, 'JVERGARA', '2022-03-05 00:00:00', 'JVERGARA', '2022-03-05 00:00:00', 1),
(205, 20, 14, 'JVERGARA', '2022-03-05 00:00:00', 'JVERGARA', '2022-03-05 00:00:00', 1),
(206, 21, 14, 'JVERGARA', '2022-03-05 00:00:00', 'JVERGARA', '2022-03-05 00:00:00', 1),
(207, 9, 14, 'JVERGARA', '2022-03-05 00:00:00', 'JVERGARA', '2022-03-05 00:00:00', 1),
(208, 14, 14, 'JVERGARA', '2022-03-05 00:00:00', 'JVERGARA', '2022-03-05 00:00:00', 1),
(209, 15, 14, 'JVERGARA', '2022-03-05 00:00:00', 'JVERGARA', '2022-03-05 00:00:00', 1),
(210, 16, 14, 'JVERGARA', '2022-03-05 00:00:00', 'JVERGARA', '2022-03-05 00:00:00', 1),
(211, 24, 14, 'JVERGARA', '2022-03-05 00:00:00', 'JVERGARA', '2022-03-05 00:00:00', 1),
(212, 18, 14, 'JVERGARA', '2022-03-05 00:00:00', 'JVERGARA', '2022-03-05 00:00:00', 1),
(213, 29, 14, 'JVERGARA', '2022-03-05 00:00:00', 'JVERGARA', '2022-03-05 00:00:00', 1),
(214, 19, 14, 'JVERGARA', '2022-03-05 00:00:00', 'JVERGARA', '2022-03-05 00:00:00', 1),
(215, 28, 14, 'JVERGARA', '2022-03-05 00:00:00', 'JVERGARA', '2022-03-05 00:00:00', 1),
(216, 2, 14, 'JVERGARA', '2022-03-05 00:00:00', 'JVERGARA', '2022-03-05 00:00:00', 1),
(217, 23, 14, 'JVERGARA', '2022-03-05 00:00:00', 'JVERGARA', '2022-03-05 00:00:00', 1),
(218, 5, 14, 'JVERGARA', '2022-03-05 00:00:00', 'JVERGARA', '2022-03-05 00:00:00', 1),
(219, 22, 14, 'JVERGARA', '2022-03-05 00:00:00', 'JVERGARA', '2022-03-05 00:00:00', 1),
(220, 2, 15, 'JVERGARA', '2022-03-05 00:00:00', 'JVERGARA', '2022-03-05 00:00:00', 1),
(221, 8, 15, 'JVERGARA', '2022-03-05 00:00:00', 'JVERGARA', '2022-03-05 00:00:00', 1),
(222, 1, 16, 'JVERGARA', '2022-03-05 00:00:00', 'JVERGARA', '2022-03-05 00:00:00', 1),
(223, 2, 16, 'JVERGARA', '2022-03-05 00:00:00', 'JVERGARA', '2022-03-05 00:00:00', 1),
(224, 5, 16, 'JVERGARA', '2022-03-05 00:00:00', 'JVERGARA', '2022-03-05 00:00:00', 1),
(225, 7, 16, 'JVERGARA', '2022-03-05 00:00:00', 'JVERGARA', '2022-03-05 00:00:00', 1),
(226, 9, 16, 'JVERGARA', '2022-03-05 00:00:00', 'JVERGARA', '2022-03-05 00:00:00', 1),
(227, 2, 19, 'JVERGARA', '2022-03-05 00:00:00', 'JVERGARA', '2022-03-05 00:00:00', 1),
(228, 8, 19, 'JVERGARA', '2022-03-05 00:00:00', 'JVERGARA', '2022-03-05 00:00:00', 1),
(297, 11, 24, 'JVERGARA', '2022-03-11 00:00:00', 'JVERGARA', '2022-03-11 00:00:00', 1),
(298, 17, 24, 'JVERGARA', '2022-03-11 00:00:00', 'JVERGARA', '2022-03-11 00:00:00', 1),
(299, 12, 24, 'JVERGARA', '2022-03-11 00:00:00', 'JVERGARA', '2022-03-11 00:00:00', 1),
(300, 13, 24, 'JVERGARA', '2022-03-11 00:00:00', 'JVERGARA', '2022-03-11 00:00:00', 1),
(301, 10, 24, 'JVERGARA', '2022-03-11 00:00:00', 'JVERGARA', '2022-03-11 00:00:00', 1),
(302, 8, 24, 'JVERGARA', '2022-03-11 00:00:00', 'JVERGARA', '2022-03-11 00:00:00', 1),
(303, 6, 24, 'JVERGARA', '2022-03-11 00:00:00', 'JVERGARA', '2022-03-11 00:00:00', 1),
(304, 1, 24, 'JVERGARA', '2022-03-11 00:00:00', 'JVERGARA', '2022-03-11 00:00:00', 1),
(305, 7, 24, 'JVERGARA', '2022-03-11 00:00:00', 'JVERGARA', '2022-03-11 00:00:00', 1),
(306, 20, 24, 'JVERGARA', '2022-03-11 00:00:00', 'JVERGARA', '2022-03-11 00:00:00', 1),
(307, 21, 24, 'JVERGARA', '2022-03-11 00:00:00', 'JVERGARA', '2022-03-11 00:00:00', 1),
(308, 9, 24, 'JVERGARA', '2022-03-11 00:00:00', 'JVERGARA', '2022-03-11 00:00:00', 1),
(309, 14, 24, 'JVERGARA', '2022-03-11 00:00:00', 'JVERGARA', '2022-03-11 00:00:00', 1),
(310, 15, 24, 'JVERGARA', '2022-03-11 00:00:00', 'JVERGARA', '2022-03-11 00:00:00', 1),
(311, 16, 24, 'JVERGARA', '2022-03-11 00:00:00', 'JVERGARA', '2022-03-11 00:00:00', 1),
(312, 18, 24, 'JVERGARA', '2022-03-11 00:00:00', 'JVERGARA', '2022-03-11 00:00:00', 1),
(313, 29, 24, 'JVERGARA', '2022-03-11 00:00:00', 'JVERGARA', '2022-03-11 00:00:00', 1),
(314, 19, 24, 'JVERGARA', '2022-03-11 00:00:00', 'JVERGARA', '2022-03-11 00:00:00', 1),
(315, 28, 24, 'JVERGARA', '2022-03-11 00:00:00', 'JVERGARA', '2022-03-11 00:00:00', 1),
(316, 2, 24, 'JVERGARA', '2022-03-11 00:00:00', 'JVERGARA', '2022-03-11 00:00:00', 1),
(317, 5, 24, 'JVERGARA', '2022-03-11 00:00:00', 'JVERGARA', '2022-03-11 00:00:00', 1),
(318, 22, 24, 'JVERGARA', '2022-03-11 00:00:00', 'JVERGARA', '2022-03-11 00:00:00', 1),
(319, 30, 1, 'JVERGARA', '2022-03-12 00:00:00', 'JVERGARA', '2022-03-12 00:00:00', 1),
(320, 31, 1, 'JVERGARA', '2022-03-12 00:00:00', 'JVERGARA', '2022-03-12 00:00:00', 1),
(323, 1, 25, 'JVERGARA', '2022-03-12 00:00:00', 'JVERGARA', '2022-03-12 00:00:00', 1),
(324, 2, 25, 'JVERGARA', '2022-03-12 00:00:00', 'JVERGARA', '2022-03-12 00:00:00', 1),
(325, 5, 25, 'JVERGARA', '2022-03-12 00:00:00', 'JVERGARA', '2022-03-12 00:00:00', 1),
(326, 7, 25, 'JVERGARA', '2022-03-12 00:00:00', 'JVERGARA', '2022-03-12 00:00:00', 1),
(327, 9, 25, 'JVERGARA', '2022-03-12 00:00:00', 'JVERGARA', '2022-03-12 00:00:00', 1),
(328, 1, 26, 'JVERGARA', '2022-03-14 00:00:00', 'JVERGARA', '2022-03-14 00:00:00', 1),
(329, 2, 26, 'JVERGARA', '2022-03-14 00:00:00', 'JVERGARA', '2022-03-14 00:00:00', 1),
(330, 5, 26, '12345678', '2022-03-14 22:47:39', '12345678', '2022-03-14 22:47:39', 1),
(331, 6, 26, '12345678', '2022-03-14 22:47:39', '12345678', '2022-03-14 22:47:39', 1),
(332, 1, 27, '12345678', '2022-03-15 01:05:44', '12345678', '2022-03-15 01:05:44', 1),
(333, 2, 27, '12345678', '2022-03-15 01:05:44', '12345678', '2022-03-15 01:05:44', 1),
(334, 5, 27, '12345678', '2022-03-15 01:05:44', '12345678', '2022-03-15 01:05:44', 1),
(335, 6, 27, '12345678', '2022-03-15 01:05:44', '12345678', '2022-03-15 01:05:44', 1),
(336, 7, 27, '12345678', '2022-03-15 01:05:44', '12345678', '2022-03-15 01:05:44', 1),
(337, 8, 27, '12345678', '2022-03-15 01:05:44', '12345678', '2022-03-15 01:05:44', 1),
(338, 9, 27, '12345678', '2022-03-15 01:05:44', '12345678', '2022-03-15 01:05:44', 1),
(339, 10, 27, '12345678', '2022-03-15 01:05:44', '12345678', '2022-03-15 01:05:44', 1),
(347, 1, 28, '12345678', '2022-03-15 01:08:22', '12345678', '2022-03-15 01:08:22', 1),
(348, 2, 28, '12345678', '2022-03-15 01:08:22', '12345678', '2022-03-15 01:08:22', 1),
(349, 5, 28, '12345678', '2022-03-15 01:08:22', '12345678', '2022-03-15 01:08:22', 1),
(350, 6, 28, '12345678', '2022-03-15 01:08:22', '12345678', '2022-03-15 01:08:22', 1),
(351, 7, 28, '12345678', '2022-03-15 01:08:22', '12345678', '2022-03-15 01:08:22', 1),
(352, 8, 28, '12345678', '2022-03-15 01:08:22', '12345678', '2022-03-15 01:08:22', 1),
(353, 9, 28, '12345678', '2022-03-15 01:08:22', '12345678', '2022-03-15 01:08:22', 1),
(354, 10, 28, '12345678', '2022-03-15 01:08:22', '12345678', '2022-03-15 01:08:22', 1),
(455, 5, 21, '12345678', '2022-03-15 01:58:35', '12345678', '2022-03-15 01:58:35', 1),
(456, 6, 21, '12345678', '2022-03-15 01:58:35', '12345678', '2022-03-15 01:58:35', 1),
(457, 1, 21, '12345678', '2022-03-15 01:58:35', '12345678', '2022-03-15 01:58:35', 1),
(458, 2, 21, '12345678', '2022-03-15 01:58:35', '12345678', '2022-03-15 01:58:35', 1),
(459, 7, 21, '12345678', '2022-03-15 01:58:35', '12345678', '2022-03-15 01:58:35', 1),
(460, 9, 21, '12345678', '2022-03-15 01:58:35', '12345678', '2022-03-15 01:58:35', 1),
(461, 10, 21, '12345678', '2022-03-15 01:58:35', '12345678', '2022-03-15 01:58:35', 1),
(462, 8, 21, '12345678', '2022-03-15 01:58:35', '12345678', '2022-03-15 01:58:35', 1),
(463, 11, 21, '12345678', '2022-03-15 01:58:35', '12345678', '2022-03-15 01:58:35', 1),
(464, 14, 21, '12345678', '2022-03-15 01:58:35', '12345678', '2022-03-15 01:58:35', 1),
(465, 12, 21, '12345678', '2022-03-15 01:58:35', '12345678', '2022-03-15 01:58:35', 1),
(466, 13, 21, '12345678', '2022-03-15 01:58:35', '12345678', '2022-03-15 01:58:35', 1),
(467, 17, 21, '12345678', '2022-03-15 01:58:35', '12345678', '2022-03-15 01:58:35', 1),
(468, 15, 21, '12345678', '2022-03-15 01:58:35', '12345678', '2022-03-15 01:58:35', 1),
(469, 16, 21, '12345678', '2022-03-15 01:58:35', '12345678', '2022-03-15 01:58:35', 1),
(470, 18, 21, '12345678', '2022-03-15 01:58:35', '12345678', '2022-03-15 01:58:35', 1),
(471, 19, 21, '12345678', '2022-03-15 01:58:35', '12345678', '2022-03-15 01:58:35', 1),
(472, 20, 21, '12345678', '2022-03-15 01:58:35', '12345678', '2022-03-15 01:58:35', 1),
(473, 23, 21, '12345678', '2022-03-15 01:58:35', '12345678', '2022-03-15 01:58:35', 1),
(474, 24, 21, '12345678', '2022-03-15 01:58:35', '12345678', '2022-03-15 01:58:35', 1),
(475, 21, 21, '12345678', '2022-03-15 01:58:35', '12345678', '2022-03-15 01:58:35', 1),
(476, 22, 21, '12345678', '2022-03-15 01:58:35', '12345678', '2022-03-15 01:58:35', 1),
(477, 25, 21, '12345678', '2022-03-15 01:58:35', '12345678', '2022-03-15 01:58:35', 1),
(478, 26, 21, '12345678', '2022-03-15 01:58:35', '12345678', '2022-03-15 01:58:35', 1),
(479, 27, 21, '12345678', '2022-03-15 01:58:35', '12345678', '2022-03-15 01:58:35', 1),
(480, 28, 21, '12345678', '2022-03-15 01:58:35', '12345678', '2022-03-15 01:58:35', 1),
(481, 29, 21, '12345678', '2022-03-15 01:58:35', '12345678', '2022-03-15 01:58:35', 1),
(547, 1, 22, '12345678', '2022-03-16 21:13:30', '12345678', '2022-03-16 21:13:30', 1),
(548, 2, 22, '12345678', '2022-03-16 21:13:30', '12345678', '2022-03-16 21:13:30', 1),
(549, 5, 22, '12345678', '2022-03-16 21:13:30', '12345678', '2022-03-16 21:13:30', 1),
(550, 6, 22, '12345678', '2022-03-16 21:13:30', '12345678', '2022-03-16 21:13:30', 1),
(551, 7, 22, '12345678', '2022-03-16 21:13:30', '12345678', '2022-03-16 21:13:30', 1),
(552, 8, 22, '12345678', '2022-03-16 21:13:30', '12345678', '2022-03-16 21:13:30', 1),
(553, 9, 22, '12345678', '2022-03-16 21:13:30', '12345678', '2022-03-16 21:13:30', 1),
(554, 10, 22, '12345678', '2022-03-16 21:13:30', '12345678', '2022-03-16 21:13:30', 1),
(562, 1, 23, '12345678', '2022-03-16 21:59:47', '12345678', '2022-03-16 21:59:47', 1),
(563, 2, 23, '12345678', '2022-03-16 21:59:47', '12345678', '2022-03-16 21:59:47', 1),
(564, 5, 23, '12345678', '2022-03-16 21:59:47', '12345678', '2022-03-16 21:59:47', 1),
(565, 6, 23, '12345678', '2022-03-16 21:59:47', '12345678', '2022-03-16 21:59:47', 1),
(566, 7, 23, '12345678', '2022-03-16 21:59:47', '12345678', '2022-03-16 21:59:47', 1),
(567, 8, 23, '12345678', '2022-03-16 21:59:47', '12345678', '2022-03-16 21:59:47', 1),
(568, 9, 23, '12345678', '2022-03-16 21:59:47', '12345678', '2022-03-16 21:59:47', 1),
(569, 10, 23, '12345678', '2022-03-16 21:59:47', '12345678', '2022-03-16 21:59:47', 1),
(577, 1, 29, '12345678', '2022-03-16 22:49:57', '12345678', '2022-03-16 22:49:57', 1),
(578, 2, 29, '12345678', '2022-03-16 22:49:57', '12345678', '2022-03-16 22:49:57', 1),
(579, 5, 29, '12345678', '2022-03-16 22:49:57', '12345678', '2022-03-16 22:49:57', 1),
(580, 6, 29, '12345678', '2022-03-16 22:49:57', '12345678', '2022-03-16 22:49:57', 1),
(581, 7, 29, '12345678', '2022-03-16 22:49:57', '12345678', '2022-03-16 22:49:57', 1),
(582, 8, 29, '12345678', '2022-03-16 22:49:57', '12345678', '2022-03-16 22:49:57', 1),
(583, 9, 29, '12345678', '2022-03-16 22:49:57', '12345678', '2022-03-16 22:49:57', 1),
(584, 10, 29, '12345678', '2022-03-16 22:49:57', '12345678', '2022-03-16 22:49:57', 1),
(592, 1, 32, '12345678', '2022-03-17 15:17:45', '12345678', '2022-03-17 15:17:45', 1),
(593, 2, 32, '12345678', '2022-03-17 15:17:45', '12345678', '2022-03-17 15:17:45', 1),
(594, 5, 32, '12345678', '2022-03-17 15:17:45', '12345678', '2022-03-17 15:17:45', 1),
(595, 6, 32, '12345678', '2022-03-17 15:17:45', '12345678', '2022-03-17 15:17:45', 1),
(596, 7, 32, '12345678', '2022-03-17 15:17:45', '12345678', '2022-03-17 15:17:45', 1),
(597, 8, 32, '12345678', '2022-03-17 15:17:45', '12345678', '2022-03-17 15:17:45', 1),
(598, 9, 32, '12345678', '2022-03-17 15:17:45', '12345678', '2022-03-17 15:17:45', 1),
(599, 10, 32, '12345678', '2022-03-17 15:17:45', '12345678', '2022-03-17 15:17:45', 1),
(607, 1, 33, '12345678', '2022-03-17 20:13:28', '12345678', '2022-03-17 20:13:28', 1),
(608, 2, 33, '12345678', '2022-03-17 20:13:28', '12345678', '2022-03-17 20:13:28', 1),
(609, 5, 33, '12345678', '2022-03-17 20:13:28', '12345678', '2022-03-17 20:13:28', 1),
(610, 6, 33, '12345678', '2022-03-17 20:13:28', '12345678', '2022-03-17 20:13:28', 1),
(611, 7, 33, '12345678', '2022-03-17 20:13:28', '12345678', '2022-03-17 20:13:28', 1),
(612, 8, 33, '12345678', '2022-03-17 20:13:28', '12345678', '2022-03-17 20:13:28', 1),
(613, 9, 33, '12345678', '2022-03-17 20:13:28', '12345678', '2022-03-17 20:13:28', 1),
(614, 10, 33, '12345678', '2022-03-17 20:13:28', '12345678', '2022-03-17 20:13:28', 1),
(622, 1, 34, '12345678', '2022-03-17 20:47:06', '12345678', '2022-03-17 20:47:06', 1),
(623, 2, 34, '12345678', '2022-03-17 20:47:06', '12345678', '2022-03-17 20:47:06', 1),
(624, 5, 34, '12345678', '2022-03-17 20:47:06', '12345678', '2022-03-17 20:47:06', 1),
(625, 6, 34, '12345678', '2022-03-17 20:47:06', '12345678', '2022-03-17 20:47:06', 1),
(626, 7, 34, '12345678', '2022-03-17 20:47:06', '12345678', '2022-03-17 20:47:06', 1),
(627, 8, 34, '12345678', '2022-03-17 20:47:06', '12345678', '2022-03-17 20:47:06', 1),
(628, 9, 34, '12345678', '2022-03-17 20:47:06', '12345678', '2022-03-17 20:47:06', 1),
(629, 10, 34, '12345678', '2022-03-17 20:47:06', '12345678', '2022-03-17 20:47:06', 1),
(637, 1, 35, 'JVERGARA', '2022-03-17 00:00:00', 'JVERGARA', '2022-03-17 00:00:00', 1),
(638, 2, 35, 'JVERGARA', '2022-03-17 00:00:00', 'JVERGARA', '2022-03-17 00:00:00', 1),
(639, 5, 35, 'JVERGARA', '2022-03-17 00:00:00', 'JVERGARA', '2022-03-17 00:00:00', 1),
(640, 6, 35, 'JVERGARA', '2022-03-17 00:00:00', 'JVERGARA', '2022-03-17 00:00:00', 1),
(641, 7, 35, 'JVERGARA', '2022-03-17 00:00:00', 'JVERGARA', '2022-03-17 00:00:00', 1),
(642, 8, 35, 'JVERGARA', '2022-03-17 00:00:00', 'JVERGARA', '2022-03-17 00:00:00', 1),
(643, 9, 35, 'JVERGARA', '2022-03-17 00:00:00', 'JVERGARA', '2022-03-17 00:00:00', 1),
(644, 10, 35, 'JVERGARA', '2022-03-17 00:00:00', 'JVERGARA', '2022-03-17 00:00:00', 1),
(652, 5, 36, 'admin', '2022-03-17 23:52:36', 'admin', '2022-03-17 23:52:36', 1),
(653, 6, 36, 'admin', '2022-03-17 23:52:36', 'admin', '2022-03-17 23:52:36', 1),
(654, 1, 36, 'admin', '2022-03-17 23:52:36', 'admin', '2022-03-17 23:52:36', 1),
(655, 2, 36, 'admin', '2022-03-17 23:52:36', 'admin', '2022-03-17 23:52:36', 1),
(656, 7, 36, 'admin', '2022-03-17 23:52:36', 'admin', '2022-03-17 23:52:36', 1),
(657, 9, 36, 'admin', '2022-03-17 23:52:36', 'admin', '2022-03-17 23:52:36', 1),
(658, 10, 36, 'admin', '2022-03-17 23:52:36', 'admin', '2022-03-17 23:52:36', 1),
(659, 8, 36, 'admin', '2022-03-17 23:52:36', 'admin', '2022-03-17 23:52:36', 1),
(660, 11, 36, 'admin', '2022-03-17 23:52:36', 'admin', '2022-03-17 23:52:36', 1),
(661, 14, 36, 'admin', '2022-03-17 23:52:36', 'admin', '2022-03-17 23:52:36', 1),
(662, 12, 36, 'admin', '2022-03-17 23:52:36', 'admin', '2022-03-17 23:52:36', 1),
(663, 13, 36, 'admin', '2022-03-17 23:52:36', 'admin', '2022-03-17 23:52:36', 1),
(664, 17, 36, 'admin', '2022-03-17 23:52:36', 'admin', '2022-03-17 23:52:36', 1),
(665, 15, 36, 'admin', '2022-03-17 23:52:36', 'admin', '2022-03-17 23:52:36', 1),
(666, 16, 36, 'admin', '2022-03-17 23:52:36', 'admin', '2022-03-17 23:52:36', 1),
(667, 18, 36, 'admin', '2022-03-17 23:52:36', 'admin', '2022-03-17 23:52:36', 1),
(668, 19, 36, 'admin', '2022-03-17 23:52:36', 'admin', '2022-03-17 23:52:36', 1),
(669, 20, 36, 'admin', '2022-03-17 23:52:36', 'admin', '2022-03-17 23:52:36', 1),
(670, 23, 36, 'admin', '2022-03-17 23:52:36', 'admin', '2022-03-17 23:52:36', 1),
(671, 24, 36, 'admin', '2022-03-17 23:52:36', 'admin', '2022-03-17 23:52:36', 1),
(672, 21, 36, 'admin', '2022-03-17 23:52:36', 'admin', '2022-03-17 23:52:36', 1),
(673, 22, 36, 'admin', '2022-03-17 23:52:36', 'admin', '2022-03-17 23:52:36', 1),
(674, 25, 36, 'admin', '2022-03-17 23:52:36', 'admin', '2022-03-17 23:52:36', 1),
(675, 26, 36, 'admin', '2022-03-17 23:52:36', 'admin', '2022-03-17 23:52:36', 1),
(676, 27, 36, 'admin', '2022-03-17 23:52:36', 'admin', '2022-03-17 23:52:36', 1),
(677, 28, 36, 'admin', '2022-03-17 23:52:36', 'admin', '2022-03-17 23:52:36', 1),
(678, 29, 36, 'admin', '2022-03-17 23:52:36', 'admin', '2022-03-17 23:52:36', 1),
(679, 5, 37, 'admin', '2022-03-17 23:53:53', 'admin', '2022-03-17 23:53:53', 1),
(680, 6, 37, 'admin', '2022-03-17 23:53:53', 'admin', '2022-03-17 23:53:53', 1),
(681, 1, 37, 'admin', '2022-03-17 23:53:53', 'admin', '2022-03-17 23:53:53', 1),
(682, 2, 37, 'admin', '2022-03-17 23:53:53', 'admin', '2022-03-17 23:53:53', 1),
(683, 7, 37, 'admin', '2022-03-17 23:53:53', 'admin', '2022-03-17 23:53:53', 1),
(684, 9, 37, 'admin', '2022-03-17 23:53:53', 'admin', '2022-03-17 23:53:53', 1),
(685, 10, 37, 'admin', '2022-03-17 23:53:53', 'admin', '2022-03-17 23:53:53', 1),
(686, 8, 37, 'admin', '2022-03-17 23:53:53', 'admin', '2022-03-17 23:53:53', 1),
(687, 11, 37, 'admin', '2022-03-17 23:53:53', 'admin', '2022-03-17 23:53:53', 1),
(688, 14, 37, 'admin', '2022-03-17 23:53:53', 'admin', '2022-03-17 23:53:53', 1),
(689, 12, 37, 'admin', '2022-03-17 23:53:53', 'admin', '2022-03-17 23:53:53', 1),
(690, 13, 37, 'admin', '2022-03-17 23:53:53', 'admin', '2022-03-17 23:53:53', 1),
(691, 17, 37, 'admin', '2022-03-17 23:53:53', 'admin', '2022-03-17 23:53:53', 1),
(692, 15, 37, 'admin', '2022-03-17 23:53:53', 'admin', '2022-03-17 23:53:53', 1),
(693, 16, 37, 'admin', '2022-03-17 23:53:53', 'admin', '2022-03-17 23:53:53', 1),
(694, 18, 37, 'admin', '2022-03-17 23:53:53', 'admin', '2022-03-17 23:53:53', 1),
(695, 19, 37, 'admin', '2022-03-17 23:53:53', 'admin', '2022-03-17 23:53:53', 1),
(696, 20, 37, 'admin', '2022-03-17 23:53:53', 'admin', '2022-03-17 23:53:53', 1),
(697, 23, 37, 'admin', '2022-03-17 23:53:53', 'admin', '2022-03-17 23:53:53', 1),
(698, 24, 37, 'admin', '2022-03-17 23:53:53', 'admin', '2022-03-17 23:53:53', 1),
(699, 21, 37, 'admin', '2022-03-17 23:53:53', 'admin', '2022-03-17 23:53:53', 1),
(700, 22, 37, 'admin', '2022-03-17 23:53:53', 'admin', '2022-03-17 23:53:53', 1),
(701, 25, 37, 'admin', '2022-03-17 23:53:53', 'admin', '2022-03-17 23:53:53', 1),
(702, 26, 37, 'admin', '2022-03-17 23:53:53', 'admin', '2022-03-17 23:53:53', 1),
(703, 27, 37, 'admin', '2022-03-17 23:53:53', 'admin', '2022-03-17 23:53:53', 1),
(704, 28, 37, 'admin', '2022-03-17 23:53:53', 'admin', '2022-03-17 23:53:53', 1),
(705, 29, 37, 'admin', '2022-03-17 23:53:53', 'admin', '2022-03-17 23:53:53', 1),
(706, 5, 38, 'admin', '2022-03-17 23:55:17', 'admin', '2022-03-17 23:55:17', 1),
(707, 6, 38, 'admin', '2022-03-17 23:55:17', 'admin', '2022-03-17 23:55:17', 1),
(708, 1, 38, 'admin', '2022-03-17 23:55:17', 'admin', '2022-03-17 23:55:17', 1),
(709, 2, 38, 'admin', '2022-03-17 23:55:17', 'admin', '2022-03-17 23:55:17', 1),
(710, 7, 38, 'admin', '2022-03-17 23:55:17', 'admin', '2022-03-17 23:55:17', 1),
(711, 9, 38, 'admin', '2022-03-17 23:55:17', 'admin', '2022-03-17 23:55:17', 1),
(712, 10, 38, 'admin', '2022-03-17 23:55:17', 'admin', '2022-03-17 23:55:17', 1),
(713, 8, 38, 'admin', '2022-03-17 23:55:17', 'admin', '2022-03-17 23:55:17', 1),
(714, 11, 38, 'admin', '2022-03-17 23:55:17', 'admin', '2022-03-17 23:55:17', 1),
(715, 14, 38, 'admin', '2022-03-17 23:55:17', 'admin', '2022-03-17 23:55:17', 1),
(716, 12, 38, 'admin', '2022-03-17 23:55:17', 'admin', '2022-03-17 23:55:17', 1),
(717, 13, 38, 'admin', '2022-03-17 23:55:17', 'admin', '2022-03-17 23:55:17', 1),
(718, 17, 38, 'admin', '2022-03-17 23:55:17', 'admin', '2022-03-17 23:55:17', 1),
(719, 15, 38, 'admin', '2022-03-17 23:55:17', 'admin', '2022-03-17 23:55:17', 1),
(720, 16, 38, 'admin', '2022-03-17 23:55:17', 'admin', '2022-03-17 23:55:17', 1),
(721, 18, 38, 'admin', '2022-03-17 23:55:17', 'admin', '2022-03-17 23:55:17', 1),
(722, 19, 38, 'admin', '2022-03-17 23:55:17', 'admin', '2022-03-17 23:55:17', 1),
(723, 20, 38, 'admin', '2022-03-17 23:55:17', 'admin', '2022-03-17 23:55:17', 1),
(724, 23, 38, 'admin', '2022-03-17 23:55:17', 'admin', '2022-03-17 23:55:17', 1),
(725, 24, 38, 'admin', '2022-03-17 23:55:17', 'admin', '2022-03-17 23:55:17', 1),
(726, 21, 38, 'admin', '2022-03-17 23:55:17', 'admin', '2022-03-17 23:55:17', 1),
(727, 22, 38, 'admin', '2022-03-17 23:55:17', 'admin', '2022-03-17 23:55:17', 1),
(728, 25, 38, 'admin', '2022-03-17 23:55:17', 'admin', '2022-03-17 23:55:17', 1),
(729, 26, 38, 'admin', '2022-03-17 23:55:17', 'admin', '2022-03-17 23:55:17', 1),
(730, 27, 38, 'admin', '2022-03-17 23:55:17', 'admin', '2022-03-17 23:55:17', 1),
(731, 28, 38, 'admin', '2022-03-17 23:55:17', 'admin', '2022-03-17 23:55:17', 1),
(732, 29, 38, 'admin', '2022-03-17 23:55:17', 'admin', '2022-03-17 23:55:17', 1),
(733, 5, 39, 'admin', '2022-03-17 23:56:16', 'admin', '2022-03-17 23:56:16', 1),
(734, 6, 39, 'admin', '2022-03-17 23:56:16', 'admin', '2022-03-17 23:56:16', 1),
(735, 1, 39, 'admin', '2022-03-17 23:56:16', 'admin', '2022-03-17 23:56:16', 1),
(736, 2, 39, 'admin', '2022-03-17 23:56:16', 'admin', '2022-03-17 23:56:16', 1),
(737, 7, 39, 'admin', '2022-03-17 23:56:16', 'admin', '2022-03-17 23:56:16', 1),
(738, 9, 39, 'admin', '2022-03-17 23:56:16', 'admin', '2022-03-17 23:56:16', 1),
(739, 10, 39, 'admin', '2022-03-17 23:56:16', 'admin', '2022-03-17 23:56:16', 1),
(740, 8, 39, 'admin', '2022-03-17 23:56:16', 'admin', '2022-03-17 23:56:16', 1),
(741, 11, 39, 'admin', '2022-03-17 23:56:16', 'admin', '2022-03-17 23:56:16', 1),
(742, 14, 39, 'admin', '2022-03-17 23:56:16', 'admin', '2022-03-17 23:56:16', 1),
(743, 12, 39, 'admin', '2022-03-17 23:56:16', 'admin', '2022-03-17 23:56:16', 1),
(744, 13, 39, 'admin', '2022-03-17 23:56:16', 'admin', '2022-03-17 23:56:16', 1),
(745, 17, 39, 'admin', '2022-03-17 23:56:16', 'admin', '2022-03-17 23:56:16', 1),
(746, 15, 39, 'admin', '2022-03-17 23:56:16', 'admin', '2022-03-17 23:56:16', 1),
(747, 16, 39, 'admin', '2022-03-17 23:56:16', 'admin', '2022-03-17 23:56:16', 1),
(748, 18, 39, 'admin', '2022-03-17 23:56:16', 'admin', '2022-03-17 23:56:16', 1),
(749, 19, 39, 'admin', '2022-03-17 23:56:16', 'admin', '2022-03-17 23:56:16', 1),
(750, 20, 39, 'admin', '2022-03-17 23:56:16', 'admin', '2022-03-17 23:56:16', 1),
(751, 23, 39, 'admin', '2022-03-17 23:56:16', 'admin', '2022-03-17 23:56:16', 1),
(752, 24, 39, 'admin', '2022-03-17 23:56:16', 'admin', '2022-03-17 23:56:16', 1),
(753, 21, 39, 'admin', '2022-03-17 23:56:16', 'admin', '2022-03-17 23:56:16', 1),
(754, 22, 39, 'admin', '2022-03-17 23:56:16', 'admin', '2022-03-17 23:56:16', 1),
(755, 25, 39, 'admin', '2022-03-17 23:56:16', 'admin', '2022-03-17 23:56:16', 1),
(756, 26, 39, 'admin', '2022-03-17 23:56:16', 'admin', '2022-03-17 23:56:16', 1),
(757, 27, 39, 'admin', '2022-03-17 23:56:16', 'admin', '2022-03-17 23:56:16', 1),
(758, 28, 39, 'admin', '2022-03-17 23:56:16', 'admin', '2022-03-17 23:56:16', 1),
(759, 29, 39, 'admin', '2022-03-17 23:56:16', 'admin', '2022-03-17 23:56:16', 1),
(760, 5, 40, 'admin', '2022-03-17 23:57:16', 'admin', '2022-03-17 23:57:16', 1),
(761, 6, 40, 'admin', '2022-03-17 23:57:16', 'admin', '2022-03-17 23:57:16', 1),
(762, 1, 40, 'admin', '2022-03-17 23:57:16', 'admin', '2022-03-17 23:57:16', 1),
(763, 2, 40, 'admin', '2022-03-17 23:57:16', 'admin', '2022-03-17 23:57:16', 1),
(764, 7, 40, 'admin', '2022-03-17 23:57:16', 'admin', '2022-03-17 23:57:16', 1),
(765, 9, 40, 'admin', '2022-03-17 23:57:16', 'admin', '2022-03-17 23:57:16', 1),
(766, 10, 40, 'admin', '2022-03-17 23:57:16', 'admin', '2022-03-17 23:57:16', 1),
(767, 8, 40, 'admin', '2022-03-17 23:57:16', 'admin', '2022-03-17 23:57:16', 1),
(768, 11, 40, 'admin', '2022-03-17 23:57:16', 'admin', '2022-03-17 23:57:16', 1),
(769, 14, 40, 'admin', '2022-03-17 23:57:16', 'admin', '2022-03-17 23:57:16', 1),
(770, 12, 40, 'admin', '2022-03-17 23:57:16', 'admin', '2022-03-17 23:57:16', 1),
(771, 13, 40, 'admin', '2022-03-17 23:57:16', 'admin', '2022-03-17 23:57:16', 1),
(772, 17, 40, 'admin', '2022-03-17 23:57:16', 'admin', '2022-03-17 23:57:16', 1),
(773, 15, 40, 'admin', '2022-03-17 23:57:16', 'admin', '2022-03-17 23:57:16', 1),
(774, 16, 40, 'admin', '2022-03-17 23:57:16', 'admin', '2022-03-17 23:57:16', 1),
(775, 18, 40, 'admin', '2022-03-17 23:57:16', 'admin', '2022-03-17 23:57:16', 1),
(776, 19, 40, 'admin', '2022-03-17 23:57:16', 'admin', '2022-03-17 23:57:16', 1),
(777, 20, 40, 'admin', '2022-03-17 23:57:16', 'admin', '2022-03-17 23:57:16', 1),
(778, 23, 40, 'admin', '2022-03-17 23:57:16', 'admin', '2022-03-17 23:57:16', 1),
(779, 24, 40, 'admin', '2022-03-17 23:57:16', 'admin', '2022-03-17 23:57:16', 1),
(780, 21, 40, 'admin', '2022-03-17 23:57:16', 'admin', '2022-03-17 23:57:16', 1),
(781, 22, 40, 'admin', '2022-03-17 23:57:16', 'admin', '2022-03-17 23:57:16', 1),
(782, 25, 40, 'admin', '2022-03-17 23:57:16', 'admin', '2022-03-17 23:57:16', 1),
(783, 26, 40, 'admin', '2022-03-17 23:57:16', 'admin', '2022-03-17 23:57:16', 1),
(784, 27, 40, 'admin', '2022-03-17 23:57:16', 'admin', '2022-03-17 23:57:16', 1),
(785, 28, 40, 'admin', '2022-03-17 23:57:16', 'admin', '2022-03-17 23:57:16', 1),
(786, 29, 40, 'admin', '2022-03-17 23:57:16', 'admin', '2022-03-17 23:57:16', 1),
(787, 1, 41, 'admin', '2022-03-18 00:05:31', 'admin', '2022-03-18 00:05:31', 1),
(788, 2, 41, 'admin', '2022-03-18 00:05:31', 'admin', '2022-03-18 00:05:31', 1),
(789, 5, 41, 'admin', '2022-03-18 00:05:31', 'admin', '2022-03-18 00:05:31', 1),
(790, 6, 41, 'admin', '2022-03-18 00:05:31', 'admin', '2022-03-18 00:05:31', 1),
(791, 7, 41, 'admin', '2022-03-18 00:05:31', 'admin', '2022-03-18 00:05:31', 1),
(792, 8, 41, 'admin', '2022-03-18 00:05:31', 'admin', '2022-03-18 00:05:31', 1),
(793, 9, 41, 'admin', '2022-03-18 00:05:31', 'admin', '2022-03-18 00:05:31', 1),
(794, 10, 41, 'admin', '2022-03-18 00:05:31', 'admin', '2022-03-18 00:05:31', 1),
(795, 1, 46, '004644398', '2022-03-18 10:38:02', '004644398', '2022-03-18 10:38:02', 1),
(796, 2, 46, '004644398', '2022-03-18 10:38:02', '004644398', '2022-03-18 10:38:02', 1),
(797, 5, 46, '004644398', '2022-03-18 10:38:02', '004644398', '2022-03-18 10:38:02', 1),
(798, 6, 46, '004644398', '2022-03-18 10:38:02', '004644398', '2022-03-18 10:38:02', 1),
(799, 7, 46, '004644398', '2022-03-18 10:38:02', '004644398', '2022-03-18 10:38:02', 1),
(800, 8, 46, '004644398', '2022-03-18 10:38:02', '004644398', '2022-03-18 10:38:02', 1),
(801, 9, 46, '004644398', '2022-03-18 10:38:02', '004644398', '2022-03-18 10:38:02', 1),
(802, 10, 46, '004644398', '2022-03-18 10:38:02', '004644398', '2022-03-18 10:38:02', 1);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla sueldo
--

CREATE TABLE sueldo (
  id_sueldo int(11) NOT NULL,
  id_persona int(11) DEFAULT NULL,
  ta_vigenciaInicio date NOT NULL,
  ta_vigenciaFin date NOT NULL,
  ta_basico decimal(14,2) DEFAULT NULL,
  ta_estado int(11) DEFAULT '1',
  ta_observacion varchar(250) DEFAULT NULL,
  ta_fecha_r datetime DEFAULT CURRENT_TIMESTAMP,
  ta_fecha_c datetime DEFAULT CURRENT_TIMESTAMP,
  ta_csdia varchar(50) DEFAULT NULL,
  ta_asignacion_familiar decimal(14,2) DEFAULT NULL,
  ta_bonificacion decimal(14,2) DEFAULT NULL,
  ta_movilidad decimal(14,2) DEFAULT NULL,
  ta_alimentos decimal(14,2) DEFAULT NULL,
  ta_total decimal(14,2) DEFAULT NULL,
  userCreacion varchar(50) NOT NULL,
  fechaCreacion datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  userModificacion varchar(50) NOT NULL,
  fechaModificacion datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  flEliminado int(11) NOT NULL DEFAULT '1'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Volcado de datos para la tabla sueldo
--

INSERT INTO sueldo (id_sueldo, id_persona, ta_vigenciaInicio, ta_vigenciaFin, ta_basico, ta_estado, ta_observacion, ta_fecha_r, ta_fecha_c, ta_csdia, ta_asignacion_familiar, ta_bonificacion, ta_movilidad, ta_alimentos, ta_total, userCreacion, fechaCreacion, userModificacion, fechaModificacion, flEliminado) VALUES
(5, 12, '2022-03-18', '2022-03-31', '1000.00', 1, '', '2022-03-18 10:38:02', '2022-03-18 10:38:02', '0', '90.00', '1000.00', '1000.00', '1000.00', '4090.00', '004644398', '2022-03-18 10:38:02', '004644398', '2022-03-18 10:38:02', 1),
(6, 13, '2022-03-18', '2022-04-30', '1400.00', 1, '', '2022-03-18 15:38:01', '2022-03-18 15:38:01', '0', '0.00', '0.00', '0.00', '0.00', '1400.00', '004644398', '2022-03-18 15:38:01', '004644398', '2022-03-18 15:38:01', 1),
(7, 14, '2022-03-02', '2100-01-01', '1400.00', 1, '', '2022-03-18 18:37:23', '2022-03-18 18:37:23', '0', '0.00', '0.00', '0.00', '0.00', '1400.00', '004644398', '2022-03-18 18:37:23', '004644398', '2022-03-18 18:37:23', 1),
(8, 15, '2022-03-18', '2100-01-01', '1400.00', 1, '', '2022-03-18 18:41:02', '2022-03-18 18:41:02', '0', '0.00', '0.00', '0.00', '0.00', '1400.00', '004644398', '2022-03-18 18:41:02', '004644398', '2022-03-18 18:41:02', 1);

--
-- Disparadores sueldo
--
DELIMITER $$
CREATE TRIGGER trg_log_actualizar_empleado_has_sueldo BEFORE UPDATE ON sueldo FOR EACH ROW BEGIN

/*
 * REGISTRO: 1
 * EDICION : 2
 * ANULACION: 3
 * ELIMINACION: 4
 * */
  
  DECLARE dec_NewRegistro TEXT;
  DECLARE dec_OldRegistro TEXT;

  SELECT 
    group_concat(
        concat(
             "CODIGO: [",IFNULL(NEW.id_sueldo  , ''),"] " 
            ,"VIGENCIA I: [",IFNULL(NEW.ta_vigenciaInicio, ''),"] "
            ,"VIGENCIA F: [",IFNULL(fun_get_fecha_indeterminado_gen(NEW.ta_vigenciaFin), ''),"] "
            ,"BASICO: [",IFNULL(NEW.ta_basico, ''),"] " 
            ,"ASIGNACION FAMILIAR: [",IFNULL(NEW.ta_asignacion_familiar, ''),"] " 
            ,"BONIFICACION: [",IFNULL(NEW.ta_bonificacion, ''),"] " 
            ,"MOVILIDAD: [",IFNULL(NEW.ta_movilidad, ''),"] " 
            ,"ALIMENTOS: [",IFNULL(NEW.ta_alimentos, ''),"] " 
            ,"ESTADO: [",IFNULL(fun_get_estado_gen(new.ta_estado), ''),"] " 
            ,"FECHA: [",IFNULL(NEW.fechaCreacion, ''),"] "
        )
        SEPARATOR ' '
    ) into dec_NewRegistro;
   
   SELECT 
    group_concat(
        concat(
             "CODIGO: [",IFNULL(OLD.id_sueldo  , ''),"] " 
            ,"VIGENCIA I: [",IFNULL(OLD.ta_vigenciaInicio, ''),"] "
            ,"VIGENCIA F: [",IFNULL(fun_get_fecha_indeterminado_gen(OLD.ta_vigenciaFin), ''),"] "
            ,"BASICO: [",IFNULL(OLD.ta_basico, ''),"] " 
            ,"ASIGNACION FAMILIAR: [",IFNULL(OLD.ta_asignacion_familiar, ''),"] " 
            ,"BONIFICACION: [",IFNULL(OLD.ta_bonificacion, ''),"] " 
            ,"MOVILIDAD: [",IFNULL(OLD.ta_movilidad, ''),"] " 
            ,"ALIMENTOS: [",IFNULL(OLD.ta_alimentos, ''),"] " 
            ,"ESTADO: [",IFNULL(fun_get_estado_gen(OLD.ta_estado), ''),"] " 
            ,"FECHA: [",IFNULL(OLD.fechaCreacion, ''),"] "
        )
        SEPARATOR ' '
    ) into dec_OldRegistro;

    INSERT INTO auditoria(id_tablas, tipo_auditoria, old_value, new_value, usuario, fecha) 
    VALUES (
        3,
        2,
        dec_OldRegistro, 
        dec_NewRegistro,
        NEW.userModificacion,
        now()
    );


END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER trg_log_registrar_empleado_has_sueldo BEFORE INSERT ON sueldo FOR EACH ROW BEGIN

/*
 * REGISTRO: 1
 * EDICION : 2
 * ANULACION: 3
 * ELIMINACION: 4
 * */
  
  DECLARE dec_NewRegistro TEXT;
  DECLARE dec_OldRegistro TEXT;

  SELECT 
    group_concat(
        concat(
             "CODIGO: [",IFNULL(NEW.id_sueldo  , ''),"] " 
            ,"VIGENCIA I: [",IFNULL(NEW.ta_vigenciaInicio, ''),"] "
            ,"VIGENCIA F: [",IFNULL(fun_get_fecha_indeterminado_gen(NEW.ta_vigenciaFin), ''),"] "
            ,"BASICO: [",IFNULL(NEW.ta_basico, ''),"] " 
            ,"ASIGNACION FAMILIAR: [",IFNULL(NEW.ta_asignacion_familiar, ''),"] " 
            ,"BONIFICACION: [",IFNULL(NEW.ta_bonificacion, ''),"] " 
            ,"MOVILIDAD: [",IFNULL(NEW.ta_movilidad, ''),"] " 
            ,"ALIMENTOS: [",IFNULL(NEW.ta_alimentos, ''),"] " 
            ,"ESTADO: [",IFNULL(fun_get_estado_gen(new.ta_estado), ''),"] " 
            ,"FECHA: [",IFNULL(NEW.fechaCreacion, ''),"] "
        )
        SEPARATOR ' '
    ) into dec_NewRegistro;
   
    INSERT INTO auditoria(id_tablas, tipo_auditoria, old_value, new_value, usuario, fecha) 
    VALUES (
        3,
        1,
        '', 
        dec_NewRegistro,
        NEW.userModificacion,
        now()
    );


END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla suplente_cobrar
--

CREATE TABLE suplente_cobrar (
  id_sucobrar int(11) NOT NULL,
  id_persona int(11) NOT NULL,
  suc_origen int(11) DEFAULT NULL,
  suc_estado int(11) DEFAULT '1',
  suc_fecha_r datetime DEFAULT CURRENT_TIMESTAMP,
  suc_fecha_c datetime DEFAULT CURRENT_TIMESTAMP,
  suc_observacion text,
  userCreacion varchar(50) NOT NULL,
  fechaCreacion datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  userModificacion varchar(50) NOT NULL,
  fechaModificacion datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  flEliminado int(11) NOT NULL DEFAULT '1'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Disparadores suplente_cobrar
--
DELIMITER $$
CREATE TRIGGER trg_log_actualizar_suplente_cobrar BEFORE UPDATE ON suplente_cobrar FOR EACH ROW BEGIN

/*
 * REGISTRO: 1
 * EDICION : 2
 * ANULACION: 3
 * ELIMINACION: 4
 * */
  
  DECLARE dec_NewRegistro TEXT;
  DECLARE dec_OldRegistro TEXT;

  SELECT 
    group_concat(
        concat(
             "CODIGO: [",IFNULL(NEW.id_sucobrar      , ''),"] " 
            ,"NOMBRES: [",IFNULL(fun_get_nombres_persona_gen(NEW.id_persona ), ''),"] "  
            ,"BANCO: [",IFNULL(fun_get_origen_banco_gen(NEW.id_persona ), ''),"] "
            ,"TIPO DE CUENTA: [",IFNULL(fun_get_origen_tp_cuenta_gen(NEW.id_persona ), ''),"] " 
            ,"CUENTA: [",IFNULL(fun_get_origen_cuenta_gen(NEW.id_persona ), ''),"] " 
            ,"CCI: [",IFNULL(fun_get_origen_cci_gen(NEW.id_persona ), ''),"] "  
            ,"ESTADO: [",IFNULL(fun_get_estado_gen(new.suc_estado), ''),"] " 
            ,"FECHA: [",IFNULL(NEW.fechaModificacion, ''),"] "
        )
        SEPARATOR ' '
    ) into dec_NewRegistro;
   
   SELECT 
    group_concat(
        concat(
             "CODIGO: [",IFNULL(OLD.id_sucobrar      , ''),"] " 
            ,"NOMBRES: [",IFNULL(fun_get_nombres_persona_gen(OLD.id_persona ), ''),"] "  
            ,"BANCO: [",IFNULL(fun_get_origen_banco_gen(OLD.id_persona ), ''),"] "
            ,"TIPO DE CUENTA: [",IFNULL(fun_get_origen_tp_cuenta_gen(OLD.id_persona ), ''),"] " 
            ,"CUENTA: [",IFNULL(fun_get_origen_cuenta_gen(OLD.id_persona ), ''),"] " 
            ,"CCI: [",IFNULL(fun_get_origen_cci_gen(OLD.id_persona ), ''),"] "  
            ,"ESTADO: [",IFNULL(fun_get_estado_gen(OLD.suc_estado), ''),"] " 
            ,"FECHA: [",IFNULL(OLD.fechaModificacion, ''),"] "
        )
        SEPARATOR ' '
    ) into dec_OldRegistro;

    INSERT INTO auditoria(id_tablas, tipo_auditoria, old_value, new_value, usuario, fecha) 
    VALUES (
        7,
        2,
        dec_OldRegistro, 
        dec_NewRegistro,
        NEW.userModificacion,
        now()
    );


END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER trg_log_registrar_suplente_cobrar BEFORE INSERT ON suplente_cobrar FOR EACH ROW BEGIN

/*
 * REGISTRO: 1
 * EDICION : 2
 * ANULACION: 3
 * ELIMINACION: 4
 * */
  
  DECLARE dec_NewRegistro TEXT;
  DECLARE dec_OldRegistro TEXT;

  SELECT 
    group_concat(
        concat(
             "CODIGO: [",IFNULL(NEW.id_sucobrar      , ''),"] " 
            ,"NOMBRES: [",IFNULL(fun_get_nombres_persona_gen(NEW.id_persona), ''),"] "  
            ,"BANCO: [",IFNULL(fun_get_origen_banco_gen(NEW.id_persona), ''),"] "
            ,"TIPO DE CUENTA: [",IFNULL(fun_get_origen_tp_cuenta_gen(NEW.id_persona), ''),"] " 
            ,"CUENTA: [",IFNULL(fun_get_origen_cuenta_gen(NEW.id_persona), ''),"] " 
            ,"CCI: [",IFNULL(fun_get_origen_cci_gen(NEW.id_persona), ''),"] "  
            ,"ESTADO: [",IFNULL(fun_get_estado_gen(new.suc_estado), ''),"] " 
            ,"FECHA: [",IFNULL(NEW.fechaCreacion, ''),"] "
        )
        SEPARATOR ' '
    ) into dec_NewRegistro;
   
    INSERT INTO auditoria(id_tablas, tipo_auditoria, old_value, new_value, usuario, fecha) 
    VALUES (
        7,
        1,
        '', 
        dec_NewRegistro,
        NEW.userCreacion,
        now()
    );


END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla tablas_dba
--

CREATE TABLE tablas_dba (
  id_tablas int(11) NOT NULL,
  tbs_mostrar varchar(60) NOT NULL,
  tbs_real varchar(60) NOT NULL,
  userCreacion varchar(50) NOT NULL,
  fechaCreacion datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  userModificacion varchar(50) NOT NULL,
  fechaModificacion datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  flEliminado int(11) NOT NULL DEFAULT '1'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Volcado de datos para la tabla tablas_dba
--

INSERT INTO tablas_dba (id_tablas, tbs_mostrar, tbs_real, userCreacion, fechaCreacion, userModificacion, fechaModificacion, flEliminado) VALUES
(1, 'Empleados', 'empleado', 'JVERGARA', '2022-03-16 20:42:45', 'JVERGARA', '2022-03-16 20:42:45', 1),
(2, 'Cargos del empleado', 'cargos_empleado', 'JVERGARA', '2022-03-16 20:42:45', 'JVERGARA', '2022-03-16 20:42:45', 1),
(3, 'Sueldo del empleado', 'sueldo', 'JVERGARA', '2022-03-16 20:42:45', 'JVERGARA', '2022-03-16 20:42:45', 1),
(4, 'Descanso del empleado', 'descanso', 'JVERGARA', '2022-03-16 20:42:45', 'JVERGARA', '2022-03-16 20:42:45', 1),
(5, 'Sede del empleado', 'sede_empleado', 'JVERGARA', '2022-03-16 20:42:45', 'JVERGARA', '2022-03-16 20:42:45', 1),
(6, 'Banco del empleado', 'persona_has_banco', 'JVERGARA', '2022-03-16 20:42:45', 'JVERGARA', '2022-03-16 20:42:45', 1),
(7, 'Suplente a cobrar', 'suplente_cobrar', 'JVERGARA', '2022-03-16 20:42:45', 'JVERGARA', '2022-03-16 20:42:45', 1),
(8, 'Documentos de empleado', 'documentos_has_empleado', 'JVERGARA', '2022-03-16 20:42:45', 'JVERGARA', '2022-03-16 20:42:45', 1),
(9, 'Cese de empleado', 'empleado_has_cese', 'JVERGARA', '2022-03-16 20:42:45', 'JVERGARA', '2022-03-16 20:42:45', 1),
(10, 'Lista negra empleado', 'persona_has_listanegra', 'JVERGARA', '2022-03-16 20:42:45', 'JVERGARA', '2022-03-16 20:42:45', 1),
(11, 'Tareo', 'tareo', 'JVERGARA', '2022-03-16 20:42:45', 'JVERGARA', '2022-03-16 20:42:45', 1),
(12, 'Usuarios de los empleados', 'usuarios', 'JVERGARA', '2022-03-16 20:42:45', 'JVERGARA', '2022-03-16 20:42:45', 1),
(13, 'Perfiles de usuario', 'tipo_usuario', 'JVERGARA', '2022-03-16 20:42:45', 'JVERGARA', '2022-03-16 20:42:45', 1),
(14, 'Bancos', 'banco', 'JVERGARA', '2022-03-16 20:42:45', 'JVERGARA', '2022-03-16 20:42:45', 1),
(15, 'Documentos de identidad', 'tipo_documento', 'JVERGARA', '2022-03-16 20:42:45', 'JVERGARA', '2022-03-16 20:42:45', 1),
(16, 'Nacionalidad', 'nacionalidad', 'JVERGARA', '2022-03-16 20:42:45', 'JVERGARA', '2022-03-16 20:42:45', 1),
(17, 'Sedes', 'sede', 'JVERGARA', '2022-03-16 20:42:45', 'JVERGARA', '2022-03-16 20:42:45', 1),
(18, 'Cargo', 'cargo', 'JVERGARA', '2022-03-16 20:42:45', 'JVERGARA', '2022-03-16 20:42:45', 1),
(19, 'Documentos del empleado', 'documentos_empleado', 'JVERGARA', '2022-03-16 20:42:45', 'JVERGARA', '2022-03-16 20:42:45', 1);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla tareo
--

CREATE TABLE tareo (
  id_tareo int(11) NOT NULL,
  ta_remunerado int(11) NOT NULL DEFAULT '1',
  id_persona int(11) NOT NULL DEFAULT '0',
  id_sede_em int(11) DEFAULT NULL,
  id_sede int(11) DEFAULT NULL,
  id_cargo int(11) DEFAULT NULL,
  id_sueldo int(11) DEFAULT NULL,
  id_descanso int(11) DEFAULT NULL,
  id_marcador int(11) NOT NULL,
  ta_estado int(11) DEFAULT NULL,
  ta_etapa int(11) NOT NULL DEFAULT '0',
  ta_fecha_r datetime DEFAULT CURRENT_TIMESTAMP,
  ta_fecha_c datetime DEFAULT CURRENT_TIMESTAMP,
  ta_hora_r time DEFAULT NULL,
  ta_hora_c time DEFAULT NULL,
  ta_hrstrabajadas decimal(14,2) DEFAULT NULL,
  ta_usuario int(11) DEFAULT NULL,
  ta_permiso int(11) NOT NULL DEFAULT '0',
  ta_auditoria datetime DEFAULT CURRENT_TIMESTAMP,
  userCreacion varchar(50) DEFAULT NULL,
  fechaCreacion datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  userModificacion varchar(50) DEFAULT NULL,
  fechaModificacion datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  flEliminado int(11) NOT NULL DEFAULT '1'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Volcado de datos para la tabla tareo
--

INSERT INTO tareo (id_tareo, ta_remunerado, id_persona, id_sede_em, id_sede, id_cargo, id_sueldo, id_descanso, id_marcador, ta_estado, ta_etapa, ta_fecha_r, ta_fecha_c, ta_hora_r, ta_hora_c, ta_hrstrabajadas, ta_usuario, ta_permiso, ta_auditoria, userCreacion, fechaCreacion, userModificacion, fechaModificacion, flEliminado) VALUES
(3, 1, 7, 60, 1, 1, 0, NULL, 1, 1, 1, '2022-03-14 06:07:00', '2022-03-14 14:07:00', '06:07:00', '14:07:00', '8.00', 7, 0, '2022-03-18 00:08:33', '80604020', '2022-03-18 00:08:33', '80604020', '2022-03-18 00:08:33', 1),
(4, 1, 7, 60, 1, 1, 0, NULL, 1, 1, 1, '2022-03-16 06:07:00', '2022-03-16 14:10:00', '06:07:00', '14:10:00', '8.05', 7, 0, '2022-03-18 00:09:33', '80604020', '2022-03-18 00:09:33', '80604020', '2022-03-18 00:09:33', 1),
(13, 1, 20, 74, 1, 3, 0, NULL, 1, 1, 1, '2022-03-18 11:03:00', '2022-03-18 14:03:00', '11:03:00', '14:03:00', '3.00', 12, 0, '2022-03-19 11:04:19', '002018776', '2022-03-19 11:04:19', '002018776', '2022-03-19 11:04:19', 1),
(14, 1, 7, 60, 1, 1, 0, NULL, 1, 1, 1, '2022-03-19 22:16:00', '2022-03-19 22:16:00', '22:16:00', '22:16:00', '0.00', 7, 0, '2022-03-19 22:16:34', '80604020', '2022-03-19 22:16:34', '80604020', '2022-03-19 22:16:34', 1),
(15, 0, 7, NULL, 1, 1, 1, NULL, 6, 1, 0, '2022-03-17 22:18:43', '2022-03-17 00:00:00', '00:00:00', '00:00:00', '0.00', 7, 1, '2022-03-19 22:18:43', '80604020', '2022-03-19 22:18:43', '80604020', '2022-03-19 22:18:43', 1),
(16, 1, 7, NULL, 1, 1, 1, NULL, 4, 1, 0, '2022-03-15 00:00:00', '2022-03-15 00:00:00', '00:00:00', '00:00:00', '0.00', 7, 0, '2022-03-19 22:19:06', '80604020', '2022-03-19 22:19:06', '80604020', '2022-03-19 22:19:06', 1),
(17, 1, 7, NULL, 1, 1, 1, NULL, 4, 1, 0, '2022-03-07 00:00:00', '2022-03-07 00:00:00', '00:00:00', '00:00:00', '0.00', 7, 0, '2022-03-19 22:51:24', '80604020', '2022-03-19 22:51:24', '80604020', '2022-03-19 22:51:24', 1),
(18, 0, 7, NULL, 1, 1, 1, NULL, 5, 1, 0, '2022-03-09 00:00:00', '2022-03-09 00:00:00', '00:00:00', '00:00:00', '0.00', 7, 0, '2022-03-19 22:53:57', '80604020', '2022-03-19 22:53:57', '80604020', '2022-03-19 22:53:57', 1);

--
-- Disparadores tareo
--
DELIMITER $$
CREATE TRIGGER trg_log_actualizar_tareo BEFORE UPDATE ON tareo FOR EACH ROW BEGIN

/*
 * REGISTRO: 1
 * EDICION : 2
 * ANULACION: 3
 * ELIMINACION: 4
 * */
  
  DECLARE dec_NewRegistro TEXT;
  DECLARE dec_OldRegistro TEXT;

  SELECT 
    group_concat(
        concat(
             "CODIGO: [",IFNULL(NEW.id_tareo , ''),"] " 
            ,"PERSONA: [",IFNULL(fun_get_nombres_persona_gen(NEW.id_persona ), ''),"] " 
            ,"SEDE: [",IFNULL(fun_get_sede_gen(NEW.id_sede), ''),"] " 
            ,"ETAPA: [",IFNULL(fun_get_etapa_tareo_gen(NEW.id_tareo), ''),"] " 
            ,"FECHA INGRESO: [",IFNULL(date(NEW.ta_fecha_r ), ''),"] " 
            ,"HORA INGRESO: [",IFNULL(NEW.ta_hora_r, ''),"] " 
            ,"FECHA CIERRE: [",IFNULL(fun_get_feCierre_tareo_gen(NEW.id_tareo), ''),"] " 
            ,"HORA CIERRE: [",IFNULL(fun_get_hcierre_tareo_gen(NEW.id_tareo), ''),"] " 
            ,"MARCADOR: [",IFNULL(fun_get_marcador_tareo_gen(NEW.id_tareo), ''),"] "  
            ,"ESTADO: [",IFNULL(fun_get_estado_gen(new.ta_estado), ''),"] " 
            ,"FECHA: [",IFNULL(NEW.fechaModificacion, ''),"] "
        )
        SEPARATOR ' '
    ) into dec_NewRegistro;
   
   SELECT 
    group_concat(
        concat(
             "CODIGO: [",IFNULL(OLD.id_tareo , ''),"] " 
            ,"PERSONA: [",IFNULL(fun_get_nombres_persona_gen(OLD.id_persona ), ''),"] " 
            ,"SEDE: [",IFNULL(fun_get_sede_gen(OLD.id_sede), ''),"] " 
            ,"ETAPA: [",IFNULL(fun_get_etapa_tareo_gen(OLD.id_tareo), ''),"] " 
            ,"FECHA INGRESO: [",IFNULL(date(OLD.ta_fecha_r ), ''),"] " 
            ,"HORA INGRESO: [",IFNULL(OLD.ta_hora_r, ''),"] " 
            ,"FECHA CIERRE: [",IFNULL(fun_get_feCierre_tareo_gen(OLD.id_tareo), ''),"] " 
            ,"HORA CIERRE: [",IFNULL(fun_get_hcierre_tareo_gen(OLD.id_tareo), ''),"] " 
            ,"MARCADOR: [",IFNULL(fun_get_marcador_tareo_gen(OLD.id_tareo), ''),"] "  
            ,"ESTADO: [",IFNULL(fun_get_estado_gen(OLD.ta_estado), ''),"] " 
            ,"FECHA: [",IFNULL(OLD.fechaModificacion, ''),"] "
        )
        SEPARATOR ' '
    ) into dec_OldRegistro;

    INSERT INTO auditoria(id_tablas, tipo_auditoria, old_value, new_value, usuario, fecha) 
    VALUES (
        11,
        2,
        dec_OldRegistro, 
        dec_NewRegistro,
        NEW.userModificacion,
        now()
    );


END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER trg_log_eliminar_tareo BEFORE DELETE ON tareo FOR EACH ROW BEGIN

/*
 * REGISTRO: 1
 * EDICION : 2
 * ANULACION: 3
 * ELIMINACION: 4
 * */
  
  DECLARE dec_NewRegistro TEXT;
  DECLARE dec_OldRegistro TEXT;

  SELECT 
    group_concat(
        concat(
             "CODIGO: [",IFNULL(OLD.id_tareo , ''),"] " 
            ,"PERSONA: [",IFNULL(fun_get_nombres_persona_gen(OLD.id_persona ), ''),"] " 
            ,"SEDE: [",IFNULL(fun_get_sede_gen(OLD.id_sede), ''),"] " 
            ,"ETAPA: [",IFNULL(fun_get_etapa_tareo_gen(OLD.id_tareo), ''),"] " 
            ,"FECHA INGRESO: [",IFNULL(date(OLD.ta_fecha_r ), ''),"] " 
            ,"HORA INGRESO: [",IFNULL(OLD.ta_hora_r, ''),"] " 
            ,"FECHA CIERRE: [",IFNULL(fun_get_feCierre_tareo_gen(OLD.id_tareo), ''),"] " 
            ,"HORA CIERRE: [",IFNULL(fun_get_hcierre_tareo_gen(OLD.id_tareo), ''),"] " 
            ,"MARCADOR: [",IFNULL(fun_get_marcador_tareo_new_gen(OLD.id_marcador), ''),"] "  
            ,"ESTADO: [",IFNULL(fun_get_estado_gen(OLD.ta_estado), ''),"] " 
            ,"FECHA: [",IFNULL(OLD.fechaModificacion, ''),"] "
        )
        SEPARATOR ' '
    ) into dec_NewRegistro;
   
    INSERT INTO auditoria(id_tablas, tipo_auditoria, old_value, new_value, usuario, fecha) 
    VALUES (
        11,
        4,
        dec_NewRegistro, 
        '',
        OLD.userCreacion,
        now()
    );


END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER trg_log_registrar_tareo BEFORE INSERT ON tareo FOR EACH ROW BEGIN

/*
 * REGISTRO: 1
 * EDICION : 2
 * ANULACION: 3
 * ELIMINACION: 4
 * */
  
  DECLARE dec_NewRegistro TEXT;
  DECLARE dec_OldRegistro TEXT;

  SELECT 
    group_concat(
        concat(
             "CODIGO: [",IFNULL(NEW.id_tareo , ''),"] " 
            ,"PERSONA: [",IFNULL(fun_get_nombres_persona_gen(NEW.id_persona ), ''),"] " 
            ,"SEDE: [",IFNULL(fun_get_sede_gen(NEW.id_sede), ''),"] " 
            ,"ETAPA: [",IFNULL(fun_get_etapa_tareo_gen(NEW.id_tareo), ''),"] " 
            ,"FECHA INGRESO: [",IFNULL(date(NEW.ta_fecha_r ), ''),"] " 
            ,"HORA INGRESO: [",IFNULL(NEW.ta_hora_r, ''),"] " 
            ,"FECHA CIERRE: [",IFNULL(fun_get_feCierre_tareo_gen(NEW.id_tareo), ''),"] " 
            ,"HORA CIERRE: [",IFNULL(fun_get_hcierre_tareo_gen(NEW.id_tareo), ''),"] " 
            ,"MARCADOR: [",IFNULL(fun_get_marcador_tareo_new_gen(NEW.id_marcador), ''),"] "  
            ,"ESTADO: [",IFNULL(fun_get_estado_gen(new.ta_estado), ''),"] " 
            ,"FECHA: [",IFNULL(NEW.fechaModificacion, ''),"] "
        )
        SEPARATOR ' '
    ) into dec_NewRegistro;
   
    INSERT INTO auditoria(id_tablas, tipo_auditoria, old_value, new_value, usuario, fecha) 
    VALUES (
        11,
        1,
        '', 
        dec_NewRegistro,
        NEW.userCreacion,
        now()
    );


END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla tipo_cuenta
--

CREATE TABLE tipo_cuenta (
  id_tpcuenta int(11) NOT NULL,
  tpc_abreviatura varchar(45) DEFAULT NULL,
  tpc_descripcion varchar(45) DEFAULT NULL,
  tpc_estado int(11) DEFAULT NULL,
  tcp_fecha_r datetime DEFAULT CURRENT_TIMESTAMP,
  tcp_fecha_c datetime DEFAULT CURRENT_TIMESTAMP,
  userCreacion varchar(50) NOT NULL,
  fechaCreacion datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  userModificacion varchar(50) NOT NULL,
  fechaModificacion datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  flEliminado int(11) NOT NULL DEFAULT '1'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Volcado de datos para la tabla tipo_cuenta
--

INSERT INTO tipo_cuenta (id_tpcuenta, tpc_abreviatura, tpc_descripcion, tpc_estado, tcp_fecha_r, tcp_fecha_c, userCreacion, fechaCreacion, userModificacion, fechaModificacion, flEliminado) VALUES
(1, 'P', 'Propio', 1, '2021-08-21 17:29:27', '2021-08-21 17:29:27', '', '2022-03-13 19:01:28', '', '2022-03-13 19:01:28', 1),
(2, 'I', 'Interbancario', 1, '2021-08-21 17:29:27', '2021-08-21 17:29:27', '', '2022-03-13 19:01:28', '', '2022-03-13 19:01:28', 1);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla tipo_documento
--

CREATE TABLE tipo_documento (
  id_tpdocumento varchar(45) NOT NULL,
  tpd_descripcion varchar(45) DEFAULT NULL,
  tpd_abreviatura varchar(45) DEFAULT NULL,
  tpd_longitud int(11) DEFAULT NULL,
  tpd_estado int(11) DEFAULT '1',
  tpd_fecha_r datetime DEFAULT CURRENT_TIMESTAMP,
  tpd_fecha_c datetime DEFAULT CURRENT_TIMESTAMP,
  userCreacion varchar(50) NOT NULL,
  fechaCreacion datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  userModificacion varchar(50) NOT NULL,
  fechaModificacion datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  flEliminado int(11) NOT NULL DEFAULT '1'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Volcado de datos para la tabla tipo_documento
--

INSERT INTO tipo_documento (id_tpdocumento, tpd_descripcion, tpd_abreviatura, tpd_longitud, tpd_estado, tpd_fecha_r, tpd_fecha_c, userCreacion, fechaCreacion, userModificacion, fechaModificacion, flEliminado) VALUES
('CE', 'Carnet de Extranjería', 'CE', 20, 1, '2022-03-17 23:41:05', '2022-03-17 23:41:05', 'admin', '2022-03-17 23:41:05', 'admin', '2022-03-17 23:41:29', 1),
('DNI', 'Documento nacional de identidad', 'DNI', 8, 1, '2021-08-21 17:29:27', '2021-08-21 17:29:27', '', '2022-03-13 19:01:51', 'admin', '2022-03-17 23:29:14', 1);

--
-- Disparadores tipo_documento
--
DELIMITER $$
CREATE TRIGGER trg_log_actualizar_tipo_documento BEFORE UPDATE ON tipo_documento FOR EACH ROW BEGIN

/*
 * REGISTRO: 1
 * EDICION : 2
 * ANULACION: 3
 * ELIMINACION: 4
 * */
  
  DECLARE dec_NewRegistro TEXT;
  DECLARE dec_OldRegistro TEXT;

  SELECT 
    group_concat(
        concat(
             "CODIGO: [",IFNULL(NEW.id_tpdocumento     , ''),"] " 
            ,"NOMBRE: [",IFNULL(NEW.tpd_descripcion, ''),"] " 
            ,"ABREVIATURA: [",IFNULL(NEW.tpd_abreviatura, ''),"] " 
            ,"LONGITUD: [",IFNULL(NEW.tpd_longitud, ''),"] " 
            ,"ESTADO: [",IFNULL(fun_get_estado_gen(new.tpd_estado), ''),"] " 
            ,"FECHA: [",IFNULL(NEW.fechaModificacion, ''),"] "
        )
        SEPARATOR ' '
    ) into dec_NewRegistro;
   
   SELECT 
    group_concat(
       concat(
             "CODIGO: [",IFNULL(OLD.id_tpdocumento     , ''),"] " 
            ,"NOMBRE: [",IFNULL(OLD.tpd_descripcion, ''),"] " 
            ,"ABREVIATURA: [",IFNULL(OLD.tpd_abreviatura, ''),"] " 
            ,"LONGITUD: [",IFNULL(OLD.tpd_longitud, ''),"] " 
            ,"ESTADO: [",IFNULL(fun_get_estado_gen(OLD.tpd_estado), ''),"] " 
            ,"FECHA: [",IFNULL(OLD.fechaModificacion, ''),"] "
        )
        SEPARATOR ' '
    ) into dec_OldRegistro;

    INSERT INTO auditoria(id_tablas, tipo_auditoria, old_value, new_value, usuario, fecha) 
    VALUES (
        15,
        2,
        dec_OldRegistro, 
        dec_NewRegistro,
        NEW.userModificacion,
        now()
    );


END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER trg_log_registrar_tipo_documento BEFORE INSERT ON tipo_documento FOR EACH ROW BEGIN

/*
 * REGISTRO: 1
 * EDICION : 2
 * ANULACION: 3
 * ELIMINACION: 4
 * */
  
  DECLARE dec_NewRegistro TEXT;
  DECLARE dec_OldRegistro TEXT;

  SELECT 
    group_concat(
        concat(
             "CODIGO: [",IFNULL(NEW.id_tpdocumento     , ''),"] " 
            ,"NOMBRE: [",IFNULL(NEW.tpd_descripcion, ''),"] " 
            ,"ABREVIATURA: [",IFNULL(NEW.tpd_abreviatura, ''),"] " 
            ,"LONGITUD: [",IFNULL(NEW.tpd_longitud, ''),"] " 
            ,"ESTADO: [",IFNULL(fun_get_estado_gen(new.tpd_estado), ''),"] " 
            ,"FECHA: [",IFNULL(NEW.fechaModificacion, ''),"] "
        )
        SEPARATOR ' '
    ) into dec_NewRegistro;
   
    INSERT INTO auditoria(id_tablas, tipo_auditoria, old_value, new_value, usuario, fecha) 
    VALUES (
        15,
        1,
        '', 
        dec_NewRegistro,
        NEW.userCreacion,
        now()
    );


END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla tipo_usuario
--

CREATE TABLE tipo_usuario (
  id_tpusuario int(11) NOT NULL,
  tpu_descripcion varchar(45) DEFAULT NULL,
  tpu_estado int(11) DEFAULT NULL,
  tpu_abreviatura varchar(45) DEFAULT NULL,
  userCreacion varchar(50) NOT NULL,
  fechaCreacion datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  userModificacion varchar(50) NOT NULL,
  fechaModificacion datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  flEliminado int(11) NOT NULL DEFAULT '1'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Volcado de datos para la tabla tipo_usuario
--

INSERT INTO tipo_usuario (id_tpusuario, tpu_descripcion, tpu_estado, tpu_abreviatura, userCreacion, fechaCreacion, userModificacion, fechaModificacion, flEliminado) VALUES
(1, 'SUPERVISOR', 1, 'SUP', '', '2022-03-13 19:02:16', '12345678', '2022-03-17 01:24:11', 1),
(3, 'OPERARIO', 1, 'OP', '', '2022-03-13 19:02:16', '', '2022-03-13 19:02:16', 1),
(6, 'ADM. DEL SISTEMA', 1, 'ADMSIST', '', '2022-03-13 19:02:16', '', '2022-03-13 19:02:16', 1);

--
-- Disparadores tipo_usuario
--
DELIMITER $$
CREATE TRIGGER trg_log_actualizar_tipo_usuario BEFORE UPDATE ON tipo_usuario FOR EACH ROW BEGIN

/*
 * REGISTRO: 1
 * EDICION : 2
 * ANULACION: 3
 * ELIMINACION: 4
 * */
  
  DECLARE dec_NewRegistro TEXT;
  DECLARE dec_OldRegistro TEXT;

  SELECT 
    group_concat(
        concat(
             "CODIGO: [",IFNULL(NEW.id_tpusuario   , ''),"] " 
            ,"NOMBRE: [",IFNULL(NEW.tpu_descripcion, ''),"] " 
            ,"ABREVIATURA: [",IFNULL(NEW.tpu_abreviatura, ''),"] " 
            ,"CANTIDAD DE PERMISOS: [",IFNULL(fun_get_cantidad_permisos_gen(NEW.id_tpusuario), ''),"] "  
            ,"ESTADO: [",IFNULL(fun_get_estado_gen(new.tpu_estado), ''),"] " 
            ,"FECHA: [",IFNULL(NEW.fechaModificacion, ''),"] "
        )
        SEPARATOR ' '
    ) into dec_NewRegistro;
   
   SELECT 
    group_concat(
        concat(
             "CODIGO: [",IFNULL(NEW.id_tpusuario   , ''),"] " 
            ,"NOMBRE: [",IFNULL(NEW.tpu_descripcion, ''),"] " 
            ,"ABREVIATURA: [",IFNULL(NEW.tpu_abreviatura, ''),"] " 
            ,"CANTIDAD DE PERMISOS: [",IFNULL(fun_get_cantidad_permisos_gen(NEW.id_tpusuario), ''),"] "  
            ,"ESTADO: [",IFNULL(fun_get_estado_gen(new.tpu_estado), ''),"] " 
            ,"FECHA: [",IFNULL(NEW.fechaModificacion, ''),"] "
        )
        SEPARATOR ' '
    ) into dec_OldRegistro;

    INSERT INTO auditoria(id_tablas, tipo_auditoria, old_value, new_value, usuario, fecha) 
    VALUES (
        13,
        2,
        dec_OldRegistro, 
        dec_NewRegistro,
        NEW.userModificacion,
        now()
    );


END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER trg_log_registrar_tipo_usuario BEFORE INSERT ON tipo_usuario FOR EACH ROW BEGIN

/*
 * REGISTRO: 1
 * EDICION : 2
 * ANULACION: 3
 * ELIMINACION: 4
 * */
  
  DECLARE dec_NewRegistro TEXT;
  DECLARE dec_OldRegistro TEXT;

  SELECT 
    group_concat(
        concat(
             "CODIGO: [",IFNULL(NEW.id_tpusuario   , ''),"] " 
            ,"NOMBRE: [",IFNULL(NEW.tpu_descripcion, ''),"] " 
            ,"ABREVIATURA: [",IFNULL(NEW.tpu_abreviatura, ''),"] " 
            ,"CANTIDAD DE PERMISOS: [",IFNULL(fun_get_cantidad_permisos_gen(NEW.id_tpusuario), ''),"] "  
            ,"ESTADO: [",IFNULL(fun_get_estado_gen(new.tpu_estado), ''),"] " 
            ,"FECHA: [",IFNULL(NEW.fechaModificacion, ''),"] "
        )
        SEPARATOR ' '
    ) into dec_NewRegistro;
   
    INSERT INTO auditoria(id_tablas, tipo_auditoria, old_value, new_value, usuario, fecha) 
    VALUES (
        13,
        1,
        '', 
        dec_NewRegistro,
        NEW.userCreacion,
        now()
    );


END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla usuario
--

CREATE TABLE usuario (
  id_usuario int(11) NOT NULL,
  id_tpusuario int(11) NOT NULL,
  us_usuario varchar(45) DEFAULT NULL,
  us_contrasenia varchar(45) DEFAULT NULL,
  us_estado int(11) DEFAULT NULL,
  us_fecha_r datetime DEFAULT CURRENT_TIMESTAMP,
  us_fecha_c datetime DEFAULT CURRENT_TIMESTAMP,
  us_empleado int(11) DEFAULT NULL,
  us_persona int(11) DEFAULT NULL,
  userCreacion varchar(50) NOT NULL,
  fechaCreacion datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  userModificacion varchar(50) NOT NULL,
  fechaModificacion datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  flEliminado int(11) NOT NULL DEFAULT '1'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Volcado de datos para la tabla usuario
--

INSERT INTO usuario (id_usuario, id_tpusuario, us_usuario, us_contrasenia, us_estado, us_fecha_r, us_fecha_c, us_empleado, us_persona, userCreacion, fechaCreacion, userModificacion, fechaModificacion, flEliminado) VALUES
(1, 6, 'admin', '87654321', 1, '2021-08-21 17:59:26', '2021-08-21 17:59:26', 1, 1, '12345678', '2022-03-13 19:02:34', '12345678', '2022-03-14 22:41:55', 1),
(36, 6, '72260964', '72260964', 1, '2022-03-17 23:52:36', '2022-03-17 23:52:36', 2, 2, 'admin', '2022-03-17 23:52:36', 'admin', '2022-03-17 23:52:36', 1),
(37, 6, '46480582', '46480582', 1, '2022-03-17 23:53:53', '2022-03-17 23:53:53', 3, 3, 'admin', '2022-03-17 23:53:53', 'admin', '2022-03-17 23:53:53', 1),
(38, 6, '003909808', '003909808', 1, '2022-03-17 23:55:17', '2022-03-17 23:55:17', 4, 4, 'admin', '2022-03-17 23:55:17', 'admin', '2022-03-17 23:55:17', 1),
(39, 6, '004644398', '004644398', 1, '2022-03-17 23:56:16', '2022-03-17 23:56:16', 5, 5, 'admin', '2022-03-17 23:56:16', 'admin', '2022-03-17 23:56:16', 1),
(40, 6, '10203040', '10203040', 0, '2022-03-17 23:57:16', '2022-03-17 23:57:16', 6, 6, 'admin', '2022-03-17 23:57:16', 'admin', '2022-03-18 00:01:48', 1),
(41, 1, '80604020', '80604020', 1, '2022-03-18 00:05:31', '2022-03-18 00:05:31', 7, 7, 'admin', '2022-03-18 00:05:31', 'admin', '2022-03-18 00:05:31', 1),
(46, 1, '002018776', '002018776', 1, '2022-03-18 10:38:02', '2022-03-18 10:38:02', 12, 12, '004644398', '2022-03-18 10:38:02', '004644398', '2022-03-18 10:38:02', 1),
(47, 3, '40588094', '40588094', 1, '2022-03-18 15:38:01', '2022-03-18 15:38:01', 13, 13, '004644398', '2022-03-18 15:38:01', '004644398', '2022-03-18 15:38:01', 1),
(48, 3, '004547356', '004547356', 1, '2022-03-18 18:37:23', '2022-03-18 18:37:23', 14, 14, '004644398', '2022-03-18 18:37:23', '004644398', '2022-03-18 18:37:23', 1),
(49, 3, '005114915', '005114915', 1, '2022-03-18 18:41:02', '2022-03-18 18:41:02', 15, 15, '004644398', '2022-03-18 18:41:02', '004644398', '2022-03-18 18:41:02', 1),
(50, 3, '004850867', '004850867', 1, '2022-03-18 18:43:42', '2022-03-18 18:43:42', 16, 16, '004644398', '2022-03-18 18:43:42', '004644398', '2022-03-18 18:43:42', 1),
(51, 3, '48256987', '48256987', 1, '2022-03-18 23:23:54', '2022-03-18 23:23:54', 18, 18, '46480582', '2022-03-18 23:23:54', '46480582', '2022-03-18 23:25:25', 1),
(52, 3, '45826874', '45826874', 1, '2022-03-18 23:33:59', '2022-03-18 23:33:59', 19, 19, '46480582', '2022-03-18 23:33:59', '46480582', '2022-03-18 23:35:41', 1),
(53, 3, '12344321', '12344321', 0, '2022-03-19 10:27:03', '2022-03-19 10:27:03', 20, 20, 'admin', '2022-03-19 10:27:03', 'admin', '2022-03-19 22:06:03', 1);

--
-- Disparadores usuario
--
DELIMITER $$
CREATE TRIGGER trg_log_actualizar_usuario BEFORE UPDATE ON usuario FOR EACH ROW BEGIN

/*
 * REGISTRO: 1
 * EDICION : 2
 * ANULACION: 3
 * ELIMINACION: 4
 * */
  
  DECLARE dec_NewRegistro TEXT;
  DECLARE dec_OldRegistro TEXT;

  SELECT 
    group_concat(
        concat(
             "CODIGO: [",IFNULL(NEW.id_usuario  , ''),"] " 
            ,"PERSONA: [",IFNULL(fun_get_nombres_persona_gen(NEW.us_persona ), ''),"] " 
            ,"USAURIO: [",IFNULL(NEW.us_usuario, ''),"] " 
            ,"CONTRASEÑA: [",IFNULL(NEW.us_contrasenia, ''),"] " 
            ,"PERFIL DE USUARIO: [",IFNULL(fun_get_tipo_usuario_p_gen(NEW.id_tpusuario), ''),"] " 
            ,"ESTADO: [",IFNULL(fun_get_estado_gen(new.us_estado), ''),"] " 
            ,"FECHA: [",IFNULL(NEW.fechaModificacion, ''),"] "
        )
        SEPARATOR ' '
    ) into dec_NewRegistro;
   
   SELECT 
    group_concat(
        concat(
             "CODIGO: [",IFNULL(OLD.id_usuario  , ''),"] " 
            ,"PERSONA: [",IFNULL(fun_get_nombres_persona_gen(OLD.us_persona ), ''),"] " 
            ,"USAURIO: [",IFNULL(OLD.us_usuario, ''),"] " 
            ,"CONTRASEÑA: [",IFNULL(OLD.us_contrasenia, ''),"] " 
            ,"PERFIL DE USUARIO: [",IFNULL(fun_get_tipo_usuario_p_gen(OLD.id_tpusuario), ''),"] " 
            ,"ESTADO: [",IFNULL(fun_get_estado_gen(OLD.us_estado), ''),"] " 
            ,"FECHA: [",IFNULL(OLD.fechaModificacion, ''),"] "
        )
        SEPARATOR ' '
    ) into dec_OldRegistro;

    INSERT INTO auditoria(id_tablas, tipo_auditoria, old_value, new_value, usuario, fecha) 
    VALUES (
        12,
        2,
        dec_OldRegistro, 
        dec_NewRegistro,
        NEW.userModificacion,
        now()
    );


END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER trg_log_registrar_usuario BEFORE INSERT ON usuario FOR EACH ROW BEGIN

/*
 * REGISTRO: 1
 * EDICION : 2
 * ANULACION: 3
 * ELIMINACION: 4
 * */
  
  DECLARE dec_NewRegistro TEXT;
  DECLARE dec_OldRegistro TEXT;

  SELECT 
    group_concat(
        concat(
             "CODIGO: [",IFNULL(NEW.id_usuario  , ''),"] " 
            ,"PERSONA: [",IFNULL(fun_get_nombres_persona_gen(NEW.us_persona ), ''),"] " 
            ,"USAURIO: [",IFNULL(NEW.us_usuario, ''),"] " 
            ,"CONTRASEÑA: [",IFNULL(NEW.us_contrasenia, ''),"] " 
            ,"PERFIL DE USUARIO: [",IFNULL(fun_get_tipo_usuario_p_gen(NEW.id_tpusuario), ''),"] " 
            ,"ESTADO: [",IFNULL(fun_get_estado_gen(new.us_estado), ''),"] " 
            ,"FECHA: [",IFNULL(NEW.fechaModificacion, ''),"] "
        )
        SEPARATOR ' '
    ) into dec_NewRegistro;
   
    INSERT INTO auditoria(id_tablas, tipo_auditoria, old_value, new_value, usuario, fecha) 
    VALUES (
        12,
        1,
        '', 
        dec_NewRegistro,
        NEW.userCreacion,
        now()
    );


END
$$
DELIMITER ;

--
-- Índices para tablas volcadas
--

--
-- Indices de la tabla app_version
--
ALTER TABLE app_version
  ADD PRIMARY KEY (id_version);

--
-- Indices de la tabla auditoria
--
ALTER TABLE auditoria
  ADD PRIMARY KEY (id_auditoria);

--
-- Indices de la tabla banco
--
ALTER TABLE banco
  ADD PRIMARY KEY (id_banco);

--
-- Indices de la tabla cargo
--
ALTER TABLE cargo
  ADD PRIMARY KEY (id_cargo);

--
-- Indices de la tabla cargos_empleado
--
ALTER TABLE cargos_empleado
  ADD PRIMARY KEY (id_caempleado);

--
-- Indices de la tabla ca_planilla
--
ALTER TABLE ca_planilla
  ADD PRIMARY KEY (id_planilla);

--
-- Indices de la tabla cliente
--
ALTER TABLE cliente
  ADD PRIMARY KEY (id_cliente);

--
-- Indices de la tabla descanso
--
ALTER TABLE descanso
  ADD PRIMARY KEY (id_descanso,id_persona),
  ADD KEY fk_descanso_empleado1_idx (id_persona);

--
-- Indices de la tabla de_planilla
--
ALTER TABLE de_planilla
  ADD PRIMARY KEY (de_planilla);

--
-- Indices de la tabla documentos_empleado
--
ALTER TABLE documentos_empleado
  ADD PRIMARY KEY (id_emdocumento);

--
-- Indices de la tabla documentos_has_empleado
--
ALTER TABLE documentos_has_empleado
  ADD PRIMARY KEY (id_docemp);

--
-- Indices de la tabla empleado
--
ALTER TABLE empleado
  ADD PRIMARY KEY (id_persona);

--
-- Indices de la tabla empleado_has_cese
--
ALTER TABLE empleado_has_cese
  ADD PRIMARY KEY (id_cese);

--
-- Indices de la tabla feriado
--
ALTER TABLE feriado
  ADD PRIMARY KEY (id_feriado);

--
-- Indices de la tabla marcador
--
ALTER TABLE marcador
  ADD PRIMARY KEY (id_marcador);

--
-- Indices de la tabla motivos_cese
--
ALTER TABLE motivos_cese
  ADD PRIMARY KEY (id_motivo);

--
-- Indices de la tabla nacionalidad
--
ALTER TABLE nacionalidad
  ADD PRIMARY KEY (id_nacionalidad);

--
-- Indices de la tabla permiso
--
ALTER TABLE permiso
  ADD PRIMARY KEY (id_permiso);

--
-- Indices de la tabla persona
--
ALTER TABLE persona
  ADD PRIMARY KEY (id_persona),
  ADD KEY fk_persona_tipo_documento1_idx (id_tpdocumento),
  ADD KEY fk_persona_nacionalidad1_idx (id_nacionalidad);

--
-- Indices de la tabla persona_has_banco
--
ALTER TABLE persona_has_banco
  ADD PRIMARY KEY (id_phbanco);

--
-- Indices de la tabla persona_has_listanegra
--
ALTER TABLE persona_has_listanegra
  ADD PRIMARY KEY (id_lista);

--
-- Indices de la tabla planilla_procesada
--
ALTER TABLE planilla_procesada
  ADD PRIMARY KEY (id_proplanilla);

--
-- Indices de la tabla pla_configuraciones
--
ALTER TABLE pla_configuraciones
  ADD PRIMARY KEY (id_configuracion);

--
-- Indices de la tabla sede
--
ALTER TABLE sede
  ADD PRIMARY KEY (id_sede);

--
-- Indices de la tabla sede_empleado
--
ALTER TABLE sede_empleado
  ADD PRIMARY KEY (id_sede_em);

--
-- Indices de la tabla sis_modulo
--
ALTER TABLE sis_modulo
  ADD PRIMARY KEY (id_smodulo);

--
-- Indices de la tabla sis_modulo_permiso
--
ALTER TABLE sis_modulo_permiso
  ADD PRIMARY KEY (id_mpermiso);

--
-- Indices de la tabla sis_perfil_modperm
--
ALTER TABLE sis_perfil_modperm
  ADD PRIMARY KEY (id_permodper);

--
-- Indices de la tabla sis_permiso
--
ALTER TABLE sis_permiso
  ADD PRIMARY KEY (id_spermiso);

--
-- Indices de la tabla sis_usuario_modperm
--
ALTER TABLE sis_usuario_modperm
  ADD PRIMARY KEY (id_usmodper);

--
-- Indices de la tabla sueldo
--
ALTER TABLE sueldo
  ADD PRIMARY KEY (id_sueldo);

--
-- Indices de la tabla suplente_cobrar
--
ALTER TABLE suplente_cobrar
  ADD PRIMARY KEY (id_sucobrar,id_persona),
  ADD KEY fk_suplente_cobrar_persona1_idx (id_persona);

--
-- Indices de la tabla tablas_dba
--
ALTER TABLE tablas_dba
  ADD PRIMARY KEY (id_tablas);

--
-- Indices de la tabla tareo
--
ALTER TABLE tareo
  ADD PRIMARY KEY (id_tareo,id_marcador),
  ADD KEY fk_tareo_marcador1_idx (id_marcador);

--
-- Indices de la tabla tipo_cuenta
--
ALTER TABLE tipo_cuenta
  ADD PRIMARY KEY (id_tpcuenta);

--
-- Indices de la tabla tipo_documento
--
ALTER TABLE tipo_documento
  ADD PRIMARY KEY (id_tpdocumento);

--
-- Indices de la tabla tipo_usuario
--
ALTER TABLE tipo_usuario
  ADD PRIMARY KEY (id_tpusuario);

--
-- Indices de la tabla usuario
--
ALTER TABLE usuario
  ADD PRIMARY KEY (id_usuario,id_tpusuario),
  ADD KEY fk_usuario_tipo_usuario_idx (id_tpusuario);

--
-- AUTO_INCREMENT de las tablas volcadas
--

--
-- AUTO_INCREMENT de la tabla app_version
--
ALTER TABLE app_version
  MODIFY id_version int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=15;

--
-- AUTO_INCREMENT de la tabla auditoria
--
ALTER TABLE auditoria
  MODIFY id_auditoria int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=216;

--
-- AUTO_INCREMENT de la tabla banco
--
ALTER TABLE banco
  MODIFY id_banco int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT de la tabla cargo
--
ALTER TABLE cargo
  MODIFY id_cargo int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=16;

--
-- AUTO_INCREMENT de la tabla cargos_empleado
--
ALTER TABLE cargos_empleado
  MODIFY id_caempleado int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=43;

--
-- AUTO_INCREMENT de la tabla ca_planilla
--
ALTER TABLE ca_planilla
  MODIFY id_planilla int(10) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla cliente
--
ALTER TABLE cliente
  MODIFY id_cliente int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla descanso
--
ALTER TABLE descanso
  MODIFY id_descanso int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT de la tabla de_planilla
--
ALTER TABLE de_planilla
  MODIFY de_planilla int(10) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla documentos_empleado
--
ALTER TABLE documentos_empleado
  MODIFY id_emdocumento int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=10;

--
-- AUTO_INCREMENT de la tabla documentos_has_empleado
--
ALTER TABLE documentos_has_empleado
  MODIFY id_docemp int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=51;

--
-- AUTO_INCREMENT de la tabla empleado_has_cese
--
ALTER TABLE empleado_has_cese
  MODIFY id_cese int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=35;

--
-- AUTO_INCREMENT de la tabla feriado
--
ALTER TABLE feriado
  MODIFY id_feriado int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla marcador
--
ALTER TABLE marcador
  MODIFY id_marcador int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT de la tabla motivos_cese
--
ALTER TABLE motivos_cese
  MODIFY id_motivo int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT de la tabla nacionalidad
--
ALTER TABLE nacionalidad
  MODIFY id_nacionalidad int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=10;

--
-- AUTO_INCREMENT de la tabla permiso
--
ALTER TABLE permiso
  MODIFY id_permiso int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT de la tabla persona
--
ALTER TABLE persona
  MODIFY id_persona int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=21;

--
-- AUTO_INCREMENT de la tabla persona_has_banco
--
ALTER TABLE persona_has_banco
  MODIFY id_phbanco int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT de la tabla persona_has_listanegra
--
ALTER TABLE persona_has_listanegra
  MODIFY id_lista int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla planilla_procesada
--
ALTER TABLE planilla_procesada
  MODIFY id_proplanilla int(6) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla pla_configuraciones
--
ALTER TABLE pla_configuraciones
  MODIFY id_configuracion int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT de la tabla sede
--
ALTER TABLE sede
  MODIFY id_sede int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT de la tabla sede_empleado
--
ALTER TABLE sede_empleado
  MODIFY id_sede_em int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=75;

--
-- AUTO_INCREMENT de la tabla sis_modulo
--
ALTER TABLE sis_modulo
  MODIFY id_smodulo int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=16;

--
-- AUTO_INCREMENT de la tabla sis_modulo_permiso
--
ALTER TABLE sis_modulo_permiso
  MODIFY id_mpermiso int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=32;

--
-- AUTO_INCREMENT de la tabla sis_perfil_modperm
--
ALTER TABLE sis_perfil_modperm
  MODIFY id_permodper int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=55;

--
-- AUTO_INCREMENT de la tabla sis_permiso
--
ALTER TABLE sis_permiso
  MODIFY id_spermiso int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=14;

--
-- AUTO_INCREMENT de la tabla sis_usuario_modperm
--
ALTER TABLE sis_usuario_modperm
  MODIFY id_usmodper int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=827;

--
-- AUTO_INCREMENT de la tabla sueldo
--
ALTER TABLE sueldo
  MODIFY id_sueldo int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=9;

--
-- AUTO_INCREMENT de la tabla suplente_cobrar
--
ALTER TABLE suplente_cobrar
  MODIFY id_sucobrar int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla tablas_dba
--
ALTER TABLE tablas_dba
  MODIFY id_tablas int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=20;

--
-- AUTO_INCREMENT de la tabla tareo
--
ALTER TABLE tareo
  MODIFY id_tareo int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=19;

--
-- AUTO_INCREMENT de la tabla tipo_cuenta
--
ALTER TABLE tipo_cuenta
  MODIFY id_tpcuenta int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT de la tabla tipo_usuario
--
ALTER TABLE tipo_usuario
  MODIFY id_tpusuario int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT de la tabla usuario
--
ALTER TABLE usuario
  MODIFY id_usuario int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=54;

--
-- Restricciones para tablas volcadas
--

--
-- Filtros para la tabla descanso
--
ALTER TABLE descanso
  ADD CONSTRAINT fk_descanso_empleado1 FOREIGN KEY (id_persona) REFERENCES empleado (id_persona) ON DELETE NO ACTION ON UPDATE NO ACTION;

--
-- Filtros para la tabla empleado
--
ALTER TABLE empleado
  ADD CONSTRAINT fk_empleado_persona1 FOREIGN KEY (id_persona) REFERENCES persona (id_persona) ON DELETE NO ACTION ON UPDATE NO ACTION;

--
-- Filtros para la tabla persona
--
ALTER TABLE persona
  ADD CONSTRAINT fk_persona_nacionalidad1 FOREIGN KEY (id_nacionalidad) REFERENCES nacionalidad (id_nacionalidad) ON DELETE NO ACTION ON UPDATE NO ACTION,
  ADD CONSTRAINT fk_persona_tipo_documento1 FOREIGN KEY (id_tpdocumento) REFERENCES tipo_documento (id_tpdocumento) ON DELETE NO ACTION ON UPDATE NO ACTION;

--
-- Filtros para la tabla suplente_cobrar
--
ALTER TABLE suplente_cobrar
  ADD CONSTRAINT fk_suplente_cobrar_persona1 FOREIGN KEY (id_persona) REFERENCES persona (id_persona) ON DELETE NO ACTION ON UPDATE NO ACTION;

--
-- Filtros para la tabla tareo
--
ALTER TABLE tareo
  ADD CONSTRAINT fk_tareo_marcador1 FOREIGN KEY (id_marcador) REFERENCES marcador (id_marcador) ON DELETE NO ACTION ON UPDATE NO ACTION;

--
-- Filtros para la tabla usuario
--
ALTER TABLE usuario
  ADD CONSTRAINT fk_usuario_tipo_usuario FOREIGN KEY (id_tpusuario) REFERENCES tipo_usuario (id_tpusuario) ON DELETE NO ACTION ON UPDATE NO ACTION;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;

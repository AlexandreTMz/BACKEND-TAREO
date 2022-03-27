<?php
class TareoDAO{
	private $easyPDO;

	public function __construct()
	{
		$this->easyPDO = new EasyPDO();
	}

	public function mdtM_RegistrarTareo($data)
	{
		try{
			$this->easyPDO->db_procedure('MOV_UP_UP_REGISTRO_TAREO',array(
				$data['id_marcador'],  
			    $data['id_persona'],  
			    $data['id_tpdocumento'], 
			    $data['id_nacionalidad'],  
			    $data['id_cargo'],  
			    $data['id_sede'],  
			    $data['ta_estado'],  
			    $data['ta_fecha_r'],  
			    $data['ta_fecha_c'],  
			    $data['ta_hora_r'], 
			    $data['ta_hora_c'], 
			    $data['ta_usuario'],
			    $data['id_sede_em'],
			    $data['id_sueldo'],
			    $data['ta_remunerado'],
			    $data['userCreacion']  
			));
			$this->easyPDO->stm->closeCursor(); 
			Response::responsse(200, "Tareo registrado correctamente!");
		}catch(PDOException $e){
			Response::responsse(409, $e->getMessage());
		}
	}

	public function mdtM_CerrarTareo($data)
	{ 
		try{
			$this->easyPDO->db_procedure('MOV_UP_UP_CERRAR_TAREO',array(
				$data['id_tareo'],  
			    $data['ta_estado'],
			    $data['ta_etapa'],  
			    $data['ta_fecha_c'], 
			    $data['ta_hora_c']  
			));
			$this->easyPDO->stm->closeCursor(); 
			Response::responsse(200, "Tareo cerrado correctamente!");
		}catch(PDOException $e){
			Response::responsse(409, $e->getMessage());
		}
	}

	public function mdt_RegistrarPermiso($data)
	{
		try{ 
			$this->easyPDO->db_procedure('UP_REGISTRO_PERMISO_TAREO',array(
				$data['id_permiso'],  
			    $data['id_persona'],  
			    $data['id_tpdocumento'], 
			    $data['id_nacionalidad'],  
			    $data['id_cargo'],  
			    $data['id_sede'], 
			    $data['trs_remunerado'], 
			    $data['ta_estado'],  
			    $data['trs_fecha_r'],  
			    $data['trs_fecha_c'],   
			    $data['ta_usuario'],
			    $data['id_sueldo'],
			    $data['id_marcador'] 
			));
			$this->easyPDO->stm->closeCursor(); 
			Response::responsse(200, "Tareo registrado correctamente!");
		}catch(PDOException $e){
			Response::responsse(409, $e->getMessage());
		}
	}

	public function mdtM_RegistrarPermiso($data)
	{
		try{ 
			$this->easyPDO->db_procedure('MOV_UP_REGISTRO_PERMISO_TAREO',array(
				$data['id_permiso'],  
			    $data['id_persona'],  
			    $data['id_tpdocumento'], 
			    $data['id_nacionalidad'],  
			    $data['id_cargo'],  
			    $data['id_sede'], 
			    $data['trs_remunerado'], 
			    $data['ta_estado'],  
			    $data['trs_fecha_r'],  
			    $data['trs_fecha_c'],   
			    $data['ta_usuario'],
			    $data['id_sueldo'],
			    $data['id_marcador'],
			    $data['userCreacion']  
			));
			$this->easyPDO->stm->closeCursor(); 
			Response::responsse(200, "Tareo registrado correctamente!");
		}catch(PDOException $e){
			Response::responsse(409, $e->getMessage());
		}
	}


	public function mdt_RegistrarDescansoFalta($data)
	{
		try{ 
			$this->easyPDO->db_procedure('UP_REGISTRO_DESCANSO_FALTA_TAREO',array( 
			    $data['id_persona'],  
			    $data['id_tpdocumento'], 
			    $data['id_nacionalidad'],  
			    $data['id_cargo'],  
			    $data['id_sede'], 
			    $data['trs_remunerado'], 
			    $data['ta_estado'],  
			    $data['trs_fecha_r'],  
			    $data['trs_fecha_c'],   
			    $data['ta_usuario'],
			    $data['id_sueldo'],
			    $data['id_marcador'] 
			));
			$this->easyPDO->stm->closeCursor(); 
			Response::responsse(200, "Registro completado!");
		}catch(PDOException $e){
			Response::responsse(409, $e->getMessage());
		}
	}


	public function mdtM_RegistrarDescansoFalta($data)
	{
		try{ 
			$this->easyPDO->db_procedure('MOV_UP_REGISTRO_DESCANSO_FALTA_TAREO',array( 
			    $data['id_persona'],  
			    $data['id_tpdocumento'], 
			    $data['id_nacionalidad'],  
			    $data['id_cargo'],  
			    $data['id_sede'], 
			    $data['trs_remunerado'], 
			    $data['ta_estado'],  
			    $data['trs_fecha_r'],  
			    $data['trs_fecha_c'],   
			    $data['ta_usuario'],
			    $data['id_sueldo'],
			    $data['id_marcador'],
			    $data['userCreacion']
			));
			$this->easyPDO->stm->closeCursor(); 
			Response::responsse(200, "Registro completado!");
		}catch(PDOException $e){
			Response::responsse(409, $e->getMessage());
		}
	}

	public function mdt_BuscarEmpleadoCierreTareo($documento)
	{
		try{
			$this->easyPDO->db_procedure('UP_BUSCAR_TAREO_CIERRE',array(
				$documento
			));
			$data = $this->easyPDO->getData();
			$this->easyPDO->stm->closeCursor(); 
			Response::responsse(200, $data);
		}catch(PDOException $e){
			Response::responsse(409, $e->getMessage());
		}
	}

	// borrar
	public function mdt_BuscarTareoEmpleado($documento)
	{
		try{
			$this->easyPDO->db_procedure('UP_BUSCAR_TAREO_CIERRE_REGISTRO',array(
				$documento
			));
			$data = $this->easyPDO->getData();
			$this->easyPDO->stm->closeCursor(); 
			Response::responsse(200, $data);
		}catch(PDOException $e){
			Response::responsse(409, $e->getMessage());
		}
	}

	public function mdtM_BuscarTareoEmpleadoMovil($documento, $id_sede)
	{
		try{
			$this->easyPDO->db_procedure('MOV_UP_UP_BUSCAR_TAREO_CIERRE_REGISTRO',array(
				$documento,
				$id_sede
			));
			$data = $this->easyPDO->getData();
			$this->easyPDO->stm->closeCursor(); 
			Response::responsse(200, $data);
		}catch(PDOException $e){
			Response::responsse(409, $e->getMessage());
		}
	}

	public function mdt_TareoReporte($data)
	{
		try{
			$this->easyPDO->db_procedure('UP_BUSCAR_TAREO_SUPERVISOR_hosting',array(
			    $data['fechaInicio'],  
			    $data['fechaFin'], 
			    $data['documento'],
				$data['id_marcador'],
				$data['id_sede'] 
			));
			$data = array(
				"msg" => "Busqueda hecha",
				"data" => $this->easyPDO->getData()
			);
			$this->easyPDO->stm->closeCursor(); 
			Response::responsse(200, $data);
		}catch(PDOException $e){
			Response::responsse(409, $e->getMessage());
		}
	}

	public function mdtM_TareoReporte($data)
	{
		try{
			$this->easyPDO->db_procedure('MOV_UP_BUSCAR_TAREO_SUPERVISOR',array(
			    $data['fechaInicio'],  
			    $data['fechaFin'], 
			    $data['documento'],
				$data['id_marcador'],
				$data['id_sede'] 
			));
			$data = array(
				"msg" => "Busqueda hecha",
				"data" => $this->easyPDO->getData()
			);
			$this->easyPDO->stm->closeCursor(); 
			Response::responsse(200, $data);
		}catch(PDOException $e){
			Response::responsse(409, $e->getMessage());
		}
	}

	public function mdt_TareoReporteOperario($data)
	{
		try{
			$this->easyPDO->db_procedure('UP_BUSCAR_TAREO_OPERADOR_hosting',array(
			    $data['fechaInicio'],  
			    $data['fechaFin'], 
			    $data['documento'],
				$data['id_marcador']
			));
			$data = array(
				"msg" => "Busqueda hecha",
				"data" => $this->easyPDO->getData()
			);
			$this->easyPDO->stm->closeCursor(); 
			Response::responsse(200, $data);
		}catch(PDOException $e){
			Response::responsse(409, $e->getMessage());
		}
	}

	public function mdtM_TareoReporteOperario($data)
	{
		try{
			$this->easyPDO->db_procedure('MOV_UP_BUSCAR_TAREO_OPERADOR',array(
			    $data['fechaInicio'],  
			    $data['fechaFin'], 
			    $data['documento'],
				$data['id_marcador']
			));
			$data = array(
				"msg" => "Busqueda hecha",
				"data" => $this->easyPDO->getData()
			);
			$this->easyPDO->stm->closeCursor(); 
			Response::responsse(200, $data);
		}catch(PDOException $e){
			Response::responsse(409, $e->getMessage());
		}
	}


	// TAREO
	public function mtd_GenerarReporteTareoWeb(){
		try{ 
			$this->easyPDO->db_procedure('UP_GENERAR_REPORTE_TAREO',array(
				$_POST['id_sede'],
				$_POST['documento'],
				$_POST['inicio'],
				$_POST['fin'],
				$_POST['marcador'] 
			));
 			$data = $this->easyPDO->getData();
			$this->easyPDO->stm->closeCursor(); 
			Response::responsse(200, $data);
		}catch(PDOException $e){
			Response::responsse(409, $e->getMessage());
		}
	}

	public function mtd_GenerarReportePermisoWeb($data){ 
		try{ 
			$this->easyPDO->db_procedure('UP_GENERAR_REPORTE_PERMISO',array(
				$data['id_sede'],
				$data['id_permiso'],
				$data['pagado'],
				$data['inicio'],
				$data['fin'] 
			));
 			$data = $this->easyPDO->getData();
			$this->easyPDO->stm->closeCursor(); 
			Response::responsse(200, $data);
		}catch(PDOException $e){
			Response::responsse(409, $e->getMessage());
		}
	}

	public function mdt_ModificarEstadoTareo($data)
	{
		try{
			$this->easyPDO->db_procedure('UP_MODIFICAR_TAREO_WEB',array(
			    $data['id_tareo'],  
			    $data['ta_estado'],
			    $data['userCreacion']  
			));
			$this->easyPDO->stm->closeCursor(); 
			Response::responsse(200, "Modificacion existosa!");
		}catch(PDOException $e){
			Response::responsse(409, $e->getMessage());
		}
	}

	public function mdt_EliminarTareo($data)
	{
		try{
			$this->easyPDO->db_procedure('UP_ELIMINAR_TAREO_WEB',array(
			    $data['id_tareo']
			));
			$this->easyPDO->stm->closeCursor(); 
			Response::responsse(200, "Eliminacion existosa!");
		}catch(PDOException $e){
			Response::responsse(409, $e->getMessage());
		}
	}

	public function mdt_ContarTareo()
	{
		try{
			$this->easyPDO->db_procedure('up_cantidad_tareo_registrado');
			$data = $this->easyPDO->getData();
			$this->easyPDO->stm->closeCursor(); 
			Response::responsse(200, $data[0]);
		}catch(PDOException $e){
			Response::responsse(409, $e->getMessage());
		}
	}

	public function mdt_LineaReporteCharTareo($data)
	{
		try{
			$this->easyPDO->db_procedure('up_linea_tiempo_tareo',array(
				$data['fechaInicio'],
				$data['fechaFin'],
				$data['sede']
			));
			$data = $this->easyPDO->getData();
			$this->easyPDO->stm->closeCursor(); 
			Response::responsse(200, $data);
		}catch(PDOException $e){
			Response::responsse(409, $e->getMessage());
		}
	}

}

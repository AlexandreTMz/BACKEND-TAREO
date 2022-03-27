<?php
class EmpleadoDAO{
	private $easyPDO;

	public function __construct()
	{
		$this->easyPDO = new EasyPDO();
	}

	public function mdt_ListarEmpleado()
	{
		try{
			$this->easyPDO->db_procedure('UP_LISTAR_EMPLEADO');
			$data = $this->easyPDO->getData();
			$this->easyPDO->stm->closeCursor(); 
			Response::responsse(200, $data);
		}catch(PDOException $e){
			Response::responsse(409, $e->getMessage());
		}
	}

	public function mdt_ListarEmpleadoSedeMobil($id_sede,$estado)
	{
		try{
			$this->easyPDO->db_procedure('UP_LISTAR_EMPLEADO_SEDES_MOBIL',array(
				$id_sede,
				$estado
			));
			$data = $this->easyPDO->getData();
			$this->easyPDO->stm->closeCursor(); 
			Response::responsse(200, $data);
		}catch(PDOException $e){
			Response::responsse(409, $e->getMessage());
		}
	}

	public function mdt_ListarEmpleadoDescansoSedeMobil($data)
	{
		try{
			$this->easyPDO->db_procedure('UP_LISTAR_EMPLEADO_SEDES_DESCANSO_MOBIL',array(
				$data['id_sede']
			));
			$data = $this->easyPDO->getData();
			$this->easyPDO->stm->closeCursor(); 
			Response::responsse(200, array(
				"msg" => "xdd",
				"data" => $data
			));
		}catch(PDOException $e){
			Response::responsse(409, $e->getMessage());
		}
	}
 
	public function mtd_reporteDocumentosEmpleadoSede($data)
	{
		try{
			$this->easyPDO->db_procedure('up_buscar_documentos_x_sede',array(
 				$data['id_sede'],
				$data['tp_documento'],
				$data['conSin'],
				$data['estadoEmpleado'],
				$data['opcionSede'] 
			));
			$data = $this->easyPDO->getData();
			$this->easyPDO->stm->closeCursor(); 
			Response::responsse(200, $data);
		}catch(PDOException $e){
			Response::responsse(409, $e->getMessage());
		}
	}

	public function mtd_reporteDocumentosEmpleadoNombre($data)
	{
		try{
			$this->easyPDO->db_procedure('up_buscar_documentos_x_nombres',array(
 				$data['nombre'],
				$data['tp_documento'],
				$data['conSin'],
				$data['estadoEmpleado'],
				$data['opcionSede']   
			));
			$data = $this->easyPDO->getData();
			$this->easyPDO->stm->closeCursor(); 
			Response::responsse(200, $data);
		}catch(PDOException $e){
			Response::responsse(409, $e->getMessage());
		}
	}

	public function mtd_reporteDocumentosEmpleadoTodos($data)
	{
		try{
			$this->easyPDO->db_procedure('up_buscar_documentos_x_todos',array(
 				$data['documento'],
				$data['tp_documento'],
				$data['conSin'],
				$data['estadoEmpleado'],
				$data['opcionSede']   
			));
			$data = $this->easyPDO->getData();
			$this->easyPDO->stm->closeCursor(); 
			Response::responsse(200, $data);
		}catch(PDOException $e){
			Response::responsse(409, $e->getMessage());
		}
	}

	public function fn_returnPathEmployee($fileObject){
		return $fileObject->per_documento.'-'.preg_replace('/[ ,]+/', '-', trim($fileObject->datos));
	}

	public function mtd_descargarReporteDocumentosEmpleadoSede($data)
	{
		try{
			$this->easyPDO->db_procedure('up_buscar_documentos_x_sede',array(
				$data['id_sede'],
				$data['tp_documento'],
				$data['conSin'],
				$data['estadoEmpleado'],
				$data['opcionSede'] 
			));
			$data = $this->easyPDO->getData();
			$this->easyPDO->stm->closeCursor(); 

			$contador = 0;

			foreach($data as $key=>$file){
				if($file->isPossesihng == "Si"){
					$contador++;
				} 
			}
 
			if($contador<=0){
				Response::responsse(409, "No hay archivos que descargar!");
				exit;
			}

			$time = date("Ymd-H-i-s");
			$zip = new ZipArchive;
			$pathZip = Remove_files::getUrlDirectory().'reporte_'.$time.'.zip';
			if ($zip->open($pathZip, ZipArchive::CREATE) === TRUE)
			{
			    foreach($data as $key=>$file){
					if($file->isPossesihng == "Si"){
						$zip->addFile(
							Remove_files::getUrlDocumento($file->per_documento,$file->emd_nombrefile),
							Remove_files::generatePath($this->fn_returnPathEmployee($file),$file->documento.'.'.$this->fileExtension($file->emd_nombrefile))
						);
					} 
				}
			    // All files are added, so close the zip file.
			    $zip->close();
			}else{
				Response::responsse(409, "Algo ocurrio");
			}

			  
		    header($_SERVER['SERVER_PROTOCOL'].' 200 OK');
		    header("Content-Type: application/zip");
		    header("Content-Transfer-Encoding: Binary");    
		    header("Content-Length: ".filesize($pathZip)); 
		    header("Content-Disposition:attachment;filename=\"".basename($pathZip)."\"");


		    while (ob_get_level()) 
		    {
		     ob_end_clean();
		     }
		    readfile($pathZip);   
		    exit;
		    ob_start ();   

		}catch(PDOException $e){
			Response::responsse(409, $e->getMessage());
		}
	}

	public function mtd_descargarReporteDocumentosEmpleadoTodos($data)
	{
		try{
			$this->easyPDO->db_procedure('up_buscar_documentos_x_todos',array(
 				$data['documento'],
				$data['tp_documento'],
				$data['conSin'],
				$data['estadoEmpleado'],
				$data['opcionSede']    
			));
			$data = $this->easyPDO->getData();
			$this->easyPDO->stm->closeCursor(); 

			$contador = 0;

			foreach($data as $key=>$file){
				if($file->isPossesihng == "Si"){
					$contador++;
				} 
			}
   
			if($contador<=0){
				Response::responsse(409, "No hay archivos que descargar!");
				exit;
			}

			$time = date("Ymd-H-i-s");
			$zip = new ZipArchive;
			$pathZip = Remove_files::getUrlDirectory().'reporte_'.$time.'.zip';
			if ($zip->open($pathZip, ZipArchive::CREATE) === TRUE)
			{
			    foreach($data as $key=>$file){ 
					if($file->isPossesihng == "Si"){
						$zip->addFile(
							Remove_files::getUrlDocumento($file->per_documento,$file->emd_nombrefile),
							Remove_files::generatePath($this->fn_returnPathEmployee($file),$file->documento.'.'.$this->fileExtension($file->emd_nombrefile))
						); 
					} 
				}
			    // All files are added, so close the zip file.
			    $zip->close();
			}else{
				Response::responsse(409, "Algo ocurrio");
			} 
 
		    header($_SERVER['SERVER_PROTOCOL'].' 200 OK');
		    header("Content-Type: application/zip");
		    header("Content-Transfer-Encoding: Binary");    
		    header("Content-Length: ".filesize($pathZip)); 
		    header("Content-Disposition:attachment;filename=\"".basename($pathZip)."\"");


		    while (ob_get_level()) 
		    {
		     ob_end_clean();
		     }
		    readfile($pathZip);   
		    exit;
		    ob_start ();   

		}catch(PDOException $e){
			Response::responsse(409, $e->getMessage());
		}
	}

	public function fileExtension($name) {
	    $n = strrpos($name, '.');
	    return ($n === false) ? '' : substr($name, $n+1);
	}

	public function mtd_descargarReporteDocumentosEmpleadoNombre($data) {
		try{
			$this->easyPDO->db_procedure('up_buscar_documentos_x_nombres',array(
 				$data['nombre'],
				$data['tp_documento'],
				$data['conSin'],
				$data['estadoEmpleado'],
				$data['opcionSede']
			));
			$data = $this->easyPDO->getData();
			$this->easyPDO->stm->closeCursor(); 

			$contador = 0;

			foreach($data as $key=>$file){
				if($file->isPossesihng == "Si"){
					$contador++;
				} 
			}
 
			if($contador<=0){
				Response::responsse(409, "No hay archivos que descargar!");
				exit;
			}

			$time = date("Ymd-H-i-s");
			$zip = new ZipArchive;
			$pathZip = Remove_files::getUrlDirectory().'reporte_'.$time.'.zip';
			if ($zip->open($pathZip, ZipArchive::CREATE) === TRUE)
			{
			    foreach($data as $key=>$file){
					if($file->isPossesihng == "Si"){
						$zip->addFile(
							Remove_files::getUrlDocumento($file->per_documento,$file->emd_nombrefile),
							Remove_files::generatePath($this->fn_returnPathEmployee($file),$file->documento.'.'.$this->fileExtension($file->emd_nombrefile))
						);
					} 
				}
			    // All files are added, so close the zip file.
			    $zip->close();
			}else{
				Response::responsse(409, "Algo ocurrio");
			}

			  
		    header($_SERVER['SERVER_PROTOCOL'].' 200 OK');
		    header("Content-Type: application/zip");
		    header("Content-Transfer-Encoding: Binary");    
		    header("Content-Length: ".filesize($pathZip)); 
		    header("Content-Disposition:attachment;filename=\"".basename($pathZip)."\"");


		    while (ob_get_level()) 
		    {
		     ob_end_clean();
		     }
		    readfile($pathZip);   
		    exit;
		    ob_start ();   

		}catch(PDOException $e){
			Response::responsse(409, $e->getMessage());
		}
	} 
	/*
	*	MOVIL
	*	
	*/
	public function mdtM_ListarEmpleadoDescansoSedeMobil($data) {
		try{
			$this->easyPDO->db_procedure('UPM_LISTAR_EMPLEADO_SEDES_DESCANSO_MOBIL',array(
				$data['id_sede']
			));
			$data = $this->easyPDO->getData();
			$this->easyPDO->stm->closeCursor(); 
			Response::responsse(200, array(
				"msg" => "xdd",
				"data" => $data
			));
		}catch(PDOException $e){
			Response::responsse(409, $e->getMessage());
		}
	}
	/*
	* END
	*/

	public function mtd_AdministradorRegistrarEmpleado($data){
		try{
			$this->easyPDO->db_procedure('UP_ADMINISTRADOR_REGISTRAR_EMPLEADO',array(
				$data['tipo_documento'],
				$data['nacionalidad'],
				$data['nombres'],
				$data['apellido_paterno'],
				$data['apellido_materno'],
				$data['documento'],
				$data['fecha_nacimiento'],
				$data['celular'],
				$data['correo'],
				$data['nacionalidad'], 
				$data['fecha_ingreso'],
				$data['titular'],
				$data['usuario'],
				$data['sexo'],
				$data['direccion'],
				$data['estado'],
				json_encode($data['empleado']),
				json_encode($data['pago']),
				$data['userCreacion']
			));
 			$this->easyPDO->stm->closeCursor(); 
			Response::responsse(200, "Empleado registrado satisfactoriamente!");
		}catch(PDOException $e){
			Response::responsse(409, $e->getMessage());
		}catch (Exception $e) {
		  	Response::responsse(409, $e->getMessage());
		}
	}

	public function mtd_MergePersonaEmpleado($data){
		try{
			$this->easyPDO->db_procedure('UP_MERGE_PERSONA_EMPLEADO',array(
				$data['id_persona'],
				$data['tipo_documento'],
				$data['nacionalidad'],
				$data['nombres'],
				$data['apellido_paterno'],
				$data['apellido_materno'],
				$data['documento'],
				$data['fecha_nacimiento'],
				$data['celular'],
				$data['correo'],
				$data['nacionalidad'], 
				$data['fecha_ingreso'],
				$data['fecha_cese'],
				$data['titular'],
				$data['usuario'],
				$data['sexo'],
				$data['direccion'],
				$data['estado']
			));
 			$this->easyPDO->stm->closeCursor();
 			$rsp =	($data['id_persona'] == 0) ? "registrado" : "actualizado"; 
			Response::responsse(200, "Persona ".$rsp." satisfactoriamente!");
		}catch(PDOException $e){
			Response::responsse(409, $e->getMessage());
		}
	}

	public function mtdM_SupervisorRegistrarEmpleado($data){
		try{
			$this->easyPDO->db_procedure('MOV_UP_SUPERVISOR_REGISTRAR_EMPLEADOV',array(
				$data['tipo_documento'],
				$data['nacionalidad'],
				$data['nombres'],
				$data['apellido_paterno'],
				$data['apellido_materno'],
				$data['documento'],
				$data['fecha_nacimiento'],
				$data['celular'],
				$data['correo'],
				1,
				$data['fecha_ingreso'],
				$data['titular'],
				$data['usuario'],
				$data['sexo'],
				$data['direccion'],
				$data['estado'],
				json_encode($data['empleado']),
				json_encode($data['pago'])
			));
 			$this->easyPDO->stm->closeCursor(); 
			Response::responsse(200, "Empleado registrado satisfactoriamente!");
		}catch(PDOException $e){
			Response::responsse(409, $e->getMessage());
		}catch (Exception $e) {
		  	Response::responsse(409, $e->getMessage());
		}
	}

	public function mtd_AdministradorRegistrarSueldoAprobar($data){
		try{
			$this->easyPDO->db_procedure('UP_APROBAR_REGISTRA_SUELDO_ADM',array(
				$data['id_sueldo'],
				$data['id_persona'],
				$data['basicSalary'],
				$data['householdAllowance'],
				$data['bonus'],
				$data['mobility'],
				$data['food'],
				$data['ta_total']
			));
 			$this->easyPDO->stm->closeCursor(); 
			Response::responsse(200, "Sueldo registrado satisfactoriamente!");
		}catch(PDOException $e){
			Response::responsse(409, $e->getMessage());
		}
	}

	public function mtd_DesicionAprobarOeliminar($data){
		try{
			$this->easyPDO->db_procedure('UP_DESICION_ESTADO_EMPLEADO',array(
				$data['id_persona'],
				$data['opcion'],
				$data['userCreacion'] 
			));
 			$this->easyPDO->stm->closeCursor(); 
			Response::responsse(200, "Sueldo registrado satisfactoriamente!");
		}catch(PDOException $e){
			Response::responsse(409, $e->getMessage());
		}
	}

	// REGISTRAR A LOS SUELDO Y DESHABIULITAR EL RESTO
	public function mtd_AdministradorRegistrarSueldoWeb($data){
		try{
			$this->easyPDO->db_procedure('UP_REGISTRAR_SUELDO_PERSONAWEB',array(
				$data['id_persona'],
				$data['ta_basico'],
				$data['ta_estado'],
				$data['ta_observacion'],
				$data['ta_csdia'],
				$data['ta_asignacion_familiar'],
				$data['ta_bonificacion'],
				$data['ta_movilidad'],
				$data['ta_alimentos'],
				$data['ta_total'],
				$data['ta_vigenciaInicio'],
				$data['ta_vigenciaFin'],
				$data['userCreacion']
			));
 			$this->easyPDO->stm->closeCursor(); 
			Response::responsse(200, "Sueldo registrado satisfactoriamente!");
		}catch(PDOException $e){
			Response::responsse(409, $e->getMessage());
		}
	}

	public function mtd_AdministradorActualizarSueldoWeb($data){
		try{
			$this->easyPDO->db_procedure('UP_ACTUALIZAR_SUELDO_PERSONAWEB',array(
				$data['id_sueldo'],
				$data['id_persona'],
				$data['ta_basico'],
				$data['ta_estado'],
				$data['ta_observacion'],
				$data['ta_csdia'],
				$data['ta_asignacion_familiar'],
				$data['ta_bonificacion'],
				$data['ta_movilidad'],
				$data['ta_alimentos'],
				$data['ta_total'],
				$data['ta_vigenciaInicio'],
				$data['ta_vigenciaFin'],
				$data['userCreacion']
			));
 			$this->easyPDO->stm->closeCursor(); 
			Response::responsse(200, "Sueldo actualizado satisfactoriamente!");
		}catch(PDOException $e){
			Response::responsse(409, $e->getMessage());
		}
	}

	public function mtd_uploadImageEmpleado(){
       	$handle = new Files_img($_FILES['image']);
       		if ($handle->uploaded) {
	            $nombreArchivo = $_POST['documento'];
	            $handle->file_new_name_body   	= $nombreArchivo;
	            $handle->jpeg_quality 			= 70; 
	            $handle->image_convert 			= 'jpg';
	            $handle->file_new_name_ext 		= 'jpg';
	            $handle->image_resize 			= true;
	            $handle->image_x 				= 180;
	            $handle->image_y 				= 180;
	            
	            $handle->process('UPLOADS/'.$_POST['documento']);
            	if ($handle->processed) {
            		$this->mtd_ActualizarFotoPerfil($_POST['documento'], $nombreArchivo, $_POST['userCreacion']);
                	Response::responsse(200, $nombreArchivo);
            	}
        	}else{
        		$msg = !isset($_FILES['image']) ? 'No se actualizó la foto' : '¡Error desconocido! Foto no subida' ;
        		Response::responsse(409, $msg);
        	}
		
	}

	public function mtd_ActualizarFotoPerfil($documento,$foto, $userCreacion){
		try{
			$this->easyPDO->db_procedure('UP_ACTUALIZAR_FOTO_PERFIL',array(
				$documento,
				$foto,
				$userCreacion
			));
 			$this->easyPDO->stm->closeCursor();
		}catch(PDOException $e){
			Response::responsse(409, $e->getMessage());
		}
	}

	public function mtd_uploadDocumentEmpleado(){
       	$handle = new Files_img($_FILES['file_documents']);
       		if ($handle->uploaded) {
	            $nombreArchivo = $_POST['documento'].uniqid();
	            $handle->file_new_name_body   	= $nombreArchivo; 
	            $handle->file_overwrite 		= true;
	            $handle->process('UPLOADS/'.$_POST['documento'].'/documentos');
            	if ($handle->processed) {
            		$this->mtd_SubirDocumentosEmpleados(
            			$_POST['documento'],
            			$_POST['id_emdocumento'],
            			($nombreArchivo.'.'.$handle->file_src_name_ext),
            			$_POST['emd_pesofile'],
            			$_POST['emd_emision'],
            			$_POST['emd_vigencia'],
            			$_POST['userCreacion']
            		);
                	Response::responsse(200, $nombreArchivo.'.'.$handle->file_src_name_ext);
            	}
        	}else{
        		$msg = !isset($_FILES['file_documents']) ? 'Se subio los documenots' : '¡Error desconocido! Foto no subida' ;
        		Response::responsse(409, $msg);
        	} 
	}

	public function mtd_SubirDocumentosEmpleados($documento,$id_emdocumento,$emd_nombrefile,$emd_pesofile,$emd_emision,$emd_vigencia,$userCreacion){
		try{
			$this->easyPDO->db_procedure('UP_REGISTRAR_DOCUMENTOS_EMPLEADO',array(
				$documento,
				$id_emdocumento,
				$emd_nombrefile,
				$emd_pesofile,
				$emd_emision,
				$emd_vigencia, 
				$userCreacion 
			));
 			$this->easyPDO->stm->closeCursor();
		}catch(PDOException $e){
			Response::responsse(409, $e->getMessage());
		}
	}
	

	// DESHABILITAR SUELDO
	public function mtd_AdministradorDeshabilitarSueldoWeb($data){
		try{
			$this->easyPDO->db_procedure('UP_DESHABILITAR_SUELDO_PERSONAWEB',array(
				$data['id_sueldo'],
				$data['userCreacion']
			));
 			$this->easyPDO->stm->closeCursor(); 
			Response::responsse(200, "Sueldo deshabilitado satisfactoriamente!");
		}catch(PDOException $e){
			Response::responsse(409, $e->getMessage());
		}
	}

	// REGISTRAR A LOS DESCANSOS Y DESHABIULITAR EL RESTO
	public function mtd_SupervisorRegistrarDescansoMobil($data){
		try{ 
			$this->easyPDO->db_procedure('UP_REGISTRAR_DESCANSO_PERSONAMOBIL',array(
				$data['id_persona'],
				$data['de_fecha'] 
			));
 			$this->easyPDO->stm->closeCursor(); 
			Response::responsse(200, "Descanso registrado satisfactoriamente!");
		}catch(PDOException $e){
			Response::responsse(409, $e->getMessage());
		}
	}

	// REGISTRAR A LOS DESCANSOS Y DESHABIULITAR EL RESTO
	public function mtd_AdministradorRegistrarDescansoWeb($data){
		try{ 
			$this->easyPDO->db_procedure('UP_REGISTRAR_DESCANSO_PERSONAWEB',array(
				$data['id_persona'],
				$data['de_fecha'],
				$data['de_observacion'],
				$data['de_estado'],
				$data['de_referencia'],
				$data['userCreacion']
			));
 			$this->easyPDO->stm->closeCursor(); 
			Response::responsse(200, "Descanso registrado satisfactoriamente!");
		}catch(PDOException $e){
			Response::responsse(409, $e->getMessage());
		}
	}

	// DESHABILITAR DESCANSOS
	public function mtd_AdministradorDeshabilitarDescansoWeb($data){
		try{
			$this->easyPDO->db_procedure('UP_DESHABILITAR_DESCANSO_PERSONAWEB',array(
				$data['id_descanso'] ,
				$data['userCreacion']
			));
 			$this->easyPDO->stm->closeCursor(); 
			Response::responsse(200, "Descanso eliminado satisfactoriamente!");
		}catch(PDOException $e){
			Response::responsse(409, $e->getMessage());
		}
	}

	public function mtd_AdministradorHabilitarDescansoWeb($data){
		try{
			$this->easyPDO->db_procedure('UP_HABILITARS_DESCANSO_PERSONAWEB',array(
				$data['id_descanso'],
				$data['userCreacion']
			));
 			$this->easyPDO->stm->closeCursor(); 
			Response::responsse(200, "Descanso eliminado satisfactoriamente!");
		}catch(PDOException $e){
			Response::responsse(409, $e->getMessage());
		}
	}


	// REGISTRAR A LOS CUENTA TITULAR Y DESHABIULITAR EL RESTO
	public function mtd_AdministradorRegistrarCuentaTitularWeb($data){
		try{ 
			$this->easyPDO->db_procedure('UP_REGISTRAR_CUENTA_TITULAR_PERSONAWEB',array(
				$data['id_persona'],
				$data['id_banco'],
				$data['id_tpcuenta'],
				$data['phb_cuenta'],
				$data['phb_cci'],
				$data['userCreacion']
			));
 			$this->easyPDO->stm->closeCursor(); 
			Response::responsse(200, "Cuenta titular registrado satisfactoriamente!");
		}catch(PDOException $e){
			Response::responsse(409, $e->getMessage());
		}
	}

	public function mtd_AdministradorActualizarCuentaTitularWeb($data){
		try{ 
			$this->easyPDO->db_procedure('UP_ACTUALZIAR_CUENTA_TITULAR_PERSONAWEB',array(
				$data['id_persona'],
				$data['id_phbbanco'],
				$data['id_banco'],
				$data['id_tpcuenta'],
				$data['phb_cuenta'],
				$data['phb_cci'],
				$data['userCreacion']
			));
 			$this->easyPDO->stm->closeCursor(); 
			Response::responsse(200, "Cuenta titular actualizado satisfactoriamente!");
		}catch(PDOException $e){
			Response::responsse(409, $e->getMessage());
		}
	}

	public function mtd_AdministradorDeshabilitarCuentaTitularWeb($data){
		try{
			$this->easyPDO->db_procedure('UP_HABILITAR_DESHABILITAR_CUENTA_TITULAR_PERSONAWEB',array(
				$data['id_persona'],
				$data['id_phbbanco'],
				$data['opcion'],
				$data['userCreacion']
			));
 			$this->easyPDO->stm->closeCursor(); 
			Response::responsse(200, "Cuenta actualizado satisfactoriamente!");
		}catch(PDOException $e){
			Response::responsse(409, $e->getMessage());
		}
	}

	// REGISTRAR A LOS CUENTA TERCERO Y DESHABIULITAR EL RESTO
	public function mtd_AdministradorRegistrarCuentaTerceroWeb($data){
		try{ 
			$this->easyPDO->db_procedure('UP_REGISTRAR_CUENTA_TERCERO_PERSONAWEB',array(
				$data['id_origen'],
				$data['doc_suplente'],
				$data['userCreacion']
			));
 			$this->easyPDO->stm->closeCursor(); 
			Response::responsse(200, "Cuenta titular registrado satisfactoriamente!");
		}catch(PDOException $e){
			Response::responsse(409, $e->getMessage());
		}
	}

	public function mtd_AdministradorDeshabilitarHabilitarCuentaTerceroWeb($data){
		try{ 
			$this->easyPDO->db_procedure('UP_HABILITAR_DESHABILITAR_CUENTA_TERCERO_PERSONAWEB',array(
				$data['id_persona'],
				$data['id_sucobrar'],
				$data['opcion'] 
			));
 			$this->easyPDO->stm->closeCursor(); 
			Response::responsse(200, "Cuenta titular registrado satisfactoriamente!");
		}catch(PDOException $e){
			Response::responsse(409, $e->getMessage());
		}
	}

	// REGISTRAR A LOS CARGOS Y DESHABIULITAR EL RESTO
	public function mtd_AdministradorRegistrarCargoWeb($data){
		try{ 
			$this->easyPDO->db_procedure('UP_REGISTRAR_CARGO_PERSONAWEB',array(
				$data['id_persona'],
				$data['id_cargo'],
				$data['ce_estado'],
				$data['ce_observacion'],
				$data['userCreacion']
			));
 			$this->easyPDO->stm->closeCursor(); 
			Response::responsse(200, "Cargo registrado satisfactoriamente!");
		}catch(PDOException $e){
			Response::responsse(409, $e->getMessage());
		}
	}

	// DESHABILITAR CARGOS
	public function mtd_AdministradorDeshabilitarCargoWeb($data){
		try{
			$this->easyPDO->db_procedure('UP_DESHABILITAR_CARGO_PERSONAWEB',array(
				$data['id_caempleado'],
				$data['userCreacion']
			));
 			$this->easyPDO->stm->closeCursor(); 
			Response::responsse(200, "Cargo deshabilitado satisfactoriamente!");
		}catch(PDOException $e){
			Response::responsse(409, $e->getMessage());
		}
	}

	// REACTIVAR CARGOS
	public function mtd_AdministradorRactivarCargoWeb($data){
		try{
			$this->easyPDO->db_procedure('UP_REACTIVAR_CARGO_PERSONAWEB',array(
				$data['id_persona'], 
				$data['id_caempleado'],
				$data['userCreacion']
			));
 			$this->easyPDO->stm->closeCursor(); 
			Response::responsse(200, "Cargo rehabilitado satisfactoriamente!");
		}catch(PDOException $e){
			Response::responsse(409, $e->getMessage());
		}
	}

	// REGISTRAR A LOS CARGOS Y DESHABIULITAR EL RESTO
	public function mtd_AdministradorRegistrarSedeWeb($data){
		try{ 
			$this->easyPDO->db_procedure('UP_REGISTRAR_SEDE_PERSONAWEB',array(
				$data['id_persona'],
				$data['id_sede'],
				$data['sm_codigo'],
				$data['sm_observacion'],
				$data['sm_estado'] ,
				$data['userCreacion']
			));
 			$this->easyPDO->stm->closeCursor(); 
			Response::responsse(200, "Sede registrado satisfactoriamente!");
		}catch(PDOException $e){
			Response::responsse(409, $e->getMessage());
		}
	}

	// DESHABILITAR CARGOS
	public function mtd_AdministradorCambioEstadoSedeWeb($data){
		try{
			$this->easyPDO->db_procedure('UP_CAMBIO_ESTADO_SEDE_PERSONAWEB',array(
				$data['id_sede_em'],
				($data['opcion'] == 1 ? 1 : 0),
				$data['userCreacion']
			));
 			$this->easyPDO->stm->closeCursor(); 
 			$estado = $data['opcion'] == 1 ? 'habilitado' : 'deshabilitado' ;
			Response::responsse(200, "Sede ".$estado." satisfactoriamente!");
		}catch(PDOException $e){
			Response::responsse(409, $e->getMessage());
		}
	}

	public function mdt_ListarSedeWeb($datos)
	{
		try{
			$this->easyPDO->db_procedure('UP_LISTAR_SEDE_EMPLEADO',array(
				$datos
			));
			$data = $this->easyPDO->getData();
			$this->easyPDO->stm->closeCursor(); 
			Response::responsse(200, $data);
		}catch(PDOException $e){
			Response::responsse(409, $e->getMessage());
		}
	}

	public function mdt_ListarCuentas($datos)
	{
		try{
			$this->easyPDO->db_procedure('UP_LISTAR_BANCOS_X_EMPLEADO',array(
				$datos
			));
			$data = $this->easyPDO->getData();
			$this->easyPDO->stm->closeCursor(); 
			Response::responsse(200, $data);
		}catch(PDOException $e){
			Response::responsse(409, $e->getMessage());
		}
	}

	public function mdt_ListarSueldoWeb($datos)
	{
		try{
			$this->easyPDO->db_procedure('UP_LISTAR_SUELDO_EMPLEADO',array(
				$datos
			));
			$data = $this->easyPDO->getData();
			$this->easyPDO->stm->closeCursor(); 
			Response::responsse(200, $data);
		}catch(PDOException $e){
			Response::responsse(409, $e->getMessage());
		}
	}

	public function mdt_ListarDescansoWeb($datos)
	{
		try{
			$this->easyPDO->db_procedure('UP_LISTAR_DESCANSO_EMPLEADO',array(
				$datos
			));
			$data = $this->easyPDO->getData();
			$this->easyPDO->stm->closeCursor(); 
			Response::responsse(200, $data);
		}catch(PDOException $e){
			Response::responsse(409, $e->getMessage());
		}
	}

	public function mdt_ListarCargoWeb($datos)
	{
		try{
			$this->easyPDO->db_procedure('UP_LISTAR_CARGOS_EMPLEADO',array(
				$datos
			));
			$data = $this->easyPDO->getData();
			$this->easyPDO->stm->closeCursor(); 
			Response::responsse(200, $data);
		}catch(PDOException $e){
			Response::responsse(409, $e->getMessage());
		}
	}

	public function mdt_GetPersonaIdPer($datos)
	{
		try{
			$this->easyPDO->db_procedure('UP_GET_DATA_PERSONA',array(
				$datos
			));
			$data = $this->easyPDO->getData();
			$this->easyPDO->stm->closeCursor(); 
			Response::responsse(200, $data[0]);
		}catch(PDOException $e){
			Response::responsse(409, $e->getMessage());
		}
	}


	public function mdt_ListarEmpleadoSu($datos)
	{
		try{
			$this->easyPDO->db_procedure('UP_BUSCAR_EMPLEADO_ADM_WEB',array(
				$datos['opcion'],
				$datos['nombres'],
				$datos['documento'],
				$datos['sede'],
				$datos['cargo'],
				$datos['opcionSede'],
				$datos['estadoEmpleado'] 
			));
			$data = $this->easyPDO->getData();
			$this->easyPDO->stm->closeCursor(); 
			Response::responsse(200, $data);
		}catch(PDOException $e){
			Response::responsse(409, $e->getMessage());
		}
	}
 
	public function mdt_ListarEmpleadoSinAprobar($datos)
	{
		try{
			$this->easyPDO->db_procedure('UP_LISTAR_EMPLEADOS_SIN_APROBAR_V',array(
				$datos['opcion'],
				$datos['dato']
			));
			$data = $this->easyPDO->getData();
			$this->easyPDO->stm->closeCursor(); 
			Response::responsse(200, $data);
		}catch(PDOException $e){
			Response::responsse(409, $e->getMessage());
		}
	}

	// BORRAR
	public function mdt_ListarEmpleadoPermiso($documento)
	{
		try{
			$this->easyPDO->db_procedure('UP_BUSCAR_EMPLEADO_PERMISO',array(
				$documento 
			));
			$data = $this->easyPDO->getData();
			$this->easyPDO->stm->closeCursor(); 
			Response::responsse(200, $data);
		}catch(PDOException $e){
			Response::responsse(409, $e->getMessage());
		}
	}

	public function mdt_ListarEmpleadoPermisoV2($documento,$sede)
	{
		try{
			$this->easyPDO->db_procedure('UP_BUSCAR_EMPLEADO_PERMISOV2',array(
				$documento,
				$sede 
			));
			$data = $this->easyPDO->getData();
			$this->easyPDO->stm->closeCursor(); 
			Response::responsse(200, $data);
		}catch(PDOException $e){
			Response::responsse(409, $e->getMessage());
		}
	}

	public function mdtM_ListarEmpleadoPermisoMovil($documento,$sede)
	{
		try{
			$this->easyPDO->db_procedure('MOV_UP_BUSCAR_EMPLEADO_PERMISOV2',array(
				$documento,
				$sede 
			));
			$data = $this->easyPDO->getData();
			$this->easyPDO->stm->closeCursor(); 
			Response::responsse(200, $data);
		}catch(PDOException $e){
			Response::responsse(409, $e->getMessage());
		}
	}

	public function mtd_MigrarSuplenteEmpleado($datos){
		try{
			$this->easyPDO->db_procedure('UP_MIGRAR_SUPLENTE_EMPLEADO',array(
				$datos['id_persona']
			)); 
			$this->easyPDO->stm->closeCursor(); 
			Response::responsse(200, "El cambio se ha hecho correctamente!");
		}catch(PDOException $e){
			Response::responsse(409, $e->getMessage());
		}
	}

	public function mdt_ContarEmpleado()
	{
		try{
			$this->easyPDO->db_procedure('up_cantidad_empleados');
			$data = $this->easyPDO->getData();
			$this->easyPDO->stm->closeCursor(); 
			Response::responsse(200, $data[0]);
		}catch(PDOException $e){
			Response::responsse(409, $e->getMessage());
		}
	}

	public function mdt_ContarEmpleadoSinAprobar()
	{
		try{
			$this->easyPDO->db_procedure('up_cantidad_personas_aprobar');
			$data = $this->easyPDO->getData();
			$this->easyPDO->stm->closeCursor(); 
			Response::responsse(200, $data[0]);
		}catch(PDOException $e){
			Response::responsse(409, $e->getMessage());
		}
	}

	public function mtd_getDocumentosEmpleados()
	{
		try{
			$this->easyPDO->db_procedure('UP_GET_DOCUMENTOS_EMPLEADO');
			$data = $this->easyPDO->getData();
			$this->easyPDO->stm->closeCursor(); 
			Response::responsse(200, $data);
		}catch(PDOException $e){
			Response::responsse(409, $e->getMessage());
		}
	}

	public function mtd_getDocumentosEmpleadosEditar()
	{
		try{
			$this->easyPDO->db_procedure('UP_GET_DOCUMENTOS_EDIT_EMPLEADO');
			$data = $this->easyPDO->getData();
			$this->easyPDO->stm->closeCursor(); 
			Response::responsse(200, $data);
		}catch(PDOException $e){
			Response::responsse(409, $e->getMessage());
		}
	}

	public function mdt_ListarEmpleadoDocumentos($id_persona)
	{
		try{
			$this->easyPDO->db_procedure('up_list_all_documents',array(
				$id_persona
			));
			$data = $this->easyPDO->getData();
			$this->easyPDO->stm->closeCursor(); 
			Response::responsse(200, $data);
		}catch(PDOException $e){
			Response::responsse(409, $e->getMessage());
		}
	}


	public function mtd_eliminarDocumentosEmpleado($data){
		try{
			$this->easyPDO->db_procedure('up_eliminar_documentos_empleado',array(
				$data['id_docemp'] 
			));
 			$this->easyPDO->stm->closeCursor(); 
 			Remove_files::removeFile($data['documento'],$data['archivo']);
			Response::responsse(200, "Documento eliminado!");
		}catch(PDOException $e){
			Response::responsse(409, $e->getMessage());
		}
	} 
}
?>
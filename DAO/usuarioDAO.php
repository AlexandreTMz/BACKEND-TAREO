<?php
class UsuarioDAO{
	private $easyPDO;

	public function __construct()
	{
		$this->easyPDO = new EasyPDO();
	}

	/* API */
	public function mdt_ListarUsuario()
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

	public function mtd_LoginUsuariokkk($data){
		try{
			$this->easyPDO->db_procedure('UP_LOGIN_USUARIO',array(
				$data['usuario'],
				$data['contrasenia']
			));
 			$data = $this->easyPDO->getData();
			$this->easyPDO->stm->closeCursor(); 
			Response::responsse(200, $data[0]);
		}catch(PDOException $e){
			Response::responsse(409, $e->getMessage());
		} 
	}

	public function mtd_CambiarContraseniaUsuario($data){
		try{
			$this->easyPDO->db_procedure('up_cambiar_contrasenia_usuario',array(
				$data['usuario'],
				$data['pass_old'],
				$data['pass_new'],
				$data['userCreacion']
			));
			$this->easyPDO->stm->closeCursor(); 
			Response::responsse(200, 'La contraseña se actualizó correctamente');
		}catch(PDOException $e){
			Response::responsse(409, $e->getMessage());
		} 
	}

	public function mtd_MLoginUsuario($data){
		try{
			$this->easyPDO->db_procedure('UP_LOGIN_USUARIO_MOBIL',array(
				$data['usuario'],
				$data['contrasenia']
			));
 			$objL_Perfil = $this->easyPDO->getData()[0];
 			$idPersona = $objL_Perfil->id_persona;

 			$this->easyPDO->db_procedure('UP_GET_SEDES_EMPLEADOS_BY_IDPERSONA',array(
				$idPersona
			));

 			$objL_Sedes = $this->easyPDO->getData();
 			$acumuladorSede = "";

 			if(count($objL_Sedes) <= 0){ 
 				throw new Exception('Error este usuario no tiene sedes habilitadas!');
 			}

 			$objL_Perfil->id_sede = $objL_Sedes[0]->id_sede;
 			$objL_Perfil->sede = $objL_Sedes[0]->se_lugar." / ".$objL_Sedes[0]->se_descripcion;

 			for ($i=0; $i < count($objL_Sedes) ; $i++) { 
 				$acumuladorSede .= $objL_Sedes[$i]->id_sede."(@*)".$objL_Sedes[$i]->se_lugar." / ".$objL_Sedes[$i]->se_descripcion."[@]";
 			}

 			if(count($objL_Sedes) >= 1){
 				$acumuladorSede = substr($acumuladorSede, 0, -3);
 			}

 			$objL_Perfil->sedesPermitidas = $acumuladorSede;

			$this->easyPDO->stm->closeCursor(); 
			Response::responsse(200, $objL_Perfil);
		}catch(PDOException | Exception $e){
			Response::responsse(409, $e->getMessage());
		} 
	}

	public function mtd_CambioContrasenia($data){ 
		try{
			$this->easyPDO->db_procedure('UP_CAMBIO_CONTRASENIA_PERSONA_ID',array(
				$data['id_persona'],
				$data['contrasenia']
			)); 
			if($this->easyPDO->stm->rowCount()>0){
				Response::responsse(200, "Contraseña actualizada");
				$this->easyPDO->stm->closeCursor();
			}else{
				Response::responsse(409, "Error, no se pudo cambiar su contraseña!");
				$this->easyPDO->stm->closeCursor();
			} 
		}catch(PDOException $e){
			Response::responsse(409, $e->getMessage());
		} 
	}

	/* WEB */

	public function login()
	{
		if ($_SERVER['REQUEST_METHOD'] === 'POST') {
			if(isset($_POST['inpUsuario']) && isset($_POST['inpContrasenia'])){
				try {
					$this->easyPDO->db_procedure('up_iniciar_session',array(
						$_POST['inpUsuario'],
						$_POST['inpContrasenia']
					));
					$resUsuario =$this->easyPDO->getData();
					if(count($resUsuario)>0){
						Utilities::set_session('usuario',$resUsuario[0]);
						Utilities::redirectSwitch();
						//print_r(Utilities::get_session('usuario'));
						Utilities::setMessage("1","Bienvenido usuario!"); 
					}else {
						Utilities::setMessage("3","Usuario o contraseña incorrecta!"); 
					}
				} catch (Exception $e) {
					print_r($e->getMessage());
				}
			}else {
			   		//Helpers::redirect(Helpers::url());
			}
		}else {
				//Helpers::redirect(Helpers::url());
		}
	}

	public function mtd_WLoginUsuario()
	{
		if(isset($_POST['btnIniciarSession'])){
			try{
				$this->easyPDO->db_procedure('UP_LOGIN_USUARIO_WEB',array(
					$_POST['inpUsuario'],
					$_POST['inpContrasenia']
				));
				$data = $this->easyPDO->getData();
				if(count($data)>0){
					Session::setSession('usuario',$data[0]);
					Seguridad::redirectSwitch();
				}else{
					Utilities::setMessage("3","Usuario o contraseña incorrecta!"); 
				}
			}catch(PDOException $e){
				Utilities::setMessage("3",Response::clearMsg($e->getMessage())); 
			}
		}
	}


	public function mtd_WLoginUsuarioApi($data)
	{
		try{
			$this->easyPDO->db_procedure('UP_LOGIN_USUARIO_WEB',array(
				$data['usuario'],
				$data['contrasenia']
			));
			$resData = $this->easyPDO->getData();
			if(count($resData)>0){
				$resPermission = $this->mdt_ListarPermisoUsuario($resData[0]->id_usuario);
				$convertData = $this->object_to_array($resData[0]);
				$convertData['permission'] = $resPermission;
				Response::responsse(200, $convertData);
			}else{
				Response::responsse(409, 'Error contraseña o usuario incorrecto!');
			}

		}catch(PDOException $e){
			Response::responsse(409, $e->getMessage());
		}
	}

	public function object_to_array($data)
	{
	    if (is_array($data) || is_object($data))
	    {
	        $result = [];
	        foreach ($data as $key => $value)
	        {
	            $result[$key] = (is_array($data) || is_object($data)) ? $this->object_to_array($value) : $value;
	        }
	        return $result;
	    }
	    return $data;
	}

	public function mdt_ListarPermisoUsuario($id_usuario)
	{
		try{
			$this->easyPDO->db_procedure('up_listar_modulos_usuarios_sistema',array(
				$id_usuario
			));
			$data = $this->easyPDO->getData();
			//$this->easyPDO->stm->closeCursor();

			$array = [];  

			foreach($data as $items){
				if(!array_key_exists($items->sm_nombre, $array)){
					$array[$items->sm_nombre] = array(
						"name" => $items->sm_nombre,
						"permission" => array()
					);
				} 

				$array[$items->sm_nombre]['permission'][] = array(
					"id_spermiso" => $items->id_spermiso,
					"sp_nombre" => $items->sp_nombre,
					"id_mpermiso" => $items->id_mpermiso,
					"hasPermissionGui" => ($items->hasPermission == 1 ? true : false),
					"hasPermission" => ($items->hasPermission == 1 ? true : false)
				);

			}  
			return array_values($array);
		}catch(PDOException $e){
			Response::responsse(409, $e->getMessage());
			exit();
		}
	}



	public function mdt_ListarUsuario_sistema()
	{
		try{
			$this->easyPDO->db_procedure('UP_LISTAR_USUARIOS_SISTEMA');
			$data = $this->easyPDO->getData();
			$this->easyPDO->stm->closeCursor(); 
			Response::responsse(200, $data);
		}catch(PDOException $e){
			Response::responsse(409, $e->getMessage());
		}
	}


	public function mtd_ActualziarUsuario($data){  
		try{
			$this->easyPDO->db_procedure('UP_ACTUALIZAR_USUARIO_PERSONA_ID',array(
				$data['id_usuario'],
				$data['us_usuario'],
				$data['us_contrasenia'],
				$data['us_estado'],
				$data['option'],
				$data['userCreacion']
			)); 
			Response::responsse(200, "Usuario actualizado correctamente!");
		}catch(PDOException $e){
			Response::responsse(409, $e->getMessage());
		} 
	} 

}
?>
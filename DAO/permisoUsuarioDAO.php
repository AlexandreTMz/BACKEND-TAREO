<?php
class PermisoUsuarioDAO{
	private $easyPDO;

	public function __construct()
	{
		$this->easyPDO = new EasyPDO();
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
					"hasPermission" => ($items->hasPermission == 1 ? true : false), 
					"hasEditing" => false
				);

			}	

			/*echo "<pre>";
			print_r(array_values($array));
			echo "</pre>";
			die();*/

			Response::responsse(200, array_values($array));
		}catch(PDOException $e){
			Response::responsse(409, $e->getMessage());
		}
	}


	public function mtd_RegisterPermissionUser($data){
		try{
			$this->easyPDO->db_procedure('up_registrar_permisos_usuario_modulos',array(
				$data['id_usuario'],
				$data['id_mpermiso'],
				$data['hasPermission'],
				$data['userCreacion']
			));
 			$this->easyPDO->stm->closeCursor();
			Response::responsse(200, "Operacion realziada");
		}catch(PDOException $e){
			Response::responsse(409, $e->getMessage());
		}
	}


}
?>
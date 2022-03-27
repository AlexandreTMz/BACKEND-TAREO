<?php
class PermisoDAO{
	private $easyPDO;

	public function __construct()
	{
		$this->easyPDO = new EasyPDO();
	}

	public function mdt_ListarPermiso()
	{
		try{
			$this->easyPDO->db_procedure('UP_LISTAR_PERMISO');
			$data = $this->easyPDO->getData();
			$this->easyPDO->stm->closeCursor(); 
			Response::responsse(200, $data);
		}catch(PDOException $e){
			Response::responsse(409, $e->getMessage());
		}
	}

	/*
	*	MOVIL
	*	
	*/
	public function mdtM_ListarPermiso()
	{
		try{
			$this->easyPDO->db_procedure('MOV_UP_LISTAR_PERMISO');
			$data = $this->easyPDO->getData();
			$this->easyPDO->stm->closeCursor(); 
			Response::responsse(200, $data);
		}catch(PDOException $e){
			Response::responsse(409, $e->getMessage());
		}
	}

	/*
	* END
	*/

	public function mdt_ListarPermisoWeb()
	{
		try{
			$this->easyPDO->db_procedure('UP_LISTAR_PERMISO_WEB');
			$data = $this->easyPDO->getData();
			$this->easyPDO->stm->closeCursor(); 
			Response::responsse(200, $data);
		}catch(PDOException $e){
			Response::responsse(409, $e->getMessage());
		}
	}

	public function mtd_MergePermiso($data){
		try{
			$this->easyPDO->db_procedure('UP_MERGE_PERMISO',array(
				$data['id_permiso'],
				$data['pe_descripcion'],
				$data['pe_nombre'],
				$data['pe_estado'] 
			));
 			$this->easyPDO->stm->closeCursor();
 			$rsp =	($data['id_permiso'] == 0) ? "registrado" : "actualizado"; 
			Response::responsse(200, "Permiso ".$rsp." satisfactoriamente!");
		}catch(PDOException $e){
			Response::responsse(409, $e->getMessage());
		}
	}

}
?>
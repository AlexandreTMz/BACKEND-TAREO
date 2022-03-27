<?php
class CargoDAO{
	private $easyPDO;

	public function __construct()
	{
		$this->easyPDO = new EasyPDO();
	}

	public function mdt_ListarCargo()
	{
		try{
			$this->easyPDO->db_procedure('UP_LISTAR_CARGO');
			$data = $this->easyPDO->getData();
			$this->easyPDO->stm->closeCursor(); 
			Response::responsse(200, $data);
		}catch(PDOException $e){
			Response::responsse(409, $e->getMessage());
		}
	}

	/*
	*	MOVIL
	*/
	public function mdtM_ListarCargo()
	{
		try{
			$this->easyPDO->db_procedure('MOV_UP_LISTAR_CARGO');
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

	public function mtd_MergeCargo($data){
		try{
			$this->easyPDO->db_procedure('UP_MERGE_CARGO',array(
				$data['id_cargo'],
				$data['id_tpusuario'],
				$data['ca_descripcion'],
				$data['ca_abreviatura'],
				$data['ca_estado'],
				$data['userCreacion']
			));
 			$this->easyPDO->stm->closeCursor();
 			$rsp =	($data['id_cargo'] == 0) ? "registrado" : "actualizado"; 
			Response::responsse(200, "Cargo ".$rsp." satisfactoriamente!");
		}catch(PDOException $e){
			Response::responsse(409, $e->getMessage());
		}
	}
}
?>
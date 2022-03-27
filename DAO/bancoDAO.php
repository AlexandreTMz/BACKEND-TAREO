<?php
class BancoDAO{
	private $easyPDO;

	public function __construct()
	{
		$this->easyPDO = new EasyPDO();
	}

	public function mdt_ListarBanco()
	{
		try{
			$this->easyPDO->db_procedure('UP_LISTAR_BANCO');
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
	public function mdtM_ListarBanco()
	{
		try{
			$this->easyPDO->db_procedure('UPM_LISTAR_BANCO');
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

	public function mtd_MergeBanco($data){
		try{
			$this->easyPDO->db_procedure('UP_MERGE_BANCO',array(
				$data['id_banco'],
				$data['ba_nombre'],
				$data['ba_abreviatura'],
				$data['ba_descripcion'],
				$data['ba_estado'],
				$data['userCreacion']
			));
 			$this->easyPDO->stm->closeCursor();
 			$rsp =	($data['id_banco'] == 0) ? "registrado" : "actualizado"; 
			Response::responsse(200, "Banco ".$rsp." satisfactoriamente!");
		}catch(PDOException $e){
			Response::responsse(409, $e->getMessage());
		}
	}

}
?>
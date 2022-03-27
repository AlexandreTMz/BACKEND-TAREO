<?php
class NacionalidadDAO{
	private $easyPDO;

	public function __construct()
	{
		$this->easyPDO = new EasyPDO();
	}

	public function mdt_ListarNacionalidad()
	{
		try{
			$this->easyPDO->db_procedure('UP_LISTAR_NACIONALIDAD');
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
	public function mdtM_ListarNacionalidad()
	{
		try{
			$this->easyPDO->db_procedure('MOV_UP_LISTAR_NACIONALIDAD');
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

	public function mtd_MergeNacionalidad($data){ 
		try{
			$this->easyPDO->db_procedure('UP_MERGE_NACIONALIDAD',array(
				$data['id_nacionalidad'],
				$data['na_descripcion'],
				$data['na_abreviatura'],
				$data['na_estado'],
				$data['userCreacion']
			));
 			$this->easyPDO->stm->closeCursor();
 			$rsp =	($data['id_nacionalidad'] == 0) ? "registrado" : "actualizado"; 
			Response::responsse(200, "Nacionalidad ".$rsp." satisfactoriamente!");
		}catch(PDOException $e){
			Response::responsse(409, $e->getMessage());
		}
	}

}
?>
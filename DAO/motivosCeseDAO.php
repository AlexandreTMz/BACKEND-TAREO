<?php
class MotivosCeseDAO{
	private $easyPDO;

	public function __construct()
	{
		$this->easyPDO = new EasyPDO();
	}

	public function mdt_ListarMotivosCese()
	{
		try{
			$this->easyPDO->db_procedure('UP_LISTAR_MOTIVOS_CESE');
			$data = $this->easyPDO->getData();
			$this->easyPDO->stm->closeCursor(); 
			Response::responsse(200, $data);
		}catch(PDOException $e){
			Response::responsse(409, $e->getMessage());
		}
	}
 
	public function mtd_MergeSede($data){
		try{
			$this->easyPDO->db_procedure('UP_MERGE_SEDE',array(
				$data['id_sede'],
				$data['se_descripcion'],
				$data['se_lugar'],
				$data['se_cantidad'],
				$data['se_estado']
			));
 			$this->easyPDO->stm->closeCursor();
 			$rsp =	($data['id_sede'] == 0) ? "registrado" : "actualizado"; 
			Response::responsse(200, "Sede ".$rsp." satisfactoriamente!");
		}catch(PDOException $e){
			Response::responsse(409, $e->getMessage());
		}
	}
}
?>
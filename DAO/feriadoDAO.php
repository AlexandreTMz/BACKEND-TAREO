<?php
class FeriadoDAO{
	private $easyPDO;

	public function __construct()
	{
		$this->easyPDO = new EasyPDO();
	}

	public function mdt_ListarFeriado()
	{
		try{
			$this->easyPDO->db_procedure('UP_LISTAR_FERIADO');
			$data = $this->easyPDO->getData();
			$this->easyPDO->stm->closeCursor(); 
			Response::responsse(200, $data);
		}catch(PDOException $e){
			Response::responsse(409, $e->getMessage());
		}
	}

	public function mtd_MergeFeriado($data){
		try{
			$this->easyPDO->db_procedure('UP_MERGE_FERIADO',array(
				$data['id_feriado'],
				$data['fe_dia'],
				$data['fe_descripcion'],
				$data['fe_estado'] 
			));
 			$this->easyPDO->stm->closeCursor();
 			$rsp =	($data['id_feriado'] == 0) ? "registrado" : "actualizado"; 
			Response::responsse(200, "Feriado ".$rsp." satisfactoriamente!");
		}catch(PDOException $e){
			Response::responsse(409, $e->getMessage());
		}
	}
}
?>
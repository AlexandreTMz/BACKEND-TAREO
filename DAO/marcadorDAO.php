<?php
class MarcadorDAO{
	private $easyPDO;

	public function __construct()
	{
		$this->easyPDO = new EasyPDO();
	}

	public function mdt_ListarMarcador($tipo)
	{
		try{
			$this->easyPDO->db_procedure('UP_LISTAR_MARCADOR',array(
				$tipo
			));
			$data = $this->easyPDO->getData();
			$this->easyPDO->stm->closeCursor(); 
			Response::responsse(200, $data);
		}catch(PDOException $e){
			Response::responsse(409, $e->getMessage());
		}
	}

	public function mdt_ListarMarcadorWeb()
	{
		try{
			$this->easyPDO->db_procedure('UP_LISTAR_MARCADOR_WEB_ADM');
			$data = $this->easyPDO->getData();
			$this->easyPDO->stm->closeCursor(); 
			Response::responsse(200, $data);
		}catch(PDOException $e){
			Response::responsse(409, $e->getMessage());
		}
	}

	public function mtd_MergeTipoDocumento($data){
		try{
			$this->easyPDO->db_procedure('UP_MERGE_MARCADOR',array(
				$data['id_marcador'],
				$data['ma_descripcion'],
				$data['ma_abreviatura'],
				$data['ma_estado'] 
			));
 			$this->easyPDO->stm->closeCursor();
 			$rsp =	($data['id_marcador'] == 0) ? "registrado" : "actualizado"; 
			Response::responsse(200, "Marcador ".$rsp." satisfactoriamente!");
		}catch(PDOException $e){
			Response::responsse(409, $e->getMessage());
		}
	}

	public function mdtM_ListarMarcador($tipo)
	{
		try{
			$this->easyPDO->db_procedure('MOV_UP_UP_LISTAR_MARCADOR',array(
				$tipo
			));
			$data = $this->easyPDO->getData();
			$this->easyPDO->stm->closeCursor(); 
			Response::responsse(200, $data);
		}catch(PDOException $e){
			Response::responsse(409, $e->getMessage());
		}
	}

}
?>
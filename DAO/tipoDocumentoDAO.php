<?php
class TipoDocumentoDAO{
	private $easyPDO;

	public function __construct()
	{
		$this->easyPDO = new EasyPDO();
	}

	public function mdt_ListarTipoDocumento()
	{
		try{
			$this->easyPDO->db_procedure('UP_LISTAR_TIPO_DOCUMENTO');
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
	public function mdtM_ListarTipoDocumento()
	{
		try{
			$this->easyPDO->db_procedure('MOV_UP_LISTAR_TIPO_DOCUMENTO');
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

	public function mtd_MergeTipoDocumento($data){
		try{
			$this->easyPDO->db_procedure('UP_MERGE_TIPO_DOCUMENTO',array(
				$data['id_tpdocumento'],
				$data['tpd_descripcion'],
				$data['tpd_abreviatura'],
				$data['tpd_longitud'],
				$data['tpd_estado'],
				$data['userCreacion']
			));
 			$this->easyPDO->stm->closeCursor();
 			//$rsp =	($data['id_tpdocumento'] != '') ? "registrado" : "actualizado"; 
			Response::responsse(200, "Operacion relizada!");
		}catch(PDOException $e){
			Response::responsse(409, $e->getMessage());
		}
	}

}
?>
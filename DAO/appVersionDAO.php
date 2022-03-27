<?php
class AppVersionDAO{
	private $easyPDO;

	public function __construct()
	{
		$this->easyPDO = new EasyPDO();
	}

	/*
	*	MOVIL
	*/
	public function mdtM_VersionAPP($data)
	{
		try{
			$this->easyPDO->db_procedure('UPM_COMPROBAR_VERSION',array(
				$data['version']
			));
			$data = $this->easyPDO->getData();
			$this->easyPDO->stm->closeCursor(); 
			Response::responsse(200, $data[0]);
		}catch(PDOException $e){
			Response::responsse(409, $e->getMessage());
		}
	}

	public function mdt_ListarVersion()
	{
		try{
			$this->easyPDO->db_procedure('UPM_LISTAR_VERSIONES');
			$data = $this->easyPDO->getData();
			$this->easyPDO->stm->closeCursor(); 
			Response::responsse(200, $data);
		}catch(PDOException $e){
			Response::responsse(409, $e->getMessage());
		}
	}

	public function mtd_AppVersion(){
		try{
			/*$this->easyPDO->db_procedure('UP_MERGE_BANCO',array(
				$data['id_banco'],
				$data['ba_nombre'],
				$data['ba_abreviatura'],
				$data['ba_descripcion'],
				$data['ba_estado']
			));
 			$this->easyPDO->stm->closeCursor();
 			$rsp =	($data['id_banco'] == 0) ? "registrado" : "actualizado"; */
 			$version = str_replace('.', '', $_POST['ve_version']);
 			$files = new Files();
 			$files->mtd_UploadFile($version);
			Response::responsse(200, "Banco ".$rsp." satisfactoriamente!");
		}catch(PDOException $e){
			Response::responsse(409, $e->getMessage());
		}
	}

	/*
	* END
	*/
}
?>
<?php
class TipoCuentaDAO{
	private $easyPDO;

	public function __construct()
	{
		$this->easyPDO = new EasyPDO();
	}

	public function mdt_ListarTipoCuenta()
	{
		try{
			$this->easyPDO->db_procedure('UP_LISTAR_TIPO_CUENTA');
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
	public function mdtM_ListarTipoCuenta()
	{
		try{
			$this->easyPDO->db_procedure('UPM_LISTAR_TIPO_CUENTA');
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
}
?>
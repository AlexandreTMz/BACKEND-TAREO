<?php
class SueldoDAO{
	private $easyPDO;

	public function __construct()
	{
		$this->easyPDO = new EasyPDO();
	}

	public function mtd_CambioMasivoSueldo($data){
		try{
			$this->easyPDO->db_procedure('up_cambio_masivo_sueldo',array(
				$data['id_sede'],
				$data['fecha']
			));
 			$this->easyPDO->stm->closeCursor(); 
			Response::responsse(200, "¡Cambio realizado correctamente!");
		}catch(PDOException $e){
			Response::responsse(409, $e->getMessage());
		}
	}

	/*
	*	MOVIL
	*/
	public function mdtM_ListarSueldoEmpleado($id_persona)
	{
		try{
			$this->easyPDO->db_procedure('UP_LISTAR_EMPLEADO_SUELDOS_MOBIL',array(
				$id_persona
			));
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
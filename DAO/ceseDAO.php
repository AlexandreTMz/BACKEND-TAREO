<?php
class CeseDAO{
	private $easyPDO;

	public function __construct()
	{
		$this->easyPDO = new EasyPDO();
	}

	public function mdt_ListarHistorialCese($id_persona)
	{
		try{
			$this->easyPDO->db_procedure('UP_LISTAR_HISTORY_CESE',array(
				$id_persona
			));
			$data = $this->easyPDO->getData();
			$this->easyPDO->stm->closeCursor(); 
			Response::responsse(200, $data);
		}catch(PDOException $e){
			Response::responsse(409, $e->getMessage());
		}
	}

	public function mtd_RegistrarCese($data){
		try{
			$this->easyPDO->db_procedure('UP_REGISTRAR_CESE_EMPLEADO',array(
				$data['id_persona'],
				$data['fecha_cese'],
				$data['id_motivo'],
				$data['motivoCese'], 
				$data['listaNegra'],
				$data['userCreacion']
			));
 			$this->easyPDO->stm->closeCursor(); 
			Response::responsse(200, "Cese registrado satisfactoriamente!");
		}catch(PDOException $e){
			Response::responsse(409, $e->getMessage());
		}
	}

	public function mdt_ListarEmpleadoCeseSu($datos)
	{
		try{
			$this->easyPDO->db_procedure('UP_BUSCAR_EMPLEADO_CESE_ADM',array(
				$datos['opcion'],
				$datos['nombres'],
				$datos['documento'],
				$datos['sede'],
				$datos['cargo']
			));
			$data = $this->easyPDO->getData();
			$this->easyPDO->stm->closeCursor(); 
			Response::responsse(200, $data);
		}catch(PDOException $e){
			Response::responsse(409, $e->getMessage());
		}
	}

	public function mtd_AnularCeseEmpleado($data){
		try{
			$this->easyPDO->db_procedure('UP_ANULAR_CESE_EMPLEADO',array(
				$data['id_cese'],
				$data['userCreacion']
			));
 			$this->easyPDO->stm->closeCursor(); 
			Response::responsse(200, "Cese registrado satisfactoriamente!");
		}catch(PDOException $e){
			Response::responsse(409, $e->getMessage());
		}
	}
}
?>
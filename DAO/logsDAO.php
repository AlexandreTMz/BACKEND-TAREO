<?php 
class LogsDAO{
	private $easyPDO;

	public function __construct()
	{
		$this->easyPDO = new EasyPDO();
	}

	public function fn_getReporteLogs($data)
	{
		try{
			$this->easyPDO->db_procedure('up_listar_auditoria_empleados',array(
				$data['idTablas'],
				$data['fechaInicio'],
				$data['fechaFin'],
				$data['usaurio'],
				$data['tpAuditoria'] 
			));
			$data = $this->easyPDO->getData();
			$this->easyPDO->stm->closeCursor();
			Response::responsse(200, $data);
		}catch(PDOException $e){
			Response::responsse(409, $e->getMessage());
		}
	}
}

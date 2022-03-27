<?php
class PlanillaDAO{
	private $easyPDO;

	public function __construct()
	{
		$this->easyPDO = new EasyPDO();
	}

	public function fn_getReporteData15CNA($mes, $anio, $sede, $periodo, $reproceso)
	{
		try{
			$this->easyPDO->db_procedure('up_procesar_planilla_15CNA',array(
				$mes,
				$anio,
				$sede,
				$reproceso 
			));
			$this->easyPDO->stm->closeCursor();
			Response::responsse(200, "Planilla procesada correctamente!");
		}catch(PDOException $e){
			Response::responsse(409, $e->getMessage());
		}
	}

	public function fn_getReporteData15CNA2($mes, $anio, $sede, $periodo, $reproceso)
	{
		try{
			$this->easyPDO->db_procedure('up_procesar_planilla_15CNA_2',array(
				$mes,
				$anio,
				$sede,
				$reproceso 
			));
			$this->easyPDO->stm->closeCursor();
			Response::responsse(200, "Planilla procesada correctamente!");
		}catch(PDOException $e){
			Response::responsse(409, $e->getMessage());
		}
	}

	public function mtd_ProcesarPlanilla($mes, $anio, $sede, $periodo, $reproceso){
		if($periodo == 1){
			$persona = self::fn_getReporteData15CNA($mes, $anio, $sede, $periodo, $reproceso);
		}else if($periodo == 2){
			$persona = self::fn_getReporteData15CNA2($mes, $anio, $sede, $periodo, $reproceso);
		} 
	}

	public function mdt_GetConfiguraciones()
	{
		try{
			$this->easyPDO->db_procedure('up_get_configuraciones_planilla');
			$data = $this->easyPDO->getData();
			$this->easyPDO->stm->closeCursor(); 
			Response::responsse(200, $data[0]);
		}catch(PDOException $e){
			Response::responsse(409, $e->getMessage());
		}
	}

	public function mdt_EditarConfiguraciones($data)
	{
		try{
			$this->easyPDO->db_procedure('up_editar_configuraciones_planilla',array(
				$data['modo_descanso'],
				$data['id_configuracion']
			)); 
			$this->easyPDO->stm->closeCursor(); 
			
			Response::responsse(200,"Se actualizo correctamente!");

		}catch(PDOException $e){
			Response::responsse(409, $e->getMessage());
		}
	} 

}
?>
<?php
class DocumentoEmpleadoDAO{
	private $easyPDO;

	public function __construct()
	{
		$this->easyPDO = new EasyPDO();
	}

	public function mdt_ListarDocumentoEmpleado()
	{
		try{
			$this->easyPDO->db_procedure('UP_LISTAR_DOCUMENTOS_EMPLEADOS');
			$data = $this->easyPDO->getData();
			$this->easyPDO->stm->closeCursor(); 
			Response::responsse(200, $data);
		}catch(PDOException $e){
			Response::responsse(409, $e->getMessage());
		}
	}
  
	public function mtd_MergeDocumentoEmpleado($data){
		try{
			$this->easyPDO->db_procedure('UP_MERGE_DOCUMENTO_EMPLEADO ',array(
				$data['id_emdocumento'],
				$data['de_nombre'],
				$data['de_descripcion'],
				$data['userCreacion'],
				$data['flEliminado']
			));
 			$this->easyPDO->stm->closeCursor();
 			$rsp =	($data['id_emdocumento'] == 0) ? "registrado" : "actualizado"; 
			Response::responsse(200, "Documento ".$rsp." satisfactoriamente!");
		}catch(PDOException $e){
			Response::responsse(409, $e->getMessage());
		}
	}

	public function mtd_ActualizarFechaDocumento($data){
		try{	
			$this->easyPDO->db_procedure('up_actualizar_fecha_documentos ',array(
				$data['id_docemp'],
				$data['opcion'],
				$data['fecha_emision'],
				$data['fecha_vigencia'],
				$data['userCreacion']
			));
 			$this->easyPDO->stm->closeCursor();
			Response::responsse(200, "Fecha actualizada satisfactoriamente!");
		}catch(PDOException $e){
			Response::responsse(409, $e->getMessage());
		}
	}

	public function mdt_ListarDocumentosCaducados($data)
	{
		try{
			$this->easyPDO->db_procedure('up_reporte_documentos_caducados',array(
				$data['opcion'],
				$data['nombre'],
				$data['sede'],
				$data['documento'],
				$data['opcionFecha'],
				$data['inicio'],
				$data['fin']
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
<?php
class ListaNegraDAO{
	private $easyPDO;

	public function __construct()
	{
		$this->easyPDO = new EasyPDO();
	}

	public function mdt_ListarHistorialListaNegra($id_persona)
	{
		try{
			$this->easyPDO->db_procedure('UP_LISTAR_HISTORY_LIST_BLACK',array(
				$id_persona
			));
			$data = $this->easyPDO->getData();
			$this->easyPDO->stm->closeCursor(); 
			Response::responsse(200, $data);
		}catch(PDOException $e){
			Response::responsse(409, $e->getMessage());
		}
	}

	public function mdt_ListarListaNegraPersona($data)
	{
		$dataSearch = "";
		if($data['opcion'] == 1){
			$dataSearch = $data['nombres'];
		}else if($data['opcion'] == 2){
			$dataSearch = $data['sede'];
		}else if($data['opcion'] == 3){
			$dataSearch = $data['cargo'];
		}

		try{
			$this->easyPDO->db_procedure('UP_LISTAR_LISTA_NEGRA_PERSONA',array(
				$data['opcion'],
				$dataSearch,
				$data['estado']
			));
			$resData = $this->easyPDO->getData();
			$this->easyPDO->stm->closeCursor(); 
			Response::responsse(200, $resData);
		}catch(PDOException $e){
			Response::responsse(409, $e->getMessage());
		}
	}

	public function mtd_registrarListaNegra($data)
	{
		try{
			$this->easyPDO->db_procedure('UP_REGISTRAR_LISTA_NEGRA_PERSONA',array(
				$data['id_persona'],
				$data['motivoListaNegra']
			));
			$data = $this->easyPDO->getData();
			$this->easyPDO->stm->closeCursor(); 
			Response::responsse(200, $data[0]);
		}catch(PDOException $e){
			Response::responsse(409, $e->getMessage());
		}
	}


	public function mtd_quitarDeListaNegra($data)
	{
		try{
			$this->easyPDO->db_procedure('UP_QUITAR_LISTA_NEGRA_PERSONA',array(
				$data['id_lista'],
				$data['contrasenia'],
				$data['ls_motivo'],
				$data['userCreacion']
			));
			$this->easyPDO->stm->closeCursor();
			Response::responsse(200, "Se ha retirado satisfactoriamente!");
		}catch(PDOException $e){
			Response::responsse(409, $e->getMessage());
		}
	}
 
	public function mtd_CambiarDeEstadoListaNegra($data){
		try{
			$this->easyPDO->db_procedure('UP_INHABILITAR_LISTA_NEGRA',array(
				$data['id_lista'],
				$data['opcion']
			));
 			$this->easyPDO->stm->closeCursor();
 			$rsp =	($data['opcion'] == 0) ? "Inhabilitado" : "Habilitado"; 
			Response::responsse(200, "Se ha ".$rsp." satisfactoriamente!");
		}catch(PDOException $e){
			Response::responsse(409, $e->getMessage());
		}
	}
 
}
?>
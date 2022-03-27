<?php
class PersonaDAO{
	private $easyPDO;

	public function __construct()
	{
		$this->easyPDO = new EasyPDO();
	}

	public function mdt_GetPersonaIdPer($datos)
	{
		try{
			$this->easyPDO->db_procedure('UP_GET_DATA_PERSONA_SUPLENTE',array(
				$datos
			));
			$data = $this->easyPDO->getData();
			$this->easyPDO->stm->closeCursor(); 
			Response::responsse(200, $data[0]);
		}catch(PDOException $e){
			Response::responsse(409, $e->getMessage());
		}
	}

	public function mtd_MergePersona($data){
		try{
			$this->easyPDO->db_procedure('UP_MERGE_PERSONA',array(
				$data['id_persona'],
				$data['tipo_documento'],
				$data['nacionalidad'],
				$data['nombres'],
				$data['apellido_paterno'],
				$data['apellido_materno'],
				$data['documento'],
				$data['fecha_nacimiento'],
				$data['celular'],
				$data['correo'],
				$data['nacionalidad'], 
				$data['fecha_ingreso'],
				$data['titular'],
				$data['usuario'],
				$data['sexo'],
				$data['direccion'],
				$data['estado'],
				$data['userCreacion']
			));
 			$this->easyPDO->stm->closeCursor();
 			$rsp =	($data['id_persona'] == 0) ? "registrado" : "actualizado"; 
			Response::responsse(200, "Persona ".$rsp." satisfactoriamente!");
		}catch(PDOException $e){
			Response::responsse(409, $e->getMessage());
		}
	}

	public function mdt_ListarCuentasPersona($id_persona)
	{
		try{
			$this->easyPDO->db_procedure('UP_LISTAR_BANCOS_PERSONA_TITULAR',array(
				$id_persona
			));
			$data = $this->easyPDO->getData();
			$this->easyPDO->stm->closeCursor(); 
			Response::responsse(200, $data);
		}catch(PDOException $e){
			Response::responsse(409, $e->getMessage());
		}
	}

	public function mdt_MergeCuentasPersona($data)
	{ 
		try{ 
			$this->easyPDO->db_procedure('UP_MERGE_CUENTA_TITULAR',array(
				$data['id_phbanco'],
				$data['id_persona'], 
				$data['id_banco'],
				$data['id_tpcuenta'],
				$data['phb_cuenta'],
				$data['phb_cci'],
				$data['phb_estado'],
				$data['userCreacion']
			));  
			$estado = $data['phb_estado'] == 1 ? 'habilitado' : 'deshabilitado' ;
			Response::responsse(200, "Cuenta ".$estado." satisfactoriamente!"); 
		}catch(PDOException $e){
			Response::responsse(409, $e->getMessage());
		}
	}

	public function mdt_ListarPersonasSuplentes($data)
	{ 
		try{ 
			$this->easyPDO->db_procedure('UP_BUSCAR_PERSONA_WEB_ADM',array(
				$data['opcion'],
				$data['nombres'], 
				$data['documento'] 
			));  
			$data = $this->easyPDO->getData();
			$this->easyPDO->stm->closeCursor(); 
			Response::responsse(200, $data);
		}catch(PDOException $e){
			Response::responsse(409, $e->getMessage());
		}
	}

	public function mtd_AdministradorDeshabilitarPersonaWeb($data){
		try{
			$this->easyPDO->db_procedure('UP_DESHABILITAR_PERSONA_PERSONAWEB',array(
				$data['id_persona'],
				$data['userCreacion']
			));
 			$this->easyPDO->stm->closeCursor(); 
			Response::responsse(200, "Persona deshabilitado satisfactoriamente!");
		}catch(PDOException $e){
			Response::responsse(409, $e->getMessage());
		}
	}

	public function mdt_ListarPersona()
	{
		try{
			$this->easyPDO->db_procedure('UP_LISTAR_PERSONAS');
			$data = $this->easyPDO->getData();
			$this->easyPDO->stm->closeCursor(); 
			Response::responsse(200, $data);
		}catch(PDOException $e){
			Response::responsse(409, $e->getMessage());
		}
	}

	public function mdt_BuscarPersonaDocumento($documento)
	{
		try{
			$this->easyPDO->db_procedure('UP_BUSCAR_PERSONA_DOCUMENTO',array(
				$documento
			));
			$data = $this->easyPDO->getData();
			$this->easyPDO->stm->closeCursor(); 
			Response::responsse(200, $data);
		}catch(PDOException $e){
			Response::responsse(409, $e->getMessage());
		}
	}

	public function mdt_BuscarPersonaDocumentoTareo($documento)
	{
		try{
			$this->easyPDO->db_procedure('UP_BUSCAR_PERSONA_DOCUMENTO_TAREO',array(
				$documento
			));
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
	public function mdtM_BuscarPersonaSuplenteTareoMovil($documento)
	{
		try{
			$this->easyPDO->db_procedure('MOV_UP_BUSCAR_PERSONA_SUPLENTE_DOCUMENTO_TAREO',array(
				$documento
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

	public function mdt_BuscarPersonaSuplenteWeb($documento)
	{
		try{
			$this->easyPDO->db_procedure('UP_BUSCAR_PERSONA_SUPLENTE_DOCUMENTO_TAREO_ADMN',array(
				$documento
			));
			$data = $this->easyPDO->getData();
			$this->easyPDO->stm->closeCursor(); 
			Response::responsse(200, $data);
		}catch(PDOException $e){
			Response::responsse(409, $e->getMessage());
		}
	} 
	public function mdt_BuscarPersonaSuplenteWeb2($documento)
	{
		try{
			$this->easyPDO->db_procedure('UP_BUSCAR_PERSONA_SUPLENTE_DOCUMENTO_TAREO_ADMN2',array(
				$documento
			));
			$data = $this->easyPDO->getData();
			$this->easyPDO->stm->closeCursor(); 
			Response::responsse(200, $data);
		}catch(PDOException $e){
			Response::responsse(409, $e->getMessage());
		}
	} 

	public function mdt_ListarPersonaSuplenteWeb($id_persona)
	{
		try{
			$this->easyPDO->db_procedure('UP_LISTAR_SUPLENTE_DOCUMENTO',array(
				$id_persona
			));
			$data = $this->easyPDO->getData();
			$this->easyPDO->stm->closeCursor(); 
			Response::responsse(200, $data);
		}catch(PDOException $e){
			Response::responsse(409, $e->getMessage());
		}
	}

	public function mtd_SupervisorRegistrarSuplente($data){
		try{
			$this->easyPDO->db_procedure('UP_SUPERVISOR_REGISTRAR_SUPLENTE',array(
				$data['tipo_documento'],
				$data['nacionalidad'],
				$data['nombres'],
				$data['apellido_paterno'],
				$data['apellido_materno'],
				$data['documento'],
				$data['fecha_nacimiento'],
				$data['celular'],
				$data['correo'],
				1,
				$data['fecha_ingreso'],
				$data['titular'],
				$data['usuario'],
				$data['sexo'],
				$data['direccion'],
				$data['estado'], 
				json_encode($data['pago']),
				$data['userCreacion']
			));
 			$this->easyPDO->stm->closeCursor(); 
			Response::responsse(200, "Suplente registrado satisfactoriamente!");
		}catch(PDOException $e){
			Response::responsse(409, $e->getMessage());
		}catch (Exception $e) {
		  	Response::responsse(409, $e->getMessage());
		}
	}

	public function mtdM_SupervisorRegistrarSuplente($data){
		try{
			$this->easyPDO->db_procedure('MOV_UP_SUPERVISOR_REGISTRAR_SUPLENTE',array(
				$data['tipo_documento'],
				$data['nacionalidad'],
				$data['nombres'],
				$data['apellido_paterno'],
				$data['apellido_materno'],
				$data['documento'],
				$data['fecha_nacimiento'],
				$data['celular'],
				$data['correo'],
				1,
				$data['fecha_ingreso'],
				$data['titular'],
				$data['usuario'],
				$data['sexo'],
				$data['direccion'],
				$data['estado']
			));
 			$this->easyPDO->stm->closeCursor(); 
			Response::responsse(200, "Suplente registrado satisfactoriamente!");
		}catch(PDOException $e){
			Response::responsse(409, $e->getMessage());
		}catch (Exception $e) {
		  	Response::responsse(409, $e->getMessage());
		}
	}
}
?>
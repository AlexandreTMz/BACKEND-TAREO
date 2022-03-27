<?php
class Persona implements JsonSerializable
{
	private $Id_persona;
	private $Id_Tipo_Documento ;
	private $nro_doc;
	private $ape_paterno_per;
	private $ape_materno_per;
	private $nomb_per;
	private $fecha_nac;
	private $Id_Pais;
	private $IdUbigeoInei;
	private $direccion;
	private $id_genero;
	private $Id_Financiador;
	private $Id_Etnia;
	private $telefono1;
	private $telefono2;
	private $email;
	private $latitud;
	private $longitud;

	public function __construct()
	{
	}

	public function __GET($x)
	{
		return $this->$x;
	}

	public function __SET($x, $y)
	{
		return $this->$x = $y;
	}

	public function jsonSerialize() {
        return (object) get_object_vars($this);
    }
}
?>
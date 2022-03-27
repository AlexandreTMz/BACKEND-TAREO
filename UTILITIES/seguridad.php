<?php
class Seguridad
{
	public static function redirectSwitch()
	{
		if(Session::getSession('usuario')){
			$tipo = Session::getSession('usuario');
			switch ((int)$tipo->id_tpusuario) {
				case 6:
					Redirect::redirectt(Config::getUrl()."/adm");
				break;
				default:
					Utilities::setMessage("3","Usted no tiene acceso!"); 
				break;
			}
		}else {
			Redirect::redirectt(Config::getUrl());
		}
	}

	public static function mtd_ComprobarPermiso(){
		if(Session::getSession('usuario')){
			$tipo = Session::getSession('usuario');
			if((int)$tipo->id_tpusuario != 6){
				Redirect::redirectt(Config::getUrl());
			} 
		}else {
			Redirect::redirectt(Config::getUrl());
		}
	}
}
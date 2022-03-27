<?php
class Remove_files
{ 
	public static function removeFile($document, $path){
		$DS = DIRECTORY_SEPARATOR;
		$PATH_DIRD =$DS."UPLOADS".$DS;
		$path = getcwd().$PATH_DIRD.$document.$DS."documentos".$DS.$path;
		if(file_exists($path)) {
			$delete = unlink($path);
			if(!$delete){
				Response::responsse(409, "Hubo un problema");
			}
		}else{
			Response::responsse(409, "El archivo no existe");
		}
	}

	public static function getUrlDocumento($document, $path){
		$DS = DIRECTORY_SEPARATOR;
		$PATH_DIRD =$DS."UPLOADS".$DS;
		$path = getcwd().$PATH_DIRD.$document.$DS."documentos".$DS.$path;
		return $path;
	}

	public static function generatePath($document, $file){
		$DS = DIRECTORY_SEPARATOR;
		$path = $document.$DS."documentos".$DS.$file;
		return $path;
	}

	public static function getUrlDirectory(){
		$DS = DIRECTORY_SEPARATOR;
		return getcwd().$DS."ZIP".$DS;
	}

}
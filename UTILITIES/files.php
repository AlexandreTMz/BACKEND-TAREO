<?php
class Files{
	
	public function mtd_UploadFile($version){
		$strL_Input = "inpApk";
		$strL_Dir = "INSTALL/".$version."/";
		$this->mtdUploadFile($strL_Dir);
	    // Check if file was uploaded without errors
	    if(isset($_FILES[$strL_Input]) && $_FILES[$strL_Input]["error"] == 0){
	        $allowed = array("apk" => "application/java-archive");
	        $filename = $_FILES[$strL_Input]["name"];
	        $filetype = $_FILES[$strL_Input]["type"];
	        $filesize = $_FILES[$strL_Input]["size"];
	    
	        // Verify file extension
	        $ext = pathinfo($filename, PATHINFO_EXTENSION);
	        if(!array_key_exists($ext, $allowed)) throw new Exception('Archivo no permitido.');
	    
	        // Verify file size - 5MB maximum
	        $maxsize = 5 * 1024 * 1024;
	        if($filesize > $maxsize) throw new Exception('Tamaño del aricho es excesivo.');
	    
	        // Verify MYME type of the file
	        if(in_array($filetype, $allowed)){
	            // Check whether file exists before uploading it
	            move_uploaded_file($_FILES[$strL_Input]["tmp_name"], $strL_Dir.$version.".apk"); 
	        } else{
	            throw new Exception('Error al subir el archivo.');
	        }
	    } else{ 
	        throw new Exception($_FILES[$strL_Input]["error"]);
	    }
	}

	function mtdUploadFile($path) {
	    if (is_dir($path)) return true;
	    $prev_path = substr($path, 0, strrpos($path, '/', -2) + 1 );
	    $return = createPath($prev_path);
	    return ($return && is_writable($prev_path)) ? mkdir($path) : false;
	}

}
?>
<?php 
class Response
{
	public static function responsse($code = 200, $message = null)
	{
		ob_clean();
	    // Limpriar los headers existentes
		header_remove();
	    // Enviar el codigo del status (200,404,409, etc)
		http_response_code($code);
	    // No almacenar el chache
	    //header("Cache-Control: no-transform,public,max-age=300,s-maxage=900");
	    //header("Server-Timing: miss, db;dur=53, app;dur=47.2");
	    header('Expires: Sun, 01 Jan 2014 00:00:00 GMT');
		header('Cache-Control: no-store, no-cache, must-revalidate');
		header('Cache-Control: post-check=0, pre-check=0', FALSE);
		header('Pragma: no-cache');


	    // Esto devolvera un contenido json
	    header('Content-Type: application/json');
	    // Los status que hay
	    $status = array(
	    	200 => '200 OK',
	    	400 => '400 Bad Request',
	    	422 => 'Unprocessable Entity',
	    	500 => '500 Internal Server Error',
	    	409 => '409 Conflict',
	    );
	    // Enviar el status por el header
	    header('Status: '.$status[$code]);
	    // Retornar el json echo y derecho xd
	    if($code == 200){
	    	if (is_array($message)) {
	    		echo json_encode($message);
	    		exit();
	    	}else if(is_object($message)){
	    		echo json_encode($message);
	    		exit();
	    	}else {
	    		echo json_encode(array(
	    			"msg" => $message
	    		));
	    		exit();
	    	}
	    }else{
	    	echo json_encode(array(
	    		"msg" => Response::clearMsg($message)
	    	));
	    	exit();
	    }

	}


	public static function clearMsg($message)
	{
		$message = str_replace("SQLSTATE", "",$message);
		$message = preg_replace('/[[0-9]\]*/m', '', $message);
		$message = preg_replace('/\<\<(.?)+\>\>/m', '', $message);
		$message = preg_replace('/\<\<\>\>/m', '', $message);
		$message = preg_replace('/:+/m', '', $message);
		$message =trim($message);
		return $message;
	}
}
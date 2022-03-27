<?php 
/**
 * 
 */
class Utilities2
{

	public static function setMessage($type="0", $text= "", $red = false)
	{
	    switch ($type) {
	      case '1': 
	      	$_SESSION['msg']['msg'] = $text;
	      	$_SESSION['msg']['type'] = 'alert-success'; 
	        if ($red) { 
	        	header("Refresh:2; url=http://$_SERVER[HTTP_HOST]$_SERVER[REQUEST_URI]");
	        	//if (isset($_SESSION['msg'])) unset($_SESSION['msg']);
				//exit;
	        }
	        break;
	      case '2':
	        $_SESSION['msg']['msg'] = $text;
	      	$_SESSION['msg']['type'] = 'alert-warning'; 
	        if ($red) { 
	        	header("Refresh:2; url=http://$_SERVER[HTTP_HOST]$_SERVER[REQUEST_URI]");
	        	//if (isset($_SESSION['msg'])) unset($_SESSION['msg']);
				//exit;
	        }
	        break;
	      case '3':
	        $_SESSION['msg']['msg'] = $text;
	      	$_SESSION['msg']['type'] = 'alert-danger'; 
	        if ($red) { 
	        	header("Refresh:2; url=http://$_SERVER[HTTP_HOST]$_SERVER[REQUEST_URI]");
	        	//if (isset($_SESSION['msg'])) unset($_SESSION['msg']);
				//exit;
	        }
	        break;
	    
	      default:
	        # code...
	        break;
	    }
	}

	public static function clearMsg()
	{
		unset($_SESSION['msg']);
	}


	public static function getUrl(){
	    $name = "Hospital";
	    $url = "http" . (($_SERVER['SERVER_PORT'] == 443) ? "s" : "") . "://" . $_SERVER['HTTP_HOST']."/".$name;
	    return $url;
	}

	public static function asset(){
	    echo Utilities::getUrl()."/ui/";
	}

	public static function asset2(){
	    return Utilities::getUrl()."/ui/";
	}

	public static function uploads(){
	    echo Utilities::getUrl()."/UPLOADS/";
	}

	public static function rederigir($url){
	    echo '<script type="text/javascript">setTimeout(function(){window.top.location="'.$url.'"} , 1500);</script>';
	}


	public static function rederigirv2($time = "1"){
      //echo '<script language="javascript">window.location.href ="'.$url.'"</script>';
	  if (isset($_SESSION['msg'])) unset($_SESSION['msg']);
      echo '<script type="text/javascript">setTimeout(function(){javascript:history.go(-1)}, '.$time.');</script>';
  	}

  	function mk_safe($data) {
        /* trim whitespace */
        $data = trim($data);
        $data = htmlspecialchars($data);
        return $data;
    }

    public static function redirect($url){
		header("Location: $url");
	}

	public static function redirectTo($url, $time = 1){ 
		header("refresh:$time;url=$url");
	}

    public static function set_session($name, $object)
	{
	    $_SESSION[$name] = serialize($object);
	}

	public static function get_session($name)
	{
	    if (isset($_SESSION[$name])) {
	    	$object = unserialize($_SESSION[$name]);
	    	return $object;
	    }
	    return false;
	}

    public static function redirectSwitch()
	{
		if(Utilities::get_session('usuario')){
			$tipo = Utilities::get_session('usuario');
			switch ($tipo->id_tipo_usuario) {
				case 1:
					Utilities::redirect(Utilities::getUrl()."/adm");
				break;
				case 2:
					Utilities::redirect(Utilities::getUrl()."/user/seleccionar_ambiente");
				break; 
				default:
					print_r("Usted no tiene acceso");
				break;
			}
		}else {
			Utilities::redirect(Utilities::getUrl()."/login");
		}
	}

	public static function seguridadSwitch($type)
	{
		if(Utilities::get_session('usuario')){
			$user = Utilities::get_session('usuario');
			$tipo = (int)$user->id_tipo_usuario;
			if ($tipo !== $type) {
				Utilities::redirectSwitch();
			}
		}else {
			Utilities::redirect(Utilities::getUrl()."/login");
		}
	}

	public static function seguridadAmbiente()
	{
		if(Utilities::get_session('usuario')){

			$user = Utilities::get_session('usuario');
			$tipo = (int)$user->id_tipo_usuario;
			if ($tipo !== 2) {
				Utilities::redirectSwitch();
			}

			if(Utilities::get_session('ambiente')){
				$id_ambiente = Utilities::get_session('ambiente');
				if ($id_ambiente == "" || $id_ambiente < 0) {
					Utilities::redirectSwitch();
				}
			}else {
				Utilities::redirect(Utilities::getUrl()."/login");
			}
		}else {
			Utilities::redirect(Utilities::getUrl()."/login");
		}
	}


	public static function response($code = 200, $message = null)
	{
		ob_clean();
	    // Limpriar los headers existentes
	    header_remove();
	    // Enviar el codigo del status (200,404,409, etc)
	    http_response_code($code);
	    // No almacenar el chache
	    //header("Cache-Control: no-transform,public,max-age=300,s-maxage=900");
	    //header("Server-Timing: miss, db;dur=53, app;dur=47.2");
	    header("Cache-Control: no-cache, no-store, must-revalidate"); // HTTP 1.1. 
	    header("Pragma: no-cache"); // HTTP 1.0. 
	    header("Expires: 0"); // Proxies. 

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
	    	}else if(is_object($message)){
	    		echo json_encode($message);
	    	}else {
	    		echo json_encode(array(
		    		"msg" => $message
			    ));
	    	}
	    }else{
	    	echo json_encode(array(
	    		"msg" => Utilities::clear_msg($message)
		    ));
	    }
	}


	public static function clear_msg($message)
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
?>
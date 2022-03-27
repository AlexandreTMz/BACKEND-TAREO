<?php 
class Utilities
{
	public static function setMessage($type="0", $text= "", $red = false)
	{
	    switch ($type) {
	      case '1': 
	      	$_SESSION['msg']['msg'] = $text;
	      	$_SESSION['msg']['type'] = 'alert-success'; 
	        if ($red) { 
	        	header("Refresh:2; url=http://$_SERVER[HTTP_HOST]$_SERVER[REQUEST_URI]");
	        }
	        break;
	      case '2':
	        $_SESSION['msg']['msg'] = $text;
	      	$_SESSION['msg']['type'] = 'alert-warning'; 
	        if ($red) { 
	        	header("Refresh:2; url=http://$_SERVER[HTTP_HOST]$_SERVER[REQUEST_URI]");
	        }
	        break;
	      case '3':
	        $_SESSION['msg']['msg'] = $text;
	      	$_SESSION['msg']['type'] = 'alert-danger'; 
	        if ($red) { 
	        	header("Refresh:2; url=http://$_SERVER[HTTP_HOST]$_SERVER[REQUEST_URI]");
	        }
	        break;
	    }
	}
	public static function clearMsg()
	{
		unset($_SESSION['msg']);
	}
}
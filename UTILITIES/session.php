<?php
class Session
{
	public static function setSession($name, $object)
	{
	    $_SESSION[$name] = serialize($object);
	}

	public static function getSession($name)
	{
	    if (isset($_SESSION[$name])) {
	    	$object = unserialize($_SESSION[$name]);
	    	return $object;
	    }
	    return false;
	}
}
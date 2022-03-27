<?php
class Redirect
{
	public static function redirectt($url){
		header("Location: $url");
	}

	public static function redirectTo($url, $time = 1){ 
		header("refresh:$time;url=$url");
	}
}
<?php
class DBAccess
{
  private $conn;
  
  public function __construct()
  {

    if( defined( 'PDO::MYSQL_ATTR_MAX_BUFFER_SIZE' ) ) {
      $opt = array(PDO::MYSQL_ATTR_INIT_COMMAND => 'SET NAMES utf8', PDO::MYSQL_ATTR_MAX_BUFFER_SIZE => 15*1024*1024);
    }
    else {
      $opt = array(PDO::MYSQL_ATTR_INIT_COMMAND => 'SET NAMES utf8');
    }

    try {
      /*ALEX*/
      //$this->conn = new PDO('mysql:host=localhost;dbname=db_bienes', 'root', '',$opt);
      /*TUYO*/
      $this->conn = new PDO('mysql:host=localhost:3307;dbname=db_bienes', 'root', '',$opt);
	    $this->conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    } catch (PDOException $e )
    {
      echo "Corrige el archivo DBAccess.php COMENTADO:" .$e->getMessage();
    }
 }

  public static function getUrl(){
    $name = "UGEL-BIENES";
    $url = "http" . (($_SERVER['SERVER_PORT'] == 443) ? "s" : "") . "://" . $_SERVER['HTTP_HOST']."/".$name;
    return $url;
  }

  public function get_connection()
  {
    return $this->conn;
  }

  public static function rederigir($url){
    echo '<script type="text/javascript">setTimeout(function(){window.top.location="'.$url.'"} , 1500);</script>';
  }

}
 ?>

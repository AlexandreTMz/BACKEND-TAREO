<?php
class Autoloader {
    static public function CargarClases($className) {
        $extensions = array(".php");
        $folders = array('DAO', 'BOL', 'DAL', 'UTILITIES');

        foreach ($folders as $folder) {
            foreach ($extensions as $extension) {
                $path = $folder . DIRECTORY_SEPARATOR .lcfirst($className). $extension;
                //echo $path.'<br>';
                if (is_readable($path)) {
                    require_once($path);
                }
            }
        }
    }
}
spl_autoload_register('Autoloader::CargarClases'); 
?>
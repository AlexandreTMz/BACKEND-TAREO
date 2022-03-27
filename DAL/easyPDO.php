<?php
/**
 * Pequeño script para generar consultas utilizando procedure
 *
 * @name    EasyPDO.php
 * @author  Alexandre
 */

class EasyPDO
{
    private $db_host;
    private $db_user;
    private $db_pass;
    private $db_database;
    private $pdo;
    public $stm;
    private $data;
    private $returnClass;
    private $debug;

    public function __construct()
    {
        $this->db_host = Config::BD_HOST;
        //$this->db_host = "localhost:3307";
        $this->db_user = Config::BD_USER;
        $this->db_pass = Config::BD_PASS;
        $this->db_database = Config::BD_WEB;
        $this->data = [];
        $this->returnClass = null;
        $this->debug = false;

        try {
            $this->pdo = new PDO("mysql:host=$this->db_host;dbname=$this->db_database", $this->db_user, $this->db_pass);
            $this->pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
            $this->pdo->setAttribute(PDO::ATTR_EMULATE_PREPARES, 1); 
            $this->pdo->setAttribute(PDO::MYSQL_ATTR_USE_BUFFERED_QUERY, 1);
            $this->pdo->exec("set names utf8");
            if ($this->debug) {
                echo "Conexion: Se a conectado con exito" . "<br>";
            }
        } catch (PDOException $e) {
            echo "error:" . $e->getMessage();
            die();
        }
    }

    public function pdo()
    {
        return $this->pdo;
    }

    public function close()
    {
        return $this->pdo = null;
    }

    public function db_procedure($procedure, array $params = [])
    {
        $query = sprintf("CALL %s(%s)", $procedure, $this->generateParams($params));
        $this->stm = $this->pdo->prepare($query);
        $this->setParams($params);
        $this->stm->execute();
        if (!$params) {
            //$this->stm->closeCursor();
        }
        if ($this->debug) {
                echo "Procedure name: " . $query . "<br>";
        }
    }

    private function setParams(array $params = [])
    {
        if (count($params) > 0) {
            for ($i = 1; $i <= count($params); $i++) {
                $this->bind($i, $params[$i - 1]);
            }
        }
    }

    public function bind($param, $value, $type = null)
    {
        if (is_null($type)) {
            switch (true) {
                case is_int($value):
                    $type = PDO::PARAM_INT;
                    break;
                case is_bool($value):
                    $type = PDO::PARAM_BOOL;
                    break;
                case is_null($value):
                    $type = PDO::PARAM_NULL;
                    break;
                default:
                    $type = PDO::PARAM_STR;
            }
        }
        $this->stm->bindParam($param, $value, $type);
    }

    public function generateParams(array $params)
    {
        $query = "";
        if (count($params) > 0) {
            $query = "";
            for ($i = 0; $i < count($params); $i++) {
                $i == count($params) - 1 ? ($query .= "?") : ($query .= "?,");
            }
        }
        if ($this->debug) {
            echo "Number of parameters: " . $query . "<br>";
        }
        return $query;
    }

    public function getAfectRows()
    {
        return $this->stm->rowCount() > 0 ? $this->stm->rowCount() : 0;
    }

    public function getLasId()
    {
        $this->stm = $this->pdo->query("SELECT LAST_INSERT_ID() as lastId");
        $this->stm->execute();
        $id = $this->stm->fetch();
        return count($id) > 0 ? $id['lastId'] : null;
    }

    public function prepareData()
    {
        foreach ($this->stm->fetchAll(PDO::FETCH_OBJ) as $object) {
            if (is_null($this->returnClass)) {
                $this->data[] = $object;
            } else {
                $this->data[] = $this->cast($this->returnClass, $object);
            }
        }
        $this->stm->closeCursor();
        return $this->data;
    }


    public function getData(){
       $tempdata = $this->prepareData();
       $this->data = [];
       $this->stm->closeCursor();
       return $tempdata;
    }

    public function setClass(object $clase)
    {
        $this->returnClass = get_class($clase);
        if ($this->debug) {
            var_dump($clase) . "<br>";
        }
    }

    function cast($className, stdClass &$object)
    {
        if (!class_exists($className)) {
            throw new InvalidArgumentException(sprintf('Inexistant class %s.', $className));
            die();
        }

        $new = new $className();

        foreach ($object as $property => $value) {
            $new->__SET($property, $value);
        }
        /*unset($value);
        $object = (unset) $object;*/
        return $new;
    }

    public function startRollback()
    {
        $this->stm->closeCursor();
        $this->pdo->beginTransaction();
    }

    public function endRollback()
    {
        $this->pdo->commit();
    }
}

?>
<?php
class TipoUsuarioDAO{
    private $easyPDO;

    public function __construct()
    {
        $this->easyPDO = new EasyPDO();
    }

    public function mdt_ListarTipoUsuario()
    {
        try{
            $this->easyPDO->db_procedure('UP_LISTAR_TPUSUARIO');
            $data = $this->easyPDO->getData();
            $this->easyPDO->stm->closeCursor(); 
            Response::responsse(200, $data);
        }catch(PDOException $e){
            Response::responsse(409, $e->getMessage());
        }
    }

    public function mtd_MergePerfilUsuario($data){
        try{
            $this->easyPDO->db_procedure('UP_MERGE_PERFIL_USUARIO',array(
                $data['id_tpusuario'],
                $data['tpu_descripcion'],
                $data['tpu_estado'],
                $data['tpu_abreviatura'],
                $data['userCreacion'] 
            ));
            $this->easyPDO->stm->closeCursor();
            $rsp =  ($data['id_tpusuario'] == 0) ? "registrado" : "actualizado"; 
            Response::responsse(200, "Perfil de usuario".$rsp." satisfactoriamente!");
        }catch(PDOException $e){
            Response::responsse(409, $e->getMessage());
        }
    }

    public function mdt_ListarPerfilesUsuario()
    {
        try{
            $this->easyPDO->db_procedure('up_list_profile_users');
            $data = $this->easyPDO->getData();
            $this->easyPDO->stm->closeCursor(); 
            Response::responsse(200, $data);
        }catch(PDOException $e){
            Response::responsse(409, $e->getMessage());
        }
    }

    public function mtd_RegisterPermissionProfileUser($data){
        try{
            $this->easyPDO->db_procedure('up_registrar_permisos_perfil_usuario_modulos',array(
                $data['id_tpusuario'],
                $data['id_mpermiso'],
                $data['hasPermission'],
                $data['userCreacion'] 
            ));
            $this->easyPDO->stm->closeCursor();
            Response::responsse(200, "Operacion realziada");
        }catch(PDOException $e){
            Response::responsse(409, $e->getMessage());
        }
    }
 
    public function mdt_ListarPermisoPerfilUsuario($id_usuario)
    {
        try{
            $this->easyPDO->db_procedure('up_listar_modulos_perfiles_sistema',array(
                $id_usuario
            ));
            $data = $this->easyPDO->getData();
            //$this->easyPDO->stm->closeCursor();

            $array = [];  

            foreach($data as $items){
                if(!array_key_exists($items->sm_nombre, $array)){
                    $array[$items->sm_nombre] = array(
                        "name" => $items->sm_nombre,
                        "permission" => array()
                    );
                } 

                $array[$items->sm_nombre]['permission'][] = array(
                    "id_spermiso" => $items->id_spermiso,
                    "sp_nombre" => $items->sp_nombre,
                    "id_mpermiso" => $items->id_mpermiso,
                    "hasPermissionGui" => ($items->hasPermission == 1 ? true : false),
                    "hasPermission" => ($items->hasPermission == 1 ? true : false), 
                    "hasEditing" => false
                );

            }    
            Response::responsse(200, array_values($array));
        }catch(PDOException $e){
            Response::responsse(409, $e->getMessage());
        }
    }

}
?>
<?php

const NAME_API = Config::URL_API;

$ruta->add(NAME_API, function($view) {
    echo json_encode(array(
    	'VERSION' => '1.0',
    	'NAME' => NAME_API
    ));
}, ['get','post']);

/*
* LOGIN GET-POST-PUT-DELETE
*/
$ruta->add(NAME_API.'usuario/login', function($view) {
    $inputJSON = file_get_contents('php://input');
    $data = json_decode($inputJSON, TRUE);
    $usuarioDAO = new UsuarioDAO();
    $usuarioDAO->mtd_MLoginUsuario($data);
 }, ['post']);

/*
* NACIONALIDAD GET-POST-PUT-DELETE
*/
$ruta->add(NAME_API.'nacionalidad', function($view) {
    $nacionalidadDAO = new NacionalidadDAO();
    $nacionalidadDAO->mdtM_ListarNacionalidad();
}, ['get']);


/*
* TIPO DE DOCUMENTO GET-POST-PUT-DELETE
*/
$ruta->add(NAME_API.'tipo_documento', function($view) {
    $tipoDocumentoDAO = new TipoDocumentoDAO();
    $tipoDocumentoDAO->mdtM_ListarTipoDocumento();
}, ['get']);

/*
* CARGO GET-POST-PUT-DELETE
*/
$ruta->add(NAME_API.'cargo', function($view) {
    $cargoDAO = new CargoDAO();
    $cargoDAO->mdtM_ListarCargo();
}, ['get']);


/*
* SEDE GET-POST-PUT-DELETE
*/
$ruta->add(NAME_API.'sede', function($view) {
    $sedeDAO = new SedeDAO();
    $sedeDAO->mdtM_ListarSede();
}, ['get']);


/*
* BUSCAR SUPLENTES GET-POST-PUT-DELETE
*/
$ruta->add(NAME_API.'persona/suplente/tareo/(.*)', function($params,$view) { 
    $personaDAO = new PersonaDAO();
    $personaDAO->mdtM_BuscarPersonaSuplenteTareoMovil($params[0]); 
}, ['get']);

$ruta->add(NAME_API.'persona/suplente', function($view) {
    $inputJSON = file_get_contents('php://input');
    $data = json_decode($inputJSON, TRUE);
    $personaDAO = new PersonaDAO();
    $personaDAO->mtdM_SupervisorRegistrarSuplente($data);
}, ['post']);


/*
* EMPLEADO GET-POST-PUT-DELETE
*/
$ruta->add(NAME_API.'supervisor/empleado', function($view) {
    $inputJSON = file_get_contents('php://input');
    $data = json_decode($inputJSON, TRUE);
    $empleadoDAO = new EmpleadoDAO();
    $empleadoDAO->mtdM_SupervisorRegistrarEmpleado($data);
}, ['post']);

$ruta->add(NAME_API.'empleado/sueldo/(.*)', function($params, $view) {
    $sueldoDAO = new SueldoDAO();
    $sueldoDAO->mdtM_ListarSueldoEmpleado($params[0]);
}, ['get']);

/*
* MARCADOR GET-POST-PUT-DELETE
*/
$ruta->add(NAME_API.'marcador/(.*)', function($params,$view) {
    $marcadorDAO = new MarcadorDAO();
    $marcadorDAO->mdtM_ListarMarcador($params[0]);
}, ['get']);


// BUSCAR TAREO PERSONA
$ruta->add(NAME_API.'empleado/tareo/(.*)/(.*)', function($params,$view) { 
    $tareoDAO = new TareoDAO();
    $tareoDAO->mdtM_BuscarTareoEmpleadoMovil($params[0],$params[1]);
}, ['get']);

/*
* TAREO GET-POST-PUT-DELETE
*/
$ruta->add(NAME_API.'tareo/registro', function($view) {
    $inputJSON = file_get_contents('php://input');
    $data = json_decode($inputJSON, TRUE);
    $tareoDAO = new TareoDAO();
    $tareoDAO->mdtM_RegistrarTareo($data);
}, ['post']);

$ruta->add(NAME_API.'tareo/cierre', function($view) {
    $inputJSON = file_get_contents('php://input');
    $data = json_decode($inputJSON, TRUE);
    $tareoDAO = new TareoDAO();
    $tareoDAO->mdtM_CerrarTareo($data); 
}, ['post']);

/*
* PERMISOS GET-POST-PUT-DELETE
*/
$ruta->add(NAME_API.'permiso', function($view) {
    $permisoDAO = new PermisoDAO();
    $permisoDAO->mdtM_ListarPermiso();
}, ['get']);

$ruta->add(NAME_API.'tareo/permiso', function($view) {
    $inputJSON = file_get_contents('php://input');
    $data = json_decode($inputJSON, TRUE);
    $tareoDAO = new TareoDAO();
    $tareoDAO->mdtM_RegistrarPermiso($data);
}, ['post']);

// BUSCAR A LOS EMPLEADOS / PERMISO
$ruta->add(NAME_API.'persona/empleado/(.*)/(.*)', function($params,$view) { 
    $empleadoDAO = new EmpleadoDAO();
    $empleadoDAO->mdtM_ListarEmpleadoPermisoMovil($params[0],$params[1]);
}, ['get']);

// REPORTES
$ruta->add(NAME_API.'tareo/reporte', function($view) {
    $inputJSON = file_get_contents('php://input');
    $data = json_decode($inputJSON, TRUE);
    $tareoDAO = new TareoDAO();
    $tareoDAO->mdtM_TareoReporte($data); 
}, ['post']);

$ruta->add(NAME_API.'tareo/reporte/operario', function($view) {
    $inputJSON = file_get_contents('php://input');
    $data = json_decode($inputJSON, TRUE);
    $tareoDAO = new TareoDAO();
    $tareoDAO->mdtM_TareoReporteOperario($data); 
}, ['post']);

// DESCANSO Y FALTAS
$ruta->add(NAME_API.'tareo/descanso/falta', function($view) {
    $inputJSON = file_get_contents('php://input');
    $data = json_decode($inputJSON, TRUE);
    $tareoDAO = new TareoDAO();
    $tareoDAO->mdtM_RegistrarDescansoFalta($data);
}, ['post']);

// PERSONAS 
$ruta->add(NAME_API.'persona/sedes/(.*)/(.*)', function($params,$view) { 
    $empleadoDAO = new EmpleadoDAO();
    $empleadoDAO->mdt_ListarEmpleadoSedeMobil($params[0],$params[1]); 
}, ['get']);

// CAMBIAR CONTRASEÑA
$ruta->add(NAME_API.'usuario/cambio/contrasenia', function($view) {
    $inputJSON = file_get_contents('php://input');
    $data = json_decode($inputJSON, TRUE);
    $usuarioDAO = new UsuarioDAO();
    $usuarioDAO->mtd_CambioContrasenia($data);
 }, ['post']);

/*
* VERSION DE APP GET-POST-PUT-DELETE
*/
$ruta->add(NAME_API.'app_version', function($view) {
    $inputJSON = file_get_contents('php://input');
    $data = json_decode($inputJSON, TRUE);
    $appVersionDAO = new AppVersionDAO();
    $appVersionDAO->mdtM_VersionAPP($data);
}, ['post']);

$ruta->add(NAME_API.'app_version/install', function($view) {
    $tipoUsuario = new TipoUsuarioDAO();
    $tipoUsuario->mdt_ListarTipoUsuario();
}, ['get']);

?>
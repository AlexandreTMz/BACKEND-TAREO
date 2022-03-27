<?php
date_default_timezone_set('America/Lima');
session_name('sistema_alpha');
session_start();
// incluimos las clases del core
require_once 'CORE/Template.php';
require_once 'CORE/Route.php';
require_once 'CORE/Autoloader.php';
// REPORTES XLS
require_once 'CORE/libs/Report_excel/vendor/autoload.php';

// Define a global basepath
define('BASEPATH','/'.Config::URL_WEB);

// Instanciar la clase ROUTE
$ruta = new Route();

// Definimos las rutas de la vista ['type'=>'usuario', 'path'=>'designer/ruta/dir']
$ruta->designer(
  array(
    [
      'type' => 'adm',
      'path' => 'DESIGNER/adm/'
    ],
    [
      'type' => 'errors',
      'path' => 'DESIGNER/errors/'
    ],
    [
      'type' => 'generic',
      'path' => 'DESIGNER/generic/'
    ]
  )
);
// fin de la configuracion <- xd -!>

/*                                     
*   RUTAS PARA LA API
*/
require_once('ROUTER/API-2.php');

/*                                     
*   RUTAS PARA EL USUARIO PUBLICO
*/
$ruta->add('/adm/api/dashboard/empleados', function($view) {
    $empleadoDAO = new EmpleadoDAO();
    $empleadoDAO->mdt_ContarEmpleado();
}, ['get']);

$ruta->add('/adm/api/dashboard/tareo', function($view) {
    $tareoDAO = new TareoDAO();
    $tareoDAO->mdt_ContarTareo();
}, ['get']);

$ruta->add('/adm/api/dashboard/por-aprobar', function($view) {
    $empleadoDAO = new EmpleadoDAO();
    $empleadoDAO->mdt_ContarEmpleadoSinAprobar();
}, ['get']);

$ruta->add('/adm/api/dashboard/linea-tareo', function($view) {
    $inputJSON = file_get_contents('php://input');
    $data = json_decode($inputJSON, TRUE); 
    $tareoDAO = new TareoDAO();
    $tareoDAO->mdt_LineaReporteCharTareo($data);
}, ['post']);

/*
* SEDES
*/
$ruta->add('/adm/api/sede', function($view) {
    $sedeDAO = new SedeDAO();
    $sedeDAO->mdt_ListarSede();
}, ['get']);

$ruta->add('/adm/api/sede', function($view) {
    $inputJSON = file_get_contents('php://input');
    $data = json_decode($inputJSON, TRUE);
    $sedeDAO = new SedeDAO();
    $sedeDAO->mtd_MergeSede($data);
}, ['post']);


/*
* BANCOS
*/
$ruta->add('/adm/api/banco', function($view) {
    $bancoDAO = new BancoDAO();
    $bancoDAO->mdt_ListarBanco();
}, ['get']);

$ruta->add('/adm/api/banco', function($view) {
    $inputJSON = file_get_contents('php://input');
    $data = json_decode($inputJSON, TRUE);
    $bancoDAO = new BancoDAO();
    $bancoDAO->mtd_MergeBanco($data);
}, ['post']);


/*
* TIPO DE DOCUMENTO
*/
$ruta->add('/adm/api/tipo_documento', function($view) {
    $tipoDocumentoDAO = new TipoDocumentoDAO();
    $tipoDocumentoDAO->mdt_ListarTipoDocumento();
}, ['get']);

$ruta->add('/adm/api/tipo_documento', function($view) {
    $inputJSON = file_get_contents('php://input');
    $data = json_decode($inputJSON, TRUE);
    $tipoDocumentoDAO = new TipoDocumentoDAO();
    $tipoDocumentoDAO->mtd_MergeTipoDocumento($data);
}, ['post']);


/*
* SUPLENTE
*/
$ruta->add('/adm/suplente/personas', function($view) {  
    $inputJSON = file_get_contents('php://input');
    $data = json_decode($inputJSON, TRUE);
    $personaDAO = new PersonaDAO();
    $personaDAO->mdt_ListarPersonasSuplentes($data);
}, ['post']);

$ruta->add('/adm/suplente/register/personas', function($view) {
    $inputJSON = file_get_contents('php://input');
    $data = json_decode($inputJSON, TRUE);
    $personaDAO = new PersonaDAO();
    $personaDAO->mtd_SupervisorRegistrarSuplente($data);
}, ['post']);

$ruta->add('/adm/suplente/persona', function($view) {  
    $inputJSON = file_get_contents('php://input');
    $data = json_decode($inputJSON, TRUE);
    $personaDAO = new PersonaDAO();
    $personaDAO->mtd_AdministradorDeshabilitarPersonaWeb($data);
}, ['put']);

$ruta->add('/adm/persona/datos/(.*)', function($params,$view) { 
    $personaDAO = new PersonaDAO();
    $personaDAO->mdt_GetPersonaIdPer($params[0]); 
}, ['get']);

$ruta->add('/adm/suplente/cuentas/(.*)', function($params,$view) {  
    $personaDAO = new PersonaDAO();
    $personaDAO->mdt_ListarCuentasPersona($params[0]);
}, ['get']);

$ruta->add('/adm/suplente/actualizar/cuenta', function($view) { 
    $inputJSON = file_get_contents('php://input');
    $data = json_decode($inputJSON, TRUE);
    $personaDAO = new PersonaDAO();
    $personaDAO->mdt_MergeCuentasPersona($data);
}, ['post']);

/*
* MARCADOR GET-POST-PUT-DELETE
*/
$ruta->add('/adm/api/marcador/(.*)', function($params,$view) {
    $marcadorDAO = new MarcadorDAO();
    $marcadorDAO->mdt_ListarMarcador($params[0]);
}, ['get']);

$ruta->add('/adm/api/marcador/', function($view) {
    $inputJSON = file_get_contents('php://input');
    $data = json_decode($inputJSON, TRUE);
    $marcadorDAO = new MarcadorDAO();
    $marcadorDAO->mtd_MergeTipoDocumento($data);
}, ['post']);

$ruta->add('/adm/api/marcador-web', function($view) {
    $marcadorDAO = new MarcadorDAO();
    $marcadorDAO->mdt_ListarMarcadorWeb();
}, ['get']);


/*
* NACIONALIDAD GET-POST-PUT-DELETE
*/
$ruta->add('/adm/api/nacionalidad', function($view) {
    $nacionalidadDAO = new NacionalidadDAO();
    $nacionalidadDAO->mdt_ListarNacionalidad();
}, ['get']);

$ruta->add('/adm/api/nacionalidad', function($view) {
    $inputJSON = file_get_contents('php://input');
    $data = json_decode($inputJSON, TRUE);
    $nacionalidadDAO = new NacionalidadDAO();
    $nacionalidadDAO->mtd_MergeNacionalidad($data);
}, ['post']);

/*
* CARGO GET-POST-PUT-DELETE
*/
$ruta->add('/adm/api/cargo', function($view) {
    $cargoDAO = new CargoDAO();
    $cargoDAO->mdt_ListarCargo();
}, ['get']);

$ruta->add('/adm/api/cargo', function($view) {
    $inputJSON = file_get_contents('php://input');
    $data = json_decode($inputJSON, TRUE);
    $cargoDAO = new CargoDAO();
    $cargoDAO->mtd_MergeCargo($data);
}, ['post']);

/*
* MARCADOR GET-POST-PUT-DELETE
*/
$ruta->add('/adm/api/marcador', function($view) {
    $inputJSON = file_get_contents('php://input');
    $data = json_decode($inputJSON, TRUE);
    $marcadorDAO = new MarcadorDAO();
    $marcadorDAO->mtd_MergeTipoDocumento($data);
}, ['post']);

$ruta->add('/adm/api/marcador/(.*)', function($params,$view) {
    $marcadorDAO = new MarcadorDAO();
    $marcadorDAO->mdt_ListarMarcador($params[0]);
}, ['get']);

/*
* TIPO DE CUENTA GET-POST-PUT-DELETE
*/
$ruta->add('/adm/api/tipo_cuenta', function($view) {
    $tipoCuentaDAO = new TipoCuentaDAO();
    $tipoCuentaDAO->mdtM_ListarTipoCuenta();
}, ['get']);


/*
* FERIADO GET-POST-PUT-DELETE
*/
$ruta->add('/adm/api/feriado', function($view) {
    $feriadoDAO = new FeriadoDAO();
    $feriadoDAO->mdt_ListarFeriado();
}, ['get']);

$ruta->add('/adm/api/feriado', function($view) {
    $inputJSON = file_get_contents('php://input');
    $data = json_decode($inputJSON, TRUE);
    $feriadoDAO = new FeriadoDAO();
    $feriadoDAO->mtd_MergeFeriado($data);
}, ['post']);

/*
* PERMISO GET-POST-PUT-DELETE
*/
$ruta->add('/adm/api/permiso', function($view) {
    $permisoDAO = new PermisoDAO();
    $permisoDAO->mdt_ListarPermiso();
}, ['get']);

$ruta->add('/adm/api/permiso', function($view) {
    $inputJSON = file_get_contents('php://input');
    $data = json_decode($inputJSON, TRUE);
    $permisoDAO = new PermisoDAO();
    $permisoDAO->mtd_MergePermiso($data);
}, ['post']);


/*
* EMPLEADO GET-POST-PUT-DELETE
*/
$ruta->add('/adm/persona/actualizar', function($view) { 
    $inputJSON = file_get_contents('php://input');
    $datos = json_decode($inputJSON, TRUE);
    $personaDAO = new PersonaDAO();
    $personaDAO->mtd_MergePersona($datos); 
}, ['post']);

$ruta->add('/adm/persona/empleado/datos/(.*)', function($params,$view) { 
    $empleadoDAO = new EmpleadoDAO();
    $empleadoDAO->mdt_GetPersonaIdPer($params[0]); 
}, ['get']);

$ruta->add('/adm/api/registro/empleado', function($view) {
    $inputJSON = file_get_contents('php://input');
    $data = json_decode($inputJSON, TRUE);
    $empleadoDAO = new EmpleadoDAO();
    $empleadoDAO->mtd_AdministradorRegistrarEmpleado($data);
}, ['post']);

$ruta->add('/adm/persona/suplente/tareo/(.*)', function($params,$view) { 
    $personaDAO = new PersonaDAO();
    $personaDAO->mdt_BuscarPersonaSuplenteWeb($params[0]); 
}, ['get']);

$ruta->add('/adm/api/empleado', function($view) {
    $inputJSON = file_get_contents('php://input');
    $datos = json_decode($inputJSON, TRUE);
    $empleadoDAO = new EmpleadoDAO(); 
    $empleadoDAO->mdt_ListarEmpleadoSu($datos);
}, ['post']);

$ruta->add('/adm/api/imegen/empleado', function($view) { 
    $empleadoDAO = new EmpleadoDAO();
    $empleadoDAO->mtd_uploadImageEmpleado();
}, ['post']);

$ruta->add('/adm/api/documentos/empleado', function($view) { 
    $empleadoDAO = new EmpleadoDAO();
    $empleadoDAO->mtd_uploadDocumentEmpleado();
}, ['post']);

$ruta->add('/adm/api/documentos/empleado/eliminar', function($view) { 
    $inputJSON = file_get_contents('php://input');
    $data = json_decode($inputJSON, TRUE);
    $empleadoDAO = new EmpleadoDAO();
    $empleadoDAO->mtd_eliminarDocumentosEmpleado($data);
}, ['post']);

$ruta->add('/adm/api/documentos/empleado/(.*)', function($params,$view) { 
    $empleadoDAO = new EmpleadoDAO();
    $empleadoDAO->mdt_ListarEmpleadoDocumentos($params[0]);
}, ['get']);

$ruta->add('/adm/api/empleado/sin_aprobar', function($view) {
    $inputJSON = file_get_contents('php://input');
    $data = json_decode($inputJSON, TRUE);
    $empleadoDAO = new EmpleadoDAO(); 
    $empleadoDAO->mdt_ListarEmpleadoSinAprobar($data);
}, ['post']);

$ruta->add('/adm/api/documentos/empleado', function($view) {
    $empleadoDAO = new EmpleadoDAO();
    $empleadoDAO->mtd_getDocumentosEmpleados();
}, ['get']);

$ruta->add('/adm/procesar/planilla/api', function($view) { 
    $inputJSON = file_get_contents('php://input');
    $data = json_decode($inputJSON, TRUE);  
    $planillaDAO = new PlanillaDAO();
    $planillaDAO->mtd_ProcesarPlanilla($data['mes'],$data['anio'],$data['sede'],$data['periodo'],$data['reproceso']);
}, ['post']);


$ruta->add('/adm/persona/empleado/sueldo/(.*)', function($params,$view) { 
    $empleadoDAO = new EmpleadoDAO();
    $empleadoDAO->mdt_ListarSueldoWeb($params[0]); 
}, ['get']);

$ruta->add('/adm/persona/empleado/other/sueldo', function($view) { 
    $inputJSON = file_get_contents('php://input');
    $data = json_decode($inputJSON, TRUE);
    $empleadoDAO = new EmpleadoDAO();
    if($data['id_sueldo']>0){
        $empleadoDAO->mtd_AdministradorActualizarSueldoWeb($data); 
    }else{
        $empleadoDAO->mtd_AdministradorRegistrarSueldoWeb($data); 
    } 
}, ['post']);

$ruta->add('/adm/persona/empleado/other/sueldo', function($view) { 
    $inputJSON = file_get_contents('php://input');
    $data = json_decode($inputJSON, TRUE);
    $empleadoDAO = new EmpleadoDAO();
    $empleadoDAO->mtd_AdministradorDeshabilitarSueldoWeb($data); 
}, ['put']);

$ruta->add('/adm/persona/empleado/cargo/(.*)', function($params,$view) { 
    $empleadoDAO = new EmpleadoDAO();
    $empleadoDAO->mdt_ListarCargoWeb($params[0]); 
}, ['get']);

$ruta->add('/adm/persona/empleado/cargo', function($view) { 
    $inputJSON = file_get_contents('php://input');
    $data = json_decode($inputJSON, TRUE);
    $empleadoDAO = new EmpleadoDAO();
    $empleadoDAO->mtd_AdministradorRegistrarCargoWeb($data);
}, ['post']);

$ruta->add('/adm/persona/empleado/cargo/reactivar', function($view) { 
    $inputJSON = file_get_contents('php://input');
    $data = json_decode($inputJSON, TRUE);
    $empleadoDAO = new EmpleadoDAO();
    $empleadoDAO->mtd_AdministradorRactivarCargoWeb($data);
}, ['post']);

$ruta->add('/adm/persona/empleado/cargo', function($view) { 
    $inputJSON = file_get_contents('php://input');
    $data = json_decode($inputJSON, TRUE);
    $empleadoDAO = new EmpleadoDAO();
    $empleadoDAO->mtd_AdministradorDeshabilitarCargoWeb($data);
}, ['put']);

$ruta->add('/adm/persona/empleado/sede/(.*)', function($params,$view) { 
    $empleadoDAO = new EmpleadoDAO();
    $empleadoDAO->mdt_ListarSedeWeb($params[0]); 
}, ['get']);

$ruta->add('/adm/persona/empleado/sede', function($view) { 
    $inputJSON = file_get_contents('php://input');
    $data = json_decode($inputJSON, TRUE);
    $empleadoDAO = new EmpleadoDAO();
    $empleadoDAO->mtd_AdministradorRegistrarSedeWeb($data);
}, ['post']);

$ruta->add('/adm/persona/empleado/sede', function($view) { 
    $inputJSON = file_get_contents('php://input');
    $data = json_decode($inputJSON, TRUE);
    $empleadoDAO = new EmpleadoDAO();
    $empleadoDAO->mtd_AdministradorCambioEstadoSedeWeb($data);
}, ['put']);

$ruta->add('/adm/persona/empleado/descanso/(.*)', function($params,$view) { 
    $empleadoDAO = new EmpleadoDAO();
    $empleadoDAO->mdt_ListarDescansoWeb($params[0]); 
}, ['get']);

$ruta->add('/adm/persona/empleado/descanso', function($view) { 
    $inputJSON = file_get_contents('php://input');
    $data = json_decode($inputJSON, TRUE);
    $empleadoDAO = new EmpleadoDAO();
    $empleadoDAO->mtd_AdministradorRegistrarDescansoWeb($data);
}, ['post']);

$ruta->add('/adm/persona/empleado/descanso', function($view) { 
    $inputJSON = file_get_contents('php://input');
    $data = json_decode($inputJSON, TRUE);
    $empleadoDAO = new EmpleadoDAO();
    $empleadoDAO->mtd_AdministradorDeshabilitarDescansoWeb($data);
}, ['put']);

$ruta->add('/adm/persona/empleado/active/descanso', function($view) { 
    $inputJSON = file_get_contents('php://input');
    $data = json_decode($inputJSON, TRUE);
    $empleadoDAO = new EmpleadoDAO();
    $empleadoDAO->mtd_AdministradorHabilitarDescansoWeb($data);
}, ['put']);

$ruta->add('/adm/persona/empleado/suplente/(.*)', function($params,$view) { 
    $personaDAO = new PersonaDAO();
    $personaDAO->mdt_ListarPersonaSuplenteWeb($params[0]); 
}, ['get']);

$ruta->add('/adm/persona/empleado/cuentas/(.*)', function($params,$view) { 
    $empleadoDAO = new EmpleadoDAO();
    $empleadoDAO->mdt_ListarCuentas($params[0]); 
}, ['get']);

$ruta->add('/adm/persona/empleado/cuenta/titular', function($view) { 
    $inputJSON = file_get_contents('php://input');
    $data = json_decode($inputJSON, TRUE);
    $empleadoDAO = new EmpleadoDAO();
    if($data['id_phbbanco'] == 0){
        $empleadoDAO->mtd_AdministradorRegistrarCuentaTitularWeb($data);
    }else{
        $empleadoDAO->mtd_AdministradorActualizarCuentaTitularWeb($data);
    } 
     
}, ['post']);

$ruta->add('/adm/persona/empleado/cuenta/titular', function($view) { 
    $inputJSON = file_get_contents('php://input');
    $data = json_decode($inputJSON, TRUE);
    $empleadoDAO = new EmpleadoDAO();
    $empleadoDAO->mtd_AdministradorDeshabilitarCuentaTitularWeb($data);
}, ['put']);

$ruta->add('/adm/persona/empleado/cuenta/tercero', function($view) { 
    $inputJSON = file_get_contents('php://input');
    $data = json_decode($inputJSON, TRUE);
    $empleadoDAO = new EmpleadoDAO();
    $empleadoDAO->mtd_AdministradorRegistrarCuentaTerceroWeb($data);
}, ['post']);

$ruta->add('/adm/persona/empleado/cuenta/tercero', function($view) { 
    $inputJSON = file_get_contents('php://input');
    $data = json_decode($inputJSON, TRUE);
    $empleadoDAO = new EmpleadoDAO();
    $empleadoDAO->mtd_AdministradorDeshabilitarHabilitarCuentaTerceroWeb($data);
}, ['put']);

$ruta->add('/adm/persona/empleado/documentos/reporte', function($view) { 
    $inputJSON = file_get_contents('php://input');
    $data = json_decode($inputJSON, TRUE);
    $empleadoDAO = new EmpleadoDAO();

    if($data['opcion'] == 1){
        $empleadoDAO->mtd_reporteDocumentosEmpleadoSede($data);
    }else if($data['opcion'] == 2){
        $empleadoDAO->mtd_reporteDocumentosEmpleadoNombre($data);
    }else if($data['opcion'] == 3){
        $empleadoDAO->mtd_reporteDocumentosEmpleadoTodos($data);
    } 
}, ['post']);

$ruta->add('/adm/persona/empleado/documentos/reporte/descargar', function($view) { 
    $inputJSON = file_get_contents('php://input');
    $data = json_decode($inputJSON, TRUE);
    $empleadoDAO = new EmpleadoDAO();
     
    if($data['opcion'] == 1){
        $empleadoDAO->mtd_descargarReporteDocumentosEmpleadoSede($data);
    }else if($data['opcion'] == 2){
        $empleadoDAO->mtd_descargarReporteDocumentosEmpleadoNombre($data);
    }else if($data['opcion'] == 3){
        $empleadoDAO->mtd_descargarReporteDocumentosEmpleadoTodos($data);
    }

}, ['post']);


/*
* APROBAR EMPLEADO
*/

$ruta->add('/adm/api/empleado/sueldo', function($view) {
    $inputJSON = file_get_contents('php://input');
    $data = json_decode($inputJSON, TRUE);
    $empleadoDAO = new EmpleadoDAO();
    $empleadoDAO->mtd_AdministradorRegistrarSueldoAprobar($data);
}, ['post']);


$ruta->add('/adm/api/empleado/aprobacion', function($view) {
    $inputJSON = file_get_contents('php://input');
    $data = json_decode($inputJSON, TRUE);
    $empleadoDAO = new EmpleadoDAO();
    $empleadoDAO->mtd_DesicionAprobarOeliminar($data);
}, ['post']);


/*
* PLANILLA GET-POST-PUT-DELETE
*/
$ruta->add('/adm/reportes/planilla/validar', function($view) { 
    $reporteDAO = new ReporteDAO(); 
    if($_POST['periodo'] == 1){
        $persona = $reporteDAO->fn_getReporteData15CNA($_POST['mes'], $_POST['anio'], $_POST['sede']);
    }else if($_POST['periodo'] == 2){
        $persona = $reporteDAO->fn_getReporteData15CNA2($_POST['mes'], $_POST['anio'], $_POST['sede']);
    }
    if(count($persona)>0){
        Response::responsse(200, "Se genero el reporte de la planilla correctamente");
    }else{
        Response::responsse(409, "No se encontraron datos que mostrar!");
    }

}, ['post']);


/*
* LISTA NEGRA GET-POST-PUT-DELETE
*/
$ruta->add('/adm/list/lista-negra', function($view) { 
    $inputJSON = file_get_contents('php://input');
    $data = json_decode($inputJSON, TRUE);
    $listaNegraDAO = new ListaNegraDAO();
    $listaNegraDAO->mdt_ListarListaNegraPersona($data);
}, ['post']);

$ruta->add('/adm/lista-negra', function($view) { 
    $inputJSON = file_get_contents('php://input');
    $data = json_decode($inputJSON, TRUE);
    $listaNegraDAO = new ListaNegraDAO();
    $listaNegraDAO->mtd_registrarListaNegra($data);
}, ['post']);

$ruta->add('/adm/quitar/lista-negra', function($view) { 
    $inputJSON = file_get_contents('php://input');
    $data = json_decode($inputJSON, TRUE);
    $listaNegraDAO = new ListaNegraDAO();
    $listaNegraDAO->mtd_quitarDeListaNegra($data);
}, ['post']);

$ruta->add('/adm/lista-negra/cambio-estado', function($view) { 
    $inputJSON = file_get_contents('php://input');
    $data = json_decode($inputJSON, TRUE);
    $listaNegraDAO = new ListaNegraDAO();
    $listaNegraDAO->mtd_CambiarDeEstadoListaNegra($data);
}, ['post']);

$ruta->add('/adm/api/empleado/lista-negra/historial/(.*)', function($params,$view) { 
    $listaNegraDAO = new ListaNegraDAO(); 
    $listaNegraDAO->mdt_ListarHistorialListaNegra($params[0]);
}, ['get']);

/*
* TAREO
*/

$ruta->add('/adm/administrador/tareo', function($view) {  
    $tareoDAO = new TareoDAO();
    $tareoDAO->mtd_GenerarReporteTareoWeb();
}, ['post']);
 
$ruta->add('/adm/administrador/permisos', function($view) {  
    $inputJSON = file_get_contents('php://input');
    $data = json_decode($inputJSON, TRUE);
    $tareoDAO = new TareoDAO();
    $tareoDAO->mtd_GenerarReportePermisoWeb($data);
}, ['post']);

$ruta->add('/adm/tareo/estado', function($view) {
    $inputJSON = file_get_contents('php://input');
    $data = json_decode($inputJSON, TRUE); 
    $tareoDAO = new TareoDAO();
    $tareoDAO->mdt_ModificarEstadoTareo($data);
}, ['POST']);

$ruta->add('/adm/tareo/eliminar', function($view) {
    $inputJSON = file_get_contents('php://input');
    $data = json_decode($inputJSON, TRUE); 
    $tareoDAO = new TareoDAO();
    $tareoDAO->mdt_EliminarTareo($data);
}, ['POST']); 

/*
* DOCUMENTOS EMPLEADO
*/

$ruta->add('/adm/documentos-empleado', function($view) { 
    $inputJSON = file_get_contents('php://input');
    $data = json_decode($inputJSON, TRUE); 
    $documentoEmpleadoDAO = new DocumentoEmpleadoDAO();
    $documentoEmpleadoDAO->mtd_MergeDocumentoEmpleado($data);
}, ['post']);

$ruta->add('/adm/documentos-empleado/fechas', function($view) { 
    $inputJSON = file_get_contents('php://input');
    $data = json_decode($inputJSON, TRUE); 
    $documentoEmpleadoDAO = new DocumentoEmpleadoDAO();
    $documentoEmpleadoDAO->mtd_ActualizarFechaDocumento($data);
}, ['post']);
 
$ruta->add('/adm/documentos-empleado', function($view) {  
    $documentoEmpleadoDAO = new DocumentoEmpleadoDAO();
    $documentoEmpleadoDAO->mdt_ListarDocumentoEmpleado();
}, ['get']);


$ruta->add('/adm/documentos-empleado/reporte/caducado', function($view) { 
    $inputJSON = file_get_contents('php://input');
    $data = json_decode($inputJSON, TRUE); 
    $documentoEmpleadoDAO = new DocumentoEmpleadoDAO();
    $documentoEmpleadoDAO->mdt_ListarDocumentosCaducados($data);
}, ['post']);

/*
* USUARIO GET-POST-PUT-DELETE
*/
$ruta->add('/adm/api/login/wusuario', function($view) {
    $inputJSON = file_get_contents('php://input');
    $datos = json_decode($inputJSON, TRUE);
    $usuarioDAO = new UsuarioDAO(); 
    $usuarioDAO->mtd_WLoginUsuarioApi($datos);
}, ['post']);
 
$ruta->add('/adm/usuario/cambiar-contrasenia', function($view) { 
    $inputJSON = file_get_contents('php://input');
    $datos = json_decode($inputJSON, TRUE);
    $usuarioDAO = new UsuarioDAO(); 
    $usuarioDAO->mtd_CambiarContraseniaUsuario($datos);
}, ['post']);



/**
 * SUELDO MASIVO
 * */

$ruta->add('/adm/api/sueldo/cambio/masivo', function($view) {
    $inputJSON = file_get_contents('php://input');
    $data = json_decode($inputJSON, TRUE); 
    $sueldoDAO = new SueldoDAO();
    $sueldoDAO->mtd_CambioMasivoSueldo($data);
}, ['post']);


/**
 * CESE
 * */

$ruta->add('/adm/api/cese', function($view) {
    $inputJSON = file_get_contents('php://input');
    $data = json_decode($inputJSON, TRUE); 
    $ceseDAO = new CeseDAO();
    $ceseDAO->mtd_RegistrarCese($data);
}, ['post']);

$ruta->add('/adm/api/empleado/cese', function($view) {
    $inputJSON = file_get_contents('php://input');
    $datos = json_decode($inputJSON, TRUE);
    $ceseDAO = new CeseDAO(); 
    $ceseDAO->mdt_ListarEmpleadoCeseSu($datos);
}, ['post']);

$ruta->add('/adm/api/empleado/cese/anular', function($view) {
    $inputJSON = file_get_contents('php://input');
    $datos = json_decode($inputJSON, TRUE);
    $ceseDAO = new CeseDAO(); 
    $ceseDAO->mtd_AnularCeseEmpleado($datos);
}, ['post']);

$ruta->add('/adm/api/empleado/cese/historial/(.*)', function($params,$view) { 
    $ceseDAO = new CeseDAO(); 
    $ceseDAO->mdt_ListarHistorialCese($params[0]);
}, ['get']);

/*
* Motivos cese
*/

$ruta->add('/adm/api/motivos-cese', function($view) {
    $motivosCeseDAO = new MotivosCeseDAO();
    $motivosCeseDAO->mdt_ListarMotivosCese();
}, ['get']);

/*
* Tipo de usuario
*/

$ruta->add('/adm/api/tipo-usuario', function($view) {
    $tipoUsuarioDAO = new TipoUsuarioDAO();
    $tipoUsuarioDAO->mdt_ListarTipoUsuario();
}, ['get']);

/*
* Permiso usuario
*/
$ruta->add('/adm/api/permisos/usuario/(.*)', function($params,$view) {
    $permisoUsuarioDAO = new PermisoUsuarioDAO();
    $permisoUsuarioDAO->mdt_ListarPermisoUsuario($params[0]);
    //Response::responsse(200, $params[0]);
}, ['get']);

$ruta->add('/adm/api/permisos/usuario', function($view) {
    $inputJSON = file_get_contents('php://input');
    $datos = json_decode($inputJSON, TRUE);
    $permisoUsuarioDAO = new PermisoUsuarioDAO();
    $permisoUsuarioDAO->mtd_RegisterPermissionUser($datos);
}, ['post']);


/*
* Perfiles usuario
*/
$ruta->add('/adm/api/perfiles', function($view) {
    $tipoUsuarioDAO = new TipoUsuarioDAO();
    $tipoUsuarioDAO->mdt_ListarPerfilesUsuario();
    //Response::responsse(200, $params[0]);
}, ['get']);

$ruta->add('/adm/api/perfiles', function($view) {
    $inputJSON = file_get_contents('php://input');
    $datos = json_decode($inputJSON, TRUE);
    $tipoUsuarioDAO = new TipoUsuarioDAO();
    $tipoUsuarioDAO->mtd_MergePerfilUsuario($datos);
    //Response::responsse(200, $params[0]);
}, ['post']);

$ruta->add('/adm/api/permisos/perfiles/usuario/(.*)', function($params,$view) {
    $tipoUsuarioDAO = new TipoUsuarioDAO();
    $tipoUsuarioDAO->mdt_ListarPermisoPerfilUsuario($params[0]);
    //Response::responsse(200, $params[0]);
}, ['get']);

$ruta->add('/adm/api/permisos/perfiles/usuario', function($view) {
    $inputJSON = file_get_contents('php://input');
    $datos = json_decode($inputJSON, TRUE);
    $tipoUsuarioDAO = new TipoUsuarioDAO();
    $tipoUsuarioDAO->mtd_RegisterPermissionProfileUser($datos);
}, ['post']);


/*
* Usuarios
*/

$ruta->add('/adm/usuarios/sistema', function($view) {
    $usuarioDAO = new UsuarioDAO();
    $usuarioDAO->mdt_ListarUsuario_sistema();
}, ['get']);

$ruta->add('/adm/usuarios/sistema', function($view) {
    $inputJSON = file_get_contents('php://input');
    $data = json_decode($inputJSON, TRUE);
    $usuarioDAO = new UsuarioDAO();
    $usuarioDAO->mtd_ActualziarUsuario($data);
 }, ['post']);

/*
* ASISTENCIA
*/
$ruta->add('/adm/empleado/asistencia', function($view) {
    $inputJSON = file_get_contents('php://input');
    $data = json_decode($inputJSON, TRUE);
    $reporteDAO = new ReporteDAO();
    $reporteDAO->fn_getReporteAsistencia($data);
 }, ['post']);

/*
* LOGS
*/
$ruta->add('/adm/db/logs', function($view) {
    $inputJSON = file_get_contents('php://input');
    $data = json_decode($inputJSON, TRUE);
    $logsDAO = new LogsDAO();
    $logsDAO->fn_getReporteLogs($data);
 }, ['post']);

/*
* Tablas
*/

$ruta->add('/adm/api/tablas-db', function($view) {
    $tablaDAO = new TablaDAO();
    $tablaDAO->mdt_ListarTablasDba();
}, ['get']);


/*
* DOCUMENTOS DOWLOAD
*/

// Add a 404 not found route
$ruta->pathNotFound(function($path, $view) {
    Response::responsse(409, "No hay datos que mostrar 404");
});

// Add a 405 method not allowed route
$ruta->methodNotAllowed(function($path, $method, $view) {
    Response::responsse(409, "No hay datos que mostrar 405");
});



// Run the Router with the given Basepath
$ruta->run(BASEPATH);

//https://stardeos.com/api/v2/videos/?filter=TRENDING&page=1&userId=
//https://stardeos.com/api/v2/videos/?filter=LATEST
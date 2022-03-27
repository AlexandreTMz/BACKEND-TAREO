<?php
use PhpOffice\PhpSpreadsheet\Spreadsheet;
use PhpOffice\PhpSpreadsheet\Writer\Xlsx;
use PhpOffice\PhpSpreadsheet\Style\Border;
use PhpOffice\PhpSpreadsheet\Style\Color;

class ReporteDAO{
	private $easyPDO;

	public function __construct()
	{
		$this->easyPDO = new EasyPDO();
	}

	public function fn_getReporteAsistencia($data)
	{
		try{
			$this->easyPDO->db_procedure('up_listar_asistencia_empleado',array(
				$data['opcion'],
				$data['nombre'],
				$data['sede'],
				$data['documento'],
				$data['inicio'],
				$data['fin'],
				$data['turno'],
				$data['opcionTareo']
			));
			$data = $this->easyPDO->getData();
			$this->easyPDO->stm->closeCursor();
			Response::responsse(200, $data);
		}catch(PDOException $e){
			Response::responsse(409, $e->getMessage());
		}
	}

	public function fn_getReporteData15CNA($mes, $anio, $sede)
	{
		try{
			$this->easyPDO->db_procedure('up_reporte_planilla_15CNA',array(
				$mes,
				$anio,
				$sede 
			));
			$data = $this->easyPDO->getData();
			$this->easyPDO->stm->closeCursor();
			return $data;
		}catch(PDOException $e){
			Response::responsse(409, $e->getMessage());
		}
	}

	public function fn_getReporteData15CNA2($mes, $anio, $sede)
	{
		try{
			$this->easyPDO->db_procedure('up_reporte_planilla_15CNA_2',array(
				$mes,
				$anio,
				$sede 
			));
			$data = $this->easyPDO->getData();
			$this->easyPDO->stm->closeCursor();
			return $data;
		}catch(PDOException $e){
			Response::responsse(409, $e->getMessage());
		}
	}

	public function fn_getReporteData30AL($mes, $anio, $sede)
	{
		try{
			$this->easyPDO->db_procedure('up_generar_planilla_30ALv2',array(
				$mes,
				$anio,
				$sede 
			));
			$data = $this->easyPDO->getData();
			$this->easyPDO->stm->closeCursor();
			return $data;
		}catch(PDOException $e){
			Response::responsse(409, $e->getMessage());
		}
	}

	public function fn_getPersonaXiD($id_persona)
	{
		try{
			$this->easyPDO->db_procedure('UP_BUSCAR_PERSONA_ID',array(
				$id_persona
			));
			$data = $this->easyPDO->getData();
			$this->easyPDO->stm->closeCursor();
			return $data;
		}catch(PDOException $e){
			Response::responsse(409, $e->getMessage());
		}
	}

	public function fn_getDiasXiD($id_persona,$inicio,$fin)
	{
		try{
			$this->easyPDO->db_procedure('UP_BUSCAR_DIAS_TAREADO',array(
				$id_persona,
				$inicio,
				$fin
			));
			$data = $this->easyPDO->getData();
			$this->easyPDO->stm->closeCursor();
			return $data;
		}catch(PDOException $e){
			Response::responsse(409, $e->getMessage());
		}
	}

	public function fn_getDiaXiDPrs($id_persona,$fecha)
	{
		try{
			$this->easyPDO->db_procedure('UP_GET_DIA_ABREVIATURA_TAREADO',array(
				$id_persona,
				$fecha 
			));
			$data = $this->easyPDO->getData();
			$this->easyPDO->stm->closeCursor();
			return count($data) > 0 ? $data[0] : "";
		}catch(PDOException $e){
			Response::responsse(409, $e->getMessage());
		}
	}

	public function fn_getVigenciaIF($id_sueldo)
	{
		try{
			$this->easyPDO->db_procedure('UP_LISTAR_VIGENCIA_SUELDO',array(
				$id_sueldo 
			));
			$data = $this->easyPDO->getData();
			$this->easyPDO->stm->closeCursor();
			return count($data) > 0 ? $data : [];
		}catch(PDOException $e){
			Response::responsse(409, $e->getMessage());
		}
	}

	public function fn_getDiaCountAbreviatura($ca_planilla,$fecha)
	{
		try{
			$this->easyPDO->db_procedure('UP_CONTAR_DATA_ABREVIATURA',array(
				$ca_planilla,
				$fecha 
			));
			$data = $this->easyPDO->getData();
			$this->easyPDO->stm->closeCursor();
			return count($data) > 0 ? $data[0] : "";
		}catch(PDOException $e){
			Response::responsse(409, $e->getMessage());
		}
	}

	public function fn_getCuentaBankoPrincipalXiD($id_persona)
	{
		try{
			$this->easyPDO->db_procedure('UP_LISTAR_BANCOS_TITULAR_PLANILLA',array(
				$id_persona
			));
			$data = $this->easyPDO->getData();
			$this->easyPDO->stm->closeCursor();
			return $data;
		}catch(PDOException $e){
			Response::responsse(409, $e->getMessage());
		}
	}

	public function fn_getCuentaBankoSuplenteXiD($id_persona)
	{
		try{
			$this->easyPDO->db_procedure('UP_LISTAR_BANCOS_SUPLENTE_PLANILLA',array(
				$id_persona
			));
			$data = $this->easyPDO->getData();
			$this->easyPDO->stm->closeCursor();
			return $data;
		}catch(PDOException $e){
			Response::responsse(409, $e->getMessage());
		}
	}

	public function fn_getNameDaySpanish($day){
		switch($day){
			case "Monday":
				return "Lunes";
			break;
			case "Tuesday":
				return "Martes";
			break;
			case "Wednesday":
				return "Miercoles";
			break;
			case "Thursday":
				return "Jueves";
			break;
			case "Friday":
				return "Viernes";
			break;
			case "Saturday":
				return "Sabado";
			break;
			case "Sunday":
				return "Domingo";
			break;
		}
		return "NO DEFINIDO";
	}

	public function mtd_crearReporte($mes, $anio, $sede, $periodo){
		setlocale(LC_TIME, 'es_ES.UTF-8');
		$ca_planilla = "";

		if($periodo == 1){
			$persona = self::fn_getReporteData15CNA($mes, $anio, $sede);
			$ca_planilla = $persona[0]->cap_codigo; 
		}else if($periodo == 2){
			$persona = self::fn_getReporteData15CNA2($mes, $anio, $sede);
			$ca_planilla = $persona[0]->cap_codigo;
		}else{
			$persona = self::fn_getReporteData30AL($mes, $anio, $sede);
			$ca_planilla = $persona[0]->cap_codigo;
		}
		
		$list = array();

		/*echo "<pre>";
		var_dump($persona);
		echo "</pre>";
		die();*/

		// SEPARARLOS POR ID
		foreach($persona as $data){
			if(isset($list[$data->id_persona])){
				$list[$data->id_persona."-".$data->id_sueldo][] =$data;
			}else{
				$list[$data->id_persona."-".$data->id_sueldo][] =$data;
			} 
		}

		/*echo "<pre>";
		var_dump($list);
		echo "</pre>";
		die();*/

		// estilo del borde
		$styleArray = [
		    'borders' => [
		        'outline' => [
		            'borderStyle' => \PhpOffice\PhpSpreadsheet\Style\Border::BORDER_THIN,
		            'color' => ['argb' => '00000000'],
		            'size' => 1
		        ],
		    ],
		];

		/*echo "<pre>";
		var_dump($list);
		echo "</pre>";
		die();*/
		// CALCULARLOS
		$calculoTotalXPersona = array();
		foreach($list as $data => $subarray){ 
			if(!isset($calculoTotalXPersona[$data])){
				$calculoTotalXPersona[$data][0] = array_sum(array_column($subarray,"TOTAL_CF"));
				//$calculoTotalXPersona[$data][1] = self::fn_getPersonaXiD($data)[0]; 
				$calculoTotalXPersona[$data][3] = array_sum(array_column($subarray,"t_manana_v"));
				$calculoTotalXPersona[$data][4] = array_sum(array_column($subarray,"t_tarde_v"));
				$calculoTotalXPersona[$data][5] = array_sum(array_column($subarray,"t_noche_v"));
				$calculoTotalXPersona[$data][6] = array_sum(array_column($subarray,"descanso")); 
				$calculoTotalXPersona[$data][7] = 0; //array_sum(array_column($subarray,"faltas"));
				$calculoTotalXPersona[$data][8] = array_sum(array_column($subarray,"total_pago_maniana"));
				$calculoTotalXPersona[$data][9] = array_sum(array_column($subarray,"total_pago_tarde"));
				$calculoTotalXPersona[$data][10] = array_sum(array_column($subarray,"total_pago_noche")); 
				$calculoTotalXPersona[$data][11] = array_sum(array_column($subarray,"feriado"));
				$calculoTotalXPersona[$data][12] = array_sum(array_column($subarray,"descanso_pago"));
				$calculoTotalXPersona[$data][13] = array_sum(array_column($subarray,"total_pago_descanso"));
				$calculoTotalXPersona[$data][14] = array_sum(array_column($subarray,"pago_feriado"));

				// NUEVOS CAMPOS
				$calculoTotalXPersona[$data][15] = array_unique(array_column($subarray,"nombres"))[0];
				$calculoTotalXPersona[$data][16] = array_unique(array_column($subarray,"tPdocumento"))[0];
				$calculoTotalXPersona[$data][17] = array_unique(array_column($subarray,"nacionalidad"))[0];
				$calculoTotalXPersona[$data][18] = array_unique(array_column($subarray,"cargo"))[0];
				$calculoTotalXPersona[$data][19] = array_unique(array_column($subarray,"ingreso"))[0];
				$calculoTotalXPersona[$data][20] = array_unique(array_column($subarray,"remuneracion_bruta"))[0];
				$calculoTotalXPersona[$data][21] = array_unique(array_column($subarray,"banco"))[0];
				$calculoTotalXPersona[$data][22] = array_unique(array_column($subarray,"cuenta"))[0];
				$calculoTotalXPersona[$data][23] = array_unique(array_column($subarray,"tpCuenta"))[0];
				$calculoTotalXPersona[$data][24] = array_unique(array_column($subarray,"cci"))[0];
				$calculoTotalXPersona[$data][25] = array_unique(array_column($subarray,"suplente"))[0];
				$calculoTotalXPersona[$data][26] = array_unique(array_column($subarray,"documento"))[0];
				$calculoTotalXPersona[$data][27] = array_unique(array_column($subarray,"id_persona"))[0]; 
				$calculoTotalXPersona[$data][28] = array_sum(array_column($subarray,"faltas")); 
				$calculoTotalXPersona[$data][29] = array_sum(array_column($subarray,"total_pago_descanso_sin_turno"));
				$calculoTotalXPersona[$data][30] = array_unique(array_column($subarray,"estado_persona"))[0]; 
				$calculoTotalXPersona[$data][31] = array_unique(array_column($subarray,"fechaSece"))[0]; 
				$calculoTotalXPersona[$data][32] = array_sum(array_column($subarray,"permiso_pago")); 
				$calculoTotalXPersona[$data][33] = array_sum(array_column($subarray,"total_permiso_pago"));   
				$calculoTotalXPersona[$data][33] = array_sum(array_column($subarray,"total_permiso_pago"));
				$calculoTotalXPersona[$data][34] = array_unique(array_column($subarray,"id_sueldo"))[0];   
 
			}else{
				$calculoTotalXPersona[$data][0] = array_sum(array_column($subarray,"TOTAL_CF"));
				//$calculoTotalXPersona[$data][1] = self::fn_getPersonaXiD($data)[0];
				$calculoTotalXPersona[$data][3] = array_sum(array_column($subarray,"t_manana_v"));
				$calculoTotalXPersona[$data][4] = array_sum(array_column($subarray,"t_tarde_v"));
				$calculoTotalXPersona[$data][5] = array_sum(array_column($subarray,"t_noche_v"));
				$calculoTotalXPersona[$data][6] = array_sum(array_column($subarray,"descanso"));
				$calculoTotalXPersona[$data][7] = 0; //array_sum(array_column($subarray,"faltas"));
				$calculoTotalXPersona[$data][8] = array_sum(array_column($subarray,"total_pago_maniana"));
				$calculoTotalXPersona[$data][9] = array_sum(array_column($subarray,"total_pago_tarde"));
				$calculoTotalXPersona[$data][10] = array_sum(array_column($subarray,"total_pago_noche"));
				$calculoTotalXPersona[$data][11] = array_sum(array_column($subarray,"feriado"));
				$calculoTotalXPersona[$data][12] = array_sum(array_column($subarray,"descanso_pago"));
				$calculoTotalXPersona[$data][13] = array_sum(array_column($subarray,"total_pago_descanso"));
				$calculoTotalXPersona[$data][14] = array_sum(array_column($subarray,"pago_feriado"));

				// NUEVOS CAMPOS
				$calculoTotalXPersona[$data][15] = array_unique(array_column($subarray,"nombres"))[0];
				$calculoTotalXPersona[$data][16] = array_unique(array_column($subarray,"tPdocumento"))[0];
				$calculoTotalXPersona[$data][17] = array_unique(array_column($subarray,"nacionalidad"))[0];
				$calculoTotalXPersona[$data][18] = array_unique(array_column($subarray,"cargo"))[0];
				$calculoTotalXPersona[$data][19] = array_unique(array_column($subarray,"ingreso"))[0];
				$calculoTotalXPersona[$data][20] = array_unique(array_column($subarray,"remuneracion_bruta"))[0];
				$calculoTotalXPersona[$data][21] = array_unique(array_column($subarray,"banco"))[0];
				$calculoTotalXPersona[$data][22] = array_unique(array_column($subarray,"cuenta"))[0];
				$calculoTotalXPersona[$data][23] = array_unique(array_column($subarray,"tpCuenta"))[0];
				$calculoTotalXPersona[$data][24] = array_unique(array_column($subarray,"cci"))[0];
				$calculoTotalXPersona[$data][25] = array_unique(array_column($subarray,"suplente"))[0];
				$calculoTotalXPersona[$data][26] = array_unique(array_column($subarray,"documento"))[0];
				$calculoTotalXPersona[$data][27] = array_unique(array_column($subarray,"id_persona"))[0];
				$calculoTotalXPersona[$data][28] = array_sum(array_column($subarray,"faltas"));
				$calculoTotalXPersona[$data][29] = array_sum(array_column($subarray,"total_pago_descanso_sin_turno"));
				$calculoTotalXPersona[$data][30] = array_unique(array_column($subarray,"estado_persona"))[0]; 
				$calculoTotalXPersona[$data][31] = array_unique(array_column($subarray,"fechaSece"))[0]; 
				$calculoTotalXPersona[$data][32] = array_sum(array_column($subarray,"permiso_pago"));
				$calculoTotalXPersona[$data][33] = array_sum(array_column($subarray,"total_permiso_pago"));
				$calculoTotalXPersona[$data][34] = array_unique(array_column($subarray,"id_sueldo"))[0];   
			} 
		}  

		/*cho "<pre>";
		var_dump($calculoTotalXPersona);
		echo "</pre>";
		die();*/


		$spread = new Spreadsheet();
		$spread
		->getProperties()
		->setCreator("Alexandre Vergara")
		->setLastModifiedBy('iForce')
		->setTitle('Excel creado con PhpSpreadSheet')
		->setSubject('Planilla')
		->setDescription('Planilla')
		->setKeywords('PHPSpreadsheet')
		->setCategory('Categoría Planilla');

		$sheet = $spread->getActiveSheet();

		// MES GLOBAL
		$date = $anio.'-'.$mes.'-01';
		$end  = $anio.'-'.$mes.'-'.date('t',strtotime($date));

		if($periodo == 1){
			$date = $anio.'-'.$mes.'-01';
 			$end  = $anio.'-'.$mes.'-15';
		}else if($periodo == 2){
			$date = $anio.'-'.$mes.'-16';
 			$end  = $anio.'-'.$mes.'-'.date('t',strtotime($date));
		}else{
 			$end  = $anio.'-'.$mes.'-'.date('t',strtotime($date));
		}

		/*echo "<pre>";
		var_dump($end);
		echo "</pre>";
		die();*/

		$fechaTareo =  date('F', strtotime($date));
		$fechaTareo2 =  date('d', strtotime($date));
		$fechaTareo = "PLANILLA ".$fechaTareo2." AL ".date('d',strtotime($end))." DE ".$fechaTareo." ".$anio;
		$sheet->setCellValue("B3", $fechaTareo); 
		$sheet->getStyle("B3")->getFont()->setSize(16);

		$colum = 15;
		$row = 3; 

		while(strtotime($date) <= strtotime($end)) {
	        $day_num = date('d', strtotime($date));
	        $day_name = date('l', strtotime($date));

	        $sheet->setCellValueByColumnAndRow($colum, $row, self::fn_getNameDaySpanish($day_name)); 
	        $sheet->getCellByColumnAndRow($colum, $row)->getStyle()->getAlignment()->setTextRotation(90);

	        $date = date("Y-m-d", strtotime("+1 day", strtotime($date)));
	        $colum++;
	    }


	    $date2 = $anio.'-'.$mes.'-01';
		$end2  = $anio.'-'.$mes.'-'.date('t',strtotime($date2));

		if($periodo == 1){
 			$end2  = $anio.'-'.$mes.'-15';
		}else if($periodo == 2){
			$date2 = $anio.'-'.$mes.'-16';
 			$end2  = $anio.'-'.$mes.'-'.date('t',strtotime($date2));
		}else{
 			$end2  = $anio.'-'.$mes.'-'.date('t',strtotime($date2));
		}

	    $colum2 = 15;
		$row2 = 4;
	    while(strtotime($date2) <= strtotime($end2)) {
	        $day_num = date('d', strtotime($date2));
	        $day_name = date('l', strtotime($date2));
	        $sheet->setCellValueByColumnAndRow($colum2, $row2, "$day_num");
	        $date2 = date("Y-m-d", strtotime("+1 day", strtotime($date2)));
	        $colum2++;
	    } 

		$ia = 5; 
		$colum = 15;
		$row = 5;
		$nro = 0;
		 
		/*echo "<pre>";
		var_dump($calculoTotalXPersona);
		echo "</pre>";
		die();*/ 

		$days_of_month  = cal_days_in_month(CAL_GREGORIAN, $mes, $anio);

		if($periodo == 1 || $periodo == 2){ 
			foreach (self::excelColumnRange('O', 'AD') as $value) { 
			    $sheet->getColumnDimension($value)->setAutoSize(false);
	       	 	$sheet->getColumnDimension($value)->setWidth(3.75);
			}

			$sheet->getColumnDimension('B')->setWidth(30);
			$sheet->getColumnDimension('N')->setWidth(30);

			// CABECERA
			$sheet->setCellValue("B4", "APELLIDOS");
			$sheet->setCellValue("C4", "TIPO");
			$sheet->setCellValue("D4", "NACIONALIDAD");
			$sheet->setCellValue("E4", "NRO");
			$sheet->setCellValue("F4", "CARGO");
			$sheet->setCellValue("G4", "F/ING");
			$sheet->setCellValue("H4", "F/CESE");
			$sheet->setCellValue("I4", "REM BRUTA");
			$sheet->setCellValue("J4", "BANCO");
			$sheet->setCellValue("K4", "CUENTAS");
			$sheet->setCellValue("L4", "TP-CUENTAS"); 
			$sheet->setCellValue("M4", "CCI");
			$sheet->setCellValue("N4", "PERSONAL AUTORIZADO A COBRAR /DNI");

			// CABECERA
			$sheet->setCellValue("AE3", "COSTO");
			$sheet->setCellValue("AE4", "DIARIO");
			$sheet->setCellValue("AF3", "COSTO");
			$sheet->setCellValue("AF4", "NOCHE");
			$sheet->mergeCells("AG3:AO3");
			$sheet->getStyle("AG3:AO3")->applyFromArray($styleArray);

			$sheet->setCellValue("AG3", "CONTADOR DE DIAS");
			$sheet->getStyle("AG3")->getAlignment()->setHorizontal('center');
			$sheet->getStyle("AG3")->getAlignment()->setVertical('center');
			$sheet->setCellValue("AG4", "MA");
			$sheet->setCellValue("AH4", "TA");
			$sheet->setCellValue("AI4", "NO");
			$sheet->setCellValue("AJ4", "C");
			$sheet->setCellValue("AK4", "FAL");
			$sheet->setCellValue("AL4", "FE");
			$sheet->setCellValue("AM4", "D");
			$sheet->setCellValue("AN4", "DP");
			$sheet->setCellValue("AO4", "TD"); 
			$sheet->getColumnDimension("AG")->setWidth(5);
	       	$sheet->getColumnDimension("AH")->setWidth(5);
	       	$sheet->getColumnDimension("AI")->setWidth(5);
	       	$sheet->getColumnDimension("AJ")->setWidth(5);
	       	$sheet->getColumnDimension("AK")->setWidth(5);
	       	$sheet->getColumnDimension("AL")->setWidth(5);
	       	$sheet->getColumnDimension("AM")->setWidth(5); 
	       	$sheet->getColumnDimension("AN")->setWidth(5);
	       	$sheet->getColumnDimension("AO")->setWidth(5);

			$sheet->getStyle('AG4:AO4')->applyFromArray($styleArray); 

	       	/*$sheet->getStyle("AV4:BC4")->getBorders()
		    ->getOutline()
		    ->setBorderStyle(Border::BORDER_HAIR)
		    ->setColor(new Color('FFFF0000'));*/

			$sheet->mergeCells("AP3:AV3");
			$sheet->setCellValue("AP3", "PAGO DE LOS DIAS");  
			$sheet->getStyle("AP3")->getAlignment()->setHorizontal('center');
			$sheet->getStyle("AP3")->getAlignment()->setVertical('center');

			$sheet->getStyle("AP3:AV3")->applyFromArray($styleArray);

	       	$sheet->getColumnDimension("AP")->setWidth(5);
	       	$sheet->getColumnDimension("AQ")->setWidth(5);
	       	$sheet->getColumnDimension("AR")->setWidth(5);
	       	$sheet->getColumnDimension("AS")->setWidth(5);
	       	$sheet->getColumnDimension("AT")->setWidth(5);
	       	$sheet->getColumnDimension("AU")->setWidth(5);
	       	$sheet->getColumnDimension("AV")->setWidth(5);

	       	$sheet->getStyle("AP4:AV4")->applyFromArray($styleArray);
	 		$sheet->getStyle("B4:N4")->applyFromArray($styleArray);

			$sheet->setCellValue("AP4", "MA");
			$sheet->setCellValue("AQ4", "TA");
			$sheet->setCellValue("AR4", "NO");
			$sheet->setCellValue("AS4", "C");
			$sheet->setCellValue("AT4", "FE");
			$sheet->setCellValue("AU4", "D");
			$sheet->setCellValue("AV4", "DP"); 
			$sheet->setCellValue("AW4", "A PAGAR");
			foreach($calculoTotalXPersona as $datar){

				/*echo "<pre>";
				var_dump($datar);
				echo "</pre>";
				die();*/

				$sheet->setCellValue("AW".$ia, $datar[0]);
				// nombres
				$sheet->setCellValue("B".$ia, $datar[15]);
				// tipo de documento
				$sheet->setCellValue("C".$ia, $datar[16]);
				// nacionalidad
				$sheet->setCellValue("D".$ia, $datar[17]);
				// documento
				$sheet->setCellValue("E".$ia, $datar[26]);
				// cargo
				$sheet->setCellValue("F".$ia, $datar[18]);
				// fecha de ingreso
				$sheet->setCellValue("G".$ia, $datar[19]);
				// fecha de cese
				$sheet->setCellValue("H".$ia, (($datar[30] == 1) ? "" : $datar[31]));
				// remuneracion bruta
				$sheet->setCellValue("I".$ia, $datar[20]); 
				$sueldo = number_format((float)($datar[20] / $days_of_month), 2, '.', '');
				$sheet->setCellValue("AE".$ia, $sueldo);
				$sheet->setCellValue("AF".$ia, number_format(((float)($sueldo*1.35)), 2, '.', ''));
	  
				$valorDia = $sueldo;
				$valorNoche = number_format(((float)($sueldo*1.35)), 2, '.', '');

				// Turnos asistido
				// MAÑANA
				$sheet->setCellValue("AG".$ia, $datar[3]);
				// TARDE
				$sheet->setCellValue("AH".$ia, $datar[4]);
				// NOCHE
				$sheet->setCellValue("AI".$ia, $datar[5]);
				// PERMISO
				$sheet->setCellValue("AJ".$ia, $datar[32]);
				// FALTAS
				$sheet->setCellValue("AK".$ia, $datar[28]);
				// FERIADO
				$sheet->setCellValue("AL".$ia, $datar[11]);
				// DESCANSO
				$sheet->setCellValue("AM".$ia, $datar[6]);
				// DESCANSO PAGADO
				$sheet->setCellValue("AN".$ia, $datar[12]);
				//TOTAL DIAS TRABAJADOS
				$sheet->setCellValue("AO".$ia, number_format(($datar[3]+$datar[4]+$datar[5]+$datar[6]+$datar[7]+$datar[12]+ $datar[11]+$datar[32]),2));
				//FERIADO PAGO
				$sheet->setCellValue("AT".$ia, $datar[14]);

				/*echo "<pre>";
				var_dump($datar);
				echo "</pre>";
				die();*/

				// DESCANSO SIN TURNOS
				$sheet->setCellValue("AU".$ia, $datar[29]);
				// DESCANSO CON TURNOS
				$sheet->setCellValue("AV".$ia, $datar[13]);
				// MAÑANA PAGADO
				$sheet->setCellValue("AP".$ia, $datar[8]);
				// TARDE PAGADO
				$sheet->setCellValue("AQ".$ia, $datar[9]);
				// NOCHE PAGADO
				$sheet->setCellValue("AR".$ia, $datar[10]);
				// COVIT PAGADO
				$sheet->setCellValue("AS".$ia, $datar[33]); 

				// BANCO CUENTA TITULAR Y SUPLENTE
				$sheet->setCellValue("J".$ia, $datar[21]);
				$sheet->setCellValue("K".$ia, $datar[22]); 
				$sheet->setCellValue("L".$ia, $datar[23]);
				$sheet->setCellValue("M".$ia, $datar[24]);
				$sheet->setCellValue("N".$ia, $datar[25]); 

				$inicio_mess	= $anio.'-'.$mes.'-01'; 
				if($periodo == 1){ 
					$fin_calculo = $anio.'-'.$mes.'-15';
				}else if($periodo == 2){
					$inicio_mess = $anio.'-'.$mes.'-16';
		 			$fin_calculo  = $anio.'-'.$mes.'-'.date('t',strtotime($inicio_mess));
				}else{ 
					$fin_calculo  	= $anio.'-'.$mes.'-'.date('t',strtotime($inicio_mess));
				}  

				$sueldoVigencia =  self::fn_getVigenciaIF($datar[34]);

				/*var_dump($datar[34]);
				var_dump($sueldoVigencia);
				die();*/

				while(strtotime($inicio_mess) <= strtotime($fin_calculo)) {
					$data =  self::fn_getDiaXiDPrs($datar[27],$inicio_mess);
					if($data != ""){
						if(count($sueldoVigencia)>0){
							$vigenciaInicio = $sueldoVigencia[0]->ta_vigenciaInicio;
							$vigenciaFin = $sueldoVigencia[0]->ta_vigenciaFin;
							if((strtotime($inicio_mess) >= strtotime($vigenciaInicio)) && (strtotime($inicio_mess) <= strtotime($vigenciaFin))){
								$days = $data->Result;
								$sheet->setCellValueByColumnAndRow($colum, $row, $days);
							}
						}
					} 
			        $inicio_mess = date("Y-m-d", strtotime("+1 day", strtotime($inicio_mess)));
			        $colum++;
			    }
			    $colum = 15;
			    $row++;
				$ia++;
				$nro++;
			}
		}else{ 
 			// NO SIRVE

			foreach (self::excelColumnRange('O', 'AS') as $value) { 
			    $sheet->getColumnDimension($value)->setAutoSize(false);
	       	 	$sheet->getColumnDimension($value)->setWidth(3.75);
			}

			$sheet->getColumnDimension('B')->setWidth(30);
			$sheet->getColumnDimension('N')->setWidth(30);

			// CABECERA
			$sheet->setCellValue("B4", "APELLIDOS");
			$sheet->setCellValue("C4", "TIPO DOC");
			$sheet->setCellValue("D4", "NACIONALIDAD");
			$sheet->setCellValue("E4", "NRO");
			$sheet->setCellValue("F4", "CARGO");
			$sheet->setCellValue("G4", "FECHA DE INGRESO");
			$sheet->setCellValue("I4", "REM BRUTA");
			$sheet->setCellValue("J4", "BANCO");
			$sheet->setCellValue("K4", "CUENTAS");
			$sheet->setCellValue("L4", "TP-CUENTAS"); 
			$sheet->setCellValue("M4", "CCI");
			$sheet->setCellValue("N4", "PERSONAL AUTORIZADO A COBRAR /DNI");

			// CABECERA
			$sheet->setCellValue("AT3", "COSTO");
			$sheet->setCellValue("AT4", "DIARIO");
			$sheet->setCellValue("AU3", "COSTO");
			$sheet->setCellValue("AU4", "NOCHE");
			$sheet->mergeCells("AV3:BC3");
			$sheet->getStyle("AV3:BC3")->applyFromArray($styleArray);

			$sheet->setCellValue("AV3", "CONTADOR DE DIAS");
			$sheet->getStyle("AV3")->getAlignment()->setHorizontal('center');
			$sheet->getStyle("AV3")->getAlignment()->setVertical('center');
			$sheet->setCellValue("AV4", "M");
			$sheet->setCellValue("AW4", "T");
			$sheet->setCellValue("AX4", "N");
			//$sheet->setCellValue("AY4", "C");
			$sheet->setCellValue("AZ4", "F");
			$sheet->setCellValue("BA4", "D");
			$sheet->setCellValue("BB4", "DP");
			$sheet->setCellValue("BC4", "TD"); 
			$sheet->getColumnDimension("AV")->setWidth(5);
	       	$sheet->getColumnDimension("AW")->setWidth(5);
	       	$sheet->getColumnDimension("AY")->setWidth(5);
	       	$sheet->getColumnDimension("AX")->setWidth(5);
	       	$sheet->getColumnDimension("AZ")->setWidth(5);
	       	$sheet->getColumnDimension("BA")->setWidth(5);
	       	$sheet->getColumnDimension("BB")->setWidth(5);
	       	$sheet->getColumnDimension("BC")->setWidth(5); 

			$sheet->getStyle('AV4:BC4')->applyFromArray($styleArray); 

	       	/*$sheet->getStyle("AV4:BC4")->getBorders()
		    ->getOutline()
		    ->setBorderStyle(Border::BORDER_HAIR)
		    ->setColor(new Color('FFFF0000'));*/

			$sheet->mergeCells("BD3:BJ3");
			$sheet->setCellValue("BD3", "PAGO DE LOS DIAS");  
			$sheet->getStyle("BD3")->getAlignment()->setHorizontal('center');
			$sheet->getStyle("BD3")->getAlignment()->setVertical('center');

			$sheet->getStyle("BD3:BJ3")->applyFromArray($styleArray);

		    $sheet->getColumnDimension("BD")->setWidth(5);
	       	$sheet->getColumnDimension("BE")->setWidth(5);
	       	$sheet->getColumnDimension("BF")->setWidth(5);
	       	$sheet->getColumnDimension("BG")->setWidth(5);
	       	$sheet->getColumnDimension("BH")->setWidth(5);
	       	$sheet->getColumnDimension("BI")->setWidth(5);
	       	$sheet->getColumnDimension("BJ")->setWidth(5);

	       	$sheet->getStyle("BD4:BJ4")->applyFromArray($styleArray);
	 		$sheet->getStyle("B4:N4")->applyFromArray($styleArray);

			$sheet->setCellValue("BD4", "MA");
			$sheet->setCellValue("BE4", "TA");
			$sheet->setCellValue("BF4", "NO");
			//$sheet->setCellValue("BG4", "C");
			$sheet->setCellValue("BH4", "F");
			$sheet->setCellValue("BI4", "DESC");
			$sheet->setCellValue("BJ4", "DP"); 
			$sheet->setCellValue("BK4", "A PAGAR"); 
			foreach($calculoTotalXPersona as $datar){

				/*echo "<pre>";
				var_dump($datar);
				echo "</pre>";
				die();*/

				$sheet->setCellValue("BK".$ia, $datar[0]);
				$sheet->setCellValue("B".$ia, $datar[1]->apellidos);
				$sheet->setCellValue("C".$ia, $datar[1]->tpd_abreviatura);
				$sheet->setCellValue("D".$ia, $datar[1]->nacionalidad);
				$sheet->setCellValue("E".$ia, $datar[1]->per_documento);
				$sheet->setCellValue("F".$ia, $datar[1]->ca_descripcion);
				$sheet->setCellValue("G".$ia, $datar[1]->pe_fecha_ingreso);
				$sheet->setCellValue("I".$ia, $datar[1]->ta_basico);
				$sueldo = number_format((float)(($datar[1]->ta_basico+$datar[1]->ta_asignacion_familiar) / $days_of_month), 2, '.', '');
				$sheet->setCellValue("AT".$ia, $sueldo);
				$sheet->setCellValue("AU".$ia, number_format(((float)($sueldo*1.35)), 2, '.', ''));
	  
				$valorDia = $sueldo;
				$valorNoche = number_format(((float)($sueldo*1.35)), 2, '.', '');

				// Turnos asistido
				$sheet->setCellValue("AV".$ia, $datar[3]);
				$sheet->setCellValue("AW".$ia, $datar[4]);
				$sheet->setCellValue("AX".$ia, $datar[5]);
				$sheet->setCellValue("AZ".$ia, $datar[11]);
				$sheet->setCellValue("BA".$ia, $datar[6]);

				$sheet->setCellValue("BC".$ia, number_format(($datar[3]+$datar[4]+$datar[5]+$datar[6]+$datar[7]),2));

				// DESCANSO PAGADO
				$sheet->setCellValue("BI".$ia, number_format(((float)($datar[6])*$valorDia),2));
				// MAÑANA PAGADO
				$sheet->setCellValue("BD".$ia, $datar[8]);
				// TARDE PAGADO
				$sheet->setCellValue("BE".$ia, $datar[9]);
				// NOCHE PAGADO
				$sheet->setCellValue("BF".$ia, $datar[10]);
				//$sheet->setCellValue("BH".$ia, 0);
				//$sheet->setCellValue("AZ".$ia, $datar[7]);
				$sheet->setCellValue("BA".$ia, $datar[6]);


	 
				// is titular ? 
				$bancoTiPlanilla = self::fn_getCuentaBankoPrincipalXiD($datar[1]->id_persona);
				if(count($bancoTiPlanilla) >= 1){
					$sheet->setCellValue("J".$ia, $bancoTiPlanilla[0]->banco);
					$sheet->setCellValue("K".$ia, "'".$bancoTiPlanilla[0]->phb_cuenta);
					$sheet->setCellValue("L".$ia, $bancoTiPlanilla[0]->tpc_abreviatura);
					$sheet->setCellValue("M".$ia, "'".$bancoTiPlanilla[0]->phb_cci);
				}

				// no is titular ? 
				$bancoSuPlanilla = self::fn_getCuentaBankoSuplenteXiD($datar[1]->id_persona);
				if(count($bancoSuPlanilla) >= 1){
					$sheet->setCellValue("J".$ia, $bancoSuPlanilla[0]->banco);
					$sheet->setCellValue("K".$ia, "'".$bancoSuPlanilla[0]->phb_cuenta);
					$sheet->setCellValue("L".$ia, $bancoSuPlanilla[0]->tpc_abreviatura);
					$sheet->setCellValue("M".$ia, "'".$bancoSuPlanilla[0]->phb_cci);
					$sheet->setCellValue("N".$ia, "'".$bancoSuPlanilla[0]->datos);
				}

				$inicio_mess	= $anio.'-'.$mes.'-01'; 
				if($periodo == 1){ 
					$fin_calculo = $anio.'-'.$mes.'-15';
				}else if($periodo == 2){
					$inicio_mess = $anio.'-'.$mes.'-16';
		 			$fin_calculo  = $anio.'-'.$mes.'-'.date('t',strtotime($inicio_mess));
				}else{ 
					$fin_calculo  	= $anio.'-'.$mes.'-'.date('t',strtotime($inicio_mess));
				}  

				while(strtotime($inicio_mess) <= strtotime($fin_calculo)) {
					$data =  self::fn_getDiaXiDPrs($datar[1]->id_persona,$inicio_mess);
					if($data != ""){
						$days = $data->Result;
						$sheet->setCellValueByColumnAndRow($colum, $row, $days); 
					}
			        $inicio_mess = date("Y-m-d", strtotime("+1 day", strtotime($inicio_mess)));
			        $colum++;
			    }
			    $colum = 15;
			    $row++;
				$ia++;
				$nro++;
			}
		}

		/*var_dump($row);
		die();*/

		$date3 = $anio.'-'.$mes.'-01';
		$end3  = $anio.'-'.$mes.'-'.date('t',strtotime($date3));

		if($periodo == 1){
 			$end3  = $anio.'-'.$mes.'-15';
		}else if($periodo == 2){
			$date3 = $anio.'-'.$mes.'-16';
 			$end3  = $anio.'-'.$mes.'-'.date('t',strtotime($date3));
		}else{
 			$end3  = $anio.'-'.$mes.'-'.date('t',strtotime($date3));
		}  
		$colum3 = 15;
		$row3 = $row+1;

		$sheet->setCellValueByColumnAndRow(14, $row3, 	"Mañana");
		$sheet->setCellValueByColumnAndRow(14, $row3+1, "Tarde");
		$sheet->setCellValueByColumnAndRow(14, $row3+2, "Noche");

		/*$sheet->getStyle("N".$row3)->getAlignment()->setHorizontal('center');
		$sheet->getStyle("N".$row3+1)->getAlignment()->setHorizontal('center');
		$sheet->getStyle("N".$row3+2)->getAlignment()->setHorizontal('center'); */

	    while(strtotime($date3) <= strtotime($end3)) {  
	        $day_num = date('d', strtotime($date3));
	        $day_name = date('l', strtotime($date3));
	        $data =  self::fn_getDiaCountAbreviatura($ca_planilla,$date3);
			if($data != ""){
				$maniana = $data->maniana;
				$tarde = $data->tarde;
				$noche = $data->noche;
				$sheet->setCellValueByColumnAndRow($colum3, $row3, $maniana);
				$sheet->setCellValueByColumnAndRow($colum3, $row3+1, $tarde);
				$sheet->setCellValueByColumnAndRow($colum3, $row3+2, $noche);
			} 
	        #$sheet->setCellValueByColumnAndRow($colum3, $row3, "Si");
	        $date3 = date("Y-m-d", strtotime("+1 day", strtotime($date3)));
	        $colum3++;
	    }
		
		$periodo	= $anio.'-'.$mes.'-01'; 
		$fileName= "planilla_".$periodo.".xlsx";
		# Crear un "escritor"
		$writer = new Xlsx($spread);
		# Le pasamos la ruta de guardado
		header('Content-Type: application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
		header('Content-Disposition: attachment; filename="'. urlencode($fileName).'"');
		$writer->save('php://output');
	} 

	function excelColumnRange($lower, $upper) {
	    ++$upper;
	    for ($i = $lower; $i !== $upper; ++$i) {
	        yield $i;
	    }
	}

	public function arrayCastRecursive($array)
	{
	    if (is_array($array)) {
	        foreach ($array as $key => $value) {
	            if (is_array($value)) {
	                $array[$key] = self::arrayCastRecursive($value);
	            }
	            if ($value instanceof stdClass) {
	                $array[$key] = self::arrayCastRecursive((array)$value);
	            }
	        }
	    }
	    if ($array instanceof stdClass) {
	        return self::arrayCastRecursive((array)$array);
	    }
	    return $array;
	}

	function in_array_r($needle, $haystack, $strict = false) {
	    foreach ($haystack as $item) {
	        if (($strict ? $item === $needle : $item == $needle) || (is_array($item) && self::in_array_r($needle, $item, $strict))) {
	            return true;
	        }
	    }

	    return false;
	}

	//function 

}
?>
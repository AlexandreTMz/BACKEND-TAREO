<?php
class Template {

	public $blocks = array();
	public $cache_path = 'CORE/cache/';
	public $cache_enabled = FALSE;
	public $paths;
	public $cpath;


	public function __construct($data)
	{
		$this->paths = $data;
	}

	/*public function view($file, $data = array()) {
		$cached_file = $this->cache($file);
	    extract($data, EXTR_SKIP);
	   	require $cached_file;
	}*/

	public function filterByDow($items, $type = 5){
	    return array_filter($items, function($item) use ($type) {
	        if($item['type'] === $type){
	        	//var_dump($item);
	            return true;
	        }
	    });

	}

	public function view($type, $file, $data = array()) {
		$this->cpath = array_values($this->filterByDow($this->paths, $type))[0];
		//$this->cpath = $filter;
		//var_dump(array_values($this->cpath));
		//die();
		//if (is_null($path)) throw new Exception('Añada la ruta al inicio');
		$cached_file = $this->cache($this->cpath['path'].$file);
	    extract($data, EXTR_SKIP);
	   	require $cached_file;
	}

	public function redirect($url="", $time = 0)
	{
		$url = Utilities::getUrl()."/".$url;
	    header("refresh:$time; url=$url");
	}

	public function cache($file) {
		if (!file_exists($this->cache_path)) {
		  	mkdir($this->cache_path, 0744);
		}
	    $cached_file = $this->cache_path . str_replace(array('/', '.html'), array('_', ''), $file . '.php');
	    if (!$this->cache_enabled || !file_exists($cached_file) || filemtime($cached_file) < filemtime($file)) {
			$code = $this->includeFiles($file);
			$code = $this->compileCode($code);
	        file_put_contents($cached_file, '<?php class_exists(\'' . __CLASS__ . '\') or exit; ?>' . PHP_EOL . $code);
	    }
		return $cached_file;
	}

	public function clearCache() {
		foreach(glob($this->cache_path . '*') as $file) {
			unlink($file);
		}
	}

	public function compileCode($code) {
		$code = $this->compileBlock($code);
		$code = $this->compileYield($code);
		$code = $this->compileEchos($code);
		$code = $this->compileEscapedEchos($code);
		$code = $this->compilePHP($code);
		return $code;
	}

	public function includeFiles($file) {
		$code = file_get_contents($file) or die("Archivo no encontrado");
		preg_match_all('/{% ?(extends|include) ?\'?(.*?)\'? ?%}/i', $code, $matches, PREG_SET_ORDER);
		foreach ($matches as $value) {
			$dir = dirname($file);
			$code = str_replace($value[0], $this->includeFiles($dir."/".$value[2]), $code);
		}
		$code = preg_replace('/{% ?(extends|include) ?\'?(.*?)\'? ?%}/i', '', $code);
		return $code;
	}

	public function compilePHP($code) {
		return preg_replace('~\{%\s*(.+?)\s*\%}~is', '<?php $1 ?>', $code);
	}

	public function compileEchos($code) {
		return preg_replace('~\{{\s*(.+?)\s*\}}~is', '<?php echo $1 ?>', $code);
	}

	public function compileEscapedEchos($code) {
		return preg_replace('~\{{{\s*(.+?)\s*\}}}~is', '<?php echo htmlentities($1, ENT_QUOTES, \'UTF-8\') ?>', $code);
	}

	public function compileBlock($code) {
		preg_match_all('/{% ?block ?(.*?) ?%}(.*?){% ?endblock ?%}/is', $code, $matches, PREG_SET_ORDER);
		foreach ($matches as $value) {
			if (!array_key_exists($value[1], $this->blocks)) $this->blocks[$value[1]] = '';
			if (strpos($value[2], '@parent') === false) {
				$this->blocks[$value[1]] = $value[2];
			} else {
				$this->blocks[$value[1]] = str_replace('@parent', $this->blocks[$value[1]], $value[2]);
			}
			$code = str_replace($value[0], '', $code);
		}
		return $code;
	}

	public function compileYield($code) {
		foreach($this->blocks as $block => $value) {
			$code = preg_replace('/{% ?yield ?' . $block . ' ?%}/', $value, $code);
		}
		$code = preg_replace('/{% ?yield ?(.*?) ?%}/i', '', $code);
		return $code;
	}

}
?>
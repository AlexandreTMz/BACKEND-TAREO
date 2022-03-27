<?php
class Route {

  private $routes = Array();
  private $pathNotFound = null;
  private $methodNotAllowed = null;

  private $designer = Array();

  public $view;

  /**
    * Function used to add a new route
    * @param string $expression    Route string or expression
    * @param callable $function    Function to call if route with allowed method is found
    * @param string|array $method  Either a string of allowed method or an array with string values
    *
    */


  public function designer($data = []){
    foreach ($data as $path) {
        array_push($this->designer, Array(
          'type' => $path['type'],
          'path' => $path['path']
        ));
    }
  }

  public function add($expression, $function, $method = 'get'){
    array_push($this->routes, Array(
      'expression' => $expression,
      'function' => $function,
      'method' => $method
    ));
  }

  public function pathNotFound($function) {
    $this->pathNotFound = $function;
  }

  public function methodNotAllowed($function) {
    $this->methodNotAllowed = $function;
  }


  public function view(){
      return $this->view;
  }

  public function run($basepath = '', $case_matters = false, $trailing_slash_matters = false, $multimatch = false) {

    $this->view = new Template($this->designer); 
    //var_dump($this->view);
    // The basepath never needs a trailing slash
    // Because the trailing slash will be added using the route expressions
    $basepath = rtrim($basepath, '/');

    // Parse current URL
    $parsed_url = parse_url($_SERVER['REQUEST_URI']);

    $path = '/';

    // If there is a path available
    if (isset($parsed_url['path'])) {
      // If the trailing slash matters
  	  if ($trailing_slash_matters) {
  		  $path = $parsed_url['path'];
  	  } else {
        // If the path is not equal to the base path (including a trailing slash)
        if($basepath.'/'!=$parsed_url['path']) {
          // Cut the trailing slash away because it does not matters
          $path = rtrim($parsed_url['path'], '/');
        } else {
          $path = $parsed_url['path'];
        }
  	  }
    }

    // Get current request method
    $method = $_SERVER['REQUEST_METHOD'];

    $path_match_found = false;

    $route_match_found = false;

    foreach ($this->routes as $route) {

      // If the method matches check the path

      // Add basepath to matching string
      if ($basepath != '' && $basepath != '/') {
        $route['expression'] = '('.$basepath.')'.$route['expression'];
      }

      // Add 'find string start' automatically
      $route['expression'] = '^'.$route['expression'];

      // Add 'find string end' automatically
      $route['expression'] = $route['expression'].'$';

      // Check path match
      if (preg_match('#'.$route['expression'].'#'.($case_matters ? '' : 'i'), $path, $matches)) {
        $path_match_found = true;

        // Cast allowed method to array if it's not one already, then run through all methods
        foreach ((array)$route['method'] as $allowedMethod) {
            // Check method match
          if (strtolower($method) == strtolower($allowedMethod)) {
            array_shift($matches); // Always remove first element. This contains the whole string

            if ($basepath != '' && $basepath != '/') {
              array_shift($matches); // Remove basepath
            }

            $res = array();

            if(count($matches)>0) {
              $res[0] = array($matches, $this->view);
            }else{
              $res[0] = array($this->view);
            }

            call_user_func_array($route['function'], $res[0]);

            $route_match_found = true;

            // Do not check other routes
            break;
          }
        }
      }

      // Break the loop if the first found route is a match
      if($route_match_found&&!$multimatch){
        break;
      }

    }

    // No matching route was found
    if (!$route_match_found) {
      // But a matching path exists
      if ($path_match_found) {
        if ($this->methodNotAllowed) {
          call_user_func_array($this->methodNotAllowed, Array($path,$method, $this->view));
        }
      } else {
        if ($this->pathNotFound) {
          call_user_func_array($this->pathNotFound, Array($path, $this->view));
        }
      }

    }
  }

}

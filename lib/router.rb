require_relative './controller_base'

class Route
  attr_reader :pattern, :http_method, :controller_class, :action_name

  def initialize(pattern, http_method, controller_class, action_name)
    @pattern = pattern
    @http_method = http_method
    @controller_class = controller_class
    @action_name = action_name
  end

  # checks if pattern matches path and method matches request method
  def matches?(req)
    req.path =~ @pattern && @http_method == req.request_method.downcase.to_sym
  end

  # use pattern to pull out route params (save for later?)
  # instantiate controller and call controller action
  def run(req, res)
    route_params = req.path.match(@pattern)
    controller = @controller_class.new(req, res, build_hash(route_params))
    controller.send(:invoke_action, @action_name)
  end

  def build_hash(route_params)
    route_params.names.inject({}) do |hash, name|
      hash.tap { |h| h[name] = route_params[name] }
    end
  end
end

class Router
  attr_reader :routes

  def initialize
    @routes = []
  end

  # simply adds a new route to the list of routes
  def add_route(pattern, method, controller_class, action_name)
    @routes << Route.new(pattern, method, controller_class, action_name)
  end

  # evaluate the proc in the context of the instance
  # for syntactic sugar :)
  def draw(&proc)
    instance_eval(&proc)
  end
  # make each of these methods that
  # when called add route
  [:get, :post, :put, :delete].each do |http_method|
    define_method(http_method) do |pattern, controller_class, action_name|
      add_route(pattern, http_method, controller_class, action_name)
    end
  end

  # should return the route that matches this request
  def match(req)
    @routes.find { |route| route.matches?(req) }
  end

  # either throw 404 or call run on a matched route
  def run(req, res)
    route = match(req)
    !route.nil? ? route.run(req, res) : res.status = 404
  end

  def define_controller_helpers
    index_route = @routes.find { |route| route.action_name == :index }
    if index_route
      define_path_helper(index_route, true)
      define_url_helper(index_route, true)
    end

    show_route = @routes.find { |route| route.action_name == :show }
    if show_route
      define_path_helper(show_route, false)
      define_url_helper(show_route, false)
    end
  end

  def define_path_helper(route, plural)
    ControllerBase.send(:define_method, methodify(route.controller, "path", plural)) do |obj|
      index_route.pattern.inspect[/(\/[[:alnum:]]+)+/]
        + route.action_name == :show ? "\\#{obj.try(:id) ? obj.id : obj}" : ""
    end
  end

  def define_url_helper(route, plural)
    ControllerBase.send(:define_method, methodify(route.controller, "path", plural)) do |obj|
      URI.parse(show_route.req.request_uri).host
        + index_route.pattern.inspect[/(\/[[:alnum:]]+)+/]
        + route.action_name == :show ? "\\#{obj.try(:id) ? obj.id : obj}" : ""
    end
  end

  def methodify(controller_class, suffix, plural = false)
    class_name = uncontrollerize(controller_class)
    (plural ? class_name.pluralize : class_name) + "_#{suffix}"
  end

  def uncontrollerize(controller_class)
    controller_class.name.match(/(.+)Controller/)[1]
  end
end

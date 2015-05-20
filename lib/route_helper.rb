module RouteHelper
  def parse_route(route)
    method_missing(route)
    rescue NoMethodError
      route
    end
  end

  def link_to(text, route)
    route = parse_route(route)
    <<-HTML
      <a href="#{route}">#{text}</a>
    HTML
  end

  def button_to(text, route)
    route = parse_route
    <<-HTML
      <form method="post" action="#{route}" class="button">
        <input value=#{text} type="submit">
      </form>
    HTML
  end
end

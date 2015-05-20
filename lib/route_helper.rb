module RouteHelper
  def link_to(text, route)
    <<-HTML
      <a href="#{route}">#{text}</a>
    HTML
  end

  def button_to(text, route)
    <<-HTML
      <form method="post" action="#{route}" class="button">
        <input value=#{text} type="submit">
      </form>
    HTML
  end
end

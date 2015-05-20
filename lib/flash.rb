class Flash
  def initialize(req)
    @req = req
    my_cookie = req.cookies.find { |cookie| cookie.try(:name) == "_rails_lite_app_flash" }
    @flash = {}
    @now = my_cookie ? JSON.parse(my_cookie.value) : {}
    @flash[:errors] ||= []
    @now[:errors] ||= []
  end

  def [](key)
    @flash[key]
  end

  def []=(key, val)
    @flash[key] = val
  end

  def now[](key)
    @now[key]
  end

  def now[]=(key, val)
    @now[key] = val
  end

  # serialize the hash into json and save in a cookie
  # add to the responses cookies
  def store_flash(res)
    res.cookies << WEBrick::Cookie.new("_rails_lite_app_flash", @flash.to_json)
  end
end

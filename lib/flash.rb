class HashWithIndifferentAccess < Hash
  def [](key)
    super(key.to_sym)
  end

  def []=(key, val)
    super(key.to_sym, val)
  end

  def merge(other_hash)
    super(other_hash).inject(HashWithIndifferentAccess.new) do |hash, (k, v)|
      hash.tap { |h| h[k] = v }
    end
  end
end

class Flash
  def initialize(req)
    @req = req
    my_cookie = req.cookies.find { |cookie| cookie.try(:name) == "_rails_lite_app_flash" }
    @flash = HashWithIndifferentAccess.new
    @now = HashWithIndifferentAccess.new
    if my_cookie
      JSON.parse(my_cookie.value).each do |k, v|
        @now[k] = v
      end
    end
  end

  def [](key)
    @flash.merge(@now)[key]
  end

  def []=(key, val)
    @flash[key] = val
    @now[key] = val
  end

  def now
    @now
  end
  # serialize the hash into json and save in a cookie
  # add to the responses cookies
  def store_flash(res)
    res.cookies << WEBrick::Cookie.new("_rails_lite_app_flash", @flash.to_json)
  end
end

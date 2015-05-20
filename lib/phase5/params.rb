require 'uri'
require 'byebug'

module Phase5
  class Params
    # use your initialize to merge params from
    # 1. query string
    # 2. post body
    # 3. route params
    #
    # You haven't done routing yet; but assume route params will be
    # passed in as a hash to `Params.new` as below:
    def initialize(req, route_params = {})
      @params = route_params
      @params.merge!(parse_www_encoded_form(req.query_string)) if req.query_string
      @params.merge!(parse_www_encoded_form(req.body)) if req.body
    end

    def [](key)
      @params[key.to_sym] || @params[key.to_s]
    end

    def []=(key, val)
      @params[key.to_sym] = val
    end

    def to_s
      @params.to_json.to_s
    end

    class AttributeNotFoundError < ArgumentError; end;

    private
    # this should return deeply nested hash
    # argument format
    # user[address][street]=main&user[address][zip]=89436
    # should return
    # { "user" => { "address" => { "street" => "main", "zip" => "89436" } } }
    def parse_www_encoded_form(www_encoded_form)
      hash_builder(parse(www_encoded_form))
    end

    def hash_builder(arrays)
      hashes = []
      arrays.each do |arr|
        hash_str = ""
        arr.each_with_index do |el, i|
          case
          when i == arr.length - 1
            hash_str << quote(arr.last) + "}"
            break
          when el == ""
            hash_str << quote(arr.last) + "}" * (arr.length - 2)
            break
          else
            hash_str << "{ #{quote(el)} => "
          end
        end
        hashes << eval(hash_str)
      end
      hashes.inject(:merge)
    end

    def quote(str)
      "\"#{str}\""
    end

    # this should return an array
    # user[address][street] should return ['user', 'address', 'street']
    def parse(key)
      key.split('&').map { |arr| arr.split(/\[|\]\[|\]|=/) }
    end
  end
end

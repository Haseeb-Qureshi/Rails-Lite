require_relative './session'
require_relative './params'
require_relative './flash'
require_relative './route_helper'
require 'active_support'
require 'active_support/core_ext'
require 'active_support/inflector'
require 'erb'
require 'uri'
require 'webrick'

class ControllerBase
  include RouteHelper
  attr_reader :req, :res

  def initialize(req, res, route_params = {}, router = nil)
    @req = req
    @res = res
    @params = Params.new(req, route_params)
  end

  def already_built_response?
    @already_built_response
  end

  def session
    @session ||= Session.new(req)
  end

  def flash
    @flash ||= Flash.new(req)
  end

  # Set the response status code and header
  def redirect_to(url)
    raise "Already built" if already_built_response?
    res.body = "<HTML><A HREF=\"#{url.to_s}\">#{url.to_s}</A>.</HTML>\n"
    res['Location']  = url.to_s
    res.status = 302
    @already_built_response = true
    session.store_session(res)
    flash.store_flash(res)
  end

  # Populate the response with content.
  # Set the response's content type to the given type.
  # Raise an error if the developer tries to double render.
  def render_content(content, content_type)
    raise "Already built" if already_built_response?
    res.content_type = content_type
    res.body = content
    @already_built_response = true
    session.store_session(res)
    flash.store_flash(res)
  end

  def render(template_name)
    view = File.read("views/#{self.class.name.underscore}/#{template_name}.html.erb")
    template = ERB.new(view).result(binding)
    render_content(template, "text/html")
  end

  def invoke_action(name)
    self.send(name)
    render(name) unless already_built_response?
  end
end

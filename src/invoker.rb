#   Copyright © 2006 Sun Microsystems, Inc. All rights reserved
#   Use is subject to license terms - see file "LICENSE"
require 'net/https'
require 'atomURI'
require 'crumbs'

class Invoker
  
  attr_reader :last_error, :crumbs, :response
  
  def initialize(uriString, authent)
    @last_error = nil
    @crumbs = Crumbs.new
    @uri = AtomURI.check(uriString)
    if (@uri.class == String)
      @last_error = @uri
    end
    @authent = authent
  end
  
  def header(which)
    @response[which]
  end
  
  def prepare_http
    http = Net::HTTP.new(@uri.host, @uri.port)

    http.use_ssl = true if @uri.scheme == 'https'
    http.set_debug_output @crumbs if @crumbs
    http
  end
  
  def need_authentication?(req)
    if @response.instance_of?(Net::HTTPUnauthorized) && @authent       
       @authent.add_to req, header('WWW-Authenticate')
       #clean the request body attribute, if we don't do it http.request(req, body) will raise an exception
       req.body = nil unless req.body.nil?
       return true
    end
    return false 
  end
  
end

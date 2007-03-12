#   Copyright © 2006 Sun Microsystems, Inc. All rights reserved
#   Use is subject to license terms - see file "LICENSE"

require 'net/http'
require 'uri'
require 'atomURI'
require 'crumbs'

class Putter

  attr_reader :last_error, :response, :crumbs, :headers

  def initialize(uriString, username='', password='')
    @crumbs = Crumbs.new
    @last_error = nil
    @uri = AtomURI.check(uriString)
    if (@uri.class == String)
      @last_error = @uri
    end
    @username = username
    @password = password
    @headers = {}
  end
  
  def set_header(name, val)
    @headers[name] = val
  end


  def put(contentType, body)
    req = Net::HTTP::Put.new(AtomURI.on_the_wire(@uri))
    if @username
      req.basic_auth @username, @password
    end
    req.set_content_type contentType
    @headers.each { |k, v| req[k]= v }

    begin
      http = Net::HTTP.new(@uri.host, @uri.port)
      http.use_ssl = true if @uri.scheme == 'https'
      http.set_debug_output @crumbs if @crumbs
      http.start do |http|
        @response = http.request(req, body)
        
        if @response.code != '200'
          @last_error = @response.message
          return false
        end
        
        return true
      end
    rescue Exception
      @last_error = "Can't connect: #{$!}"
      return nil
    end
  end
end

#   Copyright © 2006 Sun Microsystems, Inc. All rights reserved
#   Use is subject to license terms - see file "LICENSE"

require 'net/http'
require 'uri'
require 'atomURI'
require 'crumbs'

class Deleter

  attr_reader :last_error, :crumbs

  def initialize(uriString, authent)
    @last_error = nil
    @crumbs = Crumbs.new
    @uri = AtomURI.check(uriString)
    if (@uri.class == String)
      @last_error = @uri
    end
    @authent = authent
  end

  def delete( req = nil )
    req = Net::HTTP::Delete.new(AtomURI.on_the_wire(@uri)) unless req
    @authent.add_to req

    begin
      http = Net::HTTP.new(@uri.host, @uri.port)
      http.use_ssl = true if @uri.scheme == 'https'
      http.set_debug_output @crumbs if @crumbs
      http.start do |connection|
        @response = connection.request(req)
        
        if @response.kind_of?(Net::HTTPUnauthorized) && @authent
           @authent.add_to req, @response['WWW-Authenticate']
            return delete(req)
        end
        
        return true if @response.kind_of? Net::HTTPSuccess

        @last_error = @response.message
        return false
      end
    rescue Exception
      @last_error = "Can't connect to #{@uri.host} on port #{@uri.port}: #{$!}"
      return nil
    end
  end
end

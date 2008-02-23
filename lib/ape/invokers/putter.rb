#   Copyright (c) 2006 Sun Microsystems, Inc. All rights reserved
#   Use is subject to license terms - see file "LICENSE"
require 'net/http'

module Ape
  class Putter < Invoker
    attr_reader :headers

    def initialize(uriString, authent)
      super uriString, authent
      @headers = {}
    end
    
    def set_header(name, val)
      @headers[name] = val
    end
    
    def put(contentType, body, req = nil)
      req = Net::HTTP::Put.new(AtomURI.on_the_wire(@uri)) unless req
      
      req.set_content_type contentType
      @headers.each { |k, v| req[k]= v }

      begin
        http = prepare_http
        
        http.start do |connection|
          @response = connection.request(req, body)
          
          return put(contentType, body, req) if need_authentication?(req)
          restart_authent_checker
          
          unless @response.kind_of? Net::HTTPSuccess
            @last_error = @response.message
            return false
          end
          
          return true
        end
      rescue Exception
        @last_error = "Can't connect to #{@uri.host} on port #{@uri.port}: #{$!}"
        return nil
      end
    end
  end
end

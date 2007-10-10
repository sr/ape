#   Copyright © 2006 Sun Microsystems, Inc. All rights reserved
#   Use is subject to license terms - see file "LICENSE"

require 'net/http'
require 'atomURI'
require 'invoker'

class Getter < Invoker

  attr_reader :contentType, :charset, :body, :security_warning

  def get(contentType = nil, depth = 0, req = nil)
    req = Net::HTTP::Get.new(AtomURI.on_the_wire(@uri)) unless req
    @last_error = nil

    return false if document_failed?(depth, req)    
    
    begin
      http = prepare_http
     
      http.start do |connection|
        @response = connection.request(req)

        if need_authentication?(req)
          @security_warning = true unless http.use_ssl?
          return get(contentType, depth + 1, req) 
        end
        
        case @response
        when Net::HTTPSuccess
          return getBody(contentType)
          
        when Net::HTTPRedirection
          redirect_to = @uri.merge(@response['location'])
          @uri = AtomURI.check(redirect_to)
          return get(contentType, depth + 1)
          
        else
          @last_error = @response.message
          return false
        end      
      end
    rescue Exception
      @last_error = "Can't connect to #{@uri.host} on port #{@uri.port}: #{$!}"
      return false
    end
  end

  def document_failed?(depth, req)
    if (depth > 1 && need_authentication?(req))
      @last_error = "Authentication is required"
      return true
    end
    if (depth > 10)
      # too many redirects
      @last_error = "Too many redirects"
      return true
    end
    return false
  end

  def getBody contentType

    if contentType
      @contentType = @response['Content-Type']
      # XXX TODO - better regex
      if @contentType =~ /^([^;]*);/
        @contentType = $1
      end
    
      if contentType != @contentType
        @last_error = "Content-type must be '#{contentType}', not '#{@contentType}'"
      end
    end
      
    @body = @response.body
    return true
  end
  
end


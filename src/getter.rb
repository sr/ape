#   Copyright © 2006 Sun Microsystems, Inc. All rights reserved
#   Use is subject to license terms - see file "LICENSE"

require 'net/http'
require 'net/https'
require 'uri'
require 'atomURI'
require 'crumbs'

class Getter

  attr_reader :last_error, :contentType, :charset, :body, :crumbs, :response

  def initialize(uri, username = nil, password = nil)
    @last_error = nil
    @crumbs = Crumbs.new
    @uri = AtomURI.check(uri)
    if (@uri.class == String)
      @last_error = @uri
    end
    @username = username
    @password = password
  end

  def get(contentType = nil, depth = 0)
    req = Net::HTTP::Get.new(AtomURI.on_the_wire(@uri))
    @last_error = nil

    if (depth > 10)
      # too many redirects
      @last_error = "Too many redirects"
      return false
    end

    begin
      http = Net::HTTP.new(@uri.host, @uri.port)
      http.use_ssl = true if @uri.scheme == 'https'
      http.set_debug_output @crumbs if @crumbs
      http.start do |http|
        if @username && @password
          req.basic_auth @username, @password
        end
        @response = http.request(req)
        
        case @response
        when Net::HTTPSuccess
          return getBody(contentType)
          
        when Net::HTTPRedirection
          redirect_to = "#{@uri.scheme}://#{@uri.host}#{@response['location']}"
          @uri = AtomURI.check(redirect_to)
          return get(contentType, depth + 1)
          
        else
          @last_error = @response.message
          return false
        end      
      end
    rescue Exception
      @last_error = "Can't connect: #{$!}"
      return false
    end
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
  
  def header(key)
    @response[key]
  end
end


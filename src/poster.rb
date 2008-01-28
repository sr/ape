#   Copyright © 2006 Sun Microsystems, Inc. All rights reserved
#   Use is subject to license terms - see file "LICENSE"

require 'net/http'
require 'atomURI'
require 'entry'
require 'invoker'

class Poster < Invoker

  attr_reader :entry, :uri

  def initialize(uriString, authent)
    super uriString, authent
    @headers = {}
    @entry = nil
  end
  
  def set_header(name, val)
    @headers[name] = val
  end

  def post(contentType, body, req = nil)
    req = Net::HTTP::Post.new(AtomURI.on_the_wire(@uri)) if req.nil?
    req.set_content_type contentType
    @headers.each { |k, v| req[k]= v }

    begin
      http = prepare_http
      
      http.start do |connection|
        @response = connection.request(req, body)
        
        return post(contentType, body, req) if need_authentication?(req)
        restart_authent_checker
        
        if @response.code != '201'
          @last_error = @response.message
          return false
        end

        if (!((@response['Content-type'] =~ %r{^application/atom\+xml}) ||
              (@response['Content-type'] =~ %r{^application/atom\+xml;type=entry})))
          return true
        end

        begin
          @entry = Entry.new(@response.body)
          return true
        rescue ArgumentError
          @last_error = @entry.broken
          return false
        end
      end
    rescue Exception
      @last_error = "Can't connect to #{@uri.host} on port #{@uri.port}: #{$!}"
      return false
    end
  end
end

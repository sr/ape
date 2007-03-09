#   Copyright © 2006 Sun Microsystems, Inc. All rights reserved
#   Use is subject to license terms - see file "LICENSE"

require 'net/http'
require 'uri'
require 'atomURI'
require 'entry'
require 'crumbs'

class Poster

  attr_reader :last_error, :response, :entry, :crumbs

  def initialize(uriString, username='', password='')
    @last_error = nil
    @uri = AtomURI.check(uriString)
    @crumbs = Crumbs.new
    if (@uri.class == String)
      @last_error = @uri
    end
    @username = username
    @password = password
    @headers = {}
    @entry = nil
  end

  def header(which)
    @response[which]
  end

  def set_header(name, val)
    @headers[name] = val
  end

  def post(contentType, body)
    req = Net::HTTP::Post.new(AtomURI.on_the_wire(@uri))
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

        if @response.code != '201'
          @last_error = @response.message
          return false
        end

        return true unless @response['Content-type'] =~ %r{^application/atom\+xml}

        begin
          @entry = Entry.new(@response.body)
          return true
        rescue ArgumentError
          @last_error = @entry.broken
          return false
        end
      end
    rescue Exception
      @last_error = "Can't connect: #{$!}"
      return false
    end
  end
end

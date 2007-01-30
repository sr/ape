#   Copyright © 2006 Sun Microsystems, Inc. All rights reserved
#   Use is subject to license terms - see file "LICENSE"

require 'net/http'
require 'uri'
require 'atomURI'
require 'crumbs'

class Deleter

  attr_reader :last_error, :crumbs

  def initialize(uriString, username='', password='')
    @last_error = nil
    @crumbs = Crumbs.new
    @uri = AtomURI.check(uriString)
    if (@uri.class == String)
      @last_error = @uri
    end
    @username = username
    @password = password
  end

  def delete
    req = Net::HTTP::Delete.new(AtomURI.on_the_wire(@uri))
    req.basic_auth(@username, @password) if @username

    begin
      http = Net::HTTP.new(@uri.host, @uri.port)
      http.use_ssl = true if @uri.scheme == 'https'
      http.set_debug_output @crumbs if @crumbs
      http.start do |http|
        @response = http.request(req)
        
        return true if @response.code == '200'

        @last_error = @response.message
        return false
      end
    rescue Exception
      @last_error = "Can't connect: #{$!}"
      return nil
    end
  end
end

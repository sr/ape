require 'rubygems'
require 'mongrel'
require 'ape'

module Ape
  class MongrelHandler < Mongrel::HttpHandler
    def process(request, response)
      cgi = Mongrel::CGIWrapper.new(request, response)

      uri  = cgi['uri'].strip
      user = cgi['username'].strip
      pass = cgi['password'].strip

      invoke_ape uri, user, pass, request, response
  
      if uri.empty?
        response.start(200, true) do |header, body|
          header['Content-Type'] = 'text/plain'
          body << 'URI argument is required'
        end
        return
      end

      format = request.params['HTTP_ACCEPT'] == 'text/plain' ? 'text' : 'html'
      ape = Ape.new({ :crumbs => true, :output => format })
      (user && pass) ? ape.check(uri, user, pass) : ape.check(uri)

      response.start(200, true) do |header, body|
        header['Content-Type'] = 'text/html'
        ape.report(body)
      end
    end
  end
end

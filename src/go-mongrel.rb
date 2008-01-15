#!/usr/bin/env ruby
require 'rubygems'
require 'mongrel'
require 'ape'

class ApeHandler < Mongrel::HttpHandler
  def process(request, response)
    cgi = Mongrel::CGIWrapper.new(request, response)

    uri  = cgi['uri'].strip
    user = cgi['username'].strip
    pass = cgi['password'].strip

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
      ape.report(output=body)
    end
  end
end

port = ARGV.include?('-p') ? ARGV[ARGV.index('-p') + 1] : 4000

h = Mongrel::HttpServer.new('0.0.0.0', port)
h.register('/', Mongrel::RedirectHandler.new('/ape/index.html'))
h.register('/ape', Mongrel::DirHandler.new(File.dirname(__FILE__) + '/layout', true))
h.register('/atompub/go', ApeHandler.new)
h.run.join

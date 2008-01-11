require 'rubygems'
require 'mongrel'
require 'mongrel/handlers'
require 'mongrel/cgi'
require 'cgi'
require 'html'
require 'ape'

class ApeHandler < Mongrel::HttpHandler
  def process(request, response)
    cgi = Mongrel::CGIWrapper.new(request, response)
    
    if !cgi['uri'] || (cgi['uri'] == '')
      response.start(200, true) do |header, body|
        HTML.error("URI argument is required", output=body)
      end
    end

    ape = Ape.new({ :crumbs => true, :output => 'html' })

    if cgi['user'] && cgi['pass']
      ape.check(cgi['uri'], cgi['user'], cgi['pass'])
    else
      ape.check(cgi['uri'])
    end

    response.start(200, true) do |head, body|
      ape.report(output=body)
    end
  end
end

h = Mongrel::HttpServer.new('0.0.0.0', 4000)
#h.register('/', Mongrel::RedirectHandler.new('/ape/index.html'))
h.register('/ape', Mongrel::DirHandler.new(File.dirname(__FILE__) + '/layout', true))
h.register('/atompub/go', ApeHandler.new)
h.run.join

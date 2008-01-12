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

    format = request.params['HTTP_ACCEPT'] == 'text/plain' ? 'text' : 'html'
    ape = Ape.new({ :crumbs => true, :output => format })

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

port = ARGV.include?('-p') ? ARGV[ARGV.index('-p') + 1] : 4000

h = Mongrel::HttpServer.new('0.0.0.0', port)
h.register('/', Mongrel::RedirectHandler.new('/ape/index.html'))
h.register('/ape', Mongrel::DirHandler.new(File.dirname(__FILE__) + '/layout', true))
h.register('/atompub/go', ApeHandler.new)
h.run.join

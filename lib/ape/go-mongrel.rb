#!/usr/bin/env ruby
require 'rubygems'
require 'mongrel'
require 'ape'
require 'optparse'
require 'ostruct'

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
      ape.report(body)
    end
  end
end

defaults = OpenStruct.new
defaults.port = 4000
defaults.host = '0.0.0.0'

options = OptionParser.new do |opts|
  opts.separator " "
  opts.on('-a', '--address ADDRESS', 'Address to bind to', "default: #{defaults.host}") do |host|
    defaults.host = host
  end
  
  opts.on('-p', '--port PORT', 'Port to bind to', "default: #{defaults.port}") do |port|
    defaults.port = port
  end
  
  opts.on('-h', '--help', 'Displays the help') do
    defaults.help = true
  end
end

begin
  options.parse!(ARGV)
rescue OptionParser::ParseError => pe
   msg = ["#{options.program_name}: #{pe}",
      "Try `#{options.program_name} --help` for more information"]
   puts msg.join("\n")
   exit 1
end

if defaults.help
  puts options.to_s
  exit 0
end

mongrel = Mongrel::Configurator.new(:host => defaults.host, :port => defaults.port) do
  log "=> Booting mongrel"
  begin
    log "=> The ape starting on http://#{defaults.host}:#{defaults.port}"
    listener do
      redirect '/', '/ape/index.html'
      uri '/ape', :handler => Mongrel::DirHandler.new(File.dirname(__FILE__) + '/layout', true)
      uri '/atompub/go', :handler => ApeHandler.new    
    end
  rescue Errno::EADDRINUSE
    log "#{options.program_name}: Address (#{defaults.host}:#{defaults.port}) is already in use"
    exit 1
  end
  trap("INT") { stop }
  trap("TERM") { stop }
  log "=> Ctrl-C to shutdown"
  run
end

mongrel.join

require 'optparse'
require 'ostruct'
require 'mongrel'
require 'ape'

module Ape
  class ApeServer
    
    def initialize(args = [])
      args ||= []
      
      @options = defaults
      
      begin
        options_parser.parse!(ARGV)
      rescue OptionParser::ParseError => pe
         msg = ["#{options_parser.program_name}: #{pe}",
            "Try `#{options_parser.program_name} --help` for more information"]
         $stderr.puts msg.join("\n")
         exit 1
      end
    end
    
    def run      
      if @options.help
        $stdout.puts options_parser.to_s
        exit 0
      end

      host = @options.host
      port = @options.port
      mongrel = ::Mongrel::Configurator.new(:host => host, :port => port) do
        log "=> Booting mongrel"
        begin
          log "=> The ape starting on http://#{host}:#{port}"
          listener do
            redirect '/', '/ape/index.html'
            uri '/ape', :handler => ::Mongrel::DirHandler.new(File.dirname(__FILE__) + '/layout', true)
            uri '/atompub/go', :handler => ApeHandler.new    
          end
        rescue Errno::EADDRINUSE
          log "ERROR: Address (#{host}:#{port}) is already in use"
          exit 1
        end
        trap("INT") { stop }
        trap("TERM") { stop }
        log "=> Ctrl-C to shutdown"
        run
      end

      mongrel.join
    end
    
    private    
    def defaults
      defaults = OpenStruct.new
      defaults.port = 4000
      defaults.host = '0.0.0.0'
      defaults
    end
    
    def options_parser
      OptionParser.new do |opts|
        opts.separator " "
        opts.on('-a', '--address ADDRESS', 'Address to bind to', "default: #{defaults.host}") do |host|
          @options.host = host
        end

        opts.on('-p', '--port PORT', 'Port to bind to', "default: #{defaults.port}") do |port|
          @options.port = port
        end

        opts.on('-h', '--help', 'Displays the help') do
          @options.help = true
        end
      end
    end
    
  end
end

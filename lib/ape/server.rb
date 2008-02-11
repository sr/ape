require 'rubygems'
require 'mongrel'
require 'ape/handler'

module Ape
  class Server
    def self.run(options)      
      mongrel = Mongrel::Configurator.new(:host => options[:host], :port => options[:port]) do
        log "=> Booting mongrel"
        begin
          log "=> The ape starting on http://#{options[:host]}:#{options[:port]}"
          listener do
            redirect '/', '/ape/index.html'
            uri '/ape', :handler => Mongrel::DirHandler.new(File.dirname(__FILE__) + '/layout', true)
            uri '/atompub/go', :handler => Handler.new    
          end
        rescue Errno::EADDRINUSE
          log "ERROR: Address (#{options[:host]}:#{options[:port]}) is already in use"
          exit 1
        end
        trap("INT") { stop }
        trap("TERM") { stop }
        log "=> Ctrl-C to shutdown"
        run
      end
      mongrel.join
    end
  end
end

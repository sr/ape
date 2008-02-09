#   Copyright © 2006 Sun Microsystems, Inc. All rights reserved
#   Use is subject to license terms - see file "LICENSE"

module Ape
  class AuthenticationError < StandardError ; end
  
  class Authent  
    def initialize(username, password, scheme=nil)
      @username = username
      @password = password
      @auth_plugin = nil
    end
    
    def add_to(req, authentication = nil)
      return unless @username && @password
      if (authentication)
        if authentication.strip.downcase.include? 'basic'
          req.basic_auth @username, @password
        else
          @auth_plugin = resolve_plugin(authentication) unless @auth_plugin
          @auth_plugin.add_credentials(req, authentication, @username, @password)
        end
      else
        req.basic_auth @username, @password
      end
    end
    
    def resolve_plugin(authentication)
      Dir.glob(File.join(File.dirname(__FILE__), 'auth/*.rb')).each do |file|
        plugin_name = file.gsub(/(.+\/auth\/)(.+)(_credentials.rb)/, '\2').gsub(/_/, '')
        plugin_class = file.gsub(/(.+\/auth\/)(.+)(.rb)/, '\2').gsub(/(^|_)(.)/) { $2.upcase }
        
        if (authentication.strip.downcase.include?(plugin_name))
          return eval("#{plugin_class}.new", binding, __FILE__, __LINE__)
        end
      end
      raise AuthenticationError, "Unknown authentication method: #{authentication}"
    end
  end
end

Dir[File.dirname(__FILE__) + '/auth/*.rb'].each { |l| require l }

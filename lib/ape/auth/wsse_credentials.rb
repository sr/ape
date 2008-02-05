require 'base64'
require 'digest/sha1'

module Ape
  class WsseCredentials
    def initialize
      @credentials = nil
    end
    
    def add_credentials(req, auth, user, password)
      wsse_auth(user, password) unless @credentials
      req['X-WSSE'] = @credentials
      req['Authorization'] = auth
    end
    
    def wsse_auth(user, password)
      nonce = Array.new(10){ rand(0x1000000) }.pack('I*')
      nonce_b64 = [nonce].pack("m").chomp
      now = Time.now.gmtime.strftime("%FT%TZ")
      digest = [Digest::SHA1.digest(nonce_b64 + now + password)].pack("m").chomp

      @credentials = %Q<UsernameToken Username="#{user}", PasswordDigest="#{digest}", Nonce="#{nonce_b64}", Created="#{now}">
    end
  end
end

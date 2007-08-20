#   Copyright © 2006 Sun Microsystems, Inc. All rights reserved
#   Use is subject to license terms - see file "LICENSE"
require 'base64'
require 'digest/sha1'

class Authent
    
  def initialize(username, password, scheme=nil)
    @username = username
    @password = password
  end
  
  def add_to(req, authentication = nil)
    return unless @username && @password
    if (authentication)
      if authentication.strip.include? 'GoogleLogin'
        #GOOGLE LOGIN DQAAAHUAAADmkxEt_8Ke4Yc8o-VHVbRvsosLkkLQVerxE3umRwDXPbvx2kSs-VHC-3WWVQHXgonBHr2FAydmxRsZxXRkE5jG8jm3GHJbumaWwXsC_mDRzSTkQcgaLyoT6kgy34xKlusJGnsOzZ3EG38eiZ8FS0AW8TBQ8B-o6Dpm8hblcNIxzw
        req['Authorization'] = "GoogleLogin auth=#{@username}"
      elsif authentication.strip.include? 'WSSE'
        req['X-WSSE'] = wsse_auth
        req['Authorization'] = authentication
      elsif authentication.strip.include?('Basic')
        req.basic_auth @username, @password
      end
    else
      req.basic_auth @username, @password
    end
  end


  # Known to interoperate with Hiroshi ASAKURA's NTT photo friends
  #  app.
  #
  def wsse_auth

    nonce = Array.new(10){ rand(0x1000000) }.pack('I*')
    nonce_b64 = [nonce].pack("m").chomp
    now = Time.now.gmtime.strftime("%FT%TZ")
    digest = [Digest::SHA1.digest(nonce_b64 + now + @password)].pack("m").chomp

    %Q<UsernameToken Username="#{@username}", PasswordDigest="#{digest}", Nonce="#{nonce_b64}", Created="#{now}">
  end

end

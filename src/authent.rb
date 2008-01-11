#   Copyright © 2006 Sun Microsystems, Inc. All rights reserved
#   Use is subject to license terms - see file "LICENSE"
require 'base64'
require 'digest/sha1'
require 'net/http'
require 'net/https'
require 'cgi'

GOOGLE_ERROR_MESSAGES = {
  "BadAuthentication" =>  "The login request used a username or password that is not recognized.",
  "NotVerified" =>        "The account email address has not been verified. The user will need to access their Google account directly to resolve the issue before logging in using a non-Google application.",
  "TermsNotAgreed" =>     "The user has not agreed to terms. The user will need to access their Google account directly to resolve the issue before logging in using a non-Google application.",
  "CaptchaRequired" =>    "Please visit https://www.google.com/accounts/DisplayUnlockCaptcha to enable access.",
  "Unknown" =>            "The error is unknown or unspecified; the request contained invalid input or was malformed.",
  "AccountDeleted" =>     "The user account has been deleted.",
  "AccountDisabled" =>    "The user account has been disabled.",
  "ServiceDisabled" =>    "The user's access to the specified service has been disabled. (The user account may still be valid.)",
  "ServiceUnavailable" => "The service is not available; try again later.",
}

class GoogleLoginAuthError < StandardError 
end
class GoogleLoginAuthUnknownError < GoogleLoginAuthError 
end

class Authent
    
  def initialize(username, password, scheme=nil)
    @username = username
    @password = password
    @authtoken = nil
  end
  
  def parse_www_authenticate(authenticate)
    # Returns a dictionary of dictionaries, one dict
    # per auth-scheme. The dictionary for each auth-scheme
    # contains all the auth-params.
    retval = {}
    authenticate.chomp()
    # Break off the scheme at the beginning of the line
    auth_scheme, the_rest = authenticate.split(/ /, 2)
    puts auth_scheme
    puts "------------"
    # Now loop over all the key value pairs that come after the scheme
    keyvalues = the_rest.split(/[ ,]/)
    auth_params = {}
    keyvalues.each do |keyvalue|
      puts "--" + keyvalue + "--"
      if keyvalue.include?("=")
        key, value = keyvalue.split(/=/, 2)
        if value.scan(/^\"/).size > 0
          value = value.strip()[1..-2]
        end
        auth_params[key.downcase()] = value.gsub(/\\(.)/, "\\1")
      elsif keyvalue.size > 0 
        retval[auth_scheme.downcase()] = auth_params
        auth_scheme = keyvalue
        auth_params = {}
      end
    end
    retval[auth_scheme.downcase()] = auth_params
    return retval
  end

  def googlelogin(name, password, useragent, challenge)
    service = challenge['googlelogin']['service']

    h = Net::HTTP.new('www.google.com', 443)
    h.use_ssl = true
    params = {'Email'=>name, 'Passwd'=>password, 'service'=>service, 'source'=>useragent}
    data = params.map {|k,v| "#{CGI::escape(k.to_s)}=#{CGI::escape(v.to_s)}" }.join('&') 
    puts data
    res = h.request_post('/accounts/ClientLogin', data, {'Content-Type' => 'application/x-www-form-urlencoded'})
    d = {}
    res.body.split(/\n/).each do |keyvalue|
      key, value = keyvalue.split(/=/)
      d[key] = value
    end
    auth = ""
    if res == Net::HTTPForbidden 
      if d.has_key?('Error')
        errorname = d['Error']
        if GOOGLE_ERROR_MESSAGES.has_key?(errorname)
          raise GoogleLoginAuthError, GOOGLE_ERROR_MESSAGES[errorname]
        else
          raise GoogleLoginAuthUnknownError, errorname
        end
      else
        raise res.error!
      end
    else
      auth = d['Auth']
    end
    return auth
  end
    
  def add_to(req, authentication = nil)
    return unless @username && @password
    if (authentication)
      auth = authentication.strip.downcase
      if auth.include? 'googlelogin'
        if @authtoken == nil
          challenge = parse_www_authenticate(authentication)
          @authtoken = googlelogin(@username, @password, 'ruby-ape-1.0', challenge)
        end
        req['Authorization'] = "GoogleLogin auth=#{@authtoken}"
      elsif auth.include? 'wsse'
        req['X-WSSE'] = wsse_auth
        req['Authorization'] = authentication
      elsif auth.include? 'basic'
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

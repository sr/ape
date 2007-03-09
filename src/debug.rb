#   Copyright © 2006 Sun Microsystems, Inc. All rights reserved
#   Use is subject to license terms - see file "LICENSE"

require 'cgi'
require 'html'
require 'ape'

cgi = CGI.new "html4"

if !cgi['uri'] || (cgi['uri'] == '')
  HTML.error "URI argument is required"
end

uri = cgi['uri']
user = cgi['username']
pass = cgi['password']

ape = Ape.new({ :crumbs => true, :output => 'html',
              :debug => true })

if user == ''
  ape.check(uri)
else
  ape.check(uri, user, pass)
end
ape.report





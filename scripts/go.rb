$:.unshift(File.join(File.dirname(__FILE__), %w[.. lib]))

require 'cgi'
require 'html'
require 'ape'

cgi = CGI.new 

if !cgi['uri'] || (cgi['uri'] == '')
  HTML.error "URI argument is required"
end

uri = cgi['uri']
user = cgi['username']
pass = cgi['password']

ape = Ape::Ape.new({ :crumbs => true, :output => 'html' })

if user == ''
  ape.check(uri)
else
  ape.check(uri, user, pass)
end
ape.report





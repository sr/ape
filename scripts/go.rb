$:.unshift File.dirname(__FILE__) + '/../lib'
require 'cgi'
require 'html'
require 'ape'

debug = ENV['APE_DEBUG'] || false

cgi = debug ? CGI.new('html4') : CGI.new 

if !cgi['uri'] || (cgi['uri'] == '')
  HTML.error "URI argument is required"
end

uri = cgi['uri']
user = cgi['username']
pass = cgi['password']

ape = Ape::Ape.new({:crumbs => true, :output => 'html', :debug => debug})

if user == ''
  ape.check(uri)
else
  ape.check(uri, user, pass)
end
ape.report





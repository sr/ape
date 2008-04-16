require 'rubygems'
require 'spec'
require 'rack/mock'

$:.unshift 'lib/', File.dirname(__FILE__) + '/../lib'
require 'ape/samples'
require 'ape/validators/entry_posting'

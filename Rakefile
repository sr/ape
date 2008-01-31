# -*- ruby -*-

require 'rubygems'
require 'hoe'
require './lib/ape.rb'

Hoe.new('ape', Ape::VERSION::STRING) do |p|
  p.rubyforge_name = 'ape'
  p.extra_deps = {'mongrel' => '>=1.1.3'}
  # p.author = 'FIX'
  # p.email = 'FIX'
  # p.summary = 'FIX'
  # p.description = p.paragraphs_of('README.txt', 2..5).join("\n\n")
  # p.url = p.paragraphs_of('README.txt', 0).first.split(/\n/)[1..-1]
  p.changes = p.paragraphs_of('History.txt', 0..1).join("\n\n")
end

desc 'Install the package as a gem, without generating documentation(ri/rdoc)'
task :install_gem_no_doc => [:clean, :package] do
  sh "#{'sudo ' unless Hoe::WINDOZE }gem install pkg/*.gem --no-rdoc --no-ri"
end

# vim: syntax=Ruby

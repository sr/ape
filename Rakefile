require File.dirname(__FILE__) + '/lib/ape/version'

begin
  require 'rubygems'
  require 'echoe'
  Echoe.new('ape', Ape::VERSION::STRING) do |p|
    p.rubyforge_name = 'ape'
    p.summary = 'A tool to exercice AtomPub server.'
    p.url = 'http://www.tbray.org/ongoing/misc/Software#p-4' 
    p.author = 'Tim Bray'
    p.email = 'tim.bray@sun.com'
    p.dependencies << 'builder >=2.1.2'
    p.extra_deps = ['mongrel >=1.1.3']
    p.test_pattern = 'test/unit/*.rb'
  end
rescue LoadError => boom
  puts 'You are missing a dependency required for meta-operations on this gem.'
  puts boom.to_s.capitalize
end

desc 'Install the package as a gem, without generating documentation(ri/rdoc)'
task :install_gem_no_doc => [:clean, :package] do
  sh "#{'sudo ' unless Hoe::WINDOZE }gem install pkg/*.gem --no-rdoc --no-ri"
end


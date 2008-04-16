require 'rubygems'
require 'rake'
require 'spec/rake/spectask'

task :default => 'spec'
desc 'Run specs'
Spec::Rake::SpecTask.new do |t|
  t.spec_opts = ['--format', 'specdoc', '--colour', '--diff']
end

desc 'Generate coverage reports'
Spec::Rake::SpecTask.new('spec:coverage') do |t|
  t.rcov = true
end

desc 'Generate a nice HTML report of spec results'
Spec::Rake::SpecTask.new('spec:report') do |t|
  t.spec_opts = ['--format', 'html:report.html', '--diff']
end

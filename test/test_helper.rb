$:.unshift File.dirname(__FILE__)
$:.unshift(File.join(File.dirname(__FILE__), %w[.. lib]))

require 'test/unit'
require 'ape'

def load_test_dir(dir)
  Dir[File.join(File.dirname(__FILE__), dir, "*.rb")].each do |file|
    require file
  end
end

module Writer
  def response=(response)
    @response = response
  end
end

Ape::Invoker.send(:include, Writer)
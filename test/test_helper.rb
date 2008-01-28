require 'test/unit'
require File.dirname(__FILE__) + '/../src/atomURI'
require File.dirname(__FILE__) + '/../src/authent'
require File.dirname(__FILE__) + '/../src/invoker'

module Writer
  def response=(response)
    @response = response
  end
end

Invoker.send(:include, Writer)
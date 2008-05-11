require 'rubygems'
require 'spec'
require 'rack/mock'

$:.unshift 'lib/', File.dirname(__FILE__) + '/../lib'
require 'ape/samples'
require 'ape/validators/entry_posting'

require File.dirname(__FILE__) + '/custom_matchers'
include CustomApeMatchers

# Ninja-patch Rack::MockResponse so it looks like an Net::HTTPResponse
class Rack::MockResponse
  alias :code :status
end

# http://blog.moertel.com/articles/2007/02/07/ruby-1-9-gets-handy-new-method-object-tap
class Object
  def tap
    yield(self)
    self
  end
end

module EntryPostingValidatorHelpers
  def do_validate
    @validator.run
  end

  def successful_response
    [201, {
      'Location'      => 'http://test.host/entries/1',
      'Content-Type'  => 'application/atom+xml;type=entry'
    }, [Ape::Samples.basic_entry.to_s]]
  end

  def response_for(what)
    response = case what
    when :successful
      successful_response
    when :unsuccessful
      successful_response.tap { |response| response[0] = 500 }
    when :no_location_header
      successful_response.tap do |response|
        response[1].reject! { |k, v| k == 'Location' }
      end
    when :incorrect_content_type
      successful_response.tap do |response|
        response[1].update('Content-Type' => 'application/xml')
      end
    when :no_content_type
      successful_response.tap do |response|
        response[1].reject! { |k, v| k == 'Content-Type' }
      end
    when :not_well_formed_entry
      successful_response.tap do |response|
        response.last[0] = '<fooo><bar>'
      end
    else
      raise ArgumentError
    end 
    app = lambda { |env| response }
    env = Rack::MockRequest.env_for(uri='/entries', :method => 'POST')
    Rack::MockResponse.new(*app.call(env))
  end

  def set_response!(response)
    @response = response_for(response)
    @http.stub!(:request).and_return(@response)
  end

  def with_response(response)
    set_response!(response)
    yield
    do_validate
  end
end

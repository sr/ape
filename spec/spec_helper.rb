require 'rubygems'
require 'spec'
require 'rack/mock'

$:.unshift 'lib/', File.dirname(__FILE__) + '/../lib'
require 'ape/samples'
require 'ape/validators/entry_posting'

# Ninja-patch Rack::MockResponse so it looks like an Net::HTTPResponse
class Rack::MockResponse
  alias :code :status
end

module EntryPostingValidatorHelpers
  def do_validate
    @validator.run
  end

  def successful_response
    [201, {'Location' => 'http://test.host/entries/1'}, [Ape::Samples.basic_entry.to_s]]
  end

  def response_for(what)
    response = case what
    when :successful
      successful_response
    when :unsuccessful
      r = successful_response
      r[0] = 500
      r
    when :no_location_header
      # TODO: err, there must be a non-ugly way to do that
      r = successful_response
      r[1].reject! { |k, v| k == 'Location' }
      r
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

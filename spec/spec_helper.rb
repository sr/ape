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

def should_report(type, message)
  @validator.reporter.should_receive(:call).with(@validator, type, message)
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
    when :divergent_returned_entry
      successful_response.tap do |response|
        response.last[0] = Atom::Entry.new.tap do |entry|
          entry.summary = 'blah'
          entry.content = %q{
            <p>A test post from the &lt;APE&gt</p>
            <p>If you see this in an entry, it's probably a left-over from an
            unsuccessful Ape run; feel free to delete it.</p>
          }
        end.tap { |e| e.content['type'] = 'html' }.to_s
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

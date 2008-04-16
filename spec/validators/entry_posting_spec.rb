require File.dirname(__FILE__) + '/../spec_helper'

describe 'When testing entry POSTing' do
  def do_validate
    @validator.run
  end

  def successful_response
    [201, {'Location' => '/entries/1'}, [Ape::Samples.basic_entry.to_s]]
  end

  def response_for(what)
    response = case what
    when :successful
      successful_response
    when :unsuccessful_posting
      [500, {}, ['']] 
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
  
  before(:each) do
    @options = {:host => 'test.host', :port => '80', :collection => '/entries'}
    @reporter = mock('Ape::Reporter', :call => 1)
    @validator = Ape::Validator::EntryPosting.new(@options)
    @validator.stub!(:reporter).and_return(@reporter)

    @http = mock('Net::HTTP')
    @request = mock('Net::HTTP::Post', :set_content_type => 1)
    Net::HTTP.stub!(:new).and_return(@http)
    Net::HTTP::Post.stub!(:new).and_return(@request)

    set_response!(:successful)
  end

  describe 'The POST request' do
    it 'should connect to the server with given options' do
      Net::HTTP.should_receive(:new).with('test.host', '80').and_return(@http)
      do_validate
    end

    it 'should perform POST request to given collection URI' do
      Net::HTTP::Post.should_receive(:new).with('/entries').and_return(@request)
      do_validate
    end

    it 'should perform POST request with right  Content-Type header' do
      @request.should_receive(:set_content_type).with('application/atom+xml;type=entry')
      do_validate
    end

    it 'should perform POST request with the right sample as its body' do
      @http.should_receive(:request).with(@request, Ape::Samples.basic_entry.to_s).and_return(@response)
      do_validate
    end
  end

  describe 'Notifices reporting' do
    it 'should notify we are testing basic entry-posting features' do
      @reporter.should_receive(:call).with(@validator, :notice, 'Testing entry-posting basics.')
      do_validate
    end

    it 'should notify we are trying to post a new entry' do
      @reporter.should_receive(:call).with(@validator, :notice, 'Posting new entry.')
      do_validate
    end
  end

  describe 'Fatal errors reporting' do
    it "should report that we can't connect to the given address" do
      @http.should_receive(:request).and_raise(SocketError)
      @reporter.should_receive(:call).with(@validator, :fatal, "Can't connect to test.host on port 80.")
      do_validate
    end
  end

  describe 'Errors reporting' do
    it "should report an error if creation of the new entry isn't successfull (aka response code is not 201)" do
      @response.stub!(:code).and_return(500)
      @reporter.should_receive(:call).with(@validator, :error, "Can't post new entry.")
      do_validate
    end

    it 'should report an error if there is no Location header in the response' do
      with_response(:no_location_header) do
        @reporter.should_receive(:call).with(@validator, :error, 'No Location header upon POST creation.')
      end
    end
  end

  it 'should report unacceptable URI' # I don't undertand what that mean
end
__END__
  it 'should report there was not return Location header in response' do
    response_without(:header) do
      @report.should_receive(:call).with(@validator, :error, 'No Location header upon POST creation')
      do_validate
    end
  end

  it "should report that POSTing was successful and display entry's Location header" do
    response_with(:header) do
      @report.should_receive(:call).with(@validator, :success, "Posting of new entry to the Entries collection \
        was successful. Entry's Location: /foo")
      do_validate
    end
  end
end

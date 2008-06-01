require File.dirname(__FILE__) + '/../spec_helper'

# TODO: 
# - custom matchers for notify, error
describe 'When testing entry POSTing' do
  include EntryPostingValidatorHelpers

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

  it 'should notify we are testing basic entry-posting features' do
    @reporter.should_receive(:call).with(@validator, :notice, 'Testing entry-posting basics.')
    do_validate
  end

  it 'should report unacceptable URI' # I don't undertand what that mean

  describe 'The POST request' do
    it 'should connect to the server with given options' do
      Net::HTTP.should_receive(:new).with('test.host', '80').and_return(@http)
      do_validate
    end

    it 'should perform POST request to given collection URI' do
      Net::HTTP::Post.should_receive(:new).with('/entries').and_return(@request)
      do_validate
    end

    it 'should perform POST request with right Content-Type header' do
      @request.should_receive(:set_content_type).with('application/atom+xml;type=entry')
      do_validate
    end

    it 'should perform POST request with the right sample as its body' do
      @http.should_receive(:request).with(@request, Ape::Samples.basic_entry.to_s).and_return(@response)
      do_validate
    end
  end

  describe 'When unable to reach the server' do
    before(:each) do
      @http.should_receive(:request).and_raise(SocketError)
    end

    it 'should report a fatal error' do
      should_report(:fatal, "Can't connect to test.host on port 80.")
      do_validate
    end

    it 'should end the validation process' do
      do_validate.should be_false
    end
  end

  describe 'When posting the entry' do
    it 'should notify we are trying to post a new entry' do
      should_report(:notice, 'Posting new entry.')
      do_validate
    end

    it "should report an error and end the validation process if creation of the new entry isn't successfull" do
      with_response(:unsuccessful) do
        should_report(:error, "Can't post new entry.")
      end.should be_false
    end

    it 'should report an error and end the validation process if there is no Location header in the response' do
      with_response(:no_location_header) do
        should_report(:error, 'No Location header upon POST creation.')
      end.should be_false
    end

    it 'should report an error if there is no Content-Type' do
      with_response(:no_content_type) do
        should_report(:error, 'Incorrect Content-Type.')
      end
    end

    it 'should report an error if the returned Content-Type is incorrect' do
      with_response(:incorrect_content_type) do
        should_report(:error, 'Incorrect Content-Type.')
      end
    end
  end

  describe 'When examining the returned entry (as returned in the POST response)' do
    it 'should notify we are examining the returned entry' do
      should_report(:notice, 'Examining the new entry as returned in the POST response')
      do_validate
    end

    it "should report an error and end the validation process if the returned entry isn't valid" do
      with_response(:not_well_formed_entry) do
        should_report(:error, 'New entry is not well-formed')
      end.should be_false
    end

    it 'should report a correct behavior if the entry is the same' do
      should_report(:correct, 'Returned entry is consistent with posted entry.')
      do_validate
    end

    it "should report an error if the returned entry isn't the same as the one we posted" do
      with_response(:divergent_returned_entry) do
        should_report(:error, 'Returned entry is inconsistent with posted entry.')
        should_report(:error, 'title element is missing.')
        should_report(:error, 'content element has type "html" but it should be "xhtml".')
        should_report(:error, /summary element is ".*" but it should be ".*"./)
      end
    end

    it 'should report a correct behavior if the provided category is in response' do
      should_report(:correct, 'Provided categories included in returned entry.')
      do_validate
    end

    it 'should report an error if one of the provided category is missing' do
      with_response(:missing_category) do
        should_report(:error, "Category <category term='simians' scheme='http://tbray.org/cat-test' xmlns='http://www.w3.org/2005/Atom'/> is missing.")
      end
    end

    it 'should report a correct behavior if the foreign markup has been preserved'
    it 'should report an error if the foreign markup has been altered'
    it 'should report an error if the foreign markup has been discarded'
  end

  describe 'When examining the new entry as retrieved using Location header in POST response' do
    it 'should notify we are examining the new entry'
    it "should report an error if the URI isn't accessible"
    it 'should report a correct behavior if the entry is server with the right Content-Type'
    it "should report an error if the new entry isn't served with the correct Content-Type"
    it "should report an error and end the validation process if the entry isn't valid"
    it 'should report a correct behavior if the entry is the same'
    it "should report an error if the returned entry isn't the same as the one we posted"
    it 'should report a correct behavior if the provoded category is included in the new entry'
    it 'should report an error if one of the provided category is missing'
    it 'should report a correct behavior if the foreign markup has been preserved'
    it 'should report an error if the foreign markup has been altered'
    it 'should report an error if the foreign markup has been discarded'
    it 'should report an error unless the slug we provided was used'
    it 'should report a correct behavior if the slug we provided was used'
  end
end

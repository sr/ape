require File.dirname(__FILE__) + '/../test_helper.rb'

class AuthentTest < Test::Unit::TestCase
  def setup
    @authent = Authent.new('david', 'my secret password')
  end
  
  def test_assert_raise_auth_error
    assert_raise(AuthenticationError) { load_plugin("Oauth") }
  end
  
  def test_assert_load_wsse_plugin
    assert_not_nil(load_plugin("Wsse"))
  end
  
  def test_assert_load_google_login_plugin
    assert_not_nil(load_plugin("GoogleLogin"))
  end
  
  #def test_assert_add_google_login_credentials_not_fail
  #  @authent.add_to(Net::HTTP::Get.new('/'), 'GoogleLogin')
  #end
  
  def test_assert_add_wsse_credentials_not_fail
    assert_nothing_raised(Exception) {
      @authent.add_to(Net::HTTP::Get.new('/'), 'Wsse')
    }
  end
  
  def load_plugin(plugin_name)
    @authent.resolve_plugin(plugin_name)
  end
  
  
end
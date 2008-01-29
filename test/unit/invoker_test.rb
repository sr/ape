require File.dirname(__FILE__) + '/../test_helper.rb'

class InvokerTest < Test::Unit::TestCase
  
  def setup
    @invoker = Invoker.new("http://localhost", Authent.new('david', 'mypassword'))
    unauthorized = Net::HTTPUnauthorized.new(401, '1.1', '')
    unauthorized['WWW-Authenticate'] = 'Wsse'
    @invoker.response = unauthorized
  end
  
  def test_assert_need_athentication_avoids_infinite_loops
      (1..5).each do |x|
        if x > 2
          assert_raise(AuthenticationError) {
            @invoker.need_authentication?(Net::HTTP::Get.new('/'))
          }
        else
          assert_nothing_raised(AuthenticationError) {  
            @invoker.need_authentication?(Net::HTTP::Get.new('/'))
          }
        end
      end
  end
end
require File.dirname(__FILE__) + '/../test_helper.rb'

require 'rexml/document'
class SamplesTest < Test::Unit::TestCase
  
  def test_ape_home
    assert_equal('/Users/david/.ape', Ape::Samples.ape_home)
  end
  
  def test_load_mini_entry
    doc = REXML::Document.new(Ape::Samples.mini_entry)
    assert_not_nil(REXML::XPath.first(doc.root, './id'))
  end
  
  def test_load_basic_entry
    doc = REXML::Document.new(Ape::Samples.basic_entry)
    assert_not_nil(REXML::XPath.first(doc.root, './summary'))
  end
  
  def test_load_unclean_xhtml_entry
    doc = REXML::Document.new(Ape::Samples.unclean_xhtml_entry)
    assert_not_nil(REXML::XPath.first(doc.root, './id'))
  end
end
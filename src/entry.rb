#   Copyright © 2006 Sun Microsystems, Inc. All rights reserved
#   Use is subject to license terms - see file "LICENSE"

require 'rexml/document'
require 'rexml/xpath'
require 'atomURI'
require 'cgi'

# represents an Atom Entry
class Entry

  # @element is the REXML dom
  # @base is the base URI if known
  @@atomNamespace = 'http://www.w3.org/2005/Atom'
  @@atomNS = { 'atom' => @@atomNamespace }

  def initialize(node, uri = nil)
    if node.class == String
      @element = REXML::Document.new(node, { :raw => nil }).root
    else
      @element = node
    end
    if uri
      @base = AtomURI.new(uri)
    else
      @base = nil
    end
  end

  def to_s
    @element.to_s
  end

  def content_src
    content = REXML::XPath.first(@element, './atom:content', @@atomNS)
    if content
      content.attributes['src']
    else
      nil
    end
  end

  def get_child(field, namespace = nil)
    if (namespace)
      thisNS = {}
      thisNS['atom'] = @@atomNamespace
      prefix = 'NN'
      thisNS[prefix] = namespace
    else
      prefix = 'atom'
      thisNS = @@atomNS
    end
    xpath = "./#{prefix}:#{field}"
    return REXML::XPath.first(@element, xpath, thisNS)
  end

  def child_type(field)
    n = get_child(field, nil)
    (n) ? n.attributes['type'] : nil
  end
  
  def child_content(field, namespace = nil)
    n = get_child(field, namespace)
    (n) ? text_from(n) : nil
  end
    
  def text_from node
    text = ''
    is_html =
      node.name =~ /(rights|subtitle|summary|title|content)$/ &&
      node.attributes['type'] == 'html'
    node.find_all do | child |
      if child.kind_of? REXML::Text
        v = child.value
        v = CGI.unescapeHTML(v).gsub(/&apos;/, "'") if is_html
        text << v
      elsif child.kind_of? REXML::Element
        text << text_from(child)
      end
    end
    text
  end

  def link(rel)
    a = REXML::XPath.first(@element, "./atom:link[@rel=\"#{rel}\"]", @@atomNS)
    if a
      l = a.attributes['href']
      l = @base.absolutize(l, @element) if @base
    else
      nil
    end
  end

  def summarize
    child_content('title')
  end

  # debugging
  def Entry.dump(node, depth=0)
    prefix = '.' * depth
    name = node.getNodeName
    uri = node.getNamespaceURI
    if uri
      puts "#{prefix} #{uri}:#{node.getNodeName}"
    else
      puts "#{prefix} #{node.getNodeName}"
    end
    Nodes.each_node(node.getChildNodes) {|child| dump(child, depth+1)}
    
  end
  
end

#   Copyright © 2006 Sun Microsystems, Inc. All rights reserved
#   Use is subject to license terms - see file "LICENSE"

require 'rexml/document'
require 'rexml/xpath'

class Feed

  @@atomNS = { 'atom' => 'http://www.w3.org/2005/Atom' }

  def initialize(input, uri)
    @uri = uri
    error = "Feed document not well-formed"
    begin
      @element = REXML::Document.new(input, { :raw => nil })
    rescue Exception
      error = $!.to_s
      @element = nil
    end
    if !@element
      raise(ArgumentError, error)
    end
    @element = @element.root
  end

  def entries
    REXML::XPath.each(@element, '//atom:entry', @@atomNS) do |node|
      yield Entry.new(node, @uri)
    end
  end

end


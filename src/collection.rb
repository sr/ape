#   Copyright © 2006 Sun Microsystems, Inc. All rights reserved
#   Use is subject to license terms - see file "LICENSE"

require 'rexml/xpath'
require 'atomURI'
require 'names'

class Collection 

  attr_reader :title, :accept, :href

  def initialize(input, doc_uri = nil)
    @input = input
    @accept = []
    @title = REXML::XPath.first(input, './atom:title', Names::XmlNamespaces)

    # sigh, RNC validation *should* take care of this
    unless @title
      raise(SyntaxError, "Collection is missing required 'atom:title'")
    end
    @title = @title.texts.join

    if doc_uri
      uris = AtomURI.new(doc_uri)
      @href = uris.absolutize(input.attributes['href'], input)
    else
      @href = input.attributes['href']
    end

    # now we have to go looking for the accept
    @accept = []
    REXML::XPath.each(input, './app:accept', Names::XmlNamespaces) do |a|
      @accept << a.texts.join
    end

    if @accept.empty?
      @accept = [ Names::AtomEntryMediaType ]
    end
  end

  def to_s
    @input.to_s
  end

  def to_str
    to_s
  end

  # the name is supposed to suggest multiple instances of "categories"
  def catses
    REXML::XPath.match(@input, './app:categories', Names::XmlNamespaces)
  end

end

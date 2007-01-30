#   Copyright © 2006 Sun Microsystems, Inc. All rights reserved
#   Use is subject to license terms - see file "LICENSE"

require 'uri'

class AtomURI

  def initialize base_uri
    if base_uri.kind_of? URI
      @base = base_uri
    else
      @base = URI.parse base_uri
    end
  end

  # Given a URI pulled out of the middle of an XML doc ('context' provides
  #  containing element) absolutize it if it's relative, with proper regard
  #  for xml:base 
  #
  def absolutize uri, context
    uri = URI.parse uri
    return uri if uri.absolute?
    
    path_base = @base
    path_to(context).each do |node|
      if (xb = node.attributes['xml:base'])
        xb = URI.parse xb
        if xb.absolute? then path_base = xb else path_base.merge! xb end
      end
    end

    path_base.merge uri
  end

  def path_to node
    if node.class == REXML::Element
      path_to(node.parent) << node
    else
      [ ]
    end
  end
  
  def AtomURI.check(uri_string)
    if uri_string.kind_of? URI
      uri = uri_string
    else
      begin
        uri = URI.parse(uri_string)
      rescue URI::InvalidURIError
        return "Invalid URI: #{$!}"
      end
    end

    unless uri.scheme =~ /^https?$/ 
      return "URI scheme must be 'http' or 'https', not '#{uri.scheme}'"
    else
      return uri
    end
  end

  def AtomURI.on_the_wire uri
    if uri.query
      "#{uri.path}?#{uri.query}"
    else
      uri.path
    end
  end


end

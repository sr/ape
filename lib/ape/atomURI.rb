#   Copyright (c) 2006 Sun Microsystems, Inc. All rights reserved
#   Use is subject to license terms - see file "LICENSE"
require 'uri'

module Ape
  # Represents an Atom URI and encapsulates Atom-specific URI helpers.
  class AtomURI

    # call-seq:
    #   AtomURI.new('http://...') => object
    #   AtomURI.new(uri) => object
    #
    # Creates a new instance using +base_uri+.
    #
    # ==== Options
    #  * base_uri - a URI string or object. If a string is passed, URI.parse is used for conversion. Required.
    def initialize(base_uri)
      if base_uri.kind_of? URI
        @base = base_uri
      else
        @base = URI.parse base_uri
      end
    end

    # Given a URI string from an XML document and its containing element,
    # absolutize it if it's relative, with proper regard for xml:base. 
    # Returns the absolute URI, or nil on failure.
    #
    # ==== Options
    #   * uri_s   - The URI string to be made absolute. Required.
    #   * context - The containing element, inside which uri_s is found. Required.
    def absolutize(uri_s, context)
      begin
        uri = URI.parse uri_s
        return uri_s if uri.absolute?

        path_base = @base
        path_to(context).each do |node|
          if (xb = node.attributes['xml:base'])
            xb = URI.parse xb
            if xb.absolute? then path_base = xb else path_base.merge! xb end
          end
        end

        return path_base.merge(uri).to_s
      rescue URI::InvalidURIError
        return nil
      end
    end

    # call-seq:
    #   path_to(element) => array
    #
    # Returns an array containing each successive element in the path from
    # the root node to +element+.
    #
    # ==== Options
    #   * element - The REXML::Element object to path-find.
    def path_to(node)
      if node.class == REXML::Element
        path_to(node.parent) << node
      else
        [ ]
      end
    end
    
    # call-seq:
    #   AtomURI.check('http://...') => string
    #
    # Validates that +uri_string+ is well-formed and uses a supported scheme.
    # Returns +uri_string+ if successful or an error message on failure.
    #
    # ==== Options
    #   * uri_string - A URI string or object to check for correctness. Required.
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

    # call-seq:
    #   AtomURI.on_the_wire(uri) => string
    #
    # Returns +uri+ in the proper format for Net::HTTPRequest and friends.
    #
    # ==== Options
    #   * uri - a URI object (*not* a string). Required.
    def AtomURI.on_the_wire(uri)
      if uri.query
        "#{uri.path}?#{uri.query}"
      else
        uri.path
      end
    end
  end
end

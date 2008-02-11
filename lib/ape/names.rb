#   Copyright © 2006 Sun Microsystems, Inc. All rights reserved
#   Use is subject to license terms - see file "LICENSE"

module Ape
  module Names
    AtomNamespace = 'http://www.w3.org/2005/Atom' unless defined?(AtomNamespace)
    AppNamespace = 'http://www.w3.org/2007/app' unless defined?(AppNamespace)
    DcNamespace = 'http://purl.org/dc/elements/1.1/' unless defined?(DcNamespace)
    XhtmlNamespace = 'http://www.w3.org/1999/xhtml' unless defined?(XhtmlNamespace)
    XmlNamespaces = {
      'app' => AppNamespace,
      'atom' =>  AtomNamespace,
      'dc' => DcNamespace,
      'xhtml' => XhtmlNamespace
    } unless defined?(XmlNamespaces)
    
    AtomMediaType = 'application/atom+xml' unless defined?(AtomMediaType)
    AtomEntryMediaType = 'application/atom+xml;type=entry' unless defined?(AtomEntryMediaType)
    AppMediaType = 'application/atomsvc+xml' unless defined?(AppMediaType)

  end
end



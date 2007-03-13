#   Copyright © 2006 Sun Microsystems, Inc. All rights reserved
#   Use is subject to license terms - see file "LICENSE"

module Names
  AtomNamespace = 'http://www.w3.org/2005/Atom'
  AppNamespace = 'http://purl.org/atom/app#'
  DcNamespace = 'http://purl.org/dc/elements/1.1/'
  XhtmlNamespace = 'http://www.w3.org/1999/xhtml'
  XmlNamespaces = {
    'app' => AppNamespace,
    'atom' =>  AtomNamespace,
    'dc' => DcNamespace,
    'xhtml' => XhtmlNamespace
  }
  
  AtomMediaType = 'application/atom+xml'
  AppMediaType = 'application/atomsvc+xml'

end



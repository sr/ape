#   Copyright © 2006 Sun Microsystems, Inc. All rights reserved
#   Use is subject to license terms - see file "LICENSE"

require 'rexml/xpath'
require 'collection'
require 'namespaces'

class Service

  def Service.collections(service, uri)
    nodes = REXML::XPath.match(service, '//app:collection', $appNS)
    nodes.collect { |n| Collection.new(n, uri) }
  end

end

#   Copyright © 2006 Sun Microsystems, Inc. All rights reserved
#   Use is subject to license terms - see file "LICENSE"

# this is a wrapper for the weird derived-from-PrintWriter class that comes
#  out of HttpResponse.getWriter

module Ape
class Printwriter

  def initialize(java_writer)
    @w = java_writer
  end

  def puts(s)
    @w.println s 
  end

  def << (s)
    @w.print s
  end

end
end

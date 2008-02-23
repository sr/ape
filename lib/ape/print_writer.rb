# Copyright (c) 2006 Sun Microsystems, Inc. All rights reserved
# See the included LICENSE[link:/files/LICENSE.html] file for details.
module Ape
  # this is a wrapper for the weird derived-from-PrintWriter class that comes
  # out of HttpResponse.getWriter
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

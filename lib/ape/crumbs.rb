#   Copyright (c) 2006 Sun Microsystems, Inc. All rights reserved
#   Use is subject to license terms - see file "LICENSE"

# All the methods (getter/poster/putter/deleter) use the set_debug_output method
#  of Net::HTTP to capture the dialogue.  This class is what gets passed to
#  set_debug_output; it exists to define << to save only the interesting bits
#  of the dialog.
#
module Ape
  class Crumbs
    def initialize
      @crumbs = []
      @keep_next = false
    end

    def grep(pattern)
      @crumbs.grep(pattern)
    end

    def << data
      if @keep_next
        @crumbs << "> #{data}"
        @keep_next = false
      elsif data =~ /^->/
        @crumbs << "< #{data.gsub(/^.../, '')}"
      elsif data =~ /^<-/
        @keep_next = true
      end
    end

    def each
      @crumbs.each { |c| yield c }
    end

    def to_s
      "  " + @crumbs.join("...\n")
    end
  end
end

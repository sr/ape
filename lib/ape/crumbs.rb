#   Copyright (c) 2006 Sun Microsystems, Inc. All rights reserved
#   Use is subject to license terms - see file "LICENSE"

module Ape
  
  # All descendants of Invoker use Net::HTTP::set_debug_output
  # to capture the dialogue. This class is what gets passed to
  # set_debug_output; it exists to define #<< to save only the interesting bits
  # of the dialog.
  class Crumbs
    
    def initialize #:nodoc:
      @crumbs = []
      @keep_next = false
    end

    # call-seq:
    #   crumbs.grep(pattern) => array
    #
    # Returns an array of crumbs for which <code>pattern === crumb</code>
    #
    # ==== Options
    #  * pattern - A string or Regexp literal, as with Enumerable#grep.
    def grep(pattern)
      @crumbs.grep(pattern)
    end

    # Appends +data+ to the report dialog
    #
    # ==== Options
    #  * data - The message, as passed by an Invoker descendant. Required.
    def <<(data)
      if @keep_next
        @crumbs << "> #{data}"
        @keep_next = false
      elsif data =~ /^->/
        @crumbs << "< #{data.gsub(/^.../, '')}"
      elsif data =~ /^<-/
        @keep_next = true
      end
    end

    # Yields each crumb sequentially to the supplied block.
    def each #:yields: crumb
      @crumbs.each { |c| yield c }
    end

    # call-seq:
    #   crumbs.to_s => string
    #
    # Returns a string containing all crumbs, seperated by newlines.
    def to_s
      "  " + @crumbs.join("...\n")
    end
  end
end

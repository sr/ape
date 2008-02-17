#   Copyright (c) 2006 Sun Microsystems, Inc. All rights reserved
#   Use is subject to license terms - see file "LICENSE"

module Ape
  class HTML
    def HTML.error(message, output=STDOUT)
      headers(output)
      output.puts <<EndOfText
  <title>Error: #{message}</title>
  </head>
  <body>
  <h2>Error</h2>
  <p>#{message}.</p>
EndOfText
    end
  end
end

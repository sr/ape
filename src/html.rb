#   Copyright © 2006 Sun Microsystems, Inc. All rights reserved
#   Use is subject to license terms - see file "LICENSE"

class HTML

  def HTML.error(message)
    headers
    puts <<EndOfText
<title>Error: #{message}</title>
</head>
<body>
<h2>Error</h2>
<p>#{message}.</p>
EndOfText
  end

  def HTML.headers
    puts "Status: 200 OK"
    puts "Content-type: text/html; charset=utf-8"
    puts ""
    puts "<!DOCTYPE html PUBLIC '-//W3C//DTD XHTML 1.1//EN' 'http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd'>"
    puts "<html>\n<head>\n"
    puts "<link rel='stylesheet' type='text/css' href='/ape/ape.css' />"
  end

  def HTML.page title
    headers
    puts "<title>#{title}</title>"
    puts "</head>\n<body>"
    yield
    puts "</body>\n</html>"
  end
end

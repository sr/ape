#   Copyright © 2006 Sun Microsystems, Inc. All rights reserved
#   Use is subject to license terms - see file "LICENSE"

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

  def HTML.headers(output)
    output.puts "Status: 200 OK\r"
    output.puts "Content-type: text/html; charset=utf-8\r"
    output.puts "
"
    output.puts "<!DOCTYPE html PUBLIC '-//W3C//DTD XHTML 1.1//EN' 'http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd'>"
    output.puts "<html>\n<head>\n"
    output.puts "<link rel='stylesheet' type='text/css' href='/ape/ape.css' />"
  end

  def HTML.page(title, output=STDOUT)
    headers(output)
    output.puts "<title>#{title}</title>"
    output.puts "</head>\n<body>"
    yield
    output.puts "</body>\n</html>"
  end
end

#   Copyright (c) 2006 Sun Microsystems, Inc. All rights reserved
#   Use is subject to license terms - see file "LICENSE"
module Ape
  class Escaper
    def Escaper.escape(text)
      text.gsub(/([&<'">])/) do
        case $1
        when '&' then '&amp;'
        when '<' then '&lt;'
        when "'" then '&apos;'
        when '"' then '&quot;'
        when '>' then '&gt;'
        end
      end
    end

    def Escaper.unescape(text)
      text.gsub(/&([^;]*);/) do
        case $1
        when 'lt' then '<'
        when 'amp' then '&'
        when 'gt' then '>'
        when 'apos' then "'"
        when 'quot' then '"'
        end
      end
    end
  end
end

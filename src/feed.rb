#   Copyright © 2006 Sun Microsystems, Inc. All rights reserved
#   Use is subject to license terms - see file "LICENSE"

require 'rexml/document'
require 'rexml/xpath'

require 'names'
require 'atomURI'
require 'validator'

class Feed

  # Load up a collection feed from its URI.  Return an array of <entry> objects.
  #  follow <link rel="next" /> pointers as required to get the whole
  #  collection
  def Feed.read(uri, name, ape, report=true)

    entries = []
    uris = []
    next_page = uri
    page_num = 1

    while next_page do

      label = "Page #{page_num} of #{name}"
      uris << next_page
      page = ape.check_resource(next_page, label, Names::AtomMediaType, report)
      break unless page

      # * Validate it
      Validator.validate(Samples.atom_RNC, page.body, label, ape) if report

      # XML-parse the feed
      error = "not well-formed"
      begin
        feed = REXML::Document.new(page.body, { :raw => nil })
      rescue Exception
        error = $!.to_s
        feed = nil
      end
      if feed == nil
        ape.error "Can't parse #{label} at #{next_page}, Parser said: #{$!}; Feed text: #{text}" if report
        break
      end

      feed = feed.root
      page_entries = REXML::XPath.match(feed, "./atom:entry", Names::XmlNamespaces)
      entries += page_entries.map { |e| Entry.new(e, next_page)}
      next_link = REXML::XPath.first(feed, "./atom:link[@rel=\"next\"]", Names::XmlNamespaces)
      if next_link
        next_link = next_link.attributes['href']
        base = AtomURI.new(next_page) 
        next_link = base.absolutize(next_link, feed).to_s
        if uris.index(next_link)
          ape.error "Collection contains circular 'next' linkage: #{next_link}" if report
          break
        end
        page_num += 1
      end
      next_page = next_link
    end
    entries
  end
end


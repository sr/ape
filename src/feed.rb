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

    while (next_page) && (page_num < 10) do

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
      if page_entries.empty? && report
        ape.info "#{label} has no entries."
      end

      entries += page_entries.map { |e| Entry.new(e, next_page)}
      
      next_link = REXML::XPath.first(feed, "./atom:link[@rel=\"next\"]", Names::XmlNamespaces)
      if next_link
        next_link = next_link.attributes['href']
        base = AtomURI.new(next_page)
        next_link = base.absolutize(next_link, feed)
        if uris.index(next_link)
          ape.error "Collection contains circular 'next' linkage: #{next_link}" if report
          break
        end
        page_num += 1
      end
      next_page = next_link
    end

    if report && next_page
      ape.warning "Stopped reading collection after #{page_num} pages." 
    end

    # all done unless we're error-checking
    return entries unless report

    # Ensure that entries are ordered by app:edited
    last_date = nil
    with_app_date = 0
    clean = true
    entries.each do |e|
      datestr = e.child_content("edited", Names::AppNamespace)
      error = nil
      if datestr
        if datestr =~ /\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\d(\.\d+)?(Z|([-+]\d\d:\d\d))/
          begin
            date = Time.parse(datestr)
            with_app_date += 1
            if last_date && (date > last_date)
              error = "app:edited values out of order, d #{date} ld #{last_date}"
            end
            last_date = date
          rescue ArgumentError
            error = "invalid app:edited value: #{datestr}"
          end
        else
          error = "invalid app:edited child: #{datestr}"
        end
        if error
          title = e.child_content "title"
          ape.error "In entry with title '#{title}', #{error}."
          clean = false
        end
      end
    end
    if with_app_date < entries.size
      ape.error "#{entries.size - with_app_date} of #{entries.size} entries in #{name} lack app:edited elements."
      clean = false
    end

    ape.good "#{name} has correct app:edited value order." if clean

    entries

  end

end


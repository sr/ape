#   Copyright © 2006 Sun Microsystems, Inc. All rights reserved
#   Use is subject to license terms - see file "LICENSE"
require 'rexml/document'
require 'rubygems'
require 'builder'

require 'getter'
require 'service'
require 'samples'
require 'entry'
require 'poster'
require 'collection'
require 'deleter'
require 'putter'
require 'feed'
require 'html'
require 'crumbs'
require 'escaper'
require 'categories'

class Ape

  @@ATOM_MEDIA_TYPE = 'application/atom+xml'

  def initialize(args)
    @dialogs = (args[:crumbs]) ? {} : []
    output = args[:output] || 'html'
    if output == 'text' || output == 'html'
      @output = output
    else
      raise ArgumentError, "output must be 'text' or 'html'"
    end

    @diarefs = {}
    @dianum = 1
    @@debugging = args[:debug]
    @steps = []
    @header = @footer = nil
    @lnum = 1
  end

  # Args: APP URI, username/password, preferred entry/media collections
  def check(uri, username=nil, password=nil,
    requested_e_coll = nil, requested_m_coll = nil)

    @username = username
    @password = password
    header(uri)
    begin
      might_fail(uri, requested_e_coll, requested_m_coll)
    rescue Exception
      error "Ouch! Ape fall down go boom; details: " +
      "#{$!}\n#{$!.class}\n#{$!.backtrace}"
    end
  end

  def might_fail(uri, requested_e_coll = nil, requested_m_coll = nil)

    name = 'Retrieval of Service Document'
    service = check_resource(uri, name, 'application/atomserv+xml')
    return unless service

    # * XML-parse the service doc
    text = service.body
    begin
      service = REXML::Document.new(text, { :raw => nil })
    rescue REXML::ParseException
      prob = $!.to_s.gsub(/\n/, '<br/>')
      error "Service document not well-formed: #{prob}"
      return
    end

    # RNC-validate the service doc
    validate(Samples.service_RNC, text, 'Service doc')

    # * Do we have collections we can post an entry and a picture to?
    #   the requested_* arguments are the requested collection titles; if
    #    provided, try to match them, otherwise just pick the first listed
    #
    begin
      collections = Service.collections(service, uri)
    rescue Exception
      error "Couldn't read collections from service doc: #{$!}"
      return
    end
    entry_coll = media_coll = nil
    if collections.length > 0
      start_list "Found these collections"
      collections.each do |collection|
        list_item "'#{collection.title}' " +
        "accepts #{collection.accept.join(', ')}"
        if (!entry_coll) && collection.accept.index('entry')
          if requested_e_coll
            if requested_e_coll == collection.title
              entry_coll = collection
            end
          else
            entry_coll = collection
          end
        end

        if !media_coll
          image_jpeg_ok = false
          collection.accept.each do |types|
            types.split(/, */).each do |type|

              if type == '*/*' || type == 'image/*' || type == 'image/jpeg'
                image_jpeg_ok = true
              end
            end
          end
          if image_jpeg_ok
            if requested_m_coll
              if requested_m_coll == collection.title
                media_coll = collection
              end
            else
              media_coll = collection
            end
          end
        end
      end
    end

    end_list

    if entry_coll
      good "Will use collection '#{entry_coll.title}' for entry creation."
    else
      error "Couldn't find appropriate entry collection."
      return
    end

    if media_coll
      good "Will use collection '#{media_coll.title}' for media creation."
    else
      warning "No collection for 'image/jpeg', won't test media posting."
    end

    # * Retrieve the entries collection, check content-type
    feed = check_resource(entry_coll.href, 'Retrieval of Entry collection', @@ATOM_MEDIA_TYPE)
    return unless feed

    # * XML-parse the entries feed
    text = feed.body
    begin
      feed = Feed.new(text, entry_coll.href)
    rescue Exception
      error "Can't parse feed at #{entry_coll.href}, Parser said: #{$!}; Feed text: #{text}"
      return
    end

    # * Validate it
    validate(Samples.atom_RNC, text, 'Entries feed')

    # * List the current entries, remember which IDs we've seen
    ids = []
    start_list "Now in the Entries feed"
    feed.entries do |entry|
      list_item entry.summarize
      ids << entry.child_content('id')
    end
    end_list

    # * Post an entry
    poster = Poster.new(entry_coll.href, @username, @password)
    if poster.last_error
      error("Unacceptable URI for '#{entry_coll.title}' collection: " +
      poster.last_error)
      return
    end

    my_entry = Entry.new(Samples.basic_entry)

    # ask it to use this in the URI
    slug = "ape-#{rand(100000)}"
    poster.set_header('Slug', slug)
    
    # add some categories to the entry, and remember which
    cats = Categories.add_cats(my_entry, entry_coll)
    
    worked = poster.post(@@ATOM_MEDIA_TYPE, my_entry.to_s)
    name = 'Posting new entry'
    save_dialog(name, poster)
    if !worked
      error("Can't POST new entry: #{poster.last_error}", name)
      return
    end

    location = poster.header('Location')
    unless location
      error("No Location header upon POST creation", name)
      return
    end
    good("Posting of new entry to the Entries collection " +
    "reported success, Location: #{location}", name)
    
    # * See if the slug was used
    if location.index(slug)
      good "Client-provided slug '#{slug}' was used in server-generated URI."
    else
      warning "Client-provided slug '#{slug}' -not used in server-generated URI."
    end

    # * Check the entry sent back is more or less the same.
    if poster.entry
      if compare_entries(my_entry, poster.entry,
        "posted entry", "returned entry")
        good "Returned entry is consistent with posted entry."
      end
    end
    
    # * See if the categories we sent made it in
    cat_probs = false
    cats.each do |cat|      
      if !poster.entry.has_cat(cat)
        cat_probs = true
        warning "Provided category not in posted entry: #{cat}"
      end
    end
    good "Provided categories included in newly-created entry." unless cat_probs

    # * See if the Location uri can be retrieved, and check its consistency
    name = "Retrieval of newly created entry"
    new_entry = check_resource(location, name, @@ATOM_MEDIA_TYPE)
    return unless new_entry

    begin
      new_entry = Entry.new(new_entry.body, location)
    rescue REXML::ParseException
      prob = $!.to_s.gsub(/\n/, '<br/>')
      error "New entry is not well-formed: #{prob}"
      return
    end

    if compare_entries(my_entry, new_entry, "posted entry",
      "newly created entry")
      good "Newly created entry is consistent with posted entry"
    end
    entry_id = new_entry.child_content('id')

    # * See if the dc:subject survived
    dc_subject = new_entry.child_content(Samples.foreign_child,
    Samples.foreign_namespace)
    if dc_subject
      if dc_subject == Samples.foreign_child_content
        good "Server preserved foreign markup."
      else
        warning "Server altered content of foreign markup."
      end
    else
      warning "Server discarded foreign markup."
    end

    # * fetch the feed again and check that version
    from_feed = find_entry(entry_coll.href, entry_id)
    if from_feed.class == String
      error "New entry didn't show up in the collections feed."
      return
    end

    # * Check the entry from the feed
    if compare_entries(my_entry, from_feed, "posted entry", "entry from feed")
      good "Entry from feed is consistent with posted entry."
    end

    edit_uri = new_entry.link('edit')
    if !edit_uri
      error "Entry from Location header has no edit link."
      return
    end

    # * Update the entry, see if the update took
    name = 'In-place update with put'
    putter = Putter.new(edit_uri, @username, @password)
    new_title = "Let's all do the Ape!"
    new_text = Samples.retitled_entry(new_title, entry_id)
    response = putter.put(@@ATOM_MEDIA_TYPE, new_text)
    save_dialog(name, putter)

    if response
      good("Update of new entry reported success.", name)
      from_feed = find_entry(entry_coll.href, entry_id)
      if from_feed.class == String
        error(from_feed, name)
        return
      end
      if from_feed.child_content('title') == new_title
        good "Update reflected in new entry."
      else
        warning "PUT apparently not reflected in the entry."
      end
    else
      warning("Can't update new entry with PUT: #{putter.last_error}", name)
    end

    # the edit-uri might have changed
    edit_uri = from_feed.link('edit')
    if !edit_uri
      error "Entry in feed has no edit link."
      return
    end

    name = 'New Entry deletion'
    deleter = Deleter.new(edit_uri, @username, @password)

    worked = deleter.delete
    save_dialog(name, deleter)
    if worked
      good("Entry deletion reported success.", name)
    else
      error("Couldn't delete the entry that was posted: " + deleter.last_error,
      name)
      return
    end

    # See if it's gone from the feed
    still_there = find_entry(entry_coll.href, entry_id)
    if still_there.class != String
      error "Entry is still in collection post-deletion."
    else
      good "Entry not found in feed after deletion."
    end

    if media_coll
      test_media_posts media_coll.href
    end
  end

  def test_media_posts media_collection
    # * Post a picture to the media collection
    #
    poster = Poster.new(media_collection, @username, @password)
    if poster.last_error
      error("Unacceptable URI for '#{media_coll.title}' collection: " +
      poster.last_error)
      return
    end

    name = 'Post image to media collection'
    poster.set_header('Title', 'Picture of the APE')
    worked = poster.post('image/jpeg', Samples.picture)
    save_dialog(name, poster)
    if !worked
      error("Can't POST picture to media collection: #{poster.last_error}",
      name)
      return
    end

    good("Post of image file reported success, media link location: " +
    "#{poster.header('Location')}", name)

    # * Retrieve the media link entry
    mle_uri = poster.header('Location')
    media_link_entry = check_resource(mle_uri, 'Retrieval of media link entry',
    @@ATOM_MEDIA_TYPE)
    return unless media_link_entry

    if media_link_entry.last_error
      error "Can't proceed with media-post testing."
      return
    end

    # * See if the <content src= is there and usable
    begin
      media_link_entry = Entry.new(media_link_entry.body, mle_uri)
    rescue REXML::ParseException
      prob = $!.to_s.gsub(/\n/, '<br/>')
      error "Media link entry is not well-formed: #{prob}"
      return
    end
    content_src = media_link_entry.content_src
    if (!content_src) || (content_src == "")
      error "Media link entry has no content@src pointer to media resource."
      return
    end

    media_link_id = media_link_entry.child_content('id')

    name = 'Retrieval of media resource'
    picture = check_resource(content_src, name, 'image/jpeg')
    return unless picture

    if picture.body == Samples.picture
      good "Media resource was apparently stored and retrieved properly."
    else
      warning "Media resource differs from posted picture"
    end

    # * Delete the media link entry
    edit_uri = media_link_entry.link('edit')
    if !edit_uri
      error "Media link entry has no edit link."
      return
    end

    name = 'Deletion of media link entry'
    deleter = Deleter.new(edit_uri, @username, @password)
    worked = deleter.delete
    save_dialog(name, deleter)
    if worked
      good("Media link entry deletion reported success.", name)
    else
      error("Couldn't delete media link entry.", name)
      return
    end

    # * media link entry still in feed?
    still_there = find_entry(media_collection, media_link_id)
    if still_there.class != String
      error "Media link entry is still in collection post-deletion."
    else
      good "Media link entry no longer in feed."
    end
  end

  #
  # End of tests; support functions from here down
  #

  # Fetch a feed and look up an entry by ID in it
  def find_entry(feed_uri, id)
    feed = Getter.new(feed_uri, @username, @password)

    if feed.last_error
      return "Unacceptable #{name} URI: " + feed.last_error
    end

    if !feed.get
      return "Couldn't get #{name}: " + feed.last_error
    end

    text = feed.body
    begin
      feed = Feed.new(text, feed_uri)
    rescue ArgumentError
      return $!
    end

    feed.entries do |from_feed|
      return from_feed if id == from_feed.child_content('id')
    end
    
    return "Couldn't find id #{id} in feed #{feed_uri}"
  end

  # remember the dialogue that the get/put/post/delete actor recorded
  def save_dialog(name, actor)
    @dialogs[name] = actor.crumbs if @dialogs
  end

  # Get a resource, optionally check its content-type
  def check_resource(uri, name, content_type, report=true)
    resource = Getter.new(uri, @username, @password)

    # * Check the URI
    if resource.last_error
      error "Unacceptable #{name} URI: " + resource.last_error
      return nil
    end

    # * Get it, make sure it has the right content-type
    worked = resource.get(content_type)
    @dialogs[name] = resource.crumbs if @dialogs

    if !worked
      # oops, couldn't even get get it
      error("#{name} failed: " + resource.last_error, name)
      return nil

    elsif resource.last_error
      # oops, media-type problem
      warning("#{name}: #{resource.last_error}", name)

    else
      # resource fetched and is of right type
      good("#{name}: it exists and is served properly.", name) if report
    end

    return resource
  end

  def validate(schema, text, name)
    # Can do this in JRuby, not native Ruby (sigh)
  end

  def header(uri)
    @header = "APP Service doc: #{uri}"
  end

  def footer(message)
    @footer = message
  end

  def show_crumbs key
    @dialogs[key].each do |d|
      puts "D: #{d}"
    end
  end

  def warning(message, crumb_key=nil)
    if @dialogs
      step "D#{crumb_key}" if crumb_key
      show_crumbs(crumb_key) if crumb_key && @@debugging
    end
    step "W" + message
  end

  def error(message, crumb_key=nil)
    if @dialogs
      step "D#{crumb_key}" if crumb_key
      show_crumbs(crumb_key) if crumb_key && @@debugging
    end
    step "E" + message
  end

  def good(message, crumb_key=nil)
    if @dialogs
      step "D#{crumb_key}" if crumb_key
      show_crumbs(crumb_key) if crumb_key && @@debugging
    end
    step "G" + message
  end

  def step(message)
    puts "PROGRESS: #{message[1..-1]}" if @@debugging
    @steps << message
  end

  def start_list(message)
    step [ message + ":" ]
  end

  def list_item(message)
    @steps[-1] << message
  end

  def end_list
  end

  def line
    printf "%2d. ", @lnum
    @lnum += 1
  end

  def report
    if @output == 'text'
      report_text
    else
      report_html
    end
  end

  def report_html
    check_mark = Proc.new do
      @w.span(:class => 'good') { STDOUT.print '&#x2713;' }
    end
    question_mark = Proc.new do
      @w.span(:class => 'warning') { @w.text! '?' }
    end
    excl_mark = Proc.new do
      @w.span(:class => 'error') { @w.text! '!' }
    end
    info_mark = Proc.new do
      @w.img(:align => 'top', :src => '/ape/info.png')
    end

    dialog = nil

    puts "Status: 200 OK\r"
    puts "Content-type: text/html; charset=utf-8\r"
    puts "\r"
    puts "<!DOCTYPE html PUBLIC '-//W3C//DTD XHTML 1.1//EN' 'http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd'>"

    @w = Builder::XmlMarkup.new(:target => STDOUT)
    @w.html do
      @w.head do
        @w.title { @w.text! 'Atom Protocol Exerciser Report' }
        @w.text! "\n"
        @w.link(:rel => 'stylesheet', :type => 'text/css',
        :href => '/ape/ape.css' )
      end
      @w.text! "\n"
      @w.body do
        @w.h2 { @w.text! 'The Ape says:' }
        @w.text! "\n"
        if @header
          @w.p { @w.text! @header }
          @w.text! "\n"
        end
        @w.ol do
          @w.text! "\n"
          @steps.each do |step|
            if step.kind_of? Array
              # it's a list; no dialog applies
              @w.li do
                @w.p do
                  info_mark.call
                  @w.text! " #{step[0]}\n"
                end
                @w.ul do
                  step[1 .. -1].each { |li| report_li(nil, nil, li) }
                end
                @w.text! "\n"
              end
            else
              body = step[1 .. -1]
              opcode = step[0,1]
              if opcode == "D"
                dialog = body
              else
                case opcode
                when "W" then report_li(dialog, question_mark, body)
                when "E" then report_li(dialog, excl_mark, body)
                when "G" then report_li(dialog, check_mark, body)
                else
                  line
                  puts "HUH? #{step}"
                end
                dialog = nil
              end
            end
          end
        end

        @w.text! "\n"
        if @footer then @w.p { @w.text! @footer } end
        @w.text! "\n"

        if @dialogs
          @w.h2 { @w.text! 'Recorded client/server dialogs' }
          @w.text! "\n"
          @diarefs.each do |k, v|
            dialog = @dialogs[k]
            @w.h3(:id => "dia-#{v}") do
              @w.text! k
            end
            @w.div(:class => 'dialog') do

              @w.div(:class => 'dialab') do
                @w.text! "\nTo server:\n"
                dialog.grep(/^>/).each { |crumb| show_message(crumb, :to) }
              end
              @w.div( :class => 'dialab' ) do
                @w.text! "\nFrom Server:\n"
                dialog.grep(/^</).each { |crumb| show_message(crumb, :from) }
              end
            end
          end
        end
      end
    end
  end

  def report_li(dialog, marker, text)
    @w.li do
      @w.p do
        if marker
          marker.call
          @w.text! ' '
        end
        @w.text! text
        if dialog
          @w.a(:class => 'diaref', :href => "#dia-#{@dianum}") do
            @w.text! ' [Dialog]'
          end
          @diarefs[dialog] = @dianum
          @dianum += 1
        end
      end
    end
    @w.text! "\n"
  end

  def show_message(crumb, tf)
    message = crumb[1 .. -1]
    message.gsub!(/^\s*"/, '')
    message.gsub!(/"\s*$/, '')
    message.gsub!(/\\"/, '"')
    message = Escaper.escape message
    message.gsub!(/\\n/, '\n<br/>')
    message.gsub!(/\\t/, '&nbsp;&nbsp;&nbsp;&nbsp;')
    @w.div(:class => tf) { print message }
  end

  def report_text
    puts @header if @header
    @steps.each do |step|
      if step.class == Crumbs
        puts "   Dialog:"
        step.each { |crumb| puts "     #{crumb}" }
      else
        body = step[1 .. -1]
        case step[0,1]
        when "W"
          line
          puts "WARNING: #{body}"
        when "E"
          line
          puts "ERROR: #{body}"
        when "G"
          line
          puts body
        when "L"
          line
          puts body
        when "e"
          # no-op
        when "I"
          puts "     #{body}"
        when "D"
          # later, dude
        else
          line
          puts "HUH? #{body}"
        end
      end
      puts @footer if @footer
    end
  end

  def compare_entries(e1, e2, e1Name, e2Name)
    problems = 0
    [ 'title', 'summary', 'content' ].each do |field|
      problems += 1 if compare1(e1, e2, e1Name, e2Name, field)
    end
    return problems == 0
  end

  def compare1(e1, e2, e1Name, e2Name, field)
    c1 = e1.child_content(field)
    c2 = e2.child_content(field)
    if c1 != c2
      problem = true
      if c1 == nil
        warning "'#{field}' absent in #{e1Name}."
      elsif c2 == nil
        warning "'#{field}' absent in #{e2Name}."
      else
        t1 = e1.child_type(field)
        t2 = e2.child_type(field)
        if t1 != t2
          warning "'#{field}' has type='#{t1}' " +
          "in #{e1Name}, type='#{t2}' in #{e2Name}"
        else
          c1 = Escaper.escape(c1)
          c2 = Escaper.escape(c2)
          warning "'#{field}' in #{e1Name} [#{c1}] " +
          "differs from that in #{e2Name} [#{c2}]."
        end
      end
    end
    return problem
  end

end


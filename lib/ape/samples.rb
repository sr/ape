require 'rubygems'
require 'atom/entry'

module Ape
  module Samples
    module_function

    def basic_entry(locals={})
      entry = Atom::Entry.new do |e|
        e.id = locals[:id] if locals[:id]
        e.title = locals[:title] || 'From the <APE> (サル)'
        e.authors.new(:name => 'The Atom Protocol Exerciser')
        e.updated = locals[:updated] || Time.now
        e.summary = 'Summary from the APE'
        e.content = %q{
          <div xmlns='http://www.w3.org/1999/xhtml'>
            <p>A test post from the &lt;APE&gt</p>
            <p>If you see this in an entry, it's probably a left-over from an
              unsuccessful Ape run; feel free to delete it.</p>
          </div>
        }
      end
      entry.content#['type'] = 'xhtml'#locals[:content_type] || 'xhtml'
      entry
    end
  end
end

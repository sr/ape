#   Copyright © 2006 Sun Microsystems, Inc. All rights reserved
#   Use is subject to license terms - see file "LICENSE"

require 'rexml/document'
require 'rexml/xpath'

module Ape
  class Categories
    attr_reader :fixed

    def Categories.from_collection(collection, authent, ape=nil)

      # "catses" because if cats is short for categories, then catses 
      #  suggests multiple <app:categories> elements
      catses = collection.catses

      catses.collect! do |cats|
        if cats.attribute(:href)
          getter = Getter.new(cats.attribute(:href).value, authent)
          if getter.last_error # wonky URI
            ape.error getter.last_error if ape
            nil
          end

          if !getter.get('application/atomcat+xml')
            ape.error "Can't fetch categories doc " + 
              "'#{cats.attribute(:href).value}': getter.last_error" if ape
            nil
          end

          ape.warning(getter.last_error) if ape && getter.last_error
          REXML::Document.new(getter.body).root
        else
          # no href attribute
          cats
        end
      end
      catses.compact
    end

  end

  # Decorate an entry which is about to be posted to a collection with some
  #  categories.  For each fixed categories element, pick one of the categories
  #  and add that.  If there are no categories elements at all, or if there's
  #  at least one with fixed="no", also add a syntho-cat that we make up.
  #  Return the list of categories that we added.
  #
  def Categories.add_cats(entry, collection, authent, ape=nil)

    added = []
    c = from_collection(collection, authent)
    if c.empty?
      add_syntho = true
    else
      add_syntho = false

      # for each <app:categories>
      c.each do |cats|
        
        default_scheme = cats.attributes['scheme']

        # if it's fixed, pick the first one
        if cats.attributes['fixed'] == "yes"
          cat_list = REXML::XPath.match(cats, './atom:category', Names::XmlNamespaces)
          if cat_list

            # for each <app:category> take the first one whose attribute "term" is not empty
            cat_list.each do |cat|
              if cat.attributes['term'].empty?
                ape.warning 'A mangled category is present in your categories list' if ape
              else
                scheme = cat.attributes['scheme']
                if !scheme
                  scheme = default_scheme
                end              
                added << entry.add_category(cat.attributes['term'], scheme)
                break
              end
            end
          end
        else
          add_syntho = true
        end

      end
    end

    if add_syntho
      added << entry.add_category('simians', 'http://tbray.org/cat-test')
    end
    added
  end
end


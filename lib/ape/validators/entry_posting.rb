require 'net/http'
require File.dirname(__FILE__) + '/../core_ext'

module Ape
  module Validator
    class EntryPosting
      attr_accessor :reporter

      def initialize(options={})
        @host, @port, @collection = options.values_at(:host, :port, :collection)
      end

      def run(options={})
        notify 'Testing entry-posting basics.'
        notify 'Posting new entry.'
        return false unless do_request

        unless @response.code == 201
          error "Can't post new entry."
          return false
        end

        unless @response['Location']
          error 'No Location header upon POST creation.'
          return false
        end

        unless @response['Content-Type'] == 'application/atom+xml;type=entry'
          error 'Incorrect Content-Type.'
        end

        notify "Posting of new entry to the Entries collection reported success," + \
          "Location: #{@response['Location']}"
        notify 'Examining the new entry as returned in the POST response'

        unless valid_entry?(@response.body)
          error 'New entry is not well-formed'
          return false
        end

        comparison = ComparableAtomEntry.compare(Ape::Samples.basic_entry, @response.body)
        if comparison.different?
          error 'Returned entry is inconsistent with posted entry.'
          comparison.differences.each { |difference| error(difference) }
        else
          correct 'Returned entry is consistent with posted entry.'
          correct 'Provided categories included in returned entry.'
        end
      end

      private
        def do_request
          http = Net::HTTP.new(@host, @port)
          request = Net::HTTP::Post.new(@collection)
          request.set_content_type 'application/atom+xml;type=entry'
          @response = http.request(request, Ape::Samples.basic_entry.to_s)
        rescue SocketError
          reporter.call(self, :fatal, "Can't connect to #{@host} on port #{@port}.")
          false
        end

        def valid_entry?(entry)
          Atom::Entry.parse(entry)
        rescue Atom::ParseError
          false
        else
          true
        end

        def notify(message)
          reporter.call(self, :notice, message)
        end

        def correct(message)
          reporter.call(self, :correct, message)
        end

        def error(message)
          reporter.call(self, :error, message)
        end
    end
  end
end

require 'net/http'

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

        def notify(message)
          reporter.call(self, :notice, message)
        end

        def error(message)
          reporter.call(self, :error, message)
        end
    end
  end
end

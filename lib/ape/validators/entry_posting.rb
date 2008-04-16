require 'net/http'

module Ape
  module Validator
    class EntryPosting
      attr_accessor :reporter

      def initialize(options={})
        @host, @port, @collection = options.values_at(:host, :port, :collection)
      end

      def run(options={})
        reporter.call(self, :notice, 'Testing entry-posting basics.')
        reporter.call(self, :notice, 'Posting new entry.')
        return unless do_request
        reporter.call(self, :error, "Can't post new entry.") unless @response.code == 201
        unless @response['Location']
          reporter.call(self, :error, 'No Location header upon POST creation.')
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
    end
  end
end

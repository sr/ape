require 'net/http'

module Ape
  module Validator
    class EntryPosting
      attr_accessor :reporter

      def self.run(options={})
        host, port, collection = options.values_at(:host, :port, :collection)
        http = Net::HTTP.new(host, port)
        request = Net::HTTP::Post.new(collection)
        request.set_content_type 'application/atom+xml;type=entry' 

        begin
          http.start do |connection|
            reporter.call(self, :notice, 'Testing entry-posting basics.')
            reporter.call(self, :notice, 'Posting new entry.')
            response = connection.request(request, Ape::Samples.basic_entry.to_s)
            reporter.call(self, :error, "Can't post new entry.") unless response.code == 201
          end
        rescue SocketError
          reporter.call(self, :fatal, "Can't connect to #{host} on port #{port}.")
        end
      end
    end
  end
end

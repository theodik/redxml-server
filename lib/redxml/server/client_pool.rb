require 'thread'
require 'redxml/server/client_worker'

module RedXML
  module Server
    # Pool creates n threads in which processes client's
    # requests.
    class ClientPool
      attr_reader :options, :queue
      attr_accessor :limit

      def initialize(options = RedXML::Server.options)
        @options = options
        @queue = Queue.new
        @limit = options[:concurency] || 25
        @thread_pool = []
      end

      def logger
        RedXML::Server::Logging.logger
      end

      def que(client)
        @queue.push client
        delete_dead_threads
        if @thread_pool.length < @limit
          create_thread
        end
      end

      private

      def delete_dead_threads
        @thread_pool.delete_if { |t| !t.status }
      end

      def create_thread
        @thread_pool << Thread.new(@queue) do |que|
          loop do
            client = nil
            begin
              client = que.pop(true)
            rescue ThreadError
              Thread.exit
            end

            logger.debug "Processing #{client}"
            RedXML::Server::ClientWorker.new(client).process
          end
        end
      end
    end
  end
end

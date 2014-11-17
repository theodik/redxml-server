require 'socket'
require 'redxml/server/client_pool'

module RedXML
  module Server
    class ServerWorker
      attr_reader :options

      def initialize(options = RedXML::Server.options)
        @options = options
        @client_pool = RedXML::Server::ClientPool.new(options)
      end

      def run
        start_server_socket
        while running?
          next unless IO.select([socket], nil, nil, 0.5)
          client = socket.accept
          logger.info "Acccept client #{str client}"
          client_pool.que(client) do |cli|
            logger.debug "Processing #{cli}"
            RedXML::Server::ClientWorker.new(cli).process
          end
          logger.debug "Client #{str client} queued"
        end
      end

      def logger
        RedXML::Server::Logging.logger
      end

      protected

      attr_accessor :socket, :client_pool

      def str(socket)
        addr = socket.remote_address
        "#{addr.ip_address}:#{addr.ip_port}"
      end

      def server_options
        [options[:bind], options[:port]]
      end

      def running?
        !Thread.current.thread_variable_get(:stop)
      end

      def start_server_socket
        logger.info 'starting listen on ' + \
          "#{server_options[0]}:#{server_options[1]}"
        @socket = TCPServer.new(*server_options)
      end
    end
  end
end

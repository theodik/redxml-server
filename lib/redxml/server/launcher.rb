module RedXML
  module Server
    class Launcher
      def initialize(options)
        @options = options
      end

      def run
        create_server
        server.run
      end

      def stop
      end

      private

      attr_accessor :server

      def create_server
        @server = RedXML::Server::ServerWorker.new(@options)
      end
    end
  end
end

module RedXML
  module Server
    class Launcher
      def initialize(options)
        @options = options
      end

      def run
        create_database_connection
        create_server
      end

      private

      def create_database_connection
        @db_conn = RedXML::Server::DatabaseConnection.new(@options)
      end

      def create_server
        @server_conn = RedXML::Server::Server.new(@options)
      end
    end
  end
end

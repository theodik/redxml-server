require 'monitor'
require 'thread'
require 'redxml/server/driver/base'
require 'redxml/server/database/database_interface'
require 'redxml/server/database/db_transaction_interface'

module RedXML
  module Server
    module Database
      def self.connection_pool
        @instance ||= ConnectionPool.new
      end

      def self.checkout
        connection_pool.checkout
      end

      def self.checkin(conn)
        connection_pool.checkin conn
      end

      class ConnectionPool
        include MonitorMixin

        attr_reader :options

        def initialize(options = RedXML::Server.options)
          super()

          @options = options
          options[:db][:driver] or fail ArgumentError, 'Database driver not specified'
          load_driver options[:db][:driver]

          @connections = []
          @available   = []
          @checked     = []
        end

        def checkout
          synchronize do
            if conn = @available.pop
              @checked << conn
              conn
            else
              new_connection.tap do |conn|
                @checked << conn
              end
            end
          end
        end

        def checkin(conn)
          synchronize do
            @available << @checked.delete(conn)
            conn
          end
        end

        def disconnect!
          synchronize do
            @checked.clear
            @available.clear
            @connections.each(&:close).clear
          end
        end

        private

        def load_driver(driver_name)
          require("redxml/server/driver/#{driver_name}")
        rescue LoadError
          raise "Driver '#{driver_name}' is not supported"
        end

        def new_connection
          name = options[:db][:driver].to_s.capitalize
          driver_klass = RedXML::Server::Driver.const_get(name)
          driver = driver_klass.new(options[:db])
          logger.debug "New #{driver_klass.name} conection with #{options[:db]}"
          conn = DBTransactionInterface.new(driver)
          @connections << conn
          conn
        end

        def logger
          RedXML::Server.logger
        end
      end
    end
  end
end

require 'redxml/protocol'
require 'redxml/server/executors'

module RedXML
  module Server
    class ClientWorker
      def initialize(client)
        @client = client
      end

      def process
        db_interface = RedXML::Server::Database.checkout

        send_hello
        loop do
          begin
            packet = receive_packet
            break unless packet
            break if packet.command == :quit

            result = execute(db_interface, packet.command, packet.param)
            send_packet packet.response(result)
          rescue RedXML::Protocol::UnsupportedCommandError, NotImplementedError => e
            builder = RedXML::Protocol::PacketBuilder.new
            builder.command(:execute).error(e.message)
            send_packet builder.build
          rescue => e
            send_packet packet.error(e.message)
          end
        end
      ensure
        @client.close
        RedXML::Server::Database.checkin db_interface
      end

      private

      def receive_packet
        RedXML::Protocol.read_packet(@client)
      end

      def send_packet(command, result = nil)
        packet = command
        if result
          packet = RedXML::Protocol::PacketBuilder.new.command(command).param(result)
        end
        @client.write packet.data
      end

      def parse(data)
        RedXML::Protocol::PacketBuilder.parse(data)
      end

      def send_hello
        hello = RedXML::Protocol::PacketBuilder.hello("RedXML-#{RedXML::Server::VERSION}")
        @client.write hello.data
      end

      def execute(db_interface, command, param)
        exe_name  = command.to_s.split('_').collect!(&:capitalize).join
        begin
          exe_class = RedXML::Server::Executors.const_get(exe_name)
        rescue NameError
          raise NotImplementedError, "Command #{command} is not currently supported."
        end
        executor  = exe_class.new(db_interface, param)
        executor.execute
      end
    end
  end
end

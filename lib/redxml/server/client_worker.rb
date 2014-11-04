require 'redxml/protocol'

module RedXML
  module Server
    class ClientWorker
      def initialize(client)
        @client = client
      end

      def process
        send_hello
        loop do
          packet = receive_packet
          break unless packet
          break if packet.command == :quit

          result = execute(packet.command, packet.param)
          send_packet(packet.command, result)
        end
      ensure
        @client.close
      end

      private

      def receive_packet
        RedXML::Protocol.read_packet(@client)
      end

      def send_packet(command, result)
        packet = RedXML::Protocol::PacketBuilder.new.command(command).param(result)
        @client.write packet.data
      end

      def parse(data)
        RedXML::Protocol::PacketBuilder.parse(data)
      end

      def send_hello
        hello = RedXML::Protocol::PacketBuilder.hello("RedXML-#{RedXML::Server::VERSION}")
        @client.write hello.data
      end

      def execute(command, param)
        # FIXME: you better get rid of this switch, its not nice
        case command
        when :execute
          # RedXML::Server::XQuery.execute(param)
          "Fake result for execute with #{param}"
        when :ping
          nil
        else
          fail NotImplementedError, "Command #{command} is not currently supported."
        end
      end
    end
  end
end

require 'spec_helper'
require 'timeout'
require 'socket'

RSpec.describe RedXML::Server::ServerWorker do
  describe '#start' do
    context 'with client' do
      let(:options) { { bind: '127.0.0.1', port: 33965, concurency: 25 } }
      let(:socket) do
        s = nil
        expect {
          s = TCPSocket.new('localhost', 33965)
        }.to_not raise_error
        s
      end
      let(:hello_packet) { RedXML::Protocol::PacketBuilder.hello("RedXML-#{RedXML::Server::VERSION}") }
      subject { RedXML::Server::ServerWorker.new(options) }

      before(:all) do
        @server_thread = Thread.new do
          subject.run
        end
      end

      after(:all) do
        @server_thread.thread_variable_set(:stop, true)
        res = @server_thread.join(3)
        res.kill unless res.nil?
      end

      it 'sends hello with version' do
        Timeout.timeout(3) do
          hello = hello_packet.data
          recv = socket.read(hello.length)
          expect(recv).to eq hello
        end
      end

      it 'responds to ping' do
        ping = RedXML::Protocol::PacketBuilder.ping.data
        recv = nil
        Timeout.timeout(3) do
          _hello = socket.read(hello_packet.data.length)

          socket.write ping
          recv = socket.read(ping.length)
        end
        expect(recv).to eq ping
      end

      it 'responds with error packet' do
        length = 7
        version = 1
        command_tag = 'x'
        param_length = 0
        data = [length, version, command_tag, param_length].pack("NNa1Nxx")

        recv = nil
        Timeout.timeout(3) do
          _hello = socket.read(hello_packet.data.length)

          socket.write data
          recv = RedXML::Protocol.read_packet socket
        end
        expect(recv.command).to eq :execute
        expect(recv.error?).to be true
      end

      it 'responds with error packet' do
        class_double('RedXML::Server::Executors::Ping').as_stubbed_const.tap do |klass|
          allow(klass).to receive(:new) do
            double('ping executor').tap do |inst|
              expect(inst).to receive(:execute) do
                fail 'test error message'
              end
            end
          end
        end
        data = RedXML::Protocol::PacketBuilder.ping.data
        recv = nil
        Timeout.timeout(3) do
          _hello = socket.read(hello_packet.data.length)

          socket.write data
          recv = RedXML::Protocol.read_packet socket
        end
        expect(recv.command).to eq :ping
        expect(recv.error?).to be true
        expect(recv.param).to eq 'test error message'
      end
    end

    it 'accepts client' do
      expect(subject).to receive(:start_server_socket)
      allow(subject).to receive(:client_pool).with(no_args) do
        double('client pool').tap do |pool|
          expect(pool).to receive(:que)
        end
      end
      allow(subject).to receive(:socket) do
        double('socket').tap do |socket|
          expect(socket).to receive(:accept)
        end
      end
      allow(subject).to receive(:running?).and_return(false)
      subject.run
    end
  end
end

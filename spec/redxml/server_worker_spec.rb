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
          hello = socket.read(hello_packet.data.length)

          socket.write ping
          recv = socket.read(ping.length)
        end
        expect(recv).to eq ping
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

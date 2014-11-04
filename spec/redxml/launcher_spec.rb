require 'spec_helper'

RSpec.describe RedXML::Server::Launcher do
  before do
    RedXML::Server.options = {
      concurency: 1,
      verbose: true,
      pidfile: '/tmp/redxml.test'
    }
    @options = RedXML::Server.options
  end

  after do
    RedXML::Server.options = @options
  end

  describe '#run' do
    before do

      @server = class_double('RedXML::Server::ServerWorker').as_stubbed_const
      @db_conn = class_double('RedXML::Server::DatabaseConnection').as_stubbed_const
    end

    it 'starts server' do
      expect(@server).to receive(:new).with(@options)
      allow(@db_conn).to receive(:new).with(@options)

      launcher = RedXML::Server::Launcher.new(@options)
      allow(launcher).to receive(:server) do
        double('server').tap do |server|
          expect(server).to receive(:run)
        end
      end
      expect(launcher).to receive(:create_server).and_call_original

      launcher.run
    end

    it 'connects to db' do
      skip 'db not implemented'
      allow(@server).to receive(:new).with(@options)
      expect(@db_conn).to receive(:new).with(@options)

      launcher = RedXML::Server::Launcher.new(@options)
      allow(launcher).to receive(:server) do
        double('server').tap do |server|
          allow(server).to receive(:run)
        end
      end
      expect(launcher).to receive(:create_database_connection).and_call_original

      launcher.run
    end
  end

  describe '#stop' do
    it 'stops server' do
      launcher = RedXML::Server::Launcher.new(@options)
      allow(launcher).to receive(:server) do
        double('server').tap do |server|
          expect(server).to receive(:shutdown)
        end
      end
      launcher.stop
    end
  end
end

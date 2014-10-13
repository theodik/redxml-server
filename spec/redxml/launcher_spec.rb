require 'spec_helper'

RSpec.describe RedXML::Server::Launcher do
  describe '#run' do
    before do
      RedXML::Server.options = {
        concurency: 1,
        verbose: true,
        pidfile: '/tmp/redxml.test'
      }
      @options = RedXML::Server.options

      @server = class_double('RedXML::Server::Server').as_stubbed_const
      @db_conn = class_double('RedXML::Server::DatabaseConnection').as_stubbed_const
    end

    it 'creates workers' do
      expect(@server).to receive(:new).with(@options)
      expect(@db_conn).to receive(:new).with(@options)

      launcher = RedXML::Server::Launcher.new(@options)
      expect(launcher).to receive(:create_server).and_call_original
      expect(launcher).to receive(:create_database_connection).and_call_original

      launcher.run
    end
  end
end

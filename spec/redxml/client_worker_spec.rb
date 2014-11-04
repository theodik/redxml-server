require 'spec_helper'
require 'stringio'
require 'redxml/protocol'

RSpec.describe RedXML::Server::ClientWorker do
  describe '#process' do
    it 'answers hello with version' do
      client = StringIO.new
      response_pos = client.length

      subject = described_class.new(client)
      subject.process

      response = StringIO.new(client.string)
      packet = RedXML::Protocol.read_packet(response)
      expect(packet.command).to eq :hello
      expect(packet.param).to eq "RedXML-#{RedXML::Server::VERSION}"
    end
  end
end

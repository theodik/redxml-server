require 'spec_helper'
require 'stringio'
require 'redxml/protocol'

RSpec.describe RedXML::Server::ClientWorker do
  describe '#process' do
    let(:client) { StringIO.new }
    let(:response) do
      response = StringIO.new(client.string)
      RedXML::Protocol.read_packet(response)
    end
    subject { described_class.new(client) }

    it 'answers hello with version' do
      subject.process

      expect(response.command).to eq :hello
      expect(response.param).to eq "RedXML-#{RedXML::Server::VERSION}"
    end
  end
end

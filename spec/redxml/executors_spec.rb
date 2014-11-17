require 'spec_helper'

RSpec.describe RedXML::Server::Executors do
  before(:all) do
    RedXML::Server.options = {db: {driver: :redis}}
    @db_interface = RedXML::Server::Database.checkout
  end

  after(:all) do
    RedXML::Server::Database.checkin @db_interface
  end

  subject { described_class.new(@db_interface, param) }

  describe RedXML::Server::Executors::Ping do
    let(:param) { nil }

    it 'returns nil' do
      expect(subject.execute).to be_nil
    end
  end

  xdescribe RedXML::Server::Executors::Execute do
    let(:param) { "doc('catalog.xml')/catalog" }

    it 'returns string as resut' do
      pending
      expect(subject.execute).to be_a String
    end
  end
end

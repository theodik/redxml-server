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

  describe RedXML::Server::Executors::LoadDocument do
    let(:param) { %w(test new catalog.xml).join("\1") }
    it 'returns document' do
      redis_clear
      redis_load 'catalog_dump.json'

      result = subject.execute

      expect(result).to match /<catalog>/
    end

    it 'fails if not found' do
      redis_clear
      expect {
        subject.execute
      }.to raise_error RedXML::Server::Transformer::MappingException
    end
  end

  describe RedXML::Server::Executors::SaveDocument do
    let(:param) { ['test', 'new', 'catalog.xml', '<xml>test</xml>'].join("\1") }

    it 'returns ok' do
      redis_clear

      expect(subject.execute).to eq 'ok'
    end

    it 'fails if already exists' do
      redis_clear
      redis_load 'catalog_dump.json'

      expect {
        subject.execute
      }.to raise_error RedXML::Server::Transformer::MappingException
    end
  end

  describe RedXML::Server::Executors::Begin do
    let(:param) { [] }

    it 'returns ok' do
      expect(subject.execute).to eq 'ok'
    end

    it 'starts transaction' do
      subject.execute
      expect(@db_interface.transaction_obj).to_not be_nil
      @db_interface.commit
    end
  end

  describe RedXML::Server::Executors::Commit do
    let(:param) { [] }

    it 'returns ok' do
      expect(subject.execute).to eq 'ok'
    end

    it 'starts transaction' do
      @db_interface.transaction
      subject.execute
      expect(@db_interface.transaction_obj).to be_nil
    end
  end
end

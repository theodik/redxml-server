require 'spec_helper'

RSpec.describe RedXML::Server::Database do
  describe '::connection' do
    before do
      RedXML::Server.options = {db: {driver: :redis}}
    end

    it 'returns connection' do
      expect(described_class.connection).to be_a_kind_of RedXML::Server::DatabaseInterface
    end
  end
end

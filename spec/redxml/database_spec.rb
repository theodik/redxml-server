require 'spec_helper'

RSpec.describe RedXML::Server::Database do
  before(:all) do
    RedXML::Server.options = {db: {driver: :redis}}
  end

  describe RedXML::Server::Database::ConnectionPool do
      it 'returns new connection' do
        conn1 = subject.checkout
        conn2 = subject.checkout

        expect(conn1).to_not be conn2

        subject.checkin conn1
        subject.checkin conn2
      end

      it 'doesnt create new connection after checkin' do
        conn = subject.checkout
        conn_id1 = conn.object_id
        subject.checkin conn

        conn = subject.checkout
        conn_id2 = conn.object_id
        subject.checkin conn

        expect(conn_id1).to eq conn_id2
      end
  end
end

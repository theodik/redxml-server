require 'spec_helper'

RSpec.describe 'Transactions' do
  let(:env_col) { '1:1:2<content' }
  let(:root_id) { '1' }
  let(:parent_node_id) { '1:2>0' }
  let(:node_id) { '1:2>0:3>0' }

  let(:manager) { RedXML::Server::Database::TransactionManager.instance }

  let(:t1) { RedXML::Server::Database.checkout }
  let(:t2) { RedXML::Server::Database.checkout }

  before do
    redis_clear
    redis_load 'transaction.json'
    t1.transaction
    t2.transaction
  end

  after do
    t1.commit
    t2.commit
    expect(manager.locks).to be_empty
    RedXML::Server::Database.checkin t1
    RedXML::Server::Database.checkin t2
  end

  it 'ir x sx' do
    t2.delete_from_hash(env_col, [parent_node_id])
    expect {
      t1.get_hash_value(env_col, node_id)
    }.to raise_error
  end

  it 'ir x nr' do
    t2.get_hash_value(env_col, node_id)
    expect {
      t1.get_hash_value(env_col, parent_node_id)
    }.to_not raise_error
  end

  it 'nr x sx' do
    t2.delete_from_hash(env_col, [node_id]) # sx
    expect {
      val = t1.get_hash_value(env_col, node_id) # nr
    }.to raise_error
  end

  it 'ix x sx' do
    t2.delete_from_hash(env_col, [node_id])
    expect {
      t1.delete_from_hash(env_col, [root_id])
    }.to raise_error
  end

  it 'cx x sx' do
    t2.delete_from_hash(env_col, [node_id])
    expect {
      t1.delete_from_hash(env_col, [parent_node_id])
    }.to raise_error
  end

  it 'sx x nr' do
    t2.delete_from_hash(env_col, [node_id])
    expect {
      t1.get_hash_value(env_col, node_id)
    }.to raise_error
  end
end

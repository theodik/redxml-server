require 'spec_helper'

describe RedXML::Server::XQuery::Parser do
  it 'initializes parser' do
    expect {
      RedXML::Server::XQuery::Parser.new
    }.to_not raise_error
  end
end

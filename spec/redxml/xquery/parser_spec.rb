require 'spec_helper'

describe RedXML::Server::XQuery::Parser do
  it 'initializes parser' do
    expect {
      RedXML::Server::XQuery::Parser.new
    }.to_not raise_error
  end

  describe '#parse_xquery' do
    it 'parses query into xml' do
      xml = subject.send(:parse_xquery, '.')
      expect(xml).to be_a Nokogiri::XML::Document
    end
  end

  describe '#build_expression_tree' do
    it 'create expression' do
      expect {
        xml = subject.send(:parse_xquery, '.')
        expr = subject.send(:build_expression_tree, xml)
        expect(expr).to be_a RedXML::Server::XQuery::Expressions::Expression
      }.to_not raise_error
    end
  end
end

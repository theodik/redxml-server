require 'nokogiri'
require 'redxml/server/xquery/expression'
# require_relative "parser_extension/Parsers"

module RedXML
  module Server
    module XQuery
      class Parser
        def initialize
          @parser = Parsers::UpdateParser.new
        end

        def parse(query)
          str = @parser.parse_XQuery(query)

          xml_doc = Nokogiri.XML(str) do |config|
            config.default_xml.noblanks
          end

          Expression.create(xml_doc)
        end
      end
    end
  end
end

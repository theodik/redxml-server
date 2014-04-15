require 'redxml/server/xquery/expression'
require 'redxml/server/xquery/Parsers'

module RedXML
  module Server
    module XQuery
      class ParseException < StandardError
      end

      class Parser
        def initialize
          @parser = Parsers::UpdateParser.new
        end

        def parse(query)
          expr = parse_xquery(query)
          build_expression_tree(expr)
        end

        private

        ##
        # Parse xquery and returns xml
        # representation of a expression
        def parse_xquery(query)
          begin
          str = @parser.parse_XQuery(query)
          rescue Parsers::ParseException => e
            fail ParseException, 'Parsing error'
          end

          Nokogiri.XML(str) do |config|
            config.default_xml.noblanks
          end
        end

        ##
        # Create expression tree from xml
        def build_expression_tree(tree)
          Expressions::Expression.create(tree)
        end
      end
    end
  end
end

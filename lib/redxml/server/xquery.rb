require 'redxml/server/xquery/exceptions'
require 'redxml/server/xquery/parser'

module RedXML
  module Server
    module XQuery
      module_function

      def execute(query)
        expression = Parser.new.parse(query)
        # Solver.new(environment, collection).solve(expression)
      end
    end
  end
end

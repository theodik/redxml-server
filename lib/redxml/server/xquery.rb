require 'redxml/server/xquery/exceptions'
require 'redxml/server/xquery/parser'
require 'redxml/server/xquery/processor'
require 'redxml/server/xquery/solver'

module RedXML
  module Server
    module XQuery
      class Executor

        def initialize(db_interface, environment, collection)
          @db_interface = db_interface
          @environment  = environment
          @collection   = collection
        end

        def execute(query)
          expression = Parser.new.parse(query)
          Solvers::Solver
            .new(@db_interface, @environment, @collection)
            .solve(expression)
        end
      end
    end
  end
end

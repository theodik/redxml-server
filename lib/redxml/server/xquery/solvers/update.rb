module RedXML
  module Server
    module XQuery
      module Solvers
        class Update
          def initialize(path_solver)
            @path_solver = path_solver
            @delete_solver = Delete.new(@path_solver)
            @insert_solver = Insert.new(@path_solver)
          end

          def solve(expression, contexts=[], pipelined=true)
            contexts << XQuerySolverContext.new if contexts.empty?

            case expression.type
            when 'DeleteExpr'
              @delete_solver.solve(expression, contexts, pipelined)
            when 'InsertExpr'
              @insert_solver.solve(expression, contexts, pipelined)
            else
              fail StandardError, "not implemented #{expression.type}"
            end
          end
        end
      end
    end
  end
end

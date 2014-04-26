module RedXML
  module Server
    module XQuery
      module Solvers
        class Delete
          def initialize(path_solver)
            @path_solver = path_solver
          end

          def solve(expression, contexts, pipelined = true)
            location = expression.location

            nodes_to_delete = []

            contexts.each do |context|
              case location.type
              when 'RelativePathExpr'
                path = @path_solver.solve(expression.location, context)
                nodes_to_delete.concat(path)
              when 'VarRef'
                nodes_to_delete.concat(context.variables[location.var_name])
              else
                fail NotSupportedError, expression.location.type
              end
            end

            DeleteProcessor.delete_nodes(nodes_to_delete, pipelined)
          end
        end
      end
    end
  end
end

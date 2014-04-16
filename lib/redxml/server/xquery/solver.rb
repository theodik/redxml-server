module RedXML
  module Server
    module XQuery
      module Solvers
        # rubocop:disable LineLength
        #autoload :Comparison,               'redxml/server/xquery/solvers/comparison"
        # rubocop:enable LineLength

        class Solver
          def initialize(context)
            @path_solver = PathSolver.new(context.environment,
                                          context.collection)
            @update_solver = UpdateSolver.new(@path_solver)
            @flwor_solver = FLWORSolver.new(@path_solver, @update_solver)
          end

          def solve(expression)
            case expression.type
            when 'FLWORExpr'
              results = @flwor_solver.solve(expression)
              prepare_results(results)
            when 'RelativePathExpr'
              results = @path_solver.solve(expression)
              prepare_results(results)
            when 'DeleteExpr', 'InsertExpr' # simple update queries
              @update_solver.solve(expression)
            when 'DirElemConstructor'
              ctx = XQuerySolverContext.new
              str = expression.get_elem_str(@path_solver, ctx, @flwor_solver)
              [str]
            else
              fail StandardError, "not implemented #{expression.type}"
            end
          end

          private

          def prepare_results(results)
            results.map do |result|
              if result.kind_of? ExtendedKey
                @path_solver.path_processor.get_node(result)
              else
                result
              end
            end
          end
        end

        class Context
          attr_reader :final
          attr_accessor :passed, :order, :variables

          def initialize(variables = [])
            # in hash can be KeyElementBuilders or prepared Nodes
            @variables = variables
            @cycles = [] # cycles contain another solver contexts
            @final = true
            @passed = true
            @order = -1
          end

          def cycles
            @cycles.empty? ? [self] : @cycles
          end

          def populate(var_name, var_contents)
            var_contents.each do |content|
              @new_variables = @variables.clone
              @new_variables[var_name] = [content]
              new_context = self.class.new(@new_variables)
              @cycles << new_context
            end
            @variables = nil
            @final = false
          end
        end
      end
    end
  end
end

module RedXML
  module Server
    module XQuery
      module Solvers
        autoload :Comparison,     'redxml/server/xquery/solvers/comparison'
        autoload :Delete,         'redxml/server/xquery/solvers/delete'
        autoload :FLWOR,          'redxml/server/xquery/solvers/flwor'
        autoload :ForLetClause,   'redxml/server/xquery/solvers/for_let_clause'
        autoload :Function,       'redxml/server/xquery/solvers/function'
        autoload :Insert,         'redxml/server/xquery/solvers/insert'
        autoload :OrderClause,    'redxml/server/xquery/solvers/order_clause'
        autoload :Path,           'redxml/server/xquery/solvers/path'
        autoload :Predicate,      'redxml/server/xquery/solvers/predicate'
        autoload :ReturnExpr,     'redxml/server/xquery/solvers/return_expr'
        autoload :Update,         'redxml/server/xquery/solvers/update'
        autoload :WhereClause,    'redxml/server/xquery/solvers/where_clause'

        class Solver
          def initialize(db_interface, environment, collection)
            @db_interface  = db_interface
            @path_solver   = Path.new(@db_interface, environment, collection)
            @update_solver = Update.new(@path_solver)
            @flwor_solver  = FLWOR.new(@path_solver, @update_solver)
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

        class XQuerySolverContext
          attr_reader :final
          attr_accessor :passed, :order, :variables

          def initialize(variables = {})
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

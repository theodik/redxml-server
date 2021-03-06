module RedXML
  module Server
    module XQuery
      module Solvers
        class WhereClause
          def initialize(path_solver)
            @path_solver = path_solver
          end

          def solve(where_expr, context)
            # puts "solving #{where_expr.type}"

            specific_where_expr = where_expr.value
            case specific_where_expr.type
            when 'ComparisonExpr'
              values1 = get_comparison_values(specific_where_expr.value1, context)
              operator = specific_where_expr.operator
              values2 = get_comparison_values(specific_where_expr.value2, context)
              result = Comparison.evaluate(values1, operator, values2)
              context.passed = result

            else
              fail StandardError, "no other where clause solving " \
                          "implmenented: #{where_expr.value.type}"
            end
          end

          def get_comparison_values(expression, context)
            case expression.type
            when 'RelativePathExpr', 'VarRef'
              results = []
              if expression.type == 'RelativePathExpr'
                results = @path_solver.solve(expression, context)
              else
                results = context.variables[expression.var_name]
              end
              final_values = []
              results.each do |result|
                final_result = result
                if result.kind_of?(ExtendedKey)
                  final_result = @path_solver.path_processor
                                    .get_node_content(result)
                end
                final_values << Expressions::DummyExpr.new('StringLiteral', final_result)
              end
              return final_values

              # String and Numeric literals return as are
              # literal objects, so it is recognisable the type
            when 'NumericLiteral'
              # returning numeric
              return [expression]
            when 'StringLiteral'
              # returning string
              return [Expressions::DummyExpr.new('StringLiteral', expression.text[1..-2])]

            else
              fail StandardError, "other types of predicate values " \
                          "are not supported yet: #{expression.type}"
            end
          end
        end
      end
    end
  end
end

module RedXML
  module Server
    module XQuery
      module Solvers
        class ReturnExpr
          def initialize(path_solver, update_solver)
            @path_solver   = path_solver
            @update_solver = update_solver
          end

          def solve(return_expr, contexts)
            results = []
            delete = false

            add_result = Proc.new do |context|
              # compose result
              result = ''
              return_expr.parts.each do |part|
                case part.type
                when 'ReturnText'
                  result << part.text
                when 'RelativePathExpr', 'VarRef'
                  ext_keys = []
                  if part.type == 'RelativePathExpr'
                    ext_keys = @path_solver.solve(part, context)
                  else
                    ext_keys = context.variables[part.var_name]
                  end
                  path_result = ''
                  if ext_keys
                    ext_keys.each do |key|
                      path_result << @path_solver.path_processor.get_node(key).to_s
                    end
                  end
                  result << path_result
                when 'DirElemConstructor'
                  result << part.get_elem_str(@path_solver, context)
                when 'DeleteExpr', 'InsertExpr' # and other
                  fail StandardError, "update expressions should be " \
                                 "performed another way -> atomically"
                else
                  fail NotSupportedError, part.type
                end
              end
              results << result
            end
            # declare contexts
            final_contexts = []

            if contexts.length > 0 && contexts[0].order == -1
              final_contexts = contexts
            else
              sorting_hash = {}
              contexts.each_with_index do |context, index|
                sorting_hash[context.order] = index
              end
              sorting_hash.keys.sort.each do |sort_key|
                context = contexts[sorting_hash[sort_key]]
                final_contexts << context
              end
            end

            first_part = return_expr.parts[0]
            if first_part.type == 'DeleteExpr' || first_part.type == 'InsertExpr'
              if return_expr.parts.length > 1
                fail NotImplementedError, "more update expressions within" \
                                          "one query not implemented"
              end
              # update operations will take care of their own pipelining
              # performing update here, sending all contexts
              @update_solver.solve(first_part, final_contexts, true)
            else
              # perform all other operations (non-update ones) here
              final_contexts.each do |context|
                add_result.call(context)
              end
            end

            results
          end
        end
      end
    end
  end
end

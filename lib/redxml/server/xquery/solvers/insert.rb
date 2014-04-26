module RedXML
  module Server
    module XQuery
      module Solvers
        class Insert
          def initialize(path_solver)
            @path_solver = path_solver
            @insert_processor = InsertProcessor.new(path_solver)
          end

          def solve(expression, contexts, pipelined)
            target_location_keys = nil
            location = expression.location

            # load all possible locations from all contexts and ensure
            # that there is only one location
            location_keys = []
            # load all locations
            contexts.each do |context|
              case location.type
              when 'RelativePathExpr'
                location_keys.concat(@path_solver.solve(location, context))
              when 'VarRef'
                location_keys.concat(context.variables[location.var_name])
              else
                fail NotSupportedError, expression.location.type
              end
            end

            # check if they are all identical
            unless ensure_identical(location_keys)
              fail StandardError, "wrong number of target location nodes, " \
                        "it is #{target_location_keys.length}, should be 1"
            end

            # set location extended key
            target_location_key = location_keys[0]

            @insert_processor.insert_nodes(expression.items,
                                           target_location_key,
                                           expression.target,
                                           pipelined,
                                           contexts)
          end

          def ensure_identical(extended_keys)
            prev_key_str = nil
            extended_keys.each do |ext_key|
              if !prev_key_str
                prev_key_str = ext_key.key_str
              elsif prev_key_str != ext_key.key_str
                return false
              end
            end
            true
          end
        end
      end
    end
  end
end

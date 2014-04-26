module RedXML
  module Server
    module XQuery
      module Solvers
        class Path
          attr_reader :path_processor

          def initialize(environment, collection)
            @function_solver = Function.new(environment, collection)
          end

          # returns keys or nodes, DOESN'T change context
          def solve(path_expr, context = XQuerySolverContext.new)
            # here is nothing to cycle, solved in FLWOR solvers only

            @path_processor = nil
            @last_step = false

            # TODO: we need to grab each step and sequentially take care of it
            # results are prepared nodes with all data or KeyElementBuilders
            results = []
            path_expr.steps.each do |step|
              if step.step_type == :STARTING
                results = solve_step(step, context)
              elsif results.empty?
                return []
              else
                new_results = []
                results.each_with_index do |res, index|
                  @last_step = false if @last_step && index > 0
                  new_results.concat(solve_step(step, context, res))
                end
                results = new_results
              end
            end
            results
          end

          private

          def solve_step(step_expression, context, actual_result = nil)
            if @last_step
              fail QueryStringError, "previous step was already " \
                "finalizing, actual step: #{step_expression.value.type}, " \
              "content: #{step_expression.value.text}"
            end

            specified_step = step_expression.value
            predicates = step_expression.predicates

            ################
            # FIRST step
            ################
            if actual_result.nil?
              # here is allowed only doc FunctionCall or VarRef
              case specified_step.type
              when 'FunctionCall'
                parameters = specified_step.function_params
                if specified_step.function_name == 'doc' &&
                  parameters.length == 1 &&
                  parameters[0].type == 'StringLiteral'
                  key_builder = @function_solver.doc(parameters[0].value)
                  @path_processor = KeyPathProcessor.new(key_builder)
                else
                  fail QueryStringError, "other function then doc with 1 " \
                    "string parameter is not allowed, here we have: " \
                    "#{specified_step.function_name}(#{parameters.length} " \
                    "params, type(1):#{parameters[0].type})"
                end

                return [ExtendedKey.new(key_builder)]
                # probably no need to solve predicates
              when 'VarRef'
                nodes = context.variables[specified_step.var_name]
                if !nodes || nodes.empty?
                  fail QueryStringError,
                       "such variable (#{specified_step.var_name}) not found "\
                       "in current context, or content sequence is empty"
                end
                @path_processor = KeyPathProcessor.new(nodes[0].key_builder)
                final_nodes = nodes
                # maybe predicates?
                unless predicates.empty?
                  final_nodes = []

                  # solve predicates
                  predicate_solver = Predicate.new(@path_processor)
                  nodes.each do |node|
                    if predicate_solver.evaluate(predicates, node, 1, 1)
                      final_nodes << node
                    end
                  end
                end
                final_nodes
              end

              ################
              # NEXT step
              ################
            else
              case specified_step.type
              when 'AbbrevForwardStep' # element or attribute
                case specified_step.value_type
                when :ELEMENT
                  ### results setting
                  results = get_child_elements(actual_result,
                                               specified_step.value_name,
                                               step_expression.step_type)
                when :ATTRIBUTE
                  @last_step = true
                  case step_expression.step_type
                  when :ORDINARY
                    ### results setting
                    attr = @path_processor.get_attribute(actual_result,
                                                      specified_step.value_name)
                    results = [attr]
                  when :RECURSIVE
                    ### results setting
                    results = get_attributes_recursively(actual_result,
                                                         specified_step.value_name)
                  else
                    fail StandardError, "impossible, abbrevforward ATTRIBUTE, " \
                      "value name: #{specified_step.value_name}"
                  end
                when :TEXT
                  @last_step = true
                  case step_expression.step_type
                  when :ORDINARY
                    ### results setting
                    results = [@path_processor.get_text(actual_result)]
                  when :RECURSIVE
                    ### results setting
                    results = @path_processor.get_descendant_texts(actual_result)
                  else
                    fail StandardError, "impossible, abbrevforward ATTRIBUTE, " \
                      "value name: #{specified_step.value_name}"
                  end
                end
              when 'FunctionCall'
                @last_step = true
                # only text() supported
                if specified_step.function_name == 'text' &&
                  specified_step.function_params.empty?
                  ### results setting
                  results = @path_processor.get_texts(actual_result)
                else
                  fail StandardError, 'other function not implemented'
                end
              else
                fail StandardError, "other type of specified step " \
                  "not implemented: #{specified_step.type}"
              end

              # remove nils
              temp_results = results
              results = []
              temp_results.each do |res|
                results << res unless res
              end

              # check if predicates exist
              return results if predicates.empty?

              # predicate solving for NEXT steps
              final_results = []
              results_size = results.length
              results.each_with_index do |res, index|
                predicate_solver = PredicateSolver.new(@path_processor)
                predicates_result = predicate_solver.evaluate(predicates,
                                                              res,
                                                              index + 1,
                                                              results_size)
                final_results << res if predicates_result
              end
              final_results
            end
          end

          def get_child_elements(actual_result, elem_name, step_type)
            case step_type
            when :ORDINARY
              @path_processor.get_children_elements(actual_result, elem_name)
            when :RECURSIVE
              @path_processor.get_descendant_elements(actual_result, elem_name)
            else
              fail StandardError, 'impossible'
            end
          end

          def get_attributes_recursively(actual_result, attr_name)
            elements = @path_processor.get_descendant_elements(actual_result)
            elements.map do |elem|
              @path_processor.get_attribute(elem, attr_name)
            end
          end
        end
      end
    end
  end
end

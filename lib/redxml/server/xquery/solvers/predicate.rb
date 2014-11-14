module RedXML
  module Server
    module XQuery
      module Solvers
        class Predicate
          def initialize(path_processor)
            @path_processor = path_processor
          end

          # it assumes that predicate_expressions are in array,
          # even if only one provided
          def evaluate(predicate_expressions, actual_result, position, max_position)
            predicate_expressions.each do |predicate|
              predicate = evaluate_predicate(predicate,
                                             actual_result,
                                             position,
                                             max_position)
              return false unless predicate
            end
            true
          end

          private

          # returns true or false
          def evaluate_predicate(predicate_expression, actual_result, position, max_position)
            predicate = predicate_expression.value
            case predicate.type
              ######################
              # Comparison handling
              ######################
            when 'ComparisonExpr'
              values1 = get_predicate_values(predicate.value1,
                                             actual_result,
                                             position, max_position)
              operator = predicate.operator
              values2 = get_predicate_values(predicate.value2,
                                             actual_result,
                                             position,
                                             max_position)
              # value1 and value2 are always arrays
              # even with only one participant
              return Comparison.evaluate(values1, operator, values2)

              ######################
              # Element or Attribute exists handling
              ######################
            when 'AbbrevForwardStep'
              if predicate.value_type == :ELEMENT
                res = @path_processor.get_children_elements(actual_result, predicate.value_name)
                return false if res.empty?

              elsif predicate.value_type == :ATTRIBUTE
                if !@path_processor.get_attribute(actual_result, predicate.value_name)
                  return false
                end
              else
                fail StandardError, 'impossible'
              end
              return true

              ######################
              # Single function handling
              ######################
            when 'FunctionCall'
              if predicate.function_name == 'last' && predicate.function_params.empty?
                return position == max_position
              elsif predicate.function_name == 'position' && predicate.function_params.empty?
                return true
              else
                fail StandardError, 'not implemented'
              end

              ######################
              # Integer handling
              ######################
            when 'IntegerLiteral'
              return predicate.text.to_i == position
            end
          end

          def get_predicate_values(expression, actual_result, position, max_position)
            case expression.type
            when 'FunctionCall'
              # we support only functions 'last' and 'position' for now
              if expression.function_name == 'last' && expression.function_params.empty?
                # returning numeric
                return [Expressions::DummyExpr.new('NumericLiteral', max_position)]
              elsif expression.function_name == 'position' && expression.function_params.empty?
                # returning numeric
                return [Expressions::DummyExpr.new('NumericLiteral', position)]
              else
                fail StandardError, "not implemented function #{expression.function_name}"
              end
            when 'ContextItemExpr'
              if expression.text != "."
                fail StandardError, "other ContextItemExpr.content not supported: #{expression.content}"
              end
              #returning string
              return [Expressions::DummyExpr.new('StringLiteral', @path_processor.get_node_content(actual_result))]

            when 'AbbrevForwardStep'
              unless @path_processor.valid_elem?(actual_result)
                fail QueryStringError, 'after text resulting step cannot be predicate of this format'
              end

              results = []
              if expression.value_type == :ELEMENT
                res = @path_processor.get_children_elements(actual_result, expression.value_name)
                res.each do |r|
                  results << @path_processor.get_node_content(r)
                end
              elsif expression.value_type == :ATTRIBUTE
                results = [@path_processor.get_attribute(actual_result, expression.value_name)]
              else
                fail StandardError, "impossible"
              end

              # returning string
              return results.map do |rs|
                Expressions::DummyExpr.new('StringLiteral', rs)
              end
              # String and Numeric literals return as are - literal objects, so
              # it is recognisable the type
            when 'NumericLiteral'
              # returning numeric
              return [expression]
            when 'StringLiteral'
              # returning string
              return [Expressions::DummyExpr.new('StringLiteral', expression.text.gsub("'", '').gsub('"', ''))]
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

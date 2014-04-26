module RedXML
  module Server
    module XQuery
      module Solvers
        class Comparison
          GENERAL_EQ = '='
          GENERAL_NE = '!='
          GENERAL_GT = '>'
          GENERAL_GE = '>='
          GENERAL_LT = '<'
          GENERAL_LE = '<='

          VALUE_EQ = 'eq'
          VALUE_NE = 'ne'
          VALUE_GT = 'gt'
          VALUE_GE = 'ge'
          VALUE_LT = 'lt'
          VALUE_LE = 'le'

          # returns true or false
          def self.evaluate(values1, operator, values2)
            if operator.type == 'ValueComp' \
              && (values1.length > 1 || values2.length > 1)
              fail TypeError, "unable to compare sequences " \
                              "with more then one item with " \
                              "respect to VALUE comparison"
            end

            values1.each do |value1|
              values2.each do |value2|
                case operator.type
                when 'ValueComp'
                  if value1.type == value2.type && value1.type != 'Literal'
                    result = evaluate_value_comp(value1, operator, value2)
                    return true if result
                  else
                    fail TypeError, 'value comp cannot compare ' \
                                    'different types of values'
                  end
                when 'GeneralComp'
                  result = evaluate_general_comp(value1, operator, value2)
                  return true if result

                else
                  fail StandardError, "impossible - other type of " \
                                      "comparison: #{operator.type}"
                end
              end
            end
            false
          end

          private

          def self.evaluate_value_comp(value1, operator, value2)
            case operator.text
            when VALUE_EQ
              return value1.text == value2.text
            when VALUE_NE
              return value1.text != value2.text
            when VALUE_GT
              return value1.text > value2.text
            when VALUE_GE
              return value1.text >= value2.text
            when VALUE_LT
              return value1.text < value2.text
            when VALUE_LE
              return value1.text <= value2.text
            else
              fail StandardError, 'not possible or implemented'
            end
          end

          def self.evaluate_general_comp(val1, operator, val2)
            value1 = nil
            value2 = nil
            if val1.type == 'NumericLiteral'
              # try to cast value2 to numeric
              value2 = make_number(val2.text)
              unless value2
                fail TypeError, "unable to cast '#{val2.text}' to a numeric " \
                                "value while comparing with: #{val1.text}"
              end
              value1 = make_number(val1.text)
            elsif val2.type == 'NumericLiteral'
              # try to cast value1 to numeric
              value1 = make_number(val1.text)
              unless value1
                fail TypeError, "unable to cast '#{val1.text}' to a numeric " \
                                "value while comparing with: #{val2.text}"
              end
              value2 = make_number(val2.text)
            else
              value1 = val1.text
              value2 = val2.text
            end
            # value1 = value1.text
            # value2 = value2.text
            # no1 = make_number(value1)
            # if(no1 != nil)
            # no2 = make_number(value2)
            # if(no2 != nil)
            # value1 = no1
            # value2 = no2
            # else
            # value1 = value1.to_s
            # value2 = value2.to_s
            # end
            # else
            # value1 = value1.to_s
            # value2 = value2.to_s
            # end

            case operator.text
            when GENERAL_EQ
              return value1 == value2
            when GENERAL_NE
              return value1 != value2
            when GENERAL_GT
              return value1 > value2
            when GENERAL_GE
              return value1 >= value2
            when GENERAL_LT
              return value1 < value2
            when GENERAL_LE
              return value1 <= value2
            else
              fail StandardError, "operator not possible or " \
                                  "implemented: #{operator.text}"
            end
          end

          def self.number?(value)
            !value.to_s.match(/\A[+-]?\d+?(\.\d+)?\Z/).nil?
          end
          alias_method :is_number?, :number?

          def self.make_number(value)
            Integer(value)
          rescue
            begin
              Float(value)
            rescue
              nil
            end
          end
        end
      end
    end
  end
end

module RedXML
  module Server
    module XQuery
      module Expressions
        class ComparisonExpr < Expression
          attr_reader :value1, :operator, :value2

          def initialize(node)
            super(node)

            if node.children.length != 3
              fail "wrong number of values in " \
                "Comparison - #{node.children.length}"
            end

            # value can be AbbrevForwardStep or some kind of literal
            @value1 = get_value(node.children[0])
            @operator = get_operator(node.children[1])
            @value2 = get_value(node.children[2])
          end

          private

          def get_value(node)
            # we don't count on predicates here
            val = Expressions.checked_reduce(node, 'AbbrevForwardStep')

            case val.name
            when 'DoubleLiteral', 'DecimalLiteral', 'IntegerLiteral'
              Expression.new(val.parent) # NumericLiteral
            when 'AbbrevForwardStep'
              AbbrevForwardStep.new(val)
            when 'RelativePathExpr'
              RelativePathExpr.new(val)
            when 'VarRef'
              VarRef.new(val)
            when 'StringLiteral'
              Expression.new(val)
            when 'FunctionCall'
              FunctionCall.new(val)
            when 'TOKEN'
              Expression.new(val.parent) # probably ContextItemExpr
            else
              fail "this type of value (#{val.name}) " \
                "is not supported as comparison parameter"
            end
          end

          def get_operator(node)
            op = Expressions.reduce(node)
            if op.name == 'TOKEN'
              op = op.parent
              Expression.new(op)
            else
              fail "this type of operator (#{val.name}) " \
                "is not supported as comparison operator"
            end
          end
        end
      end
    end
  end
end

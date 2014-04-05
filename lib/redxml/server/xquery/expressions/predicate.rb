module RedXML
  module Server
    module XQuery
      module Expressions
        class Predicate < Expression
          attr_reader :value

          def initialize(node)
            super(node)

            # we suppose, that predicate consists of '[' Expr ']'
            # so children[1] is our choice
            if node.children.length != 3
              fail "other children length (node.children.length) " \
                "than 3 not supported"
            end
            @value = get_value(Expressions.reduce(node.children[1]))
          end

          private

          def get_value(node)
            case node.name
            when 'ComparisonExpr'
              ComparisonExpr.new(node)
            when 'FunctionCall'
              FunctionCall.new(node)
            when 'IntegerLiteral'
              Expression.new(node)
            when 'AbbrevForwardStep', 'QName' # attr or elem
              AbbrevForwardStep.new(node)
            else
              fail "another predicate type not implemented " \
                "(#{node.name}), content #{node.content}"
            end
          end
        end
      end
    end
  end
end

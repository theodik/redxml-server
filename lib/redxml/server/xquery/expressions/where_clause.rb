module RedXML
  module Server
    module XQuery
      module Expressions
        class WhereClause < Expression
          attr_reader :value

          def initialize(node)
            super(node)
            reduced = Expressions.reduce(node.children[1])
            if reduced.name == 'ComparisonExpr'
              @value = ComparisonExpr.new(reduced)
            else
              fail "no other where clause implmenented: #{reduced.name}"
            end
          end
        end
      end
    end
  end
end
